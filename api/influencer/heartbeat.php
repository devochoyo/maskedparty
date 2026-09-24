<?php
/**
 * Influencer Heartbeat Endpoint
 *
 * Called by the influencer's client every 15 seconds to confirm they are
 * truly active (tab open, connected). Updates last_active_ping timestamp.
 *
 * If the influencer's current online_status is 'online' or 'busy', this
 * keeps them marked as truly online. If no ping is received for more than
 * 30 seconds, the active-status endpoint will treat them as offline/away
 * even if their online_status column still says 'online'.
 *
 * Route:  POST /api/influencer/heartbeat.php
 * Auth:   Influencer JWT required
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();

try {
    // Update last_active_ping to NOW so we know the client is alive.
    // Also refresh last_seen for backward compatibility.
    $stmt = $db->prepare("
        UPDATE influencer_profiles
        SET last_active_ping = NOW(),
            last_seen        = NOW()
        WHERE user_id = ?
    ");
    $stmt->execute([$user['id']]);

    sendResponse(true, 'Heartbeat received.', [
        'pinged_at' => date('c'),
    ]);

} catch (Exception $e) {
    error_log('Heartbeat Error: ' . $e->getMessage());
    sendError('Failed to record heartbeat.');
}