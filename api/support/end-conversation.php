<?php
/**
 * POST /api/support/end-conversation.php
 *
 * Support agent marks a ticket as resolved/ended. Only the agent assigned
 * to an ACTIVE ticket can end it. Once ended, the customer's app can
 * prompt for the satisfaction survey (see my-conversation.php's
 * "needs_survey" flag and submit-feedback.php).
 *
 * Request body (JSON):
 * {
 *   "conversation_id": 12
 * }
 *
 * Responses:
 *   200 { success: true, message: "Conversation ended." }
 *   403 { success: false, message: "You are not assigned to this conversation." }
 *   404 { success: false, message: "Conversation not found." }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$agent = getAuthenticatedSupportAgent();

$data = getJsonInput();
$conversationId = (int) ($data['conversation_id'] ?? 0);

if (!$conversationId) {
    sendValidationError('conversation_id is required.');
}

$db = getDatabaseConnection();

$stmt = $db->prepare("SELECT * FROM support_conversations WHERE id = ?");
$stmt->execute([$conversationId]);
$conversation = $stmt->fetch();

if (!$conversation) {
    sendError('Conversation not found.', 404);
}

if ($conversation['status'] !== 'active' || (int) $conversation['support_agent_id'] !== (int) $agent['id']) {
    sendError('You are not assigned to this conversation.', 403);
}

try {
    $stmt = $db->prepare("UPDATE support_conversations SET status = 'ended', ended_at = NOW() WHERE id = ?");
    $stmt->execute([$conversationId]);

    sendResponse(true, 'Conversation ended.');

} catch (Exception $e) {
    error_log("Support End Conversation Error: " . $e->getMessage());
    sendError('Failed to end conversation.');
}
