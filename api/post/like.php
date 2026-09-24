<?php
/**
 * Like a Post
 * POST /post/like.php
 * Body: { "post_id": 123 }
 * Requires authentication (any role).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db   = getDatabaseConnection();
$data = getJsonInput();

$postId = (int)($data['post_id'] ?? 0);
if (!$postId) {
    sendValidationError('post_id is required.');
}

// Verify post exists
$stmt = $db->prepare("SELECT id FROM posts WHERE id = ?");
$stmt->execute([$postId]);
if (!$stmt->fetch()) {
    sendError('Post not found.', 404);
}

try {
    $stmt = $db->prepare("INSERT IGNORE INTO post_likes (post_id, user_id) VALUES (?, ?)");
    $stmt->execute([$postId, $user['id']]);

    $countStmt = $db->prepare("SELECT COUNT(*) FROM post_likes WHERE post_id = ?");
    $countStmt->execute([$postId]);
    $likeCount = (int)$countStmt->fetchColumn();

    sendResponse(true, 'Post liked.', [
        'post_id'    => $postId,
        'like_count' => $likeCount,
        'liked'      => true,
    ]);
} catch (Exception $e) {
    error_log('Like Post Error: ' . $e->getMessage());
    sendError('Failed to like post.');
}
