<?php
/**
 * Influencer What I Offer
 *
 * GET  -> current offer + status
 * POST -> save offer
 */
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'influencer');
$db = getDatabaseConnection();

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $stmt = $db->prepare("SELECT what_offer, what_offer_status FROM influencer_profiles WHERE user_id = ?");
        $stmt->execute([$user['id']]);
        $row = $stmt->fetch();

        if (!$row) sendError('Influencer profile not found.', 404);

        $offer = trim((string)($row['what_offer'] ?? ''));
        $status = $offer !== '' ? 1 : 0;

        // Keep the explicit status column synchronized with the actual value.
        if ((int)$row['what_offer_status'] !== $status) {
            $u = $db->prepare("UPDATE influencer_profiles SET what_offer_status = ? WHERE user_id = ?");
            $u->execute([$status, $user['id']]);
        }

        sendResponse(true, 'What I Offer retrieved successfully.', [
            'what_offer' => $offer,
            'status' => $status,
        ]);
    }

    $data = getJsonInput();
    $offer = trim((string)($data['what_offer'] ?? ''));
    if ($offer === '') {
        sendValidationError('What you will offer on the video call is required.');
    }
    if (strlen($offer) > 5000) {
        sendValidationError('What I Offer is too long. Please keep it under 5000 characters.');
    }

    $stmt = $db->prepare("
        UPDATE influencer_profiles
        SET what_offer = ?, what_offer_status = 1
        WHERE user_id = ?
    ");
    $stmt->execute([$offer, $user['id']]);

    sendResponse(true, 'What I Offer saved successfully.', [
        'what_offer' => $offer,
        'status' => 1,
    ]);
} catch (Exception $e) {
    error_log("What I Offer Error: " . $e->getMessage());
    sendError('Failed to save What I Offer.');
}
