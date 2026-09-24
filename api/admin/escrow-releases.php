<?php
/**
 * Admin Escrow Releases Endpoint
 *
 * Provides a full view of all escrow release activity across the platform,
 * including both client-manual releases and automatic (cron) releases.
 * Also exposes a summary (total released, pending, counts by trigger type)
 * for dashboard widgets.
 *
 * Routes (all require admin):
 *   GET /api/admin/escrow-releases.php?action=list
 *   GET /api/admin/escrow-releases.php?action=summary
 *   GET /api/admin/escrow-releases.php?action=details&call_id=42
 *
 * Filter parameters for ?action=list:
 *   status      held | released | refunded | all  (default: all)
 *   trigger     manual | auto | all               (default: all)
 *   search      partial match on client/influencer mystery_name
 *   page        integer, default 1
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireAdmin($user);

$db     = getDatabaseConnection();
$action = $_GET['action'] ?? 'list';

try {
    switch ($action) {

        // ------------------------------------------------------------------ //
        //  LIST — paginated table of all escrow records                       //
        // ------------------------------------------------------------------ //
        case 'list':
            $page   = max(1, (int)($_GET['page'] ?? 1));
            $limit  = 20;
            $offset = ($page - 1) * $limit;

            $where  = [];
            $params = [];

            // Status filter
            $statusFilter = $_GET['status'] ?? 'all';
            $validStatuses = ['held', 'released', 'refunded'];
            if ($statusFilter !== 'all' && in_array($statusFilter, $validStatuses, true)) {
                $where[]  = 'vc.escrow_status = ?';
                $params[] = $statusFilter;
            }

            // Trigger type: manual = released by client; auto = released by cron/system
            // We infer trigger from wallet_transactions: if an escrow_release transaction
            // was inserted with a description containing 'client' it was manual, else auto.
            // Simpler: we join wallet_transactions and check description keyword.
            $triggerFilter = $_GET['trigger'] ?? 'all';

            // Search by mystery_name
            if (!empty($_GET['search'])) {
                $term     = '%' . $_GET['search'] . '%';
                $where[]  = '(cu.mystery_name LIKE ? OR iu.mystery_name LIKE ?)';
                $params[] = $term;
                $params[] = $term;
            }

            $whereSql = $where ? ('WHERE ' . implode(' AND ', $where)) : '';

            // Subquery to detect whether the escrow was released manually (client
            // triggered api/call/release.php or api/call/manual_release.php) vs
            // automatically (cron). We look for an escrow_release wallet_transaction
            // whose description mentions 'manual' — manual_release.php stamps that.
            // If no such tag exists we fall back to 'auto'.
            $stmt = $db->prepare("
                SELECT
                    vc.id                           AS call_id,
                    vc.escrow_status,
                    vc.coins_spent                  AS escrow_amount,
                    vc.start_time,
                    vc.end_time,
                    vc.actual_duration_seconds,
                    cu.mystery_name                 AS client_name,
                    iu.mystery_name                 AS influencer_name,
                    vc.client_id,
                    vc.influencer_id,
                    -- Detect manual vs auto trigger
                    COALESCE(
                        (SELECT
                            CASE
                                WHEN wt.description LIKE '%manual%' THEN 'manual'
                                ELSE 'auto'
                            END
                         FROM wallet_transactions wt
                         WHERE wt.user_id = vc.client_id
                           AND wt.type    = 'escrow_release'
                           AND wt.reference LIKE CONCAT('%call #', vc.id, '%')
                         LIMIT 1
                        ),
                        CASE WHEN vc.escrow_status = 'released' THEN 'auto' ELSE NULL END
                    )                               AS release_trigger,
                    -- Timestamp of the release transaction (if any)
                    (SELECT wt.created_at
                     FROM wallet_transactions wt
                     WHERE wt.user_id = vc.client_id
                       AND wt.type    = 'escrow_release'
                       AND wt.reference LIKE CONCAT('%call #', vc.id, '%')
                     LIMIT 1
                    )                               AS released_at
                FROM video_calls vc
                JOIN users cu ON cu.id = vc.client_id
                JOIN users iu ON iu.id = vc.influencer_id
                $whereSql
                ORDER BY vc.start_time DESC
                LIMIT $limit OFFSET $offset
            ");
            $stmt->execute($params);
            $releases = $stmt->fetchAll();

            // Apply trigger filter in PHP (avoids complex SQL HAVING on subquery alias)
            if ($triggerFilter !== 'all' && in_array($triggerFilter, ['manual', 'auto'], true)) {
                $releases = array_values(array_filter($releases, function ($r) use ($triggerFilter) {
                    return $r['release_trigger'] === $triggerFilter;
                }));
            }

            // Total count (without limit/offset) for pagination
            $countStmt = $db->prepare("
                SELECT COUNT(*)
                FROM video_calls vc
                JOIN users cu ON cu.id = vc.client_id
                JOIN users iu ON iu.id = vc.influencer_id
                $whereSql
            ");
            $countStmt->execute($params);
            $total = (int)$countStmt->fetchColumn();

            sendResponse(true, 'Escrow releases retrieved successfully.', [
                'releases'     => $releases,
                'page'         => $page,
                'limit'        => $limit,
                'total'        => $total,
                'total_pages'  => (int)ceil($total / $limit),
            ]);
            break;

        // ------------------------------------------------------------------ //
        //  SUMMARY — aggregate stats for the dashboard widget                 //
        // ------------------------------------------------------------------ //
        case 'summary':
            $summary = [];

            $summary['total_held']     = (float)$db->query("SELECT COALESCE(SUM(coins_spent), 0) FROM video_calls WHERE escrow_status = 'held'")->fetchColumn();
            $summary['total_released'] = (float)$db->query("SELECT COALESCE(SUM(coins_spent), 0) FROM video_calls WHERE escrow_status = 'released'")->fetchColumn();
            $summary['total_refunded'] = (float)$db->query("SELECT COALESCE(SUM(coins_spent), 0) FROM video_calls WHERE escrow_status = 'refunded'")->fetchColumn();

            $summary['count_held']     = (int)$db->query("SELECT COUNT(*) FROM video_calls WHERE escrow_status = 'held'")->fetchColumn();
            $summary['count_released'] = (int)$db->query("SELECT COUNT(*) FROM video_calls WHERE escrow_status = 'released'")->fetchColumn();
            $summary['count_refunded'] = (int)$db->query("SELECT COUNT(*) FROM video_calls WHERE escrow_status = 'refunded'")->fetchColumn();

            // Manual vs auto releases (based on wallet_transactions description tag)
            $summary['count_manual_release'] = (int)$db->query("
                SELECT COUNT(DISTINCT reference)
                FROM wallet_transactions
                WHERE type = 'escrow_release'
                  AND description LIKE '%manual%'
            ")->fetchColumn();

            $summary['count_auto_release'] = (int)$db->query("
                SELECT COUNT(DISTINCT reference)
                FROM wallet_transactions
                WHERE type = 'escrow_release'
                  AND description NOT LIKE '%manual%'
            ")->fetchColumn();

            // Today's releases
            $summary['today_released_amount'] = (float)$db->query("
                SELECT COALESCE(SUM(vc.coins_spent), 0)
                FROM video_calls vc
                JOIN wallet_transactions wt
                  ON wt.user_id = vc.client_id
                 AND wt.type    = 'escrow_release'
                 AND wt.reference LIKE CONCAT('%call #', vc.id, '%')
                WHERE DATE(wt.created_at) = CURDATE()
            ")->fetchColumn();

            sendResponse(true, 'Escrow summary retrieved successfully.', $summary);
            break;

        // ------------------------------------------------------------------ //
        //  DETAILS — single call escrow record                                //
        // ------------------------------------------------------------------ //
        case 'details':
            $callId = (int)($_GET['call_id'] ?? 0);
            if (!$callId) sendValidationError('call_id is required.');

            $stmt = $db->prepare("
                SELECT
                    vc.id                     AS call_id,
                    vc.escrow_status,
                    vc.coins_spent            AS escrow_amount,
                    vc.start_time,
                    vc.end_time,
                    vc.actual_duration_seconds,
                    cu.mystery_name           AS client_name,
                    vc.client_id,
                    iu.mystery_name           AS influencer_name,
                    vc.influencer_id
                FROM video_calls vc
                JOIN users cu ON cu.id = vc.client_id
                JOIN users iu ON iu.id = vc.influencer_id
                WHERE vc.id = ?
                LIMIT 1
            ");
            $stmt->execute([$callId]);
            $record = $stmt->fetch();

            if (!$record) sendError('No escrow record found for that call.', 404);

            // Fetch associated wallet transactions
            $txStmt = $db->prepare("
                SELECT user_id, type, amount_change, coins_change,
                       balance_before, balance_after, description, created_at
                FROM wallet_transactions
                WHERE reference LIKE ?
                ORDER BY created_at ASC
            ");
            $txStmt->execute(['%call #' . $callId . '%']);
            $record['transactions'] = $txStmt->fetchAll();

            sendResponse(true, 'Escrow details retrieved successfully.', $record);
            break;

        default:
            sendValidationError('Unknown action.');
    }

} catch (Exception $e) {
    error_log('Admin Escrow Releases Error: ' . $e->getMessage());
    sendError('Failed to retrieve escrow release data.');
}
