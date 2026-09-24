<?php
/**
 * Reject Call Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();
$data = getJsonInput();

$requestId = (int)($data['request_id'] ?? 0);

if (!$requestId) {
    sendValidationError('Call request ID is required.');
}

try {
    $db->beginTransaction();

    // Lock the row so a concurrent accept/reject/expiry can't race this update.
    $stmt = $db->prepare("SELECT * FROM call_requests WHERE id = ? AND influencer_id = ? FOR UPDATE");
    $stmt->execute([$requestId, $user['id']]);
    $callRequest = $stmt->fetch();

    if (!$callRequest) {
        $db->rollBack();
        sendError('Call request not found or not pending for you.', 404);
    }

    // Update call request status to rejected, only if it's still pending.
    // rowCount() confirms the row actually transitioned, guarding against a
    // race with accept.php/expiry that already changed its status.
    $stmt = $db->prepare("UPDATE call_requests SET status = 'rejected' WHERE id = ? AND status = 'pending'");
    $stmt->execute([$requestId]);

    if ($stmt->rowCount() === 0) {
        $db->rollBack();
        sendError('Call request not found or not pending for you.', 404);
    }

    // Notify client (in a real app, this would trigger a push notification)
    $stmt = $db->prepare("INSERT INTO notifications (user_id, title, body, type, created_at) VALUES (?, ?, ?, ?, NOW())");
    $stmt->execute([
        $callRequest['client_id'],
        "Call Request Rejected",
        "Your call request to " . $user['mystery_name'] . " has been rejected.",
        "call_rejected"
    ]);

    $db->commit();

    sendResponse(true, 'Call request rejected successfully.');

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Reject Call Error: " . $e->getMessage());
    sendError('Failed to reject call request.');
}
