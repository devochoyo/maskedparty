<?php
/**
 * Influencer Online Status Endpoint
 *
 * Allows manual toggle by the influencer.
 * Accepted values: 'online' | 'offline' | 'unavailable'
 * 'busy' is set automatically by the call lifecycle and cannot be set manually here.
 *
 * User Status Automation matrix (backend-enforced):
 *   Login           → ONLINE      (api/auth/login.php)
 *   Accept Call     → BUSY        (api/call/start.php)
 *   Call Ends       → ONLINE      (api/call/_settle_call.php)
 *   Logout          → OFFLINE     (api/auth/logout.php)
 *   Manual Toggle   → UNAVAILABLE (this endpoint, when status='unavailable')
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();
$data = getJsonInput();

$status = $data['status'] ?? '';

// 'busy' is set by the call lifecycle only — not a valid manual input
$allowed = ['online', 'offline', 'unavailable'];
if (!in_array($status, $allowed, true)) {
    sendValidationError('Invalid status. Must be one of: ' . implode(', ', $allowed) . '.');
}

try {
    // Guard: do not override BUSY status — if the influencer is on a call,
    // their status must remain 'busy' until the call ends.
    $stmt = $db->prepare("SELECT online_status FROM influencer_profiles WHERE user_id = ?");
    $stmt->execute([$user['id']]);
    $profile = $stmt->fetch();

    if ($profile && $profile['online_status'] === 'busy') {
        sendError('Status cannot be changed manually while you are on an active call.', 409);
    }

    $stmt = $db->prepare("UPDATE influencer_profiles SET online_status = ?, last_seen = NOW() WHERE user_id = ?");
    $stmt->execute([$status, $user['id']]);

    sendResponse(true, 'Online status updated successfully.', ['online_status' => $status]);

} catch (Exception $e) {
    error_log('Online Status Update Error: ' . $e->getMessage());
    sendError('Failed to update online status.');
}
