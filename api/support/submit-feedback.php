<?php
/**
 * POST /api/support/submit-feedback.php
 *
 * Customer submits the post-conversation survey after a ticket has ended.
 * Updates the assigned agent's good/bad feedback counters, which drive
 * their 5-point rating on the admin dashboard.
 *
 * Request body (JSON):
 * {
 *   "conversation_id": 12,
 *   "satisfied": true,
 *   "issue_resolved": false,
 *   "professional": true,
 *   "feedback_text": "Optional free text"
 * }
 *
 * A ticket is marked "bad" if ANY of satisfied / issue_resolved /
 * professional is false.
 *
 * Responses:
 *   200 { success: true, message: "Thank you for your feedback." }
 *   404 { success: false, message: "Conversation not found." }
 *   409 { success: false, message: "Feedback already submitted for this conversation." }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();

if (!in_array($user['role'], ['client', 'influencer'], true)) {
    sendError('Only clients and influencers can submit support feedback.', 403);
}

$data = getJsonInput();
$conversationId = (int) ($data['conversation_id'] ?? 0);

if (!$conversationId || !isset($data['satisfied'], $data['issue_resolved'], $data['professional'])) {
    sendValidationError('conversation_id, satisfied, issue_resolved and professional are required.');
}

$satisfied     = $data['satisfied'] ? 1 : 0;
$issueResolved = $data['issue_resolved'] ? 1 : 0;
$professional  = $data['professional'] ? 1 : 0;
$feedbackText  = isset($data['feedback_text']) ? trim($data['feedback_text']) : null;

$isBad = ($satisfied === 0 || $issueResolved === 0 || $professional === 0) ? 1 : 0;

$db = getDatabaseConnection();

try {
    $db->beginTransaction();

    $stmt = $db->prepare("
        SELECT id, support_agent_id, status, survey_submitted
        FROM support_conversations
        WHERE id = ? AND customer_id = ?
        FOR UPDATE
    ");
    $stmt->execute([$conversationId, $user['id']]);
    $conversation = $stmt->fetch();

    if (!$conversation) {
        $db->rollBack();
        sendError('Conversation not found.', 404);
    }

    if ($conversation['status'] !== 'ended') {
        $db->rollBack();
        sendError('Feedback can only be submitted after the conversation has ended.', 400);
    }

    if ((int) $conversation['survey_submitted'] === 1) {
        $db->rollBack();
        sendError('Feedback already submitted for this conversation.', 409);
    }

    if (!$conversation['support_agent_id']) {
        $db->rollBack();
        sendError('This conversation was never assigned to an agent.', 400);
    }

    $agentId = (int) $conversation['support_agent_id'];

    $stmt = $db->prepare("
        INSERT INTO support_feedback
            (conversation_id, support_agent_id, customer_id, satisfied, issue_resolved, professional, feedback_text, is_bad)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([$conversationId, $agentId, $user['id'], $satisfied, $issueResolved, $professional, $feedbackText, $isBad]);

    if ($isBad) {
        $stmt = $db->prepare("UPDATE support_agents SET bad_feedback_count = bad_feedback_count + 1 WHERE id = ?");
    } else {
        $stmt = $db->prepare("UPDATE support_agents SET good_feedback_count = good_feedback_count + 1 WHERE id = ?");
    }
    $stmt->execute([$agentId]);

    $stmt = $db->prepare("UPDATE support_conversations SET survey_submitted = 1 WHERE id = ?");
    $stmt->execute([$conversationId]);

    $db->commit();

    sendResponse(true, 'Thank you for your feedback.');

} catch (Exception $e) {
    $db->rollBack();
    error_log("Support Feedback Error: " . $e->getMessage());
    sendError('Failed to submit feedback.');
}
