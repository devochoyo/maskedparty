<?php
/**
 * Withdrawal History Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();

try {
    $stmt = $db->prepare("
        SELECT id, amount, fee, net_amount, status, reference, created_at, completed_at
        FROM withdrawal_requests
        WHERE user_id = ?
        ORDER BY created_at DESC
    ");
    $stmt->execute([$user['id']]);
    $history = $stmt->fetchAll();

    sendResponse(true, 'Withdrawal history retrieved successfully.', ['history' => $history]);

} catch (Exception $e) {
    error_log("Withdrawal History Error: " . $e->getMessage());
    sendError('Failed to retrieve withdrawal history.');
}
