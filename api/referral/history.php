<?php
/**
 * Referral - Commission History Endpoint
 *
 * Lists the authenticated user's referral commissions (people they
 * referred who have made their first deposit), plus the list of people
 * they referred who have NOT deposited yet.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
$db   = getDatabaseConnection();

$page   = max(1, (int)($_GET['page'] ?? 1));
$limit  = min(50, max(1, (int)($_GET['limit'] ?? 20)));
$offset = ($page - 1) * $limit;

$stmt = $db->prepare("
    SELECT rc.id, rc.referred_user_id, u.mystery_name AS referred_mystery_name,
           rc.payment_id, rc.deposit_amount, rc.coins_purchased,
           rc.commission_rate, rc.commission_coins, rc.status, rc.created_at
    FROM referral_commissions rc
    JOIN users u ON u.id = rc.referred_user_id
    WHERE rc.referrer_id = ?
    ORDER BY rc.created_at DESC
    LIMIT ? OFFSET ?
");
$stmt->bindValue(1, $user['id'], PDO::PARAM_INT);
$stmt->bindValue(2, $limit, PDO::PARAM_INT);
$stmt->bindValue(3, $offset, PDO::PARAM_INT);
$stmt->execute();
$commissions = $stmt->fetchAll();

$stmt = $db->prepare("SELECT COUNT(*) AS cnt FROM referral_commissions WHERE referrer_id = ?");
$stmt->execute([$user['id']]);
$total = (int)($stmt->fetch()['cnt'] ?? 0);

// Referred users who have NOT yet made their first deposit (no commission
// row exists for them yet under this referrer).
$stmt = $db->prepare("
    SELECT u.id, u.mystery_name, u.role, u.created_at
    FROM users u
    WHERE u.referred_by = ?
      AND u.id NOT IN (
          SELECT referred_user_id FROM referral_commissions WHERE referrer_id = ?
      )
    ORDER BY u.created_at DESC
");
$stmt->execute([$user['id'], $user['id']]);
$pendingReferrals = $stmt->fetchAll();

sendResponse(true, 'Referral history retrieved successfully.', [
    'commissions'        => $commissions,
    'pending_referrals'  => $pendingReferrals,
    'pagination' => [
        'page'        => $page,
        'limit'       => $limit,
        'total'       => $total,
        'total_pages' => (int)ceil($total / $limit),
    ],
]);
