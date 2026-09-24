<?php
/**
 * Coin Packages Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser(); // Protected endpoint
$db = getDatabaseConnection();

try {
    $stmt = $db->prepare("SELECT id as package_id, name as package_name, price, currency, coins, minutes, is_popular, is_best_value FROM coin_packages WHERE is_active = TRUE ORDER BY display_order ASC");
    $stmt->execute();
    $packages = $stmt->fetchAll();

    sendResponse(true, "Coin packages retrieved successfully.", ["packages" => $packages]);

} catch (Exception $e) {
    error_log("Coin Packages Error: " . $e->getMessage());
    sendError("Failed to retrieve coin packages.");
}
