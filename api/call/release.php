<?php
/**
 * Release Escrow Endpoint
 *
 * Client manually releases escrowed coins to the influencer after a
 * completed call. Verifies ownership, prevents duplicate release
 * (idempotent), credits the influencer's wallet, logs a transaction,
 * updates influencer earnings, and notifies the influencer.
 *
 * If the client never calls this, the same funds are auto-released by
 * api/cron/auto-release-escrow.php after ESCROW_AUTO_RELEASE_MINUTES.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/_release_escrow.php';

$user = getAuthenticatedUser();
requireRole($user, 'client');

$db = getDatabaseConnection();
$data = getJsonInput();

$callId = (int)($data['call_id'] ?? 0);

if (!$callId) {
    sendValidationError('Call ID is required.');
}

try {
    $result = releaseEscrow($db, $callId, (int)$user['id']);

    if ($result['already_released']) {
        sendResponse(true, 'Escrow for this call has already been released.', [
            'call_id' => $callId,
            'escrow_status' => 'released',
        ]);
    }

    sendResponse(true, 'Escrow released to influencer successfully.', [
        'call_id' => $callId,
        'escrow_status' => 'released',
        'amount_released' => $result['amount'],
    ]);

} catch (RuntimeException $e) {
    $code = (int)$e->getCode();
    sendError($e->getMessage(), $code > 0 ? $code : 500);
} catch (Exception $e) {
    error_log("Release Escrow Error: " . $e->getMessage());
    sendError('Failed to release escrow.');
}