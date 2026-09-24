<?php
/**
 * Influencer Active Status Endpoint
 *
 * Returns the *true* live online status of one or more influencers,
 * based on both their stored online_status and how recently their
 * client pinged the heartbeat endpoint.
 *
 * An influencer is considered TRULY ONLINE only when:
 *   1. Their online_status is 'online' or 'busy', AND
 *   2. Their last_active_ping is within the last 30 seconds.
 *
 * If the ping is stale (> 30 s) they are treated as "away" regardless
 * of what online_status says — this catches browser closes, crashes,
 * or lost connections that haven't yet triggered a logout.
 *
 * ─────────────────────────────────────────────────
 * Usage (GET):
 *
 *   Single influencer:
 *     GET /api/influencer/active-status.php?id=42
 *
 *   Batch (up to 50):
 *     GET /api/influencer/active-status.php?ids=1,2,3,42
 *
 * No authentication required — status is public information.
 * ─────────────────────────────────────────────────
 *
 * Response shape (single):
 * {
 *   "success": true,
 *   "data": {
 *     "influencer_id": 42,
 *     "online_status": "online",      // stored enum value
 *     "is_truly_online": true,        // heartbeat-verified
 *     "last_active_ping": "2026-08-03T10:15:30+00:00",
 *     "last_seen": "2026-08-03T10:15:28+00:00"
 *   }
 * }
 *
 * Response shape (batch):
 * {
 *   "success": true,
 *   "data": [
 *     { "influencer_id": 1,  "online_status": "online",      "is_truly_online": true,  ... },
 *     { "influencer_id": 2,  "online_status": "offline",     "is_truly_online": false, ... },
 *     { "influencer_id": 42, "online_status": "unavailable", "is_truly_online": false, ... }
 *   ]
 * }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';

$db = getDatabaseConnection();

// ── Parse request ────────────────────────────────────────────────────────────

$singleId = isset($_GET['id'])  ? (int)$_GET['id']  : 0;
$batchRaw = isset($_GET['ids']) ? trim($_GET['ids']) : '';

if (!$singleId && !$batchRaw) {
    sendValidationError('Provide either ?id=<influencer_id> or ?ids=<comma-separated list>.');
}

// Build the list of IDs to look up
if ($singleId) {
    $ids = [$singleId];
} else {
    $ids = array_values(
        array_unique(
            array_filter(
                array_map('intval', explode(',', $batchRaw))
            )
        )
    );
    if (count($ids) > 50) {
        sendValidationError('Batch limit is 50 influencer IDs per request.');
    }
}

// ── Heartbeat threshold ──────────────────────────────────────────────────────
// An influencer must have pinged within the last 30 seconds to be
// considered truly online. 30 s gives a comfortable buffer over the 15 s
// client interval, tolerating one missed ping before flipping to away.
define('HEARTBEAT_THRESHOLD_SECONDS', 30);

// ── Query ────────────────────────────────────────────────────────────────────

$placeholders = implode(',', array_fill(0, count($ids), '?'));

$stmt = $db->prepare("
    SELECT
        ip.user_id                                      AS influencer_id,
        ip.online_status,
        ip.last_active_ping,
        ip.last_seen,
        -- Truly online: status is active AND client pinged recently
        CASE
            WHEN ip.online_status IN ('online', 'busy')
             AND ip.last_active_ping IS NOT NULL
             AND TIMESTAMPDIFF(SECOND, ip.last_active_ping, NOW()) <= " . HEARTBEAT_THRESHOLD_SECONDS . "
            THEN 1
            ELSE 0
        END AS is_truly_online
    FROM influencer_profiles ip
    INNER JOIN users u ON u.id = ip.user_id
    WHERE ip.user_id IN ($placeholders)
      AND u.role   = 'influencer'
      AND u.status = 'active'
    ORDER BY FIELD(ip.user_id, $placeholders)
");

// Bind ids twice: once for IN clause, once for FIELD() ordering
$allParams = array_merge($ids, $ids);
$stmt->execute($allParams);
$rows = $stmt->fetchAll();

// ── Format results ───────────────────────────────────────────────────────────

$results = array_map(function (array $row): array {
    return [
        'influencer_id'    => (int)$row['influencer_id'],
        'online_status'    => $row['online_status'],
        'is_truly_online'  => (bool)$row['is_truly_online'],
        'last_active_ping' => $row['last_active_ping']
            ? (new DateTime($row['last_active_ping']))->format('c')
            : null,
        'last_seen'        => $row['last_seen']
            ? (new DateTime($row['last_seen']))->format('c')
            : null,
    ];
}, $rows);

// ── Return ───────────────────────────────────────────────────────────────────

if ($singleId) {
    if (empty($results)) {
        sendError('Influencer not found.', 404);
    }
    sendResponse(true, 'Active status retrieved.', $results[0]);
} else {
    sendResponse(true, 'Active statuses retrieved.', $results);
}