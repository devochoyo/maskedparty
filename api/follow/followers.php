<?php
/**
 * List Followers of an Influencer
 * GET /follow/followers.php?influencer_id=123&page=1
 * Public endpoint (no auth required).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$db = getDatabaseConnection();

$influencerId = (int)($_GET['influencer_id'] ?? 0);
$page         = max(1, (int)($_GET['page'] ?? 1));
$limit        = 30;
$offset       = ($page - 1) * $limit;

if (!$influencerId) {
    sendValidationError('influencer_id is required.');
}

// Verify influencer exists
$stmt = $db->prepare("SELECT id FROM users WHERE id = ? AND role = 'influencer'");
$stmt->execute([$influencerId]);
if (!$stmt->fetch()) {
    sendError('Influencer not found.', 404);
}

$query = "
    SELECT
        u.id,
        u.mystery_name,
        u.profile_photo,
        u.country_name,
        f.created_at AS followed_at
    FROM follows f
    JOIN users u ON u.id = f.follower_id
    WHERE f.following_id = ?
    ORDER BY f.created_at DESC
    LIMIT ? OFFSET ?
";

$stmt = $db->prepare($query);
$stmt->bindValue(1, $influencerId, PDO::PARAM_INT);
$stmt->bindValue(2, $limit, PDO::PARAM_INT);
$stmt->bindValue(3, $offset, PDO::PARAM_INT);
$stmt->execute();
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$followers = [];
foreach ($rows as $row) {
    $followers[] = [
        'id'           => (int)$row['id'],
        'mystery_name' => $row['mystery_name'],
        'profile_photo'=> !empty($row['profile_photo'])
                            ? storedPathToUrl($row['profile_photo'])
                            : null,
        'country_name' => $row['country_name'],
        'followed_at'  => $row['followed_at'],
    ];
}

// Total count
$countStmt = $db->prepare("SELECT COUNT(*) FROM follows WHERE following_id = ?");
$countStmt->execute([$influencerId]);
$total = (int)$countStmt->fetchColumn();

sendResponse(true, 'Followers retrieved.', [
    'followers'      => $followers,
    'follower_count' => $total,
    'page'           => $page,
    'limit'          => $limit,
]);
