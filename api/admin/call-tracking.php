<?php
/**
 * Admin Call Tracking Endpoint
 *
 * Thin admin-panel wrapper around the `call_tracking` table (see
 * api/call-tracking/ for the table definition and the logging helper that
 * fills it in whenever a call ends). Follows the same action-based
 * convention as the other api/admin/*.php files so it works with the
 * existing admin/proxy.php whitelist (paths matching admin/*.php).
 *
 *   GET /api/admin/call-tracking.php?action=list
 *   GET /api/admin/call-tracking.php?action=details&call_id=42
 *
 * Sidebar navigation hint (consumed by the frontend admin shell):
 *   GET /api/admin/call-tracking.php?action=nav
 *   Returns the sidebar nav entries for Call Tracking and Escrow Releases
 *   so the frontend can dynamically build / refresh its sidebar without
 *   hardcoding routes.
 *
 * Escrow release summary (proxies to escrow-releases.php?action=summary):
 *   GET /api/admin/call-tracking.php?action=escrow_summary
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$action = $_GET['action'] ?? 'list';

try {
    switch ($action) {

        case 'list':
            $page   = max(1, (int)($_GET['page'] ?? 1));
            $limit  = 20;
            $offset = ($page - 1) * $limit;

            $where  = [];
            $params = [];

            if (!empty($_GET['search'])) {
                $where[]  = "(influencer_name LIKE ? OR client_name LIKE ? OR ended_by_name LIKE ?)";
                $term     = '%' . $_GET['search'] . '%';
                $params[] = $term;
                $params[] = $term;
                $params[] = $term;
            }

            if (!empty($_GET['ended_by']) && in_array($_GET['ended_by'], ['client', 'influencer', 'system'], true)) {
                $where[]  = "ended_by_role = ?";
                $params[] = $_GET['ended_by'];
            }

            $whereSql = $where ? ('WHERE ' . implode(' AND ', $where)) : '';

            $stmt = $db->prepare("
                SELECT id, call_id, influencer_id, influencer_name, client_id, client_name,
                       ended_by_role, ended_by_user_id, ended_by_name, duration_seconds, created_at
                FROM call_tracking
                $whereSql
                ORDER BY created_at DESC
                LIMIT $limit OFFSET $offset
            ");
            $stmt->execute($params);
            $calls = $stmt->fetchAll();

            sendResponse(true, 'Call tracking history retrieved successfully.', [
                'calls' => $calls,
                'page'  => $page,
                'limit' => $limit,
            ]);
            break;

        case 'details':
            $callId = (int)($_GET['call_id'] ?? 0);
            if (!$callId) sendValidationError('call_id is required.');

            $stmt = $db->prepare("
                SELECT id, call_id, influencer_id, influencer_name, client_id, client_name,
                       ended_by_role, ended_by_user_id, ended_by_name, duration_seconds, created_at
                FROM call_tracking
                WHERE call_id = ?
                LIMIT 1
            ");
            $stmt->execute([$callId]);
            $record = $stmt->fetch();

            if (!$record) sendError('No call tracking record found for that call.', 404);

            sendResponse(true, 'Call tracking record retrieved successfully.', $record);
            break;

        // ------------------------------------------------------------------ //
        //  NAV — sidebar navigation entries for the admin shell               //
        // ------------------------------------------------------------------ //
        case 'nav':
            sendResponse(true, 'Admin sidebar nav entries.', [
                'nav_items' => [
                    [
                        'label'    => 'Call Tracking',
                        'icon'     => 'phone',
                        'endpoint' => 'admin/call-tracking.php',
                        'action'   => 'list',
                    ],
                    [
                        'label'    => 'Escrow Releases',
                        'icon'     => 'shield-check',
                        'endpoint' => 'admin/escrow-releases.php',
                        'action'   => 'list',
                        'children' => [
                            [
                                'label'  => 'All Releases',
                                'action' => 'list',
                                'filter' => ['status' => 'all'],
                            ],
                            [
                                'label'  => 'Manual Releases',
                                'action' => 'list',
                                'filter' => ['trigger' => 'manual'],
                            ],
                            [
                                'label'  => 'Auto Releases',
                                'action' => 'list',
                                'filter' => ['trigger' => 'auto'],
                            ],
                            [
                                'label'  => 'Held (Pending)',
                                'action' => 'list',
                                'filter' => ['status' => 'held'],
                            ],
                            [
                                'label'  => 'Summary',
                                'action' => 'summary',
                            ],
                        ],
                    ],
                ],
            ]);
            break;

        // ------------------------------------------------------------------ //
        //  ESCROW SUMMARY — convenience proxy to escrow-releases.php          //
        // ------------------------------------------------------------------ //
        case 'escrow_summary':
            require_once __DIR__ . '/escrow-releases.php';
            // escrow-releases.php handles its own output; execution stops there.
            break;

        default:
            sendValidationError('Unknown action.');
    }
} catch (Exception $e) {
    error_log("Admin Call Tracking Error: " . $e->getMessage());
    sendError('Failed to retrieve call tracking data.');
}
