<?php
/**
 * Extend Call Endpoint
 *
 * Client purchases additional minutes on an active call. Deducts
 * additional coins from the client's wallet balance into escrow,
 * increases the call's paid_duration_seconds (extending the countdown
 * used by api/call/countdown.php), and logs the movement.
 *
 * Uses the price_per_minute that was snapshotted on the video_calls row
 * at start time (which itself came from coin packages).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'client');

$db = getDatabaseConnection();
$data = getJsonInput();

$callId = (int)($data['call_id'] ?? 0);
$additionalMinutes = (int)($data['additional_minutes'] ?? 0);

if (!$callId) {
    sendValidationError('Call ID is required.');
}
if ($additionalMinutes <= 0) {
    sendValidationError('additional_minutes must be a positive integer.');
}

try {
    $db->beginTransaction();

    // Lock the call row so a concurrent extend/countdown-expiry can't
    // race this update.
    $stmt = $db->prepare("SELECT * FROM video_calls WHERE id = ? AND client_id = ? FOR UPDATE");
    $stmt->execute([$callId, $user['id']]);
    $call = $stmt->fetch();

    if (!$call) {
        $db->rollBack();
        sendError('Call not found or you are not the client for this call.', 404);
    }

    if ($call['status'] !== 'active') {
        $db->rollBack();
        sendError('This call is no longer active.', 409);
    }

    if (in_array($call['billing_mode'] ?? '', ['payg_minute', 'payg_second'], true)) {
        $db->rollBack();
        sendError('Pay As You Go calls are billed automatically and do not need manual extensions.', 409);
    }

    // Reject extending a call whose time has already run out — the
    // client should let it end/settle first rather than reviving it here.
    $elapsedSeconds = time() - strtotime($call['start_time']);
    if ($elapsedSeconds >= (int)$call['paid_duration_seconds']) {
        $db->rollBack();
        sendError('Call time has already expired.', 409);
    }

    // Use the rate that was locked in when the call started
    $pricePerMinute = (float)$call['price_per_minute'];
    $additionalCoins = $pricePerMinute * $additionalMinutes;

    // Lock and check the client's wallet balance.
    $stmt = $db->prepare("SELECT balance FROM wallets WHERE user_id = ? FOR UPDATE");
    $stmt->execute([$user['id']]);
    $wallet = $stmt->fetch();

    if (!$wallet || $wallet['balance'] < $additionalCoins) {
        $db->rollBack();
        sendError('Insufficient coins to extend the call.', 402);
    }

    // Deduct from client balance into escrow.
    $stmt = $db->prepare("UPDATE wallets SET balance = balance - ?, escrow_balance = escrow_balance + ? WHERE user_id = ?");
    $stmt->execute([$additionalCoins, $additionalCoins, $user['id']]);

    $escrowBalBefore = (float)($wallet['balance'] ?? 0); // captured before deduct above
    $escrowBalAfter  = $escrowBalBefore - $additionalCoins;
    $stmt = $db->prepare("
        INSERT INTO wallet_transactions
            (user_id, type, coins_change, amount_change, balance_before, balance_after, reference, description, status)
        VALUES (?, 'escrow_hold', ?, ?, ?, ?, ?, ?, 'completed')
    ");
    $stmt->execute([
        $user['id'], -$additionalCoins, -$additionalCoins,
        $escrowBalBefore, $escrowBalAfter,
        'Call extension — call #' . $callId,
        'Escrow hold of ' . number_format($additionalCoins, 2) . ' coins for ' . $additionalMinutes . ' additional minute(s).',
    ]);

    // Increase escrow amount held against this call and extend the
    // countdown.
    $newCoinsSpent = (float)$call['coins_spent'] + $additionalCoins;
    $newPaidDuration = (int)$call['paid_duration_seconds'] + ($additionalMinutes * 60);
    $newDurationMinutes = (int)$call['duration_minutes'] + $additionalMinutes;

    $stmt = $db->prepare("
        UPDATE video_calls
        SET coins_spent = ?, paid_duration_seconds = ?, duration_minutes = ?, last_extended_at = NOW()
        WHERE id = ?
    ");
    $stmt->execute([$newCoinsSpent, $newPaidDuration, $newDurationMinutes, $callId]);

    // Notify the influencer that more time was purchased.
    $stmt = $db->prepare("INSERT INTO notifications (user_id, title, body, type, created_at) VALUES (?, 'Call Extended', ?, 'call_status', NOW())");
    $stmt->execute([(int)$call['influencer_id'], 'The client purchased ' . $additionalMinutes . ' additional minute(s).']);

    $db->commit();

    $remainingSeconds = max(0, $newPaidDuration - $elapsedSeconds);

    sendResponse(true, 'Call extended successfully.', [
        'call_id' => $callId,
        'additional_minutes' => $additionalMinutes,
        'additional_coins' => $additionalCoins,
        'paid_duration_seconds' => $newPaidDuration,
        'remaining_seconds' => $remainingSeconds,
    ]);

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Extend Call Error: " . $e->getMessage());
    sendError('Failed to extend call.');
}