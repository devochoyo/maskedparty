<?php
/**
 * Referral - My Code & Stats Endpoint
 *
 * Returns the authenticated user's own referral code (client or
 * influencer — both can refer), plus summary stats about people they've
 * referred and how much they've earned.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db   = getDatabaseConnection();

// Lazily generate a referral code for accounts created before this
// feature existed, so nobody is left without one.
if (empty($user['referral_code'])) {
    $code = generateReferralCode($db);
    $stmt = $db->prepare("UPDATE users SET referral_code = ? WHERE id = ?");
    $stmt->execute([$code, $user['id']]);
    $user['referral_code'] = $code;
}

$stmt = $db->prepare("SELECT COUNT(*) AS cnt FROM users WHERE referred_by = ?");
$stmt->execute([$user['id']]);
$totalReferred = (int)($stmt->fetch()['cnt'] ?? 0);

$stmt = $db->prepare("
    SELECT COUNT(DISTINCT referred_user_id) AS converted_cnt,
           COALESCE(SUM(commission_coins), 0) AS total_coins
    FROM referral_commissions
    WHERE referrer_id = ?
");
$stmt->execute([$user['id']]);
$row = $stmt->fetch();
$convertedReferrals = (int)($row['converted_cnt'] ?? 0);
$totalEarnedCoins   = (float)($row['total_coins'] ?? 0);

sendResponse(true, 'Referral code retrieved successfully.', [
    'referral_code'      => $user['referral_code'],
    'referral_link'      => BASE_URL . '/register?ref=' . $user['referral_code'],
    'commission_rate'    => (float)REFERRAL_COMMISSION_RATE,
    'total_referred'     => $totalReferred,
    'total_converted'    => $convertedReferrals,
    'pending_referrals'  => max(0, $totalReferred - $convertedReferrals),
    'total_earned_coins' => $totalEarnedCoins,
]);
