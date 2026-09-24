<?php
/**
 * GET /api/support/messages.php
 *
 * Support agent's inbox: every PENDING ticket (unclaimed — any agent can
 * attend to it) plus every ticket ACTIVE and assigned to THIS agent.
 * Pending tickets already claimed by another agent show that agent's
 * name and cannot be attended to by this agent.
 *
 * Responses:
 *   200 { success: true, message: "No messages yet.", data: { tickets: [] } }
 *   200 { success: true, message: "Tickets retrieved.", data: { tickets: [...] } }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$agent = getAuthenticatedSupportAgent();

$db = getDatabaseConnection();

$stmt = $db->prepare("
    SELECT
        sc.id,
        sc.status,
        sc.created_at,
        sc.support_agent_id,
        u.mystery_name AS customer_name,
        u.role AS customer_role,
        CONCAT(sa.first_name, ' ', sa.last_name) AS attending_agent_name,
        (
            SELECT sm.message FROM support_messages sm
            WHERE sm.conversation_id = sc.id
            ORDER BY sm.created_at DESC LIMIT 1
        ) AS last_message,
        (
            SELECT sm.created_at FROM support_messages sm
            WHERE sm.conversation_id = sc.id
            ORDER BY sm.created_at DESC LIMIT 1
        ) AS last_message_at
    FROM support_conversations sc
    JOIN users u ON sc.customer_id = u.id
    LEFT JOIN support_agents sa ON sc.support_agent_id = sa.id
    WHERE
        sc.status = 'pending'
        OR (sc.status = 'active' AND sc.support_agent_id = ?)
    ORDER BY sc.created_at DESC
");
$stmt->execute([$agent['id']]);
$tickets = $stmt->fetchAll();

foreach ($tickets as &$ticket) {
    $ticket['id'] = (int) $ticket['id'];
    $ticket['support_agent_id'] = $ticket['support_agent_id'] !== null ? (int) $ticket['support_agent_id'] : null;
    // Whether THIS agent can claim it (only unclaimed pending tickets)
    $ticket['can_attend'] = ($ticket['status'] === 'pending');
    $ticket['is_mine'] = ($ticket['status'] === 'active' && $ticket['support_agent_id'] === (int) $agent['id']);
}
unset($ticket);

sendResponse(true, count($tickets) === 0 ? 'No messages yet.' : 'Tickets retrieved.', [
    'tickets' => $tickets,
]);
