<?php
/**
 * Saved Influencers List Endpoint
 * GET saved_influencers
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'client');

$db = getDatabaseConnection();

try {
    $stmt = $db->prepare("
        SELECT u.id, u.mystery_name, u.country_name, u.profile_photo,
               ip.average_rating, ip.online_status, ip.price_per_minute,
               ip.mask_status, ip.verification_status,
               si.created_at AS saved_at
        FROM saved_influencers si
        JOIN users u ON si.influencer_id = u.id
        JOIN influencer_profiles ip ON u.id = ip.user_id
        WHERE si.client_id = ?
        ORDER BY si.created_at DESC
    ");
    $stmt->execute([$user['id']]);
    $rows = $stmt->fetchAll();

    foreach ($rows as &$row) {
        if (!empty($row['profile_photo'])) {
            $row['profile_photo'] = storedPathToUrl($row['profile_photo']);
        }
    }
    unset($row);

    sendResponse(true, 'Saved influencers retrieved.', ['influencers' => $rows]);

} catch (Exception $e) {
    error_log('Saved Influencers Error: ' . $e->getMessage());
    sendError('Failed to retrieve saved influencers.');
}
