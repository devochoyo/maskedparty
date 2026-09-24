<?php
/**
 * POST /api/support/send.php
 *
 * Sends a message into an existing support ticket. Called by BOTH the
 * customer (client/influencer) app and the support agent app — the caller
 * is identified automatically from the Bearer token.
 *
 * Rules:
 *   - Customer can only send into their own conversation, and only while
 *     it is pending or active (not ended).
 *   - Support agent can only send into a conversation assigned to THEM,
 *     and only while it is active.
 *
 * Request body (JSON):
 * {
 *   "conversation_id": 12,
 *   "message": "Thanks for reaching out, how can I help?"
 * }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$caller = getAuthenticatedCustomerOrSupport();

$data = getJsonInput();
$conversationId = (int) ($data['conversation_id'] ?? 0);
$message = trim($data['message'] ?? '');

if (!$conversationId || empty($message)) {
    sendValidationError('conversation_id and message are required.');
}

if (strlen($message) > MAX_CHAT_MESSAGE_LENGTH) {
    sendValidationError('Message is too long.');
}

$db = getDatabaseConnection();

$stmt = $db->prepare("SELECT * FROM support_conversations WHERE id = ?");
$stmt->execute([$conversationId]);
$conversation = $stmt->fetch();

if (!$conversation) {
    sendError('Conversation not found.', 404);
}

if ($caller['type'] === 'customer') {
    $user = $caller['data'];

    if ((int) $conversation['customer_id'] !== (int) $user['id']) {
        sendError('Forbidden. This is not your conversation.', 403);
    }
    if ($conversation['status'] === 'ended') {
        sendError('This conversation has ended.', 400);
    }

    $senderType = 'customer';
    $senderId   = $user['id'];

} else { // support
    $agent = $caller['data'];

    if ($conversation['status'] !== 'active' || (int) $conversation['support_agent_id'] !== (int) $agent['id']) {
        sendError('You are not assigned to this conversation.', 403);
    }

    $senderType = 'support';
    $senderId   = $agent['id'];
}

try {
    $stmt = $db->prepare("
        INSERT INTO support_messages (conversation_id, sender_type, sender_id, message)
        VALUES (?, ?, ?, ?)
    ");
    $stmt->execute([$conversationId, $senderType, $senderId, $message]);

    sendResponse(true, 'Message sent.', [
        'message_id' => (int) $db->lastInsertId(),
    ]);

} catch (Exception $e) {
    error_log("Support Send Error: " . $e->getMessage());
    sendError('Failed to send message.');
}
