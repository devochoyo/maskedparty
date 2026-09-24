<?php
/**
 * Notification List Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

// Guard against page=0 or a negative page producing a negative OFFSET.
$page = max((int)($_GET["page"] ?? 1), 1);
$limit = 20;
$offset = ($page - 1) * $limit;

try {
    // Bound LIMIT/OFFSET explicitly as integers: with emulated prepares
    // disabled (see config/database.php), passing them through execute()
    // as plain array values sends them as strings, which the native MySQL
    // protocol rejects for LIMIT/OFFSET.
    $stmt = $db->prepare("
        SELECT id, title, body, type, is_read, created_at
        FROM notifications
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
    ");
    $stmt->bindValue(1, $user["id"], PDO::PARAM_INT);
    $stmt->bindValue(2, $limit, PDO::PARAM_INT);
    $stmt->bindValue(3, $offset, PDO::PARAM_INT);
    $stmt->execute();
    $notifications = $stmt->fetchAll();

    // Unread count, so clients can show a badge without a second round trip.
    $stmt = $db->prepare("SELECT COUNT(*) AS unread_count FROM notifications WHERE user_id = ? AND is_read = FALSE");
    $stmt->execute([$user["id"]]);
    $unreadCount = (int)$stmt->fetch()["unread_count"];

    sendResponse(true, "Notifications retrieved successfully.", [
        "notifications" => $notifications,
        "page" => $page,
        "limit" => $limit,
        "unread_count" => $unreadCount
    ]);

} catch (Exception $e) {
    error_log("Notification List Error: " . $e->getMessage());
    sendError("Failed to retrieve notifications.");
}
