<?php
/**
 * Call Tracking - Shared Logging Helper
 *
 * Not a routable endpoint itself (underscore-prefixed, same convention as
 * api/call/_settle_call.php) - included by api/call/_settle_call.php so
 * every call, however it ends, gets exactly one call_tracking row.
 *
 * Safe to call more than once for the same call_id: the UNIQUE key on
 * call_id means a repeat call is silently ignored (INSERT IGNORE) rather
 * than throwing or creating duplicates.
 */

/**
 * Record who ended a call, the two people on it, and how long it lasted.
 *
 * @param PDO      $db             Active PDO connection.
 * @param array    $call           The video_calls row (as fetched with SELECT *).
 * @param int      $durationSeconds Actual seconds spent on the call before ending.
 * @param string   $endedByRole    'client' | 'influencer' | 'system'
 * @param int|null $endedByUserId  user_id of whoever ended it, or null for 'system'.
 */
function logCallTracking(PDO $db, array $call, int $durationSeconds, string $endedByRole, ?int $endedByUserId = null) {
    try {
        $clientId = (int)$call['client_id'];
        $influencerId = (int)$call['influencer_id'];

        // Look up display names. Falls back to mystery_name, then a
        // generic label, so a missing/blank full_name never breaks the
        // insert.
        $stmt = $db->prepare("SELECT id, full_name, mystery_name FROM users WHERE id IN (?, ?)");
        $stmt->execute([$clientId, $influencerId]);
        $rows = $stmt->fetchAll();

        $names = [];
        foreach ($rows as $row) {
            $names[(int)$row['id']] = $row['full_name'] ?: ($row['mystery_name'] ?: ('User #' . $row['id']));
        }

        $clientName = $names[$clientId] ?? ('User #' . $clientId);
        $influencerName = $names[$influencerId] ?? ('User #' . $influencerId);

        if ($endedByRole === 'system' || $endedByUserId === null) {
            $endedByRole = 'system';
            $endedByUserId = null;
            $endedByName = 'System (call time expired)';
        } elseif ($endedByUserId === $influencerId) {
            $endedByRole = 'influencer';
            $endedByName = $influencerName;
        } elseif ($endedByUserId === $clientId) {
            $endedByRole = 'client';
            $endedByName = $clientName;
        } else {
            // Whoever ended it isn't one of the two call participants
            // (e.g. an admin action). Still log it, with whatever name we
            // can find for that user.
            $stmt = $db->prepare("SELECT full_name, mystery_name FROM users WHERE id = ?");
            $stmt->execute([$endedByUserId]);
            $other = $stmt->fetch();
            $endedByName = $other ? ($other['full_name'] ?: ($other['mystery_name'] ?: ('User #' . $endedByUserId))) : ('User #' . $endedByUserId);
        }

        $stmt = $db->prepare("
            INSERT IGNORE INTO call_tracking
                (call_id, influencer_id, influencer_name, client_id, client_name,
                 ended_by_role, ended_by_user_id, ended_by_name, duration_seconds, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([
            (int)$call['id'],
            $influencerId,
            $influencerName,
            $clientId,
            $clientName,
            $endedByRole,
            $endedByUserId,
            $endedByName,
            $durationSeconds,
        ]);

    } catch (Exception $e) {
        // Tracking is a reporting side-effect, not part of the call's
        // critical path - never let a logging failure break call
        // settlement itself. Just record it for later debugging.
        error_log("Call Tracking Log Error: " . $e->getMessage());
    }
}
