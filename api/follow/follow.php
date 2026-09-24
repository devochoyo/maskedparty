<?php
/**
 * Follow an Influencer
 * POST /follow/follow.php
 * Body: { "influencer_id": 123 }
 * Requires authenticated client.
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

if ($influencerId === (int)$user['id']) {
    sendError('You cannot follow yourself.', 400);
}

// Verify target is an active approved influencer
$stmt = $db->prepare("
    SELECT u.id
    FROM users u
    JOIN influencer_profiles ip ON ip.user_id = u.id
    WHERE u.id = ? AND u.role = 'influencer' AND u.status = 'active'
      AND ip.verification_status = 'approved'
");
$stmt->execute([$influencerId]);
if (!$stmt->fetch()) {
    sendError('Influencer not found or not available.', 404);
}

try {
    $stmt = $db->prepare("INSERT IGNORE INTO follows (follower_id, following_id) VALUES (?, ?)");
    $stmt->execute([$user['id'], $influencerId]);

    $countStmt = $db->prepare("SELECT COUNT(*) FROM follows WHERE following_id = ?");
    $countStmt->execute([$influencerId]);
    $followerCount = (int)$countStmt->fetchColumn();

    sendResponse(true, 'Followed successfully.', [
        'influencer_id'  => $influencerId,
        'following'      => true,
        'follower_count' => $followerCount,
    ]);
} catch (Exception $e) {
    error_log('Follow Error: ' . $e->getMessage());
    sendError('Failed to follow influencer.');
}
