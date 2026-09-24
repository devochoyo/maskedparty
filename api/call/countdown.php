<?php
/**
 * Call Countdown Endpoint
 *
 * Returns the real remaining time on an active call, based on the paid
 * duration set at start.php/extend.php versus elapsed time since
 * start_time. If the countdown has reached zero, auto-ends the call
 * (same settlement logic as api/call/end.php) so a client polling this
 * endpoint doesn't need a separate mechanism to notice expiry.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/_payg_billing.php';

$user = getAuthenticatedUser();
$db = getDatabaseConnection();
$data = getJsonInput();

$callId = (int)($data['call_id'] ?? 0);

if (!$callId) {
    sendValidationError('Call ID is required.');
}

try {
    $stmt = $db->prepare("
        SELECT * FROM video_calls
        WHERE id = ? AND (client_id = ? OR influencer_id = ?)
    ");
    $stmt->execute([$callId, $user['id'], $user['id']]);
    $call = $stmt->fetch();

    if (!$call) {
        sendError('Call not found.', 404);
    }

    if ($call['status'] !== 'active') {
        sendResponse(true, 'Call is not active.', [
            'call_id' => (int)$call['id'],
            'status' => $call['status'],
            'remaining_seconds' => 0,
            'escrow_status' => $call['escrow_status'],
        ]);
    }

    $elapsedSeconds = max(0, time() - strtotime($call['start_time']));
    $billingMode = $call['billing_mode'] ?? 'standard';
    $isPayg = in_array($billingMode, ['payg_minute', 'payg_second'], true);

    // Pay As You Go calls are renewed automatically from the client's
    // wallet. If the next billing unit cannot be funded, end the call
    // cleanly instead of allowing the wallet to go negative.
    if ($isPayg) {
        if (!topUpPaygEscrow($db, $call, $elapsedSeconds)) {
            require_once __DIR__ . '/_settle_call.php';
            $ended = settleCall($db, (int)$call['id'], 'insufficient_balance');
            sendResponse(true, 'Call ended because the client has insufficient coins.', [
                'call_id' => (int)$call['id'],
                'status' => 'completed',
                'remaining_seconds' => 0,
                'elapsed_seconds' => $elapsedSeconds,
                'actual_duration_seconds' => $ended['actual_duration_seconds'],
                'coins' => (float)$ended['coins_spent'],
                'billing_mode' => $billingMode,
                'escrow_status' => $ended['escrow_status'],
                'insufficient_balance' => true,
            ]);
        }
    }

    $remainingSeconds = max(0, (int)$call['paid_duration_seconds'] - $elapsedSeconds);

    // For standard calls only: when paid time is exhausted, auto-end.
    // For PAYG, topUpPaygEscrow above already extended paid_duration or
    // ended the call on insufficient balance — so remaining <= 0 should
    // not happen for an active PAYG call after a successful top-up.
    if ($remainingSeconds <= 0 && !$isPayg) {
        require_once __DIR__ . '/_settle_call.php';
        $ended = settleCall($db, (int)$call['id'], 'timeout');

        sendResponse(true, 'Call time expired and has been ended.', [
            'call_id' => (int)$call['id'],
            'status' => 'completed',
            'remaining_seconds' => 0,
            'elapsed_seconds' => $elapsedSeconds,
            'actual_duration_seconds' => $ended['actual_duration_seconds'],
            'coins' => (float)$ended['coins_spent'],
            'billing_mode' => $billingMode,
            'escrow_status' => $ended['escrow_status'],
        ]);
    }

    // Safety net: if PAYG somehow still has remaining <= 0 after top-up
    // (e.g. paid_duration not updated), try one more top-up path result.
    if ($remainingSeconds <= 0 && $isPayg) {
        require_once __DIR__ . '/_settle_call.php';
        $ended = settleCall($db, (int)$call['id'], 'timeout');
        sendResponse(true, 'Call time expired and has been ended.', [
            'call_id' => (int)$call['id'],
            'status' => 'completed',
            'remaining_seconds' => 0,
            'elapsed_seconds' => $elapsedSeconds,
            'actual_duration_seconds' => $ended['actual_duration_seconds'],
            'coins' => (float)$ended['coins_spent'],
            'billing_mode' => $billingMode,
            'escrow_status' => $ended['escrow_status'],
        ]);
    }

    sendResponse(true, 'Countdown retrieved.', [
        'call_id' => (int)$call['id'],
        'status' => 'active',
        'remaining_seconds' => $remainingSeconds,
        'elapsed_seconds' => $elapsedSeconds,
        'paid_duration_seconds' => (int)$call['paid_duration_seconds'],
        'coins' => (float)$call['coins_spent'],
        'billing_mode' => $billingMode,
        'escrow_status' => $call['escrow_status'],
    ]);

} catch (Exception $e) {
    error_log("Call Countdown Error: " . $e->getMessage());
    sendError('Failed to retrieve call countdown.');
}