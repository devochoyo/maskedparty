<?php
/**
 * Send Chat Message Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$data = getJsonInput();

$receiverId = (int)($data['receiver_id'] ?? 0);
$message = trim($data['message'] ?? '');

if (!$receiverId || empty($message)) {
    sendValidationError('Receiver ID and message are required.');
}

if ($receiverId === $user['id']) {
    sendError('You cannot message yourself.');
}

if (strlen($message) > MAX_CHAT_MESSAGE_LENGTH) {
    sendValidationError('Message is too long.');
}

// Filter contact information: redact matched spans with [BLOCKED] and
// store the filtered message, rather than rejecting it outright.
$message = filterContactInfo($message);

$db = getDatabaseConnection();

// Validate receiver exists and role compatibility
$stmt = $db->prepare("SELECT role FROM users WHERE id = ?");
$stmt->execute([$receiverId]);
$receiver = $stmt->fetch();

if (!$receiver) {
    sendError('Receiver not found.', 404);
}

if ($user['role'] === $receiver['role']) {
    sendError('You can only message users with a different role.');
}

// Clients and influencers can now chat freely without a prior call

try {
    $stmt = $db->prepare("
        INSERT INTO chat_messages (sender_id, receiver_id, message, is_read, created_at) 
        VALUES (?, ?, ?, 0, NOW())
    ");
    $stmt->execute([$user['id'], $receiverId, $message]);
    $messageId = $db->lastInsertId();

    // Create Notification
    $stmt = $db->prepare("
        INSERT INTO notifications (user_id, title, body, type, created_at) 
        VALUES (?, 'New Message', ?, 'chat', NOW())
    ");
    $stmt->execute([$receiverId, "You have a new message from " . $user['mystery_name']]);

    sendResponse(true, 'Message sent successfully.', [
        'message_id' => $messageId,
        'message' => $message
    ]);

} catch (Exception $e) {
    error_log("Chat Send Error: " . $e->getMessage());
    sendError('Failed to send message.');
}