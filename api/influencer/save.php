<?php
/**
 * Save Influencer Endpoint
 * POST save_influencer
 * Adds an influencer to the authenticated client's saved list.
 * Prevents duplicate saves (idempotent).
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
    // Verify target is an active influencer
    $stmt = $db->prepare("SELECT id FROM users WHERE id = ? AND role = 'influencer' AND status = 'active'");
    $stmt->execute([$influencerId]);
    if (!$stmt->fetch()) {
        sendError('Influencer not found or not active.', 404);
    }

    // Prevent duplicate save — INSERT IGNORE is safe here; if the row
    // already exists the unique index silently discards the insert.
    $stmt = $db->prepare("INSERT IGNORE INTO saved_influencers (client_id, influencer_id) VALUES (?, ?)");
    $stmt->execute([$user['id'], $influencerId]);

    sendResponse(true, 'Influencer saved successfully.');

} catch (Exception $e) {
    error_log('Save Influencer Error: ' . $e->getMessage());
    sendError('Failed to save influencer.');
}
