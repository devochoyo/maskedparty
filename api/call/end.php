<?php
/**
 * End Call Endpoint
 *
 * Either party (client or influencer) on an active call may end it early.
 * Finalizes call state and returns the influencer to ONLINE. Does NOT
 * release escrow — that is a separate step: the client manually releases
 * via api/call/release.php, or it auto-releases after
 * ESCROW_AUTO_RELEASE_MINUTES via the cron job in api/cron/.
 *
 * Whoever calls this endpoint is recorded as the person who ended the
 * call (see api/call-tracking/).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/_settle_call.php';

$user = getAuthenticatedUser();
$db = getDatabaseConnection();
$data = getJsonInput();

$callId = (int)($data['call_id'] ?? 0);

if (!$callId) {
    sendValidationError('Call ID is required.');
}

try {
    $stmt = $db->prepare("
        SELECT id FROM video_calls
        WHERE id = ? AND (client_id = ? OR influencer_id = ?)
    ");
    $stmt->execute([$callId, $user['id'], $user['id']]);
    if (!$stmt->fetch()) {
        sendError('Call not found.', 404);
    }

    $result = settleCall($db, $callId, 'manual', (int)$user['id']);

    sendResponse(true, $result['already_completed'] ? 'Call was already ended.' : 'Call ended successfully.', [
        'call_id' => $callId,
        'status' => 'completed',
        'actual_duration_seconds' => $result['actual_duration_seconds'],
        'coins' => (float)$result['coins_spent'],
        'billing_mode' => $result['billing_mode'] ?? 'standard',
    ]);

} catch (Exception $e) {
    error_log("End Call Error: " . $e->getMessage());
    sendError('Failed to end call.');
}
