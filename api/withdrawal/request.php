<?php
/**
 * Withdrawal Request Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/../../config/config.php';

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db   = getDatabaseConnection();
$data = getJsonInput();

$amount = (float)($data['amount'] ?? 0);

$errors = [];
if ($amount <= 0) {
    $errors['amount'] = 'Withdrawal amount must be positive.';
}
if ($amount < MIN_WITHDRAWAL_AMOUNT) {
    $errors['amount'] = 'Minimum withdrawal amount is ' . MIN_WITHDRAWAL_AMOUNT . '.';
}

if (!empty($errors)) {
    sendValidationError('Validation failed.', $errors);
}

try {
    $db->beginTransaction();

    // Prevent duplicate pending withdrawals (also enforced at DB level by index)
    $stmt = $db->prepare("SELECT id FROM withdrawal_requests WHERE user_id = ? AND status = 'pending' LIMIT 1");
    $stmt->execute([$user['id']]);
    if ($stmt->fetch()) {
        $db->rollBack();
        sendError('You already have a pending withdrawal request.', 409);
    }

    // Lock wallet for atomic read-then-deduct
    $stmt = $db->prepare('SELECT balance FROM wallets WHERE user_id = ? FOR UPDATE');
    $stmt->execute([$user['id']]);
    $wallet = $stmt->fetch();

    if (!$wallet || (float)$wallet['balance'] < $amount) {
        $db->rollBack();
        sendError('Insufficient balance for withdrawal.', 400);
    }

    $balanceBefore = (float)$wallet['balance'];
    $balanceAfter  = $balanceBefore - $amount;

    // Deduct immediately — funds are reserved until approved/rejected
    $stmt = $db->prepare('UPDATE wallets SET balance = balance - ? WHERE user_id = ?');
    $stmt->execute([$amount, $user['id']]);

    $netAmount = $amount; // No fee for now; extend here if fee schedule added
    $stmt = $db->prepare("INSERT INTO withdrawal_requests (user_id, amount, net_amount, status) VALUES (?, ?, ?, 'pending')");
    $stmt->execute([$user['id'], $amount, $netAmount]);
    $withdrawalId = (int)$db->lastInsertId();

    // Full ledger entry with balance snapshot
    $stmt = $db->prepare("
        INSERT INTO wallet_transactions
            (user_id, type, amount_change, balance_before, balance_after, reference, description, status)
        VALUES (?, 'withdrawal_request', ?, ?, ?, ?, ?, 'pending')
    ");
    $stmt->execute([
        $user['id'],
        -$amount,
        $balanceBefore,
        $balanceAfter,
        'Withdrawal Request #' . $withdrawalId,
        'Withdrawal request submitted for ' . number_format($amount, 2) . '. Awaiting admin approval.',
    ]);

    // Notify every active admin account of the new withdrawal request.
    $stmt = $db->prepare("
        INSERT INTO notifications (user_id, title, body, type, created_at)
        VALUES (?, 'New Withdrawal Request', ?, 'withdrawal_requested', NOW())
    ");
    $notifyBody = 'Influencer ' . $user['mystery_name'] . ' (#' . $user['id'] . ') requested a withdrawal of ' . number_format($amount, 2) . '.';
    foreach (getAdminUserIds($db) as $adminId) {
        $stmt->execute([$adminId, $notifyBody]);
    }

    // Notify the influencer that their request was received
    $stmt = $db->prepare("
        INSERT INTO notifications (user_id, title, body, type, created_at)
        VALUES (?, 'Withdrawal Requested', ?, 'withdrawal_requested', NOW())
    ");
    $stmt->execute([
        $user['id'],
        'Your withdrawal request for ' . number_format($amount, 2) . ' has been submitted and is pending admin review.',
    ]);

    $db->commit();

    sendResponse(true, 'Withdrawal request submitted successfully. It will be reviewed by an admin.', [
        'withdrawal_id' => $withdrawalId,
        'amount'        => $amount,
        'net_amount'    => $netAmount,
        'status'        => 'pending',
    ]);

} catch (Exception $e) {
    if ($db->inTransaction()) $db->rollBack();
    error_log('Withdrawal Request Error: ' . $e->getMessage());
    sendError('Failed to submit withdrawal request.');
}
