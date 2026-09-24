<?php
/**
 * Read Notification Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
$db = getDatabaseConnection();
$data = getJsonInput();

$notificationId = (int)($data["notification_id"] ?? 0);
$markAll = (bool)($data["mark_all"] ?? false);

if (!$notificationId && !$markAll) {
    sendValidationError("Notification ID or mark_all flag is required.");
}

try {
    if ($markAll) {
        $stmt = $db->prepare("UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE");
        $stmt->execute([$user["id"]]);
        sendResponse(true, "All notifications marked as read.");
    } else {
        // Mark a single notification as read
        $stmt = $db->prepare("UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?");
        $stmt->execute([$notificationId, $user["id"]]);
        if ($stmt->rowCount() === 0) {
            sendError("Notification not found or already read.", 404);
        }
        sendResponse(true, "Notification marked as read.");
    }

} catch (Exception $e) {
    error_log("Read Notification Error: " . $e->getMessage());
    sendError("Failed to mark notification as read.");
}
