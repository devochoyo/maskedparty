<?php
/**
 * Chat Messages Endpoint
 *
 * Previously a stub that returned a static success message with no data.
 * Implemented properly: returns message history between the authenticated
 * user and one other user, oldest-first, and marks the other user's
 * messages to us as read (so opening the thread clears unread badges the
 * same way notification/list.php's unread_count expects).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

$otherUserId = (int)($_GET['other_user_id'] ?? 0);

if (!$otherUserId) {
    sendValidationError('other_user_id is required.');
}

// Simple pagination: fetch messages older than before_id (exclusive),
// newest-of-the-page first, then reverse to chronological order for display.
$limit = min(max((int)($_GET['limit'] ?? 50), 1), 100);
$beforeId = (int)($_GET['before_id'] ?? 0);

try {
    $query = "
        SELECT id, sender_id, receiver_id, message, is_read, created_at
        FROM chat_messages
        WHERE ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?))
    ";
    $params = [$user['id'], $otherUserId, $otherUserId, $user['id']];

    if ($beforeId > 0) {
        $query .= " AND id < ?";
        $params[] = $beforeId;
    }

    $query .= " ORDER BY id DESC LIMIT ?";

    $stmt = $db->prepare($query);
    foreach ($params as $i => $val) {
        $stmt->bindValue($i + 1, $val, PDO::PARAM_INT);
    }
    $stmt->bindValue(count($params) + 1, $limit, PDO::PARAM_INT);
    $stmt->execute();
    $messages = array_reverse($stmt->fetchAll());

    // Mark the other user's messages to us as read now that we've fetched them.
    $stmt = $db->prepare("
        UPDATE chat_messages SET is_read = TRUE
        WHERE sender_id = ? AND receiver_id = ? AND is_read = FALSE
    ");
    $stmt->execute([$otherUserId, $user['id']]);

    sendResponse(true, 'Messages retrieved successfully.', [
        'messages' => $messages,
        'other_user_id' => $otherUserId,
        'limit' => $limit,
    ]);

} catch (Exception $e) {
    error_log("Chat Messages Error: " . $e->getMessage());
    sendError('Failed to retrieve messages.');
}
