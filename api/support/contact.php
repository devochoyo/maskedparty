<?php
/**
 * POST /api/support/contact.php
 *
 * Used by BOTH clients and influencers to contact support. If the
 * customer has no open ticket (pending or active), a new one is created
 * and every active support agent is emailed + notified in-app. If they
 * already have an open ticket, the message is simply appended to it.
 *
 * Request body (JSON):
 * {
 *   "message": "I can't withdraw my earnings"
 * }
 *
 * Responses:
 *   200 { success: true, message: "...", data: { conversation_id, status, is_new_ticket } }
 *   422 { success: false, message: "..." }   — validation
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/../../mail/supportMailFunctions.php';

$user = getAuthenticatedUser();

if (!in_array($user['role'], ['client', 'influencer'], true)) {
    sendError('Only clients and influencers can contact support.', 403);
}

$data = getJsonInput();
$message = trim($data['message'] ?? '');

if (empty($message)) {
    sendValidationError('Message is required.');
}

if (strlen($message) > MAX_CHAT_MESSAGE_LENGTH) {
    sendValidationError('Message is too long.');
}

$db = getDatabaseConnection();

try {
    $db->beginTransaction();

    // Does the customer already have an open (pending or active) ticket?
    $stmt = $db->prepare("
        SELECT id, status FROM support_conversations
        WHERE customer_id = ? AND status IN ('pending', 'active')
        ORDER BY created_at DESC LIMIT 1
    ");
    $stmt->execute([$user['id']]);
    $conversation = $stmt->fetch();

    $isNewTicket = false;

    if ($conversation) {
        $conversationId = (int) $conversation['id'];
        $status = $conversation['status'];
    } else {
        $stmt = $db->prepare("INSERT INTO support_conversations (customer_id, status) VALUES (?, 'pending')");
        $stmt->execute([$user['id']]);
        $conversationId = (int) $db->lastInsertId();
        $status = 'pending';
        $isNewTicket = true;
    }

    $stmt = $db->prepare("
        INSERT INTO support_messages (conversation_id, sender_type, sender_id, message)
        VALUES (?, 'customer', ?, ?)
    ");
    $stmt->execute([$conversationId, $user['id'], $message]);

    if ($isNewTicket) {
        // In-app notification for every active agent (notifications table
        // extended with support_agent_id/recipient_type — see sql/support_migration.sql)
        $stmt = $db->prepare("SELECT id FROM support_agents WHERE status = 'active'");
        $stmt->execute();
        $agentIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

        if ($agentIds) {
            $notifyStmt = $db->prepare("
                INSERT INTO notifications (support_agent_id, recipient_type, title, body, type, created_at)
                VALUES (?, 'support', 'New Support Ticket', ?, 'support_new_ticket', NOW())
            ");
            $notifBody = 'New ticket from ' . $user['mystery_name'] . ': ' . mb_substr($message, 0, 100);
            foreach ($agentIds as $agentId) {
                $notifyStmt->execute([$agentId, $notifBody]);
            }
        }
    }

    $db->commit();

    if ($isNewTicket) {
        // Best-effort email — never block the customer's message on mail failure.
        notifyAllSupportAgentsNewTicket($db, $user['mystery_name'], $message);
    }

    sendResponse(true, $isNewTicket ? 'Your message has been sent to support.' : 'Message sent.', [
        'conversation_id' => $conversationId,
        'status'          => $status,
        'is_new_ticket'   => $isNewTicket,
    ]);

} catch (Exception $e) {
    $db->rollBack();
    error_log("Support Contact Error: " . $e->getMessage());
    sendError('Failed to send message to support.');
}
