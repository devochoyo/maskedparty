<?php
/**
 * Shared call-settlement logic.
 *
 * Standard calls keep their existing escrow amount.
 * Pay As You Go calls are recalculated from server-side duration at the
 * moment the call ends, then escrow is adjusted to the exact final charge.
 */
require_once __DIR__ . '/../call-tracking/_log.php';

function settleCall(PDO $db, int $callId, string $reason = 'manual', ?int $endedByUserId = null) {
    $ownTransaction = !$db->inTransaction();
    if ($ownTransaction) {
        $db->beginTransaction();
    }

    try {
        $stmt = $db->prepare("SELECT * FROM video_calls WHERE id = ? FOR UPDATE");
        $stmt->execute([$callId]);
        $call = $stmt->fetch();

        if (!$call) {
            if ($ownTransaction) $db->rollBack();
            throw new RuntimeException('Call not found.', 404);
        }

        if ($call['status'] === 'completed') {
            if ($ownTransaction) $db->commit();
            return [
                'actual_duration_seconds' => (int)$call['actual_duration_seconds'],
                'already_completed' => true,
                'coins_spent' => (float)$call['coins_spent'],
                'escrow_status' => $call['escrow_status'],
                'billing_mode' => $call['billing_mode'] ?? 'standard',
            ];
        }

        $actualDurationSeconds = max(0, time() - strtotime($call['start_time']));
        $finalCoins = (float)$call['coins_spent'];

        $billingMode = $call['billing_mode'] ?? 'standard';
        if (in_array($billingMode, ['payg_minute', 'payg_second'], true)) {
            if ($billingMode === 'payg_second') {
                $finalCoins = round(
                    $actualDurationSeconds * (float)$call['price_per_second'],
                    4
                );
            } else {
                $billedMinutes = $actualDurationSeconds <= 0
                    ? 0
                    : (int)ceil($actualDurationSeconds / 60);
                $finalCoins = round(
                    $billedMinutes * (float)$call['price_per_minute'],
                    4
                );
            }

            $currentEscrowed = (float)$call['coins_spent'];
            $clientId = (int)$call['client_id'];

            $stmt = $db->prepare("SELECT balance, escrow_balance FROM wallets WHERE user_id = ? FOR UPDATE");
            $stmt->execute([$clientId]);
            $wallet = $stmt->fetch();
            if (!$wallet) {
                throw new RuntimeException('Client wallet not found.', 404);
            }

            if ($finalCoins > $currentEscrowed + 0.0000001) {
                // Normally the rolling escrow already covers this. This
                // fallback handles a client ending between countdown polls.
                $extra = round($finalCoins - $currentEscrowed, 4);
                $available = (float)$wallet['balance'];
                if ($available + 0.0000001 >= $extra) {
                    $before = $available;
                    $after = round($before - $extra, 4);
                    $stmt = $db->prepare("
                        UPDATE wallets
                        SET balance = balance - ?, escrow_balance = escrow_balance + ?
                        WHERE user_id = ?
                    ");
                    $stmt->execute([$extra, $extra, $clientId]);

                    $stmt = $db->prepare("
                        INSERT INTO wallet_transactions
                            (user_id, type, coins_change, amount_change, balance_before, balance_after, reference, description, status)
                        VALUES (?, 'escrow_hold', ?, ?, ?, ?, ?, ?, 'completed')
                    ");
                    $stmt->execute([
                        $clientId, -$extra, -$extra, $before, $after,
                        'Pay As You Go final escrow — call #' . $callId,
                        'Final Pay As You Go escrow adjustment of ' . number_format($extra, 4) . ' coins.',
                    ]);
                } else {
                    // Never allow a negative wallet. If the account could
                    // not cover the exact final unit, charge the amount
                    // already held plus whatever spendable balance remains.
                    $finalCoins = round($currentEscrowed + max(0, $available), 4);
                    if ($available > 0) {
                        $stmt = $db->prepare("
                            UPDATE wallets
                            SET balance = 0, escrow_balance = escrow_balance + ?
                            WHERE user_id = ?
                        ");
                        $stmt->execute([$available, $clientId]);
                    }
                }
            } elseif ($finalCoins < $currentEscrowed - 0.0000001) {
                // Refund any unused pre-held Pay As You Go amount.
                $refund = round($currentEscrowed - $finalCoins, 4);
                $stmt = $db->prepare("
                    UPDATE wallets
                    SET balance = balance + ?, escrow_balance = escrow_balance - ?
                    WHERE user_id = ?
                ");
                $stmt->execute([$refund, $refund, $clientId]);

                $before = (float)$wallet['balance'];
                $after = round($before + $refund, 4);
                $stmt = $db->prepare("
                    INSERT INTO wallet_transactions
                        (user_id, type, coins_change, amount_change, balance_before, balance_after, reference, description, status)
                    VALUES (?, 'refund', ?, ?, ?, ?, ?, ?, 'completed')
                ");
                $stmt->execute([
                    $clientId, $refund, $refund, $before, $after,
                    'Pay As You Go unused-time refund — call #' . $callId,
                    'Refund of ' . number_format($refund, 4) . ' unused Pay As You Go escrow coins.',
                ]);
            }

            $stmt = $db->prepare("UPDATE video_calls SET coins_spent = ? WHERE id = ?");
            $stmt->execute([$finalCoins, $callId]);
            $call['coins_spent'] = $finalCoins;
        }

        $stmt = $db->prepare("
            UPDATE video_calls
            SET status = 'completed', end_time = NOW(), actual_duration_seconds = ?
            WHERE id = ? AND status != 'completed'
        ");
        $stmt->execute([$actualDurationSeconds, $callId]);

        $stmt = $db->prepare("UPDATE influencer_profiles SET online_status = 'online' WHERE user_id = ?");
        $stmt->execute([(int)$call['influencer_id']]);

        $stmt = $db->prepare("INSERT INTO notifications (user_id, title, body, type, created_at) VALUES (?, 'Call Ended', ?, 'call_status', NOW())");
        $body = ($reason === 'timeout')
            ? 'Your call has ended because the paid time ran out.'
            : (($reason === 'insufficient_balance')
                ? 'Your call has ended because the client ran out of coins.'
                : 'Your call has ended.');
        $stmt->execute([(int)$call['client_id'], $body]);
        $stmt->execute([(int)$call['influencer_id'], $body]);

        $endedByRole = ($reason === 'timeout' || $reason === 'insufficient_balance')
            ? 'system'
            : 'manual';
        logCallTracking($db, $call, $actualDurationSeconds, $endedByRole, $endedByUserId);

        if ($ownTransaction) {
            $db->commit();
        }

        return [
            'actual_duration_seconds' => $actualDurationSeconds,
            'already_completed' => false,
            'coins_spent' => (float)$call['coins_spent'],
            'escrow_status' => $call['escrow_status'],
            'billing_mode' => $billingMode,
        ];

    } catch (Exception $e) {
        if ($ownTransaction && $db->inTransaction()) {
            $db->rollBack();
        }
        throw $e;
    }
}
