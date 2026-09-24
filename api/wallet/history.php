<?php
/**
 * Wallet History Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

$limit = min(max((int)($_GET['limit'] ?? 50), 1), 100);
$offset = max((int)($_GET['offset'] ?? 0), 0);

try {
    $stmt = $db->prepare("
        SELECT 
            id as transaction_id, 
            type, 
            coins_change as coins, 
            amount_change as amount, 
            reference, 
            status, 
            description,
            created_at
        FROM wallet_transactions
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
    ");
    $stmt->bindValue(1, $user["id"], PDO::PARAM_INT);
    $stmt->bindValue(2, $limit, PDO::PARAM_INT);
    $stmt->bindValue(3, $offset, PDO::PARAM_INT);
    $stmt->execute();
    $history = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Convert type 'coin_purchase' to 'purchase' for Flutter filtering
    foreach ($history as &$tx) {
        if ($tx['type'] === 'coin_purchase') {
            $tx['type'] = 'purchase';
        }
    }

    sendResponse(true, "Wallet history retrieved successfully.", [
        "history" => $history
    ]);

} catch (Exception $e) {
    error_log("Wallet History Error: " . $e->getMessage());
    sendError("Failed to retrieve wallet history.");
}