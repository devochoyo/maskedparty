<?php
/**
 * Verify Payment Endpoint (Flutterwave v3)
 *
 * Confirms a Flutterwave transaction server-side and credits the wallet.
 * Idempotent via payments.payment_reference.
 *
 * Accepts JSON body { "reference": "<tx_ref>" } from the app after checkout,
 * or query params from Flutterwave redirect (status, tx_ref, transaction_id).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

/**
 * Verify a Flutterwave transaction by merchant tx_ref.
 * GET /v3/transactions/verify_by_reference?tx_ref=...
 */
function verifyFlutterwaveByTxRef(string $txRef, string $secretKey): ?array {
    $url = 'https://api.flutterwave.com/v3/transactions/verify_by_reference?tx_ref=' . rawurlencode($txRef);
    $ch  = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_HTTPHEADER     => [
            'Authorization: Bearer ' . $secretKey,
            'Content-Type: application/json',
            'Cache-Control: no-cache',
        ],
    ]);
    $response  = curl_exec($ch);
    $httpCode  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError !== '' || $response === false) {
        error_log('Flutterwave verify cURL Error: ' . $curlError);
        return null;
    }
    $decoded = json_decode($response, true);
    if ($httpCode !== 200 || !is_array($decoded)) {
        error_log("Flutterwave verify Error (HTTP {$httpCode}): " . $response);
        return null;
    }
    return $decoded;
}

/**
 * Credit wallet for a successful payment. Shared by verify + webhook.
 */
function creditPaymentIfPending(PDO $db, string $txRef, ?int $expectedUserId = null): ?array {
    $db->beginTransaction();

    try {
        $stmt = $db->prepare("SELECT id, user_id, coins, amount, status FROM payments WHERE payment_reference = ? FOR UPDATE");
        $stmt->execute([$txRef]);
        $payment = $stmt->fetch();

        if (!$payment) {
            $db->rollBack();
            return null;
        }

        if ($expectedUserId !== null && (int)$payment['user_id'] !== $expectedUserId) {
            $db->rollBack();
            return null;
        }

        if ($payment['status'] === 'completed') {
            $stmt = $db->prepare('SELECT balance FROM wallets WHERE user_id = ?');
            $stmt->execute([(int)$payment['user_id']]);
            $w = $stmt->fetch();
            $db->commit();
            return [
                'already'        => true,
                'wallet_balance' => (float)($w['balance'] ?? 0),
                'user_id'        => (int)$payment['user_id'],
            ];
        }

        if ($payment['status'] !== 'pending') {
            $db->rollBack();
            return null;
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

        return [
            'already'        => false,
            'wallet_balance' => $balanceAfter,
            'user_id'        => $userId,
        ];
    } catch (Exception $e) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        error_log('creditPaymentIfPending Error: ' . $e->getMessage());
        throw $e;
    }
}

// Handle Flutterwave browser redirect (no auth token)
$source = $_GET['source'] ?? '';
if ($source === 'redirect') {
    $status = strtolower(trim((string)($_GET['status'] ?? '')));
    $txRef  = trim((string)($_GET['tx_ref'] ?? ''));

    header('Content-Type: text/html; charset=utf-8');
    if ($status === 'successful' && $txRef !== '') {
        try {
            $db = getDatabaseConnection();
            $verified = verifyFlutterwaveByTxRef($txRef, FLUTTERWAVE_SECRET_KEY);
            if ($verified && ($verified['data']['status'] ?? '') === 'successful') {
                creditPaymentIfPending($db, $txRef, null);
            }
        } catch (Exception $e) {
            error_log('Redirect credit error: ' . $e->getMessage());
        }
        echo '<!DOCTYPE html><html><head><title>Payment Successful</title></head><body>'
           . '<h2>Payment successful</h2><p>You can close this window.</p>'
           . '<script>window.paymentStatus="successful";window.txRef="' . htmlspecialchars($txRef, ENT_QUOTES) . '";</script>'
           . '</body></html>';
    } else {
        echo '<!DOCTYPE html><html><head><title>Payment Status</title></head><body>'
           . '<h2>Payment not completed</h2><p>You can close this window and try again.</p>'
           . '<script>window.paymentStatus="failed";</script>'
           . '</body></html>';
    }
    exit();
}

// Authenticated app verify call
$user = getAuthenticatedUser();
$db   = getDatabaseConnection();
$data = getJsonInput();

$reference = trim((string)($data['reference'] ?? ''));
if ($reference === '') {
    sendValidationError('A valid Flutterwave transaction reference is required.');
}

$transaction = verifyFlutterwaveByTxRef($reference, FLUTTERWAVE_SECRET_KEY);
if ($transaction === null) {
    sendError('Unable to verify payment with Flutterwave.', 502);
}

$txData = $transaction['data'] ?? [];
$status = strtolower((string)($txData['status'] ?? ''));

if ($status !== 'successful') {
    sendError('Payment not successful.', 400);
}

$stmt = $db->prepare("SELECT amount, currency, user_id FROM payments WHERE payment_reference = ?");
$stmt->execute([$reference]);
$row = $stmt->fetch();
if (!$row) {
    sendError('No matching payment found for this reference.', 404);
}
if ((int)$row['user_id'] !== (int)$user['id']) {
    sendError('This payment does not belong to the authenticated user.', 403);
}

$charged = isset($txData['amount']) ? (float)$txData['amount'] : null;
if ($charged !== null && abs($charged - (float)$row['amount']) > 0.01) {
    error_log("Flutterwave amount mismatch: expected {$row['amount']}, got {$charged} for {$reference}");
}

try {
    $result = creditPaymentIfPending($db, $reference, (int)$user['id']);
    if ($result === null) {
        sendError('No matching pending payment found.', 409);
    }
    sendResponse(true, $result['already'] ? 'Payment already verified and credited.' : 'Payment verified and wallet credited.', [
        'wallet_balance' => $result['wallet_balance'],
    ]);
} catch (Exception $e) {
    error_log('Verify Payment Error: ' . $e->getMessage());
    sendError('Failed to verify payment.');
}
