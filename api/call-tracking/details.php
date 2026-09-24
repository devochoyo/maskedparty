<?php
/**
 * Call Tracking - Details Endpoint
 *
 * Returns the tracking record for a single call: who ended it, the
 * client/influencer names, and the call duration. Available to admins,
 * or to the client/influencer who were actually on that call.
 *
 *   GET /api/call-tracking/details.php?call_id=123
 *   Headers: Authorization: Bearer <token>
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

$callId = (int)($_GET['call_id'] ?? 0);

if (!$callId) {
    sendValidationError('call_id is required.');
}

try {
    $stmt = $db->prepare("
        SELECT id, call_id, influencer_id, influencer_name, client_id, client_name,
               ended_by_role, ended_by_user_id, ended_by_name, duration_seconds, created_at
        FROM call_tracking
        WHERE call_id = ?
        LIMIT 1
    ");
    $stmt->execute([$callId]);
    $record = $stmt->fetch();

    if (!$record) {
        sendError('No call tracking record found for that call.', 404);
    }

    $isParticipant = ((int)$record['client_id'] === (int)$user['id']) || ((int)$record['influencer_id'] === (int)$user['id']);
    $isAdmin = $user['role'] === 'admin';

    if (!$isAdmin && !$isParticipant) {
        sendError('Forbidden. You do not have permission to view this record.', 403);
    }

    $record['id'] = (int)$record['id'];
    $record['call_id'] = (int)$record['call_id'];
    $record['influencer_id'] = (int)$record['influencer_id'];
    $record['client_id'] = (int)$record['client_id'];
    $record['ended_by_user_id'] = $record['ended_by_user_id'] !== null ? (int)$record['ended_by_user_id'] : null;
    $record['duration_seconds'] = (int)$record['duration_seconds'];

    sendResponse(true, 'Call tracking record retrieved.', $record);

} catch (Exception $e) {
    error_log("Call Tracking Details Error: " . $e->getMessage());
    sendError('Failed to retrieve call tracking record.');
}
