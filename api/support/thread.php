<?php
/**
 * GET /api/support/thread.php?conversation_id=12
 *
 * Support agent view of a single ticket's full message thread, plus
 * customer name and (if already claimed by someone else) that agent's
 * name so this agent knows not to message the customer.
 *
 * Responses:
 *   200 { success: true, data: { conversation: {...}, messages: [...] } }
 *   404 { success: false, message: "Conversation not found." }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$agent = getAuthenticatedSupportAgent();

$conversationId = (int) ($_GET['conversation_id'] ?? 0);

if (!$conversationId) {
    sendValidationError('conversation_id is required.');
}

$db = getDatabaseConnection();

$stmt = $db->prepare("
    SELECT sc.*, u.mystery_name AS customer_name, u.role AS customer_role,
           CONCAT(sa.first_name, ' ', sa.last_name) AS attending_agent_name
    FROM support_conversations sc
    JOIN users u ON sc.customer_id = u.id
    LEFT JOIN support_agents sa ON sc.support_agent_id = sa.id
    WHERE sc.id = ?
");
$stmt->execute([$conversationId]);
$conversation = $stmt->fetch();

if (!$conversation) {
    sendError('Conversation not found.', 404);
}

$stmt = $db->prepare("
    SELECT id, sender_type, sender_id, message, created_at
    FROM support_messages
    WHERE conversation_id = ?
    ORDER BY created_at ASC
");
$stmt->execute([$conversationId]);
$messages = $stmt->fetchAll();

$isMine = ($conversation['status'] === 'active' && (int) $conversation['support_agent_id'] === (int) $agent['id']);

sendResponse(true, 'Thread retrieved.', [
    'conversation' => [
        'id'                    => (int) $conversation['id'],
        'status'                => $conversation['status'],
        'customer_name'         => $conversation['customer_name'],
        'customer_role'         => $conversation['customer_role'],
        'attending_agent_name'  => $conversation['attending_agent_name'],
        'is_mine'               => $isMine,
        'can_reply'             => $isMine && $conversation['status'] === 'active',
        'created_at'            => $conversation['created_at'],
    ],
    'messages' => $messages,
]);
