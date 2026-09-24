<?php
/**
 * Public authenticated Pay As You Go pricing.
 * Returns the admin-controlled per-minute and per-second rates.
 */
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

getAuthenticatedUser();
$db = getDatabaseConnection();

try {
    $stmt = $db->query("SELECT per_minute, per_second, is_active FROM payg_call_pricing WHERE id = 1 LIMIT 1");
    $row = $stmt->fetch();

    if (!$row || !(int)$row['is_active']) {
        sendError('Pay As You Go pricing is currently unavailable.', 503);
    }

    sendResponse(true, 'Pay As You Go pricing retrieved successfully.', [
        'per_minute' => (float)$row['per_minute'],
        'per_second' => (float)$row['per_second'],
    ]);
} catch (Exception $e) {
    error_log("Pay As You Go Pricing Error: " . $e->getMessage());
    sendError('Failed to retrieve Pay As You Go pricing.');
}
