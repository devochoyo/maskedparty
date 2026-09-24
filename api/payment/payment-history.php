<?php
/**
 * Payment History Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

// Simple pagination so this doesn't return an unbounded result set for
// accounts with a long payment history.
$limit = min(max((int)($_GET['limit'] ?? 50), 1), 100);
$offset = max((int)($_GET['offset'] ?? 0), 0);

try {
    $stmt = $db->prepare("
        SELECT p.id as payment_id, cp.name as package_name, p.amount, p.coins, p.status, p.created_at
        FROM payments p
        JOIN coin_packages cp ON p.package_id = cp.id
        WHERE p.user_id = ?
        ORDER BY p.created_at DESC
        LIMIT ? OFFSET ?
    ");
    $stmt->bindValue(1, $user["id"], PDO::PARAM_INT);
    $stmt->bindValue(2, $limit, PDO::PARAM_INT);
    $stmt->bindValue(3, $offset, PDO::PARAM_INT);
    $stmt->execute();
    $paymentHistory = $stmt->fetchAll();

    sendResponse(true, "Payment history retrieved successfully.", ["payment_history" => $paymentHistory]);

} catch (Exception $e) {
    error_log("Payment History Error: " . $e->getMessage());
    sendError("Failed to retrieve payment history.");
}
