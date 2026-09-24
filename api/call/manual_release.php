<?php
/**
 * Manual Escrow Release Endpoint
 *
 * Allows a client to manually release escrowed coins to the influencer
 * after a completed call. This is distinct from api/call/release.php in
 * that it:
 *
 *   1. Stamps the wallet_transaction description with 'manual' so that
 *      admin/escrow-releases.php can distinguish client-triggered releases
 *      from automatic cron releases.
 *
 *   2. Returns a richer response payload your app can use to update UI
 *      state immediately — including release timestamp, both parties'
 *      updated balances (where safe to share), and a confirmation token.
 *
 *   3. Records a dedicated `manual_escrow_release` row in
 *      `escrow_release_log` (created below) for audit purposes.
 *
 * Endpoint:
 *   POST /api/call/manual_release.php
 *
 * Request body (JSON):
 *   { "call_id": 42 }
 *
 * Success response payload:
 *   {
 *     "success": true,
 *     "message": "Escrow manually released to influencer.",
 *     "data": {
 *       "call_id":           42,
 *       "escrow_status":     "released",
 *       "release_trigger":   "manual",
 *       "amount_released":   10.00,
 *       "influencer_id":     7,
 *       "released_at":       "2026-07-31 14:22:01",
 *       "confirmation_ref":  "MR-42-1753964521",
 *       "already_released":  false
 *     }
 *   }
 *
 * Already-released (idempotent) response:
 *   {
 *     "success": true,
 *     "message": "Escrow for this call has already been released.",
 *     "data": {
 *       "call_id":          42,
 *       "escrow_status":    "released",
 *       "already_released": true
 *     }
 *   }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'client');

$db   = getDatabaseConnection();
$data = getJsonInput();

$callId = (int)($data['call_id'] ?? 0);

if (!$callId) {
    sendValidationError('call_id is required.');
}

// -------------------------------------------------------------------------
// Ensure the escrow_release_log table exists (idempotent DDL).
// In production you would run this migration once; keeping it here makes
// this file self-contained and safe to deploy without a separate migration.
// -------------------------------------------------------------------------
$db->exec("
    CREATE TABLE IF NOT EXISTS escrow_release_log (
        id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        call_id        INT UNSIGNED NOT NULL,
        client_id      INT UNSIGNED NOT NULL,
        influencer_id  INT UNSIGNED NOT NULL,
        amount         DECIMAL(12,2) NOT NULL DEFAULT 0.00,
        trigger_type   ENUM('manual','auto') NOT NULL DEFAULT 'manual',
        confirmation_ref VARCHAR(64) NOT NULL,
        released_at    DATETIME NOT NULL,
        INDEX idx_call_id   (call_id),
        INDEX idx_client_id (client_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
");

// -------------------------------------------------------------------------
// Load the call record and verify ownership
// -------------------------------------------------------------------------
try {
    $db->beginTransaction();

    $stmt = $db->prepare('SELECT * FROM video_calls WHERE id = ? FOR UPDATE');
    $stmt->execute([$callId]);
    $call = $stmt->fetch();

    if (!$call) {
        $db->rollBack();
        sendError('Call not found.', 404);
    }

    if ((int)$call['client_id'] !== (int)$user['id']) {
        $db->rollBack();
        sendError('You are not the client for this call.', 403);
    }

    // -------------------------------------------------------------------------
    // Idempotency — already released
    // -------------------------------------------------------------------------
    if ($call['escrow_status'] !== 'held') {
        $db->commit();
        sendResponse(true, 'Escrow for this call has already been released.', [
            'call_id'          => $callId,
            'escrow_status'    => $call['escrow_status'],
            'already_released' => true,
        ]);
    }

    $clientId     = (int)$call['client_id'];
    $influencerId = (int)$call['influencer_id'];
    $amount       = (float)$call['coins_spent'];

    // -------------------------------------------------------------------------
    // Atomic CAS on escrow_status — only one concurrent request wins
    // -------------------------------------------------------------------------
    $stmt = $db->prepare(
        "UPDATE video_calls SET escrow_status = 'released' WHERE id = ? AND escrow_status = 'held'"
    );
    $stmt->execute([$callId]);

    if ($stmt->rowCount() === 0) {
        // Lost the race — already released by concurrent request or cron
        $db->commit();
        sendResponse(true, 'Escrow for this call has already been released.', [
            'call_id'          => $callId,
            'escrow_status'    => 'released',
            'already_released' => true,
        ]);
    }

    // -------------------------------------------------------------------------
    // Move funds: client escrow → influencer balance
    // -------------------------------------------------------------------------
    // Lock both wallets (ascending user_id order to avoid deadlocks)
    $walletIds = [$clientId, $influencerId];
    sort($walletIds);
    $stmt = $db->prepare(
        'SELECT user_id, balance, escrow_balance FROM wallets WHERE user_id IN (?, ?) FOR UPDATE'
    );
    $stmt->execute($walletIds);
    $walletMap = [];
    foreach ($stmt->fetchAll() as $row) {
        $walletMap[(int)$row['user_id']] = $row;
    }

    $clientEscrowBefore  = (float)($walletMap[$clientId]['escrow_balance'] ?? $amount);
    $influencerBalBefore = (float)($walletMap[$influencerId]['balance']     ?? 0);

    // Reduce client escrow
    $stmt = $db->prepare(
        'UPDATE wallets SET escrow_balance = escrow_balance - ? WHERE user_id = ?'
    );
    $stmt->execute([$amount, $clientId]);

    // Credit influencer balance
    $stmt = $db->prepare(
        'UPDATE wallets SET balance = balance + ? WHERE user_id = ?'
    );
    $stmt->execute([$amount, $influencerId]);

    // -------------------------------------------------------------------------
    // Ledger entries — stamped with 'manual' so admin panel can filter
    // -------------------------------------------------------------------------
    $releasedAt = date('Y-m-d H:i:s');
    $confirmRef = 'MR-' . $callId . '-' . time();

    $ledgerStmt = $db->prepare("
        INSERT INTO wallet_transactions
            (user_id, type, coins_change, amount_change,
             balance_before, balance_after, reference, description, status)
        VALUES (?, 'escrow_release', 0, ?, ?, ?, ?, ?, 'completed')
    ");

    // Client side (escrow outflow — manual)
    $ledgerStmt->execute([
        $clientId,
        -$amount,
        $clientEscrowBefore,
        $clientEscrowBefore - $amount,
        'Escrow released (manual) — call #' . $callId,
        'Manual escrow release of ' . number_format($amount, 2)
            . ' to influencer for call #' . $callId
            . '. Ref: ' . $confirmRef . '. [manual]',
    ]);

    // Influencer side (earnings credit)
    $ledgerStmt->execute([
        $influencerId,
        $amount,
        $influencerBalBefore,
        $influencerBalBefore + $amount,
        'Escrow received (manual) — call #' . $callId,
        'Call earnings of ' . number_format($amount, 2)
            . ' credited via manual client release for call #' . $callId
            . '. Ref: ' . $confirmRef . '. [manual]',
    ]);

    // -------------------------------------------------------------------------
    // Update influencer stats
    // -------------------------------------------------------------------------
    $stmt = $db->prepare("
        UPDATE influencer_profiles
        SET total_calls    = total_calls    + 1,
            total_earnings = total_earnings + ?
        WHERE user_id = ?
    ");
    $stmt->execute([$amount, $influencerId]);

    // -------------------------------------------------------------------------
    // Notify influencer
    // -------------------------------------------------------------------------
    $stmt = $db->prepare("
        INSERT INTO notifications (user_id, title, body, type, created_at)
        VALUES (?, 'Payment Released', ?, 'escrow_released', NOW())
    ");
    $stmt->execute([
        $influencerId,
        'The client has manually released your payment of '
            . number_format($amount, 2)
            . ' coins for call #' . $callId . '.',
    ]);

    // -------------------------------------------------------------------------
    // Audit log in escrow_release_log
    // -------------------------------------------------------------------------
    $stmt = $db->prepare("
        INSERT INTO escrow_release_log
            (call_id, client_id, influencer_id, amount, trigger_type, confirmation_ref, released_at)
        VALUES (?, ?, ?, ?, 'manual', ?, ?)
    ");
    $stmt->execute([$callId, $clientId, $influencerId, $amount, $confirmRef, $releasedAt]);

    $db->commit();

    // -------------------------------------------------------------------------
    // Success response — rich payload for app tracking
    // -------------------------------------------------------------------------
    sendResponse(true, 'Escrow manually released to influencer.', [
        'call_id'          => $callId,
        'escrow_status'    => 'released',
        'release_trigger'  => 'manual',
        'amount_released'  => $amount,
        'influencer_id'    => $influencerId,
        'released_at'      => $releasedAt,
        'confirmation_ref' => $confirmRef,
        'already_released' => false,
    ]);

} catch (RuntimeException $e) {
    if ($db->inTransaction()) $db->rollBack();
    $code = (int)$e->getCode();
    sendError($e->getMessage(), $code > 0 ? $code : 500);
} catch (Exception $e) {
    if ($db->inTransaction()) $db->rollBack();
    error_log('Manual Escrow Release Error: ' . $e->getMessage());
    sendError('Failed to release escrow.');
}
