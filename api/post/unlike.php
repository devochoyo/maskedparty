<?php
/**
 * Unlike a Post
 * POST /post/unlike.php
 * Body: { "post_id": 123 }
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

try {
    $stmt = $db->prepare("DELETE FROM post_likes WHERE post_id = ? AND user_id = ?");
    $stmt->execute([$postId, $user['id']]);

    $countStmt = $db->prepare("SELECT COUNT(*) FROM post_likes WHERE post_id = ?");
    $countStmt->execute([$postId]);
    $likeCount = (int)$countStmt->fetchColumn();

    sendResponse(true, 'Post unliked.', [
        'post_id'    => $postId,
        'like_count' => $likeCount,
        'liked'      => false,
    ]);
} catch (Exception $e) {
    error_log('Unlike Post Error: ' . $e->getMessage());
    sendError('Failed to unlike post.');
}
