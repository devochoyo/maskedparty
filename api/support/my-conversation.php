<?php
/**
 * GET /api/support/my-conversation.php
 *
 * Returns the customer's current (or most recently ended, if not yet
 * surveyed) support ticket, its status, assigned agent name (if any),
 * and the full message thread.
 *
 * Responses:
 *   200 { success: true, data: { conversation: null } }
 *        — customer has never contacted support
 *   200 { success: true, data: { conversation: {...}, messages: [...] } }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();

if (!in_array($user['role'], ['client', 'influencer'], true)) {
    sendError('Only clients and influencers have support conversations.', 403);
}

$db = getDatabaseConnection();

// Prefer an open ticket; otherwise fall back to the most recent ended
// ticket that still needs a survey, so the app can prompt for feedback.
$stmt = $db->prepare("
    SELECT sc.*, CONCAT(sa.first_name, ' ', sa.last_name) AS agent_name
    FROM support_conversations sc
    LEFT JOIN support_agents sa ON sc.support_agent_id = sa.id
    WHERE sc.customer_id = ?
    ORDER BY
        (sc.status != 'ended') DESC,
        (sc.status = 'ended' AND sc.survey_submitted = 0) DESC,
        sc.created_at DESC
    LIMIT 1
");
$stmt->execute([$user['id']]);
$conversation = $stmt->fetch();

if (!$conversation) {
    sendResponse(true, 'No support conversation yet.', ['conversation' => null]);
}

$stmt = $db->prepare("
    SELECT id, sender_type, sender_id, message, created_at
    FROM support_messages
    WHERE conversation_id = ?
    ORDER BY created_at ASC
");
$stmt->execute([$conversation['id']]);
$messages = $stmt->fetchAll();

sendResponse(true, 'Conversation retrieved.', [
    'conversation' => [
        'id'               => (int) $conversation['id'],
        'status'           => $conversation['status'],
        'agent_name'       => $conversation['agent_name'],
        'created_at'       => $conversation['created_at'],
        'ended_at'         => $conversation['ended_at'],
        'needs_survey'     => ($conversation['status'] === 'ended' && (int) $conversation['survey_submitted'] === 0),
    ],
    'messages' => $messages,
]);
