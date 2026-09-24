<?php
/**
 * Influencer Details Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$db = getDatabaseConnection();

$influencerId = (int)($_GET["id"] ?? 0);

if (!$influencerId) {
    sendValidationError("Influencer ID is required.");
}

/**
 * Platform-wide coins-per-minute derived from admin-defined call minute
 * costs (e.g. "1 minute = 10 coins", "12 minutes = 22 coins"). Picks the
 * tier with the cheapest coins-per-minute rate among active tiers.
 */
function getPlatformPricePerMinute(PDO $db): float {
    $stmt = $db->query("
        SELECT coin_cost, minutes
        FROM call_minute_costs
        WHERE is_active = 1 AND minutes > 0 AND coin_cost > 0
        ORDER BY (coin_cost / minutes) ASC, display_order ASC
        LIMIT 1
    ");
    $tier = $stmt->fetch();
    if ($tier && (float)$tier['minutes'] > 0) {
        return round((float)$tier['coin_cost'] / (float)$tier['minutes'], 2);
    }
    return 1.00;
}

$stmt = $db->prepare("
    SELECT u.id, u.mystery_name, u.country_name, u.profile_photo,
           ip.biography, ip.age, ip.complexion, ip.favourite_food, ip.hobby, ip.aspiration, ip.financial_target,
           ip.what_offer, ip.what_offer_status,
           ip.mask_status, ip.willing_to_remove_mask, ip.intro_video, ip.average_rating, ip.online_status,
           ip.verification_status, ip.total_calls
    FROM users u
    JOIN influencer_profiles ip ON u.id = ip.user_id
    WHERE u.id = ? AND u.role = 'influencer' AND u.status = 'active' AND ip.verification_status = 'approved'
");
$stmt->execute([$influencerId]);
$influencer = $stmt->fetch();

if (!$influencer) {
    sendError("Influencer not found or not verified.", 404);
}

// Platform rate (same for every influencer)
$influencer['price_per_minute'] = getPlatformPricePerMinute($db);

// Build public URLs from stored relative paths
if (!empty($influencer['profile_photo'])) {
    $influencer['profile_photo'] = storedPathToUrl($influencer['profile_photo']);
}
if (!empty($influencer['intro_video'])) {
    $influencer['intro_video'] = storedPathToUrl($influencer['intro_video']);
}

// Fetch gallery items and build public URLs
$stmt = $db->prepare("SELECT id, image_url FROM influencer_gallery WHERE influencer_id = ? ORDER BY id ASC");
$stmt->execute([$influencerId]);
$galleryRows = $stmt->fetchAll();
$gallery = [];
foreach ($galleryRows as $row) {
    $gallery[] = [
        'id'  => $row['id'],
        'url' => storedPathToUrl($row['image_url']),
    ];
}
$influencer['gallery'] = $gallery;

sendResponse(true, "Influencer details retrieved.", $influencer);