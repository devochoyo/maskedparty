<?php
/**
 * Get Single Post (full body + images)
 * GET /post/get.php?id=123
 * Optional auth for liked_by_me.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$db = getDatabaseConnection();

$postId = (int)($_GET['id'] ?? 0);
if (!$postId) {
    sendValidationError('id is required.');
}

$currentUserId = null;
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
    if ($row) $currentUserId = (int)$row['id'];
}

$stmt = $db->prepare("
    SELECT
        p.id, p.influencer_id, p.caption, p.body, p.created_at,
        u.mystery_name AS influencer_name,
        u.profile_photo AS influencer_photo,
        u.country_name AS influencer_country,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) AS like_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) AS comment_count
    FROM posts p
    JOIN users u ON u.id = p.influencer_id
    WHERE p.id = ?
");
$stmt->execute([$postId]);
$post = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$post) {
    sendError('Post not found.', 404);
}

$imgStmt = $db->prepare("
    SELECT id, image_url, display_order
    FROM post_images WHERE post_id = ?
    ORDER BY display_order ASC, id ASC
");
$imgStmt->execute([$postId]);
$images = [];
while ($img = $imgStmt->fetch(PDO::FETCH_ASSOC)) {
    $images[] = [
        'id'  => (int)$img['id'],
        'url' => storedPathToUrl($img['image_url']),
    ];
}

$likedByMe = false;
if ($currentUserId) {
    $likeStmt = $db->prepare("SELECT 1 FROM post_likes WHERE post_id = ? AND user_id = ? LIMIT 1");
    $likeStmt->execute([$postId, $currentUserId]);
    $likedByMe = (bool)$likeStmt->fetch();
}

sendResponse(true, 'Post retrieved.', [
    'post' => [
        'id'                 => (int)$post['id'],
        'influencer_id'      => (int)$post['influencer_id'],
        'influencer_name'    => $post['influencer_name'],
        'influencer_photo'   => !empty($post['influencer_photo'])
                                    ? storedPathToUrl($post['influencer_photo'])
                                    : null,
        'influencer_country' => $post['influencer_country'],
        'caption'            => $post['caption'],
        'body'               => $post['body'],
        'images'             => $images,
        'like_count'         => (int)$post['like_count'],
        'comment_count'      => (int)$post['comment_count'],
        'liked_by_me'        => $likedByMe,
        'created_at'         => $post['created_at'],
    ],
]);
