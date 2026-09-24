<?php
/**
 * List Public Posts (Home Feed)
 * GET /post/list.php?page=1
 * Optional Authorization header – if present, includes liked_by_me flag.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$db = getDatabaseConnection();

$page  = max(1, (int)($_GET['page'] ?? 1));
$limit = 15;
$offset = ($page - 1) * $limit;

// Optional authenticated user (for liked_by_me)
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
    if ($row) {
        $currentUserId = (int)$row['id'];
    }
}

$query = "
    SELECT
        p.id,
        p.influencer_id,
        p.caption,
        p.body,
        p.created_at,
        u.mystery_name AS influencer_name,
        u.profile_photo AS influencer_photo,
        u.country_name AS influencer_country,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) AS like_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) AS comment_count
    FROM posts p
    JOIN users u ON u.id = p.influencer_id
    JOIN influencer_profiles ip ON ip.user_id = u.id
    WHERE u.role = 'influencer'
      AND u.status = 'active'
      AND ip.verification_status = 'approved'
    ORDER BY p.created_at DESC
    LIMIT ? OFFSET ?
";

$stmt = $db->prepare($query);
$stmt->bindValue(1, $limit, PDO::PARAM_INT);
$stmt->bindValue(2, $offset, PDO::PARAM_INT);
$stmt->execute();
$posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

$result = [];
foreach ($posts as $post) {
    // Images
    $imgStmt = $db->prepare("
        SELECT id, image_url, display_order
        FROM post_images
        WHERE post_id = ?
        ORDER BY display_order ASC, id ASC
    ");
    $imgStmt->execute([$post['id']]);
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
        $likeStmt->execute([$post['id'], $currentUserId]);
        $likedByMe = (bool)$likeStmt->fetch();
    }

    // Short body preview (first ~120 chars)
    $bodyPreview = null;
    if (!empty($post['body'])) {
        $plain = strip_tags($post['body']);
        $bodyPreview = mb_strlen($plain) > 120
            ? mb_substr($plain, 0, 120) . '…'
            : $plain;
    }

    $result[] = [
        'id'                  => (int)$post['id'],
        'influencer_id'       => (int)$post['influencer_id'],
        'influencer_name'     => $post['influencer_name'],
        'influencer_photo'    => !empty($post['influencer_photo'])
                                    ? storedPathToUrl($post['influencer_photo'])
                                    : null,
        'influencer_country'  => $post['influencer_country'],
        'caption'             => $post['caption'],
        'body'                => $post['body'],
        'body_preview'        => $bodyPreview,
        'images'              => $images,
        'like_count'          => (int)$post['like_count'],
        'comment_count'       => (int)$post['comment_count'],
        'liked_by_me'         => $likedByMe,
        'created_at'          => $post['created_at'],
    ];
}

sendResponse(true, 'Posts retrieved successfully.', [
    'posts' => $result,
    'page'  => $page,
    'limit' => $limit,
]);
