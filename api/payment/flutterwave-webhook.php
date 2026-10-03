<?php
/**
 * Flutterwave Webhook Endpoint (v3)
 *
 * Register this URL in Flutterwave Dashboard → Settings → Webhooks.
 * Secret hash must match FLUTTERWAVE_SECRET_HASH in .env (sent as verif-hash header).
 *
 * Primary event: charge.completed with data.status = successful.
 * Always re-verify via API before crediting (best practice).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/config.php';

$payload   = (string)@file_get_contents('php://input');
$sigHeader = $_SERVER['HTTP_VERIF_HASH'] ?? ($_SERVER['HTTP_VERIF-HASH'] ?? '');

$secretHash = defined('FLUTTERWAVE_SECRET_HASH') ? FLUTTERWAVE_SECRET_HASH : (getenv('FLUTTERWAVE_SECRET_HASH') ?: '');

// Refuse to run without a configured secret hash (an empty one would let
// anybody call this endpoint).
if ($secretHash === '') {
    http_response_code(500);
    error_log('Flutterwave Webhook Error: FLUTTERWAVE_SECRET_HASH is not configured.');
    echo json_encode(['error' => 'Webhook is not configured.']);
    exit();
}

if ($sigHeader === '' || !hash_equals($secretHash, $sigHeader)) {
    http_response_code(401);
    error_log('Flutterwave Webhook Error: Invalid or missing verif-hash.');
    echo json_encode(['error' => 'Invalid signature.']);
    exit();
}

$event = json_decode($payload, true);
if (!$event || !is_array($event)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON payload.']);
    exit();
}

$db        = getDatabaseConnection();
$eventType = $event['event'] ?? null;

if (!$eventType) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing event type.']);
    exit();
}

switch ($eventType) {
    case 'charge.completed':
        $txData    = $event['data'] ?? [];
        $txRef     = $txData['tx_ref'] ?? null;
        $status    = strtolower((string)($txData['status'] ?? ''));
        $flwId     = $txData['id'] ?? null;

        if (!$txRef) {
            http_response_code(400);
            error_log('Flutterwave Webhook: Missing tx_ref in charge.completed.');
            echo json_encode(['error' => 'Malformed event payload.']);
            exit();
        }

        if ($status !== 'successful') {
            // Acknowledge failed/pending events without crediting
            http_response_code(200);
            echo json_encode(['status' => 'ignored', 'reason' => 'not successful']);
            exit();
        }

        // Re-verify with Flutterwave before giving value
        $url = 'https://api.flutterwave.com/v3/transactions/verify_by_reference?tx_ref=' . rawurlencode($txRef);
        $ch  = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_HTTPHEADER     => [
                'Authorization: Bearer ' . FLUTTERWAVE_SECRET_KEY,
                'Content-Type: application/json',
            ],
        ]);
        $verifyRaw  = curl_exec($ch);
        $verifyCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        $verified = json_decode((string)$verifyRaw, true);

        if ($verifyCode !== 200 || ($verified['data']['status'] ?? '') !== 'successful') {
            error_log('Flutterwave Webhook: Re-verify failed for ' . $txRef . ' — ' . $verifyRaw);
            http_response_code(200); // still ack so FLW does not retry forever
            echo json_encode(['status' => 'verify_failed']);
            exit();
        }

        try {
            // Inline credit (same logic as verify-payment)
            $db->beginTransaction();

            $stmt = $db->prepare("SELECT id, user_id, coins, amount, currency, status FROM payments WHERE payment_reference = ? FOR UPDATE");
            $stmt->execute([$txRef]);
            $payment = $stmt->fetch();

            if (!$payment) {
                $db->rollBack();
                error_log('Flutterwave Webhook: No payment row for tx_ref ' . $txRef);
                http_response_code(200);
                echo json_encode(['status' => 'unknown_ref']);
                exit();
            }

            if ($payment['status'] === 'completed') {
                $db->commit();
                http_response_code(200);
                echo json_encode(['status' => 'already_processed']);
                exit();
            }

            if ($payment['status'] !== 'pending') {
                $db->rollBack();
                http_response_code(200);
                echo json_encode(['status' => 'ignored_status']);
                exit();
            }

            // The amount and currency Flutterwave really charged must match
            // the payment we created, otherwise do not credit any coins.
            $paidAmount   = isset($verified['data']['amount']) ? (float)$verified['data']['amount'] : null;
            $paidCurrency = strtoupper((string)($verified['data']['currency'] ?? ''));
            if ($paidAmount === null
                || $paidAmount + 0.01 < (float)$payment['amount']
                || ($payment['currency'] !== null && $payment['currency'] !== '' && $paidCurrency !== strtoupper((string)$payment['currency']))) {
                $db->rollBack();
                error_log("Flutterwave Webhook: amount/currency mismatch for {$txRef} (expected {$payment['amount']} {$payment['currency']}, got {$paidAmount} {$paidCurrency})");
                http_response_code(200);
                echo json_encode(['status' => 'amount_mismatch']);
                exit();
            }

            $userId = (int)$payment['user_id'];
            $coins  = (int)$payment['coins'];
            $amount = (float)$payment['amount'];

            $stmt = $db->prepare('SELECT balance FROM wallets WHERE user_id = ? FOR UPDATE');
            $stmt->execute([$userId]);
            $wallet        = $stmt->fetch();
            $balanceBefore = (float)($wallet['balance'] ?? 0);
            $balanceAfter  = $balanceBefore + $coins;

            $stmt = $db->prepare("UPDATE payments SET status = 'completed' WHERE id = ?");
            $stmt->execute([(int)$payment['id']]);

            $stmt = $db->prepare('UPDATE wallets SET balance = balance + ?, total_purchased = total_purchased + ? WHERE user_id = ?');
            $stmt->execute([$coins, $coins, $userId]);

            $stmt = $db->prepare("
                INSERT INTO wallet_transactions
                    (user_id, type, coins_change, amount_change, balance_before, balance_after, reference, description, status)
                VALUES (?, 'coin_purchase', ?, ?, ?, ?, ?, ?, 'completed')
            ");
            $stmt->execute([
                $userId, $coins, $amount,
                $balanceBefore, $balanceAfter,
                'Flutterwave Reference: ' . $txRef,
                'Coin purchase: ' . $coins . ' coins for ' . number_format($amount, 2) . '.',
            ]);

            $stmt = $db->prepare("
                INSERT INTO notifications (user_id, title, body, type, created_at)
                VALUES (?, 'Wallet Funded', ?, 'wallet_funded', NOW())
            ");
            $stmt->execute([$userId, 'Your wallet has been topped up with ' . $coins . ' coins.']);

            processReferralCommission($db, $userId, (int)$payment['id'], $coins, $amount);

            $db->commit();
        } catch (Exception $e) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            error_log('Flutterwave Webhook Payment Processing Error: ' . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Failed to process payment.']);
            exit();
        }
        break;

    default:
        error_log('Flutterwave Webhook: Unhandled event type ' . $eventType);
        break;
}

http_response_code(200);
echo json_encode(['status' => 'success']);
