<?php
/**
 * Influencer Own Gallery List Endpoint
 *
 * NEW: added because the mobile app's gallery screen already called
 * GET /api/influencer/gallery.php to load the influencer's own gallery for
 * management (view/delete), but no such endpoint previously existed —
 * influencer/details.php only returns gallery for OTHER users' public
 * profile view, and is not auth-scoped to "my own gallery".
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();

$stmt = $db->prepare("SELECT id, image_url FROM influencer_gallery WHERE influencer_id = ? ORDER BY id ASC");
$stmt->execute([$user['id']]);
$rows = $stmt->fetchAll();

$gallery = [];
foreach ($rows as $row) {
    $gallery[] = [
        'id'  => $row['id'],
        'url' => storedPathToUrl($row['image_url']),
    ];
}

sendResponse(true, 'Gallery retrieved successfully.', ['gallery' => $gallery]);
