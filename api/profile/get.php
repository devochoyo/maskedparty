<?php
/**
 * Get Profile Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db   = getDatabaseConnection();

/**
 * Platform-wide coins-per-minute derived from coin packages.
 */
function getPlatformPricePerMinute(PDO $db): float
{
    $stmt = $db->query("
        SELECT coins, minutes
        FROM coin_packages
        WHERE is_active = 1
          AND minutes > 0
          AND coins > 0
        ORDER BY is_best_value DESC, is_popular DESC, (coins / minutes) ASC, display_order ASC
        LIMIT 1
    ");
    $pkg = $stmt->fetch();

    if ($pkg && (float) $pkg['minutes'] > 0) {
        return round((float) $pkg['coins'] / (float) $pkg['minutes'], 2);
    }

    return 1.00;
}

$stmt = $db->prepare("
    SELECT
        u.id,
        u.email,
        u.mystery_name,
        u.role,
        u.country_name,
        u.country_code,
        u.status,
        u.profile_photo,
        u.full_name,
        u.bank_name,
        u.account_number,
        w.balance        AS wallet_balance,
        w.escrow_balance
    FROM users u
    JOIN wallets w ON u.id = w.user_id
    WHERE u.id = ?
");
$stmt->execute([$user['id']]);
$profile = $stmt->fetch();

// Build public URL from stored relative path
if (!empty($profile['profile_photo'])) {
    $profile['profile_photo'] = storedPathToUrl($profile['profile_photo']);
}

if ($user['role'] === 'influencer') {
    $stmt = $db->prepare("SELECT * FROM influencer_profiles WHERE user_id = ?");
    $stmt->execute([$user['id']]);
    $influencerData = $stmt->fetch();

    if ($influencerData) {
        // Build public URLs for verification documents and gallery stored as relative paths
        $urlFields = ['government_id_url', 'selfie_url', 'verification_video_url', 'intro_video'];
        foreach ($urlFields as $field) {
            if (!empty($influencerData[$field])) {
                $influencerData[$field] = storedPathToUrl($influencerData[$field]);
            }
        }

        // Override any stored influencer price with the live platform rate
        $influencerData['price_per_minute'] = getPlatformPricePerMinute($db);

        // Explicitly ensure mask_status is always present for influencers
        // Values: "masked" | "unmasked"
        if (empty($influencerData['mask_status']) || !in_array($influencerData['mask_status'], ['masked', 'unmasked'], true)) {
            $influencerData['mask_status'] = 'masked'; // safe default
        }

        $profile = array_merge($profile, $influencerData);
    } else {
        // Profile row missing — still expose the field
        $profile['mask_status'] = 'masked';
    }
}

sendResponse(true, 'Profile retrieved successfully.', $profile);