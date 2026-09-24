<?php
/**
 * List Comments for a Post
 * GET /post/comments.php?post_id=123&page=1
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$db = getDatabaseConnection();

$postId = (int)($_GET['post_id'] ?? 0);
$page   = max(1, (int)($_GET['page'] ?? 1));
$limit  = 30;
$offset = ($page - 1) * $limit;

if (!$postId) {
    sendValidationError('post_id is required.');
}

$stmt = $db->prepare("SELECT id FROM posts WHERE id = ?");
$stmt->execute([$postId]);
if (!$stmt->fetch()) {
    sendError('Post not found.', 404);
}

$query = "
    SELECT
        c.id,
        c.post_id,
        c.user_id,
        c.comment,
        c.created_at,
        u.mystery_name AS user_name,
        u.profile_photo AS user_photo,
        u.role AS user_role
    FROM post_comments c
    JOIN users u ON u.id = c.user_id
    WHERE c.post_id = ?
    ORDER BY c.created_at ASC
    LIMIT ? OFFSET ?
";

$stmt = $db->prepare($query);
$stmt->bindValue(1, $postId, PDO::PARAM_INT);
$stmt->bindValue(2, $limit, PDO::PARAM_INT);
$stmt->bindValue(3, $offset, PDO::PARAM_INT);
$stmt->execute();
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$comments = [];
foreach ($rows as $row) {
    $comments[] = [
        'id'         => (int)$row['id'],
        'post_id'    => (int)$row['post_id'],
        'user_id'    => (int)$row['user_id'],
        'user_name'  => $row['user_name'],
        'user_photo' => !empty($row['user_photo']) ? storedPathToUrl($row['user_photo']) : null,
        'user_role'  => $row['user_role'],
        'comment'    => $row['comment'],
        'created_at' => $row['created_at'],
    ];
}

sendResponse(true, 'Comments retrieved.', [
    'comments' => $comments,
    'page'     => $page,
    'limit'    => $limit,
]);
