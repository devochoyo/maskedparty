<?php
/**
 * Escrow Auto-Release Cron Script
 *
 * NOT a web-facing endpoint — this is meant to be invoked from the
 * command line by a cron job (or an equivalent scheduled task runner),
 * not through a browser or the mobile app. It does not read any HTTP
 * request data and does not go through index.php's routing.
 *
 * Finds every video_calls row with escrow_status = 'held' whose call
 * ended more than ESCROW_AUTO_RELEASE_MINUTES ago and releases the
 * escrowed coins to the influencer, using the exact same logic as the
 * manual api/call/release.php endpoint (see _release_escrow.php), so a
 * client who never manually releases still pays out on schedule.
 *
 * Idempotent and safe to run repeatedly / on overlapping schedules: each
 * release is guarded by escrow_status = 'held' inside its own row lock,
 * so a manual release racing this cron for the same call can't double-
 * credit the influencer.
 *
 * Suggested crontab entry (runs every 5 minutes):
 *   /5 * * * * php /path/to/project/api/cron/auto-release-escrow.php >> /path/to/project/logs/escrow-cron.log 2>&1
 *
 * Exits with status 0 on success (even if there was nothing to release),
 * non-zero if a fatal error occurred before processing could complete.
 */

// Guard against accidental web access — this script must only run from
// the CLI SAPI.
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    echo "This script is for CLI/cron use only.\n";
    exit(1);
}

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../call/_release_escrow.php';

$db = getDatabaseConnection();

$releasedCount = 0;
$errorCount = 0;

try {
    // Select candidates outside the per-row transaction used by
    // releaseEscrow(), so one row's lock doesn't block us from finding
    // the others; releaseEscrow() takes its own row-level lock per call.
    $stmt = $db->prepare("
        SELECT id
        FROM video_calls
        WHERE escrow_status = 'held'
          AND status = 'completed'
          AND end_time IS NOT NULL
          AND end_time <= DATE_SUB(NOW(), INTERVAL ? MINUTE)
    ");
    $stmt->execute([ESCROW_AUTO_RELEASE_MINUTES]);
    $candidates = $stmt->fetchAll();

    foreach ($candidates as $row) {
        $callId = (int)$row['id'];
        try {
            $result = releaseEscrow($db, $callId, null);
            if (!$result['already_released']) {
                $releasedCount++;
                echo "[" . date('Y-m-d H:i:s') . "] Auto-released escrow for call #{$callId} (" .
                     number_format($result['amount'], 2) . " to influencer #{$result['influencer_id']}).\n";
            }
        } catch (Exception $e) {
            $errorCount++;
            error_log("Auto-Release Escrow Error (call #{$callId}): " . $e->getMessage());
            echo "[" . date('Y-m-d H:i:s') . "] ERROR releasing escrow for call #{$callId}: " . $e->getMessage() . "\n";
        }
    }

    echo "[" . date('Y-m-d H:i:s') . "] Done. Released: {$releasedCount}, Errors: {$errorCount}, Candidates: " . count($candidates) . ".\n";
    exit($errorCount > 0 ? 1 : 0);

} catch (Exception $e) {
    error_log("Auto-Release Escrow Fatal Error: " . $e->getMessage());
    echo "[" . date('Y-m-d H:i:s') . "] FATAL: " . $e->getMessage() . "\n";
    exit(1);
}
