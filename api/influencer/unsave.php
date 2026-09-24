<?php
/**
 * Remove Saved Influencer Endpoint
 * POST remove_saved_influencer
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'client');

$db = getDatabaseConnection();
$data = getJsonInput();

$influencerId = (int)($data['influencer_id'] ?? 0);
if (!$influencerId) {
    sendValidationError('influencer_id is required.');
}

try {
    $stmt = $db->prepare("DELETE FROM saved_influencers WHERE client_id = ? AND influencer_id = ?");
    $stmt->execute([$user['id'], $influencerId]);

    sendResponse(true, 'Influencer removed from saved list.');

} catch (Exception $e) {
    error_log('Remove Saved Influencer Error: ' . $e->getMessage());
    sendError('Failed to remove saved influencer.');
}
