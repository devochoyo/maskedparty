<?php
/**
 * List Influencers Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$db = getDatabaseConnection();

$page = (int)($_GET['page'] ?? 1);
$limit = 20;
$offset = ($page - 1) * $limit;

$country    = $_GET['country']     ?? '';
$maskStatus = $_GET['mask_status'] ?? '';
$search     = $_GET['search']      ?? '';
$sortBy     = $_GET['sort_by']     ?? 'newest';

$query = "
    SELECT u.id, u.mystery_name, u.country_name, u.profile_photo, 
           ip.mask_status, ip.online_status, ip.average_rating, ip.price_per_minute
    FROM users u
    JOIN influencer_profiles ip ON u.id = ip.user_id
    WHERE u.role = 'influencer' AND u.status = 'active' AND ip.verification_status = 'approved' AND ip.profile_completed = 1
";

$params = [];

if ($country) {
    $query .= " AND u.country_name = ?";
    $params[] = $country;
}

if ($maskStatus) {
    $query .= " AND ip.mask_status = ?";
    $params[] = $maskStatus;
}

if ($search) {
    $query .= " AND u.mystery_name LIKE ?";
    $params[] = "%$search%";
}

switch ($sortBy) {
    case 'highest_rated':
        $query .= " ORDER BY ip.average_rating DESC";
        break;
    case 'most_popular':
        $query .= " ORDER BY ip.total_calls DESC";
        break;
    case 'newest':
    default:
        $query .= " ORDER BY u.id DESC";
        break;
}

$query .= " LIMIT ? OFFSET ?";
$params[] = $limit;
$params[] = $offset;

$stmt = $db->prepare($query);
// Bind LIMIT/OFFSET explicitly as integers: with emulated prepares
// disabled (see config/database.php), passing them through execute() as
// plain array values sends them as strings, which the native MySQL
// protocol rejects for LIMIT/OFFSET.
foreach ($params as $i => $value) {
    $isLimitOrOffset = ($i === count($params) - 1 || $i === count($params) - 2);
    $stmt->bindValue($i + 1, $value, $isLimitOrOffset ? PDO::PARAM_INT : PDO::PARAM_STR);
}
$stmt->execute();
$influencers = $stmt->fetchAll();

// Build public URLs from stored relative paths
foreach ($influencers as &$inf) {
    if (!empty($inf['profile_photo'])) {
        $inf['profile_photo'] = storedPathToUrl($inf['profile_photo']);
    }
}
unset($inf);

sendResponse(true, 'Influencers retrieved successfully.', [
    'influencers' => $influencers,
    'page'        => $page,
    'limit'       => $limit,
]);