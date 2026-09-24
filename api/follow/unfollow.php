<?php
/**
 * Unfollow an Influencer
 * POST /follow/unfollow.php
 * Body: { "influencer_id": 123 }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'client');

$db   = getDatabaseConnection();
$data = getJsonInput();

$influencerId = (int)($data['influencer_id'] ?? 0);
if (!$influencerId) {
    sendValidationError('influencer_id is required.');
}

try {
    $stmt = $db->prepare("DELETE FROM follows WHERE follower_id = ? AND following_id = ?");
    $stmt->execute([$user['id'], $influencerId]);

    $countStmt = $db->prepare("SELECT COUNT(*) FROM follows WHERE following_id = ?");
    $countStmt->execute([$influencerId]);
    $followerCount = (int)$countStmt->fetchColumn();

    sendResponse(true, 'Unfollowed successfully.', [
        'influencer_id'  => $influencerId,
        'following'      => false,
        'follower_count' => $followerCount,
    ]);
} catch (Exception $e) {
    error_log('Unfollow Error: ' . $e->getMessage());
    sendError('Failed to unfollow influencer.');
}
