<?php
/**
 * Shared escrow-release logic.
 *
 * Not a routable endpoint itself — included by api/call/release.php
 * (manual) and api/cron/auto-release-escrow.php (automatic).
 *
 * Idempotent: if escrow_status is already 'released' (or 'refunded'),
 * returns without moving funds again.
 */

function releaseEscrow(PDO $db, int $callId, ?int $expectedClientId = null): array {
    $ownTransaction = !$db->inTransaction();
    if ($ownTransaction) {
        $db->beginTransaction();
    }

    try {
        // ✅ Fetch call with client and influencer names
        $stmt = $db->prepare("
            SELECT vc.*, 
                   c.mystery_name as client_name, 
                   i.mystery_name as influencer_name
            FROM video_calls vc
            JOIN users c ON vc.client_id = c.id
            JOIN users i ON vc.influencer_id = i.id
            WHERE vc.id = ? FOR UPDATE
        ");
        $stmt->execute([$callId]);
        $call = $stmt->fetch();

        if (!$call) {
            if ($ownTransaction) $db->rollBack();
            throw new RuntimeException('Call not found.', 404);
        }

        if ($expectedClientId !== null && (int)$call['client_id'] !== $expectedClientId) {
            if ($ownTransaction) $db->rollBack();
            throw new RuntimeException('You are not the client for this call.', 403);
        }

        if ($call['escrow_status'] !== 'held') {
            // Already released — idempotent no-op
            if ($ownTransaction) $db->commit();
            return ['already_released' => true];
        }

        $clientId       = (int)$call['client_id'];
        $influencerId   = (int)$call['influencer_id'];
        $amount         = (float)$call['coins_spent'];
        $clientName     = $call['client_name'] ?? 'Client';
        $influencerName = $call['influencer_name'] ?? 'Influencer';

        // Atomic CAS: only the first concurrent caller passes this gate
        $stmt = $db->prepare("UPDATE video_calls SET escrow_status = 'released' WHERE id = ? AND escrow_status = 'held'");
        $stmt->execute([$callId]);
        if ($stmt->rowCount() === 0) {
            if ($ownTransaction) $db->commit();
            return ['already_released' => true];
        }

        // Snapshot balances before movement
        $stmt = $db->prepare('SELECT user_id, balance, escrow_balance FROM wallets WHERE user_id IN (?, ?) FOR UPDATE');
        $stmt->execute([$clientId, $influencerId]);
        $walletMap = [];
        foreach ($stmt->fetchAll() as $row) {
            $walletMap[(int)$row['user_id']] = $row;
        }

        $clientEscrowBefore     = (float)($walletMap[$clientId]['escrow_balance'] ?? $amount);
        $influencerBalBefore    = (float)($walletMap[$influencerId]['balance']     ?? 0);

        // Remove held amount from client's escrow_balance
        $stmt = $db->prepare('UPDATE wallets SET escrow_balance = escrow_balance - ? WHERE user_id = ?');
        $stmt->execute([$amount, $clientId]);

        // Credit influencer's spendable balance
        $stmt = $db->prepare('UPDATE wallets SET balance = balance + ? WHERE user_id = ?');
        $stmt->execute([$amount, $influencerId]);

        // ✅ Ledger — client side (escrow outflow) — with client name
        $stmt = $db->prepare("
            INSERT INTO wallet_transactions
                (user_id, type, coins_change, amount_change, balance_before, balance_after, reference, description, status)
            VALUES (?, 'escrow_release', 0, ?, ?, ?, ?, ?, 'completed')
        ");
        $stmt->execute([
            $clientId,
            -$amount,
            $clientEscrowBefore,
            $clientEscrowBefore - $amount,
            'Payment to ' . $influencerName . ' — Call #' . $callId,
            'Payment of ' . number_format($amount, 2) . ' released to ' . $influencerName . ' for call #' . $callId . '.',
        ]);

        // ✅ Ledger — influencer side (earnings credit) — with client name
        $stmt->execute([
            $influencerId,
            $amount,
            $influencerBalBefore,
            $influencerBalBefore + $amount,
            'Payment from ' . $clientName . ' — Call #' . $callId,
            'Call earnings of ' . number_format($amount, 2) . ' received from ' . $clientName . ' for call #' . $callId . '.',
        ]);

        // Update influencer's completed-call count and total_earnings
        $stmt = $db->prepare("
            UPDATE influencer_profiles
            SET total_calls = total_calls + 1,
                total_earnings = total_earnings + ?
            WHERE user_id = ?
        ");
        $stmt->execute([$amount, $influencerId]);

        // ✅ Notify the influencer — with client name
        $stmt = $db->prepare("
            INSERT INTO notifications (user_id, title, body, type, created_at)
            VALUES (?, 'Payment Received', ?, 'escrow_released', NOW())
        ");
        $stmt->execute([
            $influencerId,
            'You received ' . number_format($amount, 2) . ' coins from ' . $clientName . ' for call #' . $callId . '.',
        ]);

        if ($ownTransaction) $db->commit();

        return ['already_released' => false, 'amount' => $amount, 'influencer_id' => $influencerId, 'client_name' => $clientName, 'influencer_name' => $influencerName];

    } catch (Exception $e) {
        if ($ownTransaction && $db->inTransaction()) $db->rollBack();
        throw $e;
    }
}