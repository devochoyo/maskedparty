<?php
/**
 * Call Tracking - List Endpoint
 *
 * Returns a paginated history of ended calls: who ended each one, the
 * client and influencer names, and how long the call lasted. Admin-only.
 *
 *   GET /api/call-tracking/list.php
 *   Headers: Authorization: Bearer <admin token>
 *
 * Optional query params:
 *   page        (default 1)
 *   limit       (default 20, max 100)
 *   search      matches influencer_name, client_name, or ended_by_name
 *   ended_by    'client' | 'influencer' | 'system'
 *   call_id     look up a single call
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

try {
    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = (int)($_GET['limit'] ?? 20);
    $limit = $limit > 0 ? min($limit, 100) : 20;
    $offset = ($page - 1) * $limit;

    $where = [];
    $params = [];

    if (!empty($_GET['search'])) {
        $where[] = "(influencer_name LIKE ? OR client_name LIKE ? OR ended_by_name LIKE ?)";
        $searchTerm = '%' . $_GET['search'] . '%';
        $params[] = $searchTerm;
        $params[] = $searchTerm;
        $params[] = $searchTerm;
    }

    if (!empty($_GET['ended_by']) && in_array($_GET['ended_by'], ['client', 'influencer', 'system'], true)) {
        $where[] = "ended_by_role = ?";
        $params[] = $_GET['ended_by'];
    }

    if (!empty($_GET['call_id'])) {
        $where[] = "call_id = ?";
        $params[] = (int)$_GET['call_id'];
    }

    $whereSql = $where ? ('WHERE ' . implode(' AND ', $where)) : '';

    $countStmt = $db->prepare("SELECT COUNT(*) AS total FROM call_tracking $whereSql");
    $countStmt->execute($params);
    $total = (int)$countStmt->fetch()['total'];

    $stmt = $db->prepare("
        SELECT id, call_id, influencer_id, influencer_name, client_id, client_name,
               ended_by_role, ended_by_user_id, ended_by_name, duration_seconds, created_at
        FROM call_tracking
        $whereSql
        ORDER BY created_at DESC
        LIMIT $limit OFFSET $offset
    ");
    $stmt->execute($params);
    $records = $stmt->fetchAll();

    foreach ($records as &$record) {
        $record['id'] = (int)$record['id'];
        $record['call_id'] = (int)$record['call_id'];
        $record['influencer_id'] = (int)$record['influencer_id'];
        $record['client_id'] = (int)$record['client_id'];
        $record['ended_by_user_id'] = $record['ended_by_user_id'] !== null ? (int)$record['ended_by_user_id'] : null;
        $record['duration_seconds'] = (int)$record['duration_seconds'];
    }
    unset($record);

    sendResponse(true, 'Call tracking history retrieved.', [
        'records' => $records,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'total_pages' => (int)ceil($total / $limit),
        ],
    ]);

} catch (Exception $e) {
    error_log("Call Tracking List Error: " . $e->getMessage());
    sendError('Failed to retrieve call tracking history.');
}
