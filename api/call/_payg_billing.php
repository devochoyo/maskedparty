<?php
/**
 * Shared Pay As You Go billing helpers.
 *
 * Payg calls keep only enough escrow for the next billing unit. Final
 * settlement recalculates the exact amount from the server-side duration:
 *   payg_minute = ceil(actual_seconds / 60) * per_minute
 *   payg_second = actual_seconds * per_second
 */
function getPaygPricing(PDO $db): array {
    $stmt = $db->query("SELECT per_minute, per_second, is_active FROM payg_call_pricing WHERE id = 1 LIMIT 1");
    $row = $stmt->fetch();
    if (!$row || !(int)$row['is_active']) {
        throw new RuntimeException('Pay As You Go pricing is unavailable.', 503);
    }

    $perMinute = (float)$row['per_minute'];
    $perSecond = (float)$row['per_second'];
    if ($perMinute <= 0 || $perSecond <= 0) {
        throw new RuntimeException('Pay As You Go pricing is not configured correctly.', 503);
    }

    return ['per_minute' => $perMinute, 'per_second' => $perSecond];
}

function paygRequiredDurationSeconds(array $call, int $elapsedSeconds): int {
    $elapsedSeconds = max(0, $elapsedSeconds);
    if (($call['billing_mode'] ?? '') === 'payg_second') {
        return max(1, $elapsedSeconds + 1);
    }
    return max(60, (int)(ceil(max(1, $elapsedSeconds + 1) / 60) * 60));
}

function paygAmountForDuration(array $call, int $durationSeconds): float {
    $durationSeconds = max(0, $durationSeconds);
    if (($call['billing_mode'] ?? '') === 'payg_second') {
        return round($durationSeconds * (float)$call['price_per_second'], 4);
    }
    $minutes = $durationSeconds <= 0 ? 0 : (int)ceil($durationSeconds / 60);
    return round($minutes * (float)$call['price_per_minute'], 4);
}

/**
 * Increase escrow so an active Pay As You Go call is covered through the
 * next billing unit. Returns false when the client cannot afford the next
 * unit; the caller should end the call.
 */
function topUpPaygEscrow(PDO $db, array &$call, int $elapsedSeconds): bool {
    if (!in_array($call['billing_mode'] ?? '', ['payg_minute', 'payg_second'], true)) {
        return true;
    }

    $requiredDuration = paygRequiredDurationSeconds($call, $elapsedSeconds);
    $paidDuration = (int)$call['paid_duration_seconds'];
    if ($requiredDuration <= $paidDuration) {
        return true;
    }

    $newAmount = paygAmountForDuration($call, $requiredDuration);
    $currentAmount = (float)$call['coins_spent'];
    $additional = round($newAmount - $currentAmount, 4);
    if ($additional <= 0) {
        return true;
    }

    $clientId = (int)$call['client_id'];
    $ownTx = !$db->inTransaction();
    if ($ownTx) {
        $db->beginTransaction();
    }

    try {
        $stmt = $db->prepare("SELECT balance, escrow_balance FROM wallets WHERE user_id = ? FOR UPDATE");
        $stmt->execute([$clientId]);
        $wallet = $stmt->fetch();

        if (!$wallet || (float)$wallet['balance'] + 0.0000001 < $additional) {
            if ($ownTx) {
                $db->rollBack();
            }
            return false;
        }

        $before = (float)$wallet['balance'];
        $after = round($before - $additional, 4);

        $stmt = $db->prepare("
            UPDATE wallets
            SET balance = balance - ?, escrow_balance = escrow_balance + ?
            WHERE user_id = ?
        ");
        $stmt->execute([$additional, $additional, $clientId]);

        $stmt = $db->prepare("
            INSERT INTO wallet_transactions
                (user_id, type, coins_change, amount_change, balance_before, balance_after, reference, description, status)
            VALUES (?, 'escrow_hold', ?, ?, ?, ?, ?, ?, 'completed')
        ");
        $stmt->execute([
            $clientId, -$additional, -$additional, $before, $after,
            'Pay As You Go escrow — call #' . $call['id'],
            'Pay As You Go escrow top-up of ' . number_format($additional, 4) . ' coins.',
        ]);

        $stmt = $db->prepare("
            UPDATE video_calls
            SET coins_spent = ?, paid_duration_seconds = ?, duration_minutes = ?
            WHERE id = ?
        ");
        $stmt->execute([
            $newAmount,
            $requiredDuration,
            (int)ceil($requiredDuration / 60),
            (int)$call['id'],
        ]);

        if ($ownTx) {
            $db->commit();
        }

        $call['coins_spent'] = $newAmount;
        $call['paid_duration_seconds'] = $requiredDuration;
        $call['duration_minutes'] = (int)ceil($requiredDuration / 60);

        return true;
    } catch (Exception $e) {
        if ($ownTx && $db->inTransaction()) {
            $db->rollBack();
        }
        error_log('topUpPaygEscrow error: ' . $e->getMessage());
        return false;
    }
}
