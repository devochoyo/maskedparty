<?php
/**
 * Chat List (Conversations) Endpoint
 *
 * Previously a stub that returned a static success message with no data.
 * Implemented properly: groups chat_messages by the other participant and
 * returns each conversation's last message + unread count, most recent
 * first.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

try {
    // Every other user this authenticated user has exchanged at least one
    // message with, most recent message first.
    $stmt = $db->prepare("
        SELECT
            CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END AS other_id,
            MAX(id) AS last_message_id
        FROM chat_messages
        WHERE sender_id = ? OR receiver_id = ?
        GROUP BY other_id
        ORDER BY last_message_id DESC
    ");
    $stmt->execute([$user['id'], $user['id'], $user['id']]);
    $rows = $stmt->fetchAll();

    $conversations = [];

    foreach ($rows as $row) {
        $otherId = (int)$row['other_id'];

        $stmt = $db->prepare("SELECT id, sender_id, message, is_read, created_at FROM chat_messages WHERE id = ?");
        $stmt->execute([$row['last_message_id']]);
        $lastMessage = $stmt->fetch();

        $stmt = $db->prepare("
            SELECT COUNT(*) FROM chat_messages
            WHERE sender_id = ? AND receiver_id = ? AND is_read = FALSE
        ");
        $stmt->execute([$otherId, $user['id']]);
        $unreadCount = (int)$stmt->fetchColumn();

        $stmt = $db->prepare("SELECT id, mystery_name, role, profile_photo FROM users WHERE id = ?");
        $stmt->execute([$otherId]);
        $otherUser = $stmt->fetch();

        if (!$otherUser) {
            // The other participant's account no longer exists — skip.
            continue;
        }

        if (!empty($otherUser['profile_photo'])) {
            $otherUser['profile_photo'] = storedPathToUrl($otherUser['profile_photo']);
        }

        $conversations[] = [
            'user' => $otherUser,
            'last_message' => $lastMessage['message'] ?? null,
            'last_message_at' => $lastMessage['created_at'] ?? null,
            'last_message_is_mine' => $lastMessage ? ((int)$lastMessage['sender_id'] === (int)$user['id']) : null,
            'unread_count' => $unreadCount,
        ];
    }

    sendResponse(true, 'Conversations retrieved successfully.', ['conversations' => $conversations]);

} catch (Exception $e) {
    error_log("Chat List Error: " . $e->getMessage());
    sendError('Failed to retrieve conversations.');
}
