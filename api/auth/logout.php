<?php
/**
 * User Logout Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

// User Status Automation: Logout → OFFLINE (for influencers)
if ($user['role'] === 'influencer') {
    $stmt = $db->prepare("UPDATE influencer_profiles SET online_status = 'offline', last_seen = NOW() WHERE user_id = ?");
    $stmt->execute([$user['id']]);
}

// Invalidate the token used in this request
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = '';
if (preg_match('/Bearer\s+(.+)/i', $authHeader, $m)) {
    $token = trim($m[1]);
}
if ($token) {
    $stmt = $db->prepare("DELETE FROM user_tokens WHERE token = ?");
    $stmt->execute([$token]);
}

sendResponse(true, 'Logged out successfully.');
