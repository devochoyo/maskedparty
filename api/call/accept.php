<?php
/**
 * Accept Call Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";
require_once __DIR__ . '/../../config/videosdk_helper.php';

// Log to a dedicated file inside api/call so failures are easy to find
// without digging through the general PHP error log.
define('CALL_ERROR_LOG', __DIR__ . '/error.log');

function logCallError($message) {
    $timestamp = date('Y-m-d H:i:s');
    error_log("[$timestamp] $message" . PHP_EOL, 3, CALL_ERROR_LOG);
}

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

logCallError("=== ACCEPT CALL STARTED ===");
logCallError("User ID: " . $user['id']);

$db = getDatabaseConnection();
$data = getJsonInput();

$requestId = (int)($data['request_id'] ?? 0);
logCallError("Request ID: " . $requestId);

if (!$requestId) {
    logCallError("ACCEPT: No request ID");
    sendValidationError('Call request ID is required.');
}

try {
    $db->beginTransaction();

    // Lock the row so a double-tap "accept", or accept racing a reject/
    // expiry, can't both be processed.
    $stmt = $db->prepare("SELECT * FROM call_requests WHERE id = ? AND influencer_id = ? FOR UPDATE");
    $stmt->execute([$requestId, $user['id']]);
    $callRequest = $stmt->fetch();

    if (!$callRequest) {
        $db->rollBack();
        logCallError("ACCEPT: Request not found - ID: $requestId, Influencer: " . $user['id']);
        sendError('Call request not found.', 404);
    }

    logCallError("ACCEPT: Request found - Status: " . $callRequest['status']);

    if ($callRequest['status'] !== 'pending') {
        $db->rollBack();
        logCallError("ACCEPT: Request not pending - Status: " . $callRequest['status']);
        sendError('Call request is no longer pending.', 409);
    }

    // Reject stale requests instead of accepting them after they've expired
    if (isset($callRequest['expires_at']) && strtotime($callRequest['expires_at']) < time()) {
        $stmt = $db->prepare("UPDATE call_requests SET status = 'expired' WHERE id = ?");
        $stmt->execute([$requestId]);
        $db->commit();
        logCallError("ACCEPT: Request expired");
        sendError('Call request has expired.', 410);
    }

    // Create real VideoSDK room
    logCallError("ACCEPT: Creating VideoSDK room...");
    $meetingId = createVideoSDKRoom();
    logCallError("ACCEPT: Room created: " . ($meetingId ?: 'FAILED'));

    if (!$meetingId) {
        $db->rollBack();
        logCallError("ACCEPT: Failed to create room - API Key: " . (VIDEOSDK_API_KEY ? 'set' : 'empty'));
        sendError('Failed to create video room. Please try again.', 500);
    }

    logCallError("ACCEPT: Generating token...");
    $meetingToken = generateVideoSDKToken($meetingId);
    logCallError("ACCEPT: Token generated: " . ($meetingToken ? 'yes' : 'no'));

    // Update call request status to accepted and persist the meeting
    // credentials so api/call/start.php can reconnect to this same
    // meeting later.
    $stmt = $db->prepare("
        UPDATE call_requests
        SET status = 'accepted', meeting_id = ?, meeting_token = ?
        WHERE id = ? AND status = 'pending'
    ");
    $stmt->execute([$meetingId, $meetingToken, $requestId]);

    if ($stmt->rowCount() === 0) {
        $db->rollBack();
        logCallError("ACCEPT: Row count 0 - already processed");
        sendError('Call request is no longer pending.', 409);
    }

    logCallError("ACCEPT: Updated to accepted. Meeting ID: $meetingId");

    // Notify the client that their request was accepted.
    $stmt = $db->prepare("INSERT INTO notifications (user_id, title, body, type, created_at) VALUES (?, 'Call Request Accepted', ?, 'call_accepted', NOW())");
    $stmt->execute([
        $callRequest['client_id'],
        "Your call request to " . $user['mystery_name'] . " has been accepted."
    ]);

    $db->commit();

    logCallError("ACCEPT: SUCCESS");

    sendResponse(true, 'Call request accepted. Meeting details provided.', [
        'meeting_id' => $meetingId,
        'meeting_token' => $meetingToken,
        'client_id' => $callRequest['client_id'],
        'influencer_id' => $callRequest['influencer_id'],
    ]);

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    logCallError("ACCEPT ERROR: " . $e->getMessage());
    logCallError("ACCEPT ERROR TRACE: " . $e->getTraceAsString());
    sendError('Failed to accept call request.');
}