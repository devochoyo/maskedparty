<?php
/**
 * Influencer Gallery Image Delete Endpoint
 *
 * NEW: added because the mobile app's gallery screen already called
 * POST /api/influencer/delete-gallery-image.php, but no such endpoint
 * previously existed.
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();
$data = getJsonInput();

$imageId = (int)($data['image_id'] ?? 0);

if (!$imageId) {
    sendValidationError('image_id is required.');
}

// Ownership check first: only the influencer who owns this gallery row may
// delete it — never trust image_id alone.
$stmt = $db->prepare("SELECT id FROM influencer_gallery WHERE id = ? AND influencer_id = ?");
$stmt->execute([$imageId, $user['id']]);
$row = $stmt->fetch();

if (!$row) {
    sendError('Gallery image not found.', 404);
}

try {
    $stmt = $db->prepare("DELETE FROM influencer_gallery WHERE id = ? AND influencer_id = ?");
    $stmt->execute([$imageId, $user['id']]);

    // NOTE: this removes the DB record (so it disappears from the gallery
    // immediately), but does not remove the underlying file from disk.
    // None of the other upload endpoints in this codebase do file cleanup
    // on delete either — if you add a shared "delete stored file" helper
    // later, wire it in here too.

    sendResponse(true, 'Gallery image deleted successfully.');

} catch (Exception $e) {
    error_log("Delete Gallery Image Error: " . $e->getMessage());
    sendError('Failed to delete gallery image.');
}
