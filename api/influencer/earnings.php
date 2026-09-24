<?php
/**
 * Influencer Earnings Dashboard Endpoint
 * GET /api/influencer/earnings.php
 *
 * Returns today's, this week's, this month's, and lifetime earnings for
 * the authenticated influencer, computed from wallet_transactions where
 * type = 'escrow_release' (credits from released call escrow).
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();

try {
    // Today
    $stmt = $db->prepare("
        SELECT COALESCE(SUM(amount_change), 0)
        FROM wallet_transactions
        WHERE user_id = ? AND type = 'escrow_release' AND amount_change > 0
          AND DATE(created_at) = CURDATE()
    ");
    $stmt->execute([$user['id']]);
    $today = (float)$stmt->fetchColumn();

    // This week (Monday–Sunday, ISO)
    $stmt = $db->prepare("
        SELECT COALESCE(SUM(amount_change), 0)
        FROM wallet_transactions
        WHERE user_id = ? AND type = 'escrow_release' AND amount_change > 0
          AND YEARWEEK(created_at, 1) = YEARWEEK(CURDATE(), 1)
    ");
    $stmt->execute([$user['id']]);
    $thisWeek = (float)$stmt->fetchColumn();

    // This month
    $stmt = $db->prepare("
        SELECT COALESCE(SUM(amount_change), 0)
        FROM wallet_transactions
        WHERE user_id = ? AND type = 'escrow_release' AND amount_change > 0
          AND YEAR(created_at) = YEAR(CURDATE())
          AND MONTH(created_at) = MONTH(CURDATE())
    ");
    $stmt->execute([$user['id']]);
    $thisMonth = (float)$stmt->fetchColumn();

    // Lifetime
    $stmt = $db->prepare("
        SELECT COALESCE(SUM(amount_change), 0)
        FROM wallet_transactions
        WHERE user_id = ? AND type = 'escrow_release' AND amount_change > 0
    ");
    $stmt->execute([$user['id']]);
    $lifetime = (float)$stmt->fetchColumn();

    // Current wallet balance & escrow
    $stmt = $db->prepare("SELECT balance, escrow_balance FROM wallets WHERE user_id = ?");
    $stmt->execute([$user['id']]);
    $wallet = $stmt->fetch();

    // Call counts
    $stmt = $db->prepare("
        SELECT
            COUNT(*) AS total_calls,
            COUNT(CASE WHEN DATE(start_time) = CURDATE() THEN 1 END) AS today_calls
        FROM video_calls
        WHERE influencer_id = ? AND status = 'completed'
    ");
    $stmt->execute([$user['id']]);
    $callStats = $stmt->fetch();

    sendResponse(true, 'Earnings retrieved successfully.', [
        'earnings' => [
            'today'      => $today,
            'this_week'  => $thisWeek,
            'this_month' => $thisMonth,
            'lifetime'   => $lifetime,
        ],
        'wallet_balance'  => (float)($wallet['balance'] ?? 0),
        'escrow_balance'  => (float)($wallet['escrow_balance'] ?? 0),
        'total_calls'     => (int)($callStats['total_calls'] ?? 0),
        'today_calls'     => (int)($callStats['today_calls'] ?? 0),
    ]);

} catch (Exception $e) {
    error_log('Influencer Earnings Error: ' . $e->getMessage());
    sendError('Failed to retrieve earnings.');
}
