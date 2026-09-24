<?php
/**
 * Pending Call Request Endpoint (influencer side)
 *
 * NEW: added because the mobile app already polled
 * GET /api/call/pending.php to find out if a client is waiting to be
 * accepted/rejected, but no such endpoint previously existed — without it
 * an influencer had no way to discover an incoming call/request.php call.
 *
 * Returns the oldest still-pending, unexpired request addressed to the
 * authenticated influencer, or data: null if there isn't one.
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();

$stmt = $db->prepare("
    SELECT cr.id AS request_id, cr.client_id, cr.expires_at,
           u.mystery_name AS client_mystery_name, u.profile_photo AS client_profile_photo
    FROM call_requests cr
    JOIN users u ON u.id = cr.client_id
    WHERE cr.influencer_id = ? AND cr.status = 'pending' AND cr.expires_at > NOW()
    ORDER BY cr.id ASC
    LIMIT 1
");
$stmt->execute([$user['id']]);
$pending = $stmt->fetch();

if (!$pending) {
    sendResponse(true, 'No pending call request.', null);
}

if (!empty($pending['client_profile_photo'])) {
    $pending['client_profile_photo'] = storedPathToUrl($pending['client_profile_photo']);
}

sendResponse(true, 'Pending call request found.', $pending);
