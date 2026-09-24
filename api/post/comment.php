<?php
/**
 * Add Comment to a Post
 * POST /post/comment.php
 * Body: { "post_id": 123, "comment": "Nice post!" }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db   = getDatabaseConnection();
$data = getJsonInput();

$postId  = (int)($data['post_id'] ?? 0);
$comment = trim($data['comment'] ?? '');

if (!$postId) {
    sendValidationError('post_id is required.');
}
if ($comment === '') {
    sendValidationError('comment is required.');
}
if (mb_strlen($comment) > 1000) {
    sendValidationError('comment must be 1000 characters or less.');
}

$stmt = $db->prepare("SELECT id FROM posts WHERE id = ?");
$stmt->execute([$postId]);
if (!$stmt->fetch()) {
    sendError('Post not found.', 404);
}

try {
    $stmt = $db->prepare("
        INSERT INTO post_comments (post_id, user_id, comment)
        VALUES (?, ?, ?)
    ");
    $stmt->execute([$postId, $user['id'], $comment]);
    $commentId = (int)$db->lastInsertId();

    // Return the new comment with basic user info
    $userStmt = $db->prepare("SELECT mystery_name, profile_photo, role FROM users WHERE id = ?");
    $userStmt->execute([$user['id']]);
    $u = $userStmt->fetch();

    sendResponse(true, 'Comment added.', [
        'comment' => [
            'id'         => $commentId,
            'post_id'    => $postId,
            'user_id'    => (int)$user['id'],
            'user_name'  => $u['mystery_name'] ?? 'User',
            'user_photo' => !empty($u['profile_photo']) ? storedPathToUrl($u['profile_photo']) : null,
            'user_role'  => $u['role'],
            'comment'    => $comment,
            'created_at' => date('Y-m-d H:i:s'),
        ],
    ]);
} catch (Exception $e) {
    error_log('Comment Post Error: ' . $e->getMessage());
    sendError('Failed to add comment.');
}
