<?php
/**
 * Admin Dashboard Statistics Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

try {
    $stats = [];

    // --- User Stats ---
    $stats['total_users']           = (int) $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
    $stats['clients']               = (int) $db->query("SELECT COUNT(*) FROM users WHERE role = 'client'")->fetchColumn();
    $stats['influencers']           = (int) $db->query("SELECT COUNT(*) FROM users WHERE role = 'influencer'")->fetchColumn();
    $stats['verified_influencers']  = (int) $db->query("SELECT COUNT(*) FROM influencer_profiles WHERE verification_status = 'approved'")->fetchColumn();
    $stats['pending_verification']  = (int) $db->query("SELECT COUNT(*) FROM influencer_profiles WHERE verification_status = 'pending'")->fetchColumn();

    // --- Online Stats ---
    $stats['online_users'] = (int) $db->query("SELECT COUNT(*) FROM influencer_profiles WHERE online_status = 'online'")->fetchColumn();

    // --- Revenue Stats ---
    // Coalesce ensures 0.00 is returned instead of null when there are no rows
    $stats['today_revenue'] = (float) $db->query("SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'completed' AND DATE(created_at) = CURDATE()")->fetchColumn();
    $stats['total_revenue'] = (float) $db->query("SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'completed'")->fetchColumn();

    // --- Call Stats ---
    $stats['today_calls'] = (int) $db->query("SELECT COUNT(*) FROM video_calls WHERE DATE(start_time) = CURDATE()")->fetchColumn();
    $stats['total_calls'] = (int) $db->query("SELECT COUNT(*) FROM video_calls")->fetchColumn();

    // --- Withdrawal Stats ---
    $stats['pending_withdrawals']   = (int) $db->query("SELECT COUNT(*) FROM withdrawal_requests WHERE status = 'pending'")->fetchColumn();
    $stats['completed_withdrawals'] = (int) $db->query("SELECT COUNT(*) FROM withdrawal_requests WHERE status = 'completed'")->fetchColumn();

    // --- Wallet Stats ---
    $stats['total_escrow_balance'] = (float) $db->query("SELECT COALESCE(SUM(escrow_balance), 0) FROM wallets")->fetchColumn();

    // --- Recent Activity (last 5 completed payments) ---
    $stmt = $db->prepare("
        SELECT 'payment' AS type, amount, created_at
        FROM payments
        WHERE status = 'completed'
        ORDER BY created_at DESC
        LIMIT 5
    ");
    $stmt->execute();
    $stats['recent_activity'] = $stmt->fetchAll();

    sendResponse(true, 'Dashboard statistics retrieved.', $stats);

} catch (Exception $e) {
    error_log("Admin Dashboard Error: " . $e->getMessage());
    sendError('Failed to retrieve dashboard statistics.');
}
