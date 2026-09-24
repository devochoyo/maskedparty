<?php
/**
 * Get Follow Status + Count for an Influencer
 * GET /follow/status.php?influencer_id=123
 * Optional auth – if present returns is_following.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$db = getDatabaseConnection();

$influencerId = (int)($_GET['influencer_id'] ?? 0);
if (!$influencerId) {
    sendValidationError('influencer_id is required.');
}

$countStmt = $db->prepare("SELECT COUNT(*) FROM follows WHERE following_id = ?");
$countStmt->execute([$influencerId]);
$followerCount = (int)$countStmt->fetchColumn();

$isFollowing = false;
$authHeader = getAuthorizationHeader();
if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
    $stmt = $db->prepare("
        SELECT u.id FROM users u
        JOIN user_tokens ut ON u.id = ut.user_id
        WHERE ut.token = ? AND ut.expires_at > NOW() AND u.status != 'banned'
        LIMIT 1
    ");
    $stmt->execute([$token]);
    $row = $stmt->fetch();
    if ($row) {
        $check = $db->prepare("SELECT 1 FROM follows WHERE follower_id = ? AND following_id = ? LIMIT 1");
        $check->execute([$row['id'], $influencerId]);
        $isFollowing = (bool)$check->fetch();
    }
}

sendResponse(true, 'Follow status retrieved.', [
    'influencer_id'  => $influencerId,
    'follower_count' => $followerCount,
    'is_following'   => $isFollowing,
]);
