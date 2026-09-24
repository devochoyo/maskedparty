<?php
/**
 * Wallet Balance Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

try {
    $stmt = $db->prepare("
        SELECT balance, total_purchased, total_spent, escrow_balance 
        FROM wallets 
        WHERE user_id = ?
    ");
    $stmt->execute([$user['id']]);
    $wallet = $stmt->fetch();

    if (!$wallet) {
        sendError('Wallet not found.', 404);
    }

    sendResponse(true, 'Wallet balance retrieved.', [
        'current_balance' => (float)$wallet['balance'],
        'total_purchased' => (float)$wallet['total_purchased'],
        'total_spent' => (float)$wallet['total_spent'],
        'escrow_balance' => (float)$wallet['escrow_balance'],
        'available_balance' => (float)($wallet['balance'] - $wallet['escrow_balance'])
    ]);

} catch (Exception $e) {
    error_log("Wallet Balance Error: " . $e->getMessage());
    sendError('Failed to retrieve wallet balance.');
}
