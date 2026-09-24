<?php
/**
 * POST /api/support/attend.php
 *
 * Support agent clicks a pending ticket and decides whether to attend.
 *
 * Request body (JSON):
 * {
 *   "conversation_id": 12,
 *   "decision": "yes"   // or "no"
 * }
 *
 * If "yes": the ticket is atomically claimed by this agent (status -> active).
 *           Fails with 409 if another agent claimed it first (race-safe).
 * If "no":  nothing changes — the ticket remains pending for other agents.
 *
 * Responses:
 *   200 { success: true, message: "You are now assisting this customer." }
 *   200 { success: true, message: "Okay, ticket left for other agents." }
 *   409 { success: false, message: "This ticket has already been claimed by <name>." }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$agent = getAuthenticatedSupportAgent();

$data = getJsonInput();
$conversationId = (int) ($data['conversation_id'] ?? 0);
$decision = strtolower(trim($data['decision'] ?? ''));

if (!$conversationId || !in_array($decision, ['yes', 'no'], true)) {
    sendValidationError('conversation_id and decision ("yes" or "no") are required.');
}

$db = getDatabaseConnection();

if ($decision === 'no') {
    // Nothing to persist — the agent simply chose not to attend.
    sendResponse(true, 'Okay, ticket left for other agents.');
}

try {
    $db->beginTransaction();

    $stmt = $db->prepare("SELECT * FROM support_conversations WHERE id = ? FOR UPDATE");
    $stmt->execute([$conversationId]);
    $conversation = $stmt->fetch();

    if (!$conversation) {
        $db->rollBack();
        sendError('Conversation not found.', 404);
    }

    if ($conversation['status'] !== 'pending') {
        $db->rollBack();

        if ($conversation['support_agent_id']) {
            $stmt = $db->prepare("SELECT CONCAT(first_name, ' ', last_name) AS name FROM support_agents WHERE id = ?");
            $stmt->execute([$conversation['support_agent_id']]);
            $existing = $stmt->fetch();
            $name = $existing['name'] ?? 'another agent';
            sendError("This ticket has already been claimed by {$name}.", 409);
        }

        sendError('This ticket is no longer available.', 409);
    }

    $stmt = $db->prepare("
        UPDATE support_conversations
        SET status = 'active', support_agent_id = ?, attended_at = NOW()
        WHERE id = ? AND status = 'pending'
    ");
    $stmt->execute([$agent['id'], $conversationId]);

    if ($stmt->rowCount() === 0) {
        // Someone else claimed it in the split second between our SELECT and UPDATE.
        $db->rollBack();
        sendError('This ticket has already been claimed by another agent.', 409);
    }

    $db->commit();

    sendResponse(true, 'You are now assisting this customer.');

} catch (Exception $e) {
    $db->rollBack();
    error_log("Support Attend Error: " . $e->getMessage());
    sendError('Failed to process your decision.');
}
