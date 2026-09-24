<?php
/**
 * Start Call Endpoint
 *
 * Called after api/call/accept.php has accepted a call request. Creates
 * the video_calls row, moves coins from the client's wallet balance into
 * escrow (wallets.escrow_balance), flips the influencer to BUSY, and
 * returns the meeting credentials + initial countdown.
 *
 * Either the client or the influencer on the accepted request may call
 * this; it is idempotent — calling it again for the same request_id
 * returns the already-created call rather than double-charging.
 *
 * Price per minute is taken from the admin-managed call_minute_costs
 * table (platform-wide), never from an influencer-set value.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/_payg_billing.php';

// Log to a dedicated file inside api/call so failures are easy to find
// without digging through the general PHP error log.
define('CALL_ERROR_LOG', __DIR__ . '/error.log');

function logCallError($message) {
    $timestamp = date('Y-m-d H:i:s');
    error_log("[$timestamp] $message" . PHP_EOL, 3, CALL_ERROR_LOG);
}

/**
 * Platform-wide coins-per-minute derived from admin-defined call minute
 * costs (e.g. "1 minute = 10 coins", "12 minutes = 22 coins"). Picks the
 * tier with the cheapest coins-per-minute rate among active tiers.
 */
function getPlatformPricePerMinute(PDO $db): float {
    $stmt = $db->query("
        SELECT coin_cost, minutes
        FROM call_minute_costs
        WHERE is_active = 1 AND minutes > 0 AND coin_cost > 0
        ORDER BY (coin_cost / minutes) ASC, display_order ASC
        LIMIT 1
    ");
    $tier = $stmt->fetch();
    if ($tier && (float)$tier['minutes'] > 0) {
        return round((float)$tier['coin_cost'] / (float)$tier['minutes'], 2);
    }
    // Safe fallback if no cost tiers exist yet
    return 1.00;
}

$user = getAuthenticatedUser();
$db = getDatabaseConnection();
$data = getJsonInput();

$requestId = (int)($data['request_id'] ?? 0);

logCallError("=== START CALL STARTED ===");
logCallError("User ID: " . $user['id']);
logCallError("Request ID: " . $requestId);

if (!$requestId) {
    logCallError("START: No request ID");
    sendValidationError('Call request ID is required.');
}

try {
    $db->beginTransaction();

    // Lock the call request so a concurrent double-start can't both
    // deduct escrow for the same request.
    $stmt = $db->prepare("
        SELECT * FROM call_requests
        WHERE id = ? AND (client_id = ? OR influencer_id = ?)
        FOR UPDATE
    ");
    $stmt->execute([$requestId, $user['id'], $user['id']]);
    $callRequest = $stmt->fetch();

    if (!$callRequest) {
        $db->rollBack();
        logCallError("START: Request not found - ID: $requestId, User: " . $user['id']);
        sendError('Call request not found.', 404);
    }

    logCallError("START: Request found - Status: " . $callRequest['status']);

    if ($callRequest['status'] !== 'accepted') {
        $db->rollBack();
        logCallError("START: Request not accepted - Status: " . $callRequest['status']);
        sendError('Call request has not been accepted yet.', 409);
    }

    // Idempotency: if a video_calls row already exists for this request,
    // the call has already been started — return its current state
    // instead of charging escrow a second time.
    $stmt = $db->prepare("SELECT * FROM video_calls WHERE call_request_id = ? LIMIT 1");
    $stmt->execute([$requestId]);
    $existingCall = $stmt->fetch();

    if ($existingCall) {
        $db->commit();
        logCallError("START: Existing call found - Call ID: " . $existingCall['id']);
        sendResponse(true, 'Call already started.', [
            'call_id' => (int)$existingCall['id'],
            'meeting_id' => $existingCall['meeting_id'],
            'meeting_token' => $existingCall['meeting_token'],
            'billing_mode' => $existingCall['billing_mode'] ?? 'standard',
            'price_per_minute' => (float)$existingCall['price_per_minute'],
            'price_per_second' => (float)($existingCall['price_per_second'] ?? 0),
            'coins' => (float)$existingCall['coins_spent'],
            'paid_duration_seconds' => (int)$existingCall['paid_duration_seconds'],
            'status' => $existingCall['status'],
        ]);
    }

    $clientId = (int)$callRequest['client_id'];
    $influencerId = (int)$callRequest['influencer_id'];
    $billingMode = $callRequest['billing_mode'] ?? 'standard';

    logCallError("START: Client ID: $clientId, Influencer ID: $influencerId, Billing mode: $billingMode");

    // Lock the client wallet. The influencer wallet is not modified until
    // escrow is released, so there is no reason to lock it at call start.
    $stmt = $db->prepare("SELECT balance FROM wallets WHERE user_id = ? FOR UPDATE");
    $stmt->execute([$clientId]);
    $wallet = $stmt->fetch();

    if (!$wallet) {
        $db->rollBack();
        sendError('Client wallet not found.', 404);
    }

    $clientBalanceBefore = (float)$wallet['balance'];

    $pricePerMinute = 0.0;
    $pricePerSecond = 0.0;
    if ($billingMode === 'standard') {
        $stmt = $db->query("
            SELECT coin_cost, minutes
            FROM call_minute_costs
            WHERE is_active = 1 AND minutes > 0 AND coin_cost > 0
            ORDER BY (coin_cost / minutes) ASC, display_order ASC
            LIMIT 1
        ");
        $tier = $stmt->fetch();
        $pricePerMinute = ($tier && (float)$tier['minutes'] > 0)
            ? round((float)$tier['coin_cost'] / (float)$tier['minutes'], 4)
            : 1.00;
        $initialDurationSeconds = 60;
        $initialCoins = $pricePerMinute;
    } else {
        $pricing = getPaygPricing($db);
        $pricePerMinute = $pricing['per_minute'];
        $pricePerSecond = $pricing['per_second'];
        $initialDurationSeconds = $billingMode === 'payg_second' ? 1 : 60;
        $initialCoins = $billingMode === 'payg_second'
            ? $pricePerSecond
            : $pricePerMinute;
    }

    if ($clientBalanceBefore + 0.0000001 < $initialCoins) {
        $db->rollBack();
        sendError('Insufficient coins to start the call.', 402);
    }

    $clientBalanceAfter = round($clientBalanceBefore - $initialCoins, 4);
    $stmt = $db->prepare("
        UPDATE wallets
        SET balance = balance - ?, escrow_balance = escrow_balance + ?
        WHERE user_id = ?
    ");
    $stmt->execute([$initialCoins, $initialCoins, $clientId]);

    $stmt = $db->prepare("
        INSERT INTO wallet_transactions
            (user_id, type, coins_change, amount_change, balance_before, balance_after, reference, description, status)
        VALUES (?, 'escrow_hold', ?, ?, ?, ?, ?, ?, 'completed')
    ");
    $stmt->execute([
        $clientId, -$initialCoins, -$initialCoins,
        $clientBalanceBefore, $clientBalanceAfter,
        'Call escrow hold — request #' . $requestId,
        'Escrow hold of ' . number_format($initialCoins, 4) . ' coins for call with influencer #' . $influencerId . '.',
    ]);

    $durationMinutes = (int)ceil($initialDurationSeconds / 60);

    // Create the video_calls row using meeting credentials from accept.php
    logCallError("START: meeting_id length: " . strlen($callRequest['meeting_id'] ?? '') . ", meeting_token length: " . strlen($callRequest['meeting_token'] ?? ''));

    $stmt = $db->prepare("
        INSERT INTO video_calls
            (call_request_id, meeting_id, meeting_token, client_id, influencer_id,
             billing_mode, coins_spent, price_per_minute, price_per_second,
             duration_minutes, paid_duration_seconds,
             escrow_status, status, start_time)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'held', 'active', NOW())
    ");
    $stmt->execute([
        $requestId,
        $callRequest['meeting_id'],
        $callRequest['meeting_token'],
        $clientId,
        $influencerId,
        $billingMode,
        $initialCoins,
        $pricePerMinute,
        $pricePerSecond,
        $durationMinutes,
        $initialDurationSeconds,
    ]);
    $callId = (int)$db->lastInsertId();

    logCallError("START: video_calls row created - Call ID: $callId");

    // Flip influencer to BUSY for the duration of the call.
    $stmt = $db->prepare("UPDATE influencer_profiles SET online_status = 'busy' WHERE user_id = ?");
    $stmt->execute([$influencerId]);

    // Notify both sides that the call has started.
    $stmt = $db->prepare("INSERT INTO notifications (user_id, title, body, type, created_at) VALUES (?, 'Call Started', ?, 'call_status', NOW())");
    $stmt->execute([$clientId, 'Your call has started.']);
    $stmt->execute([$influencerId, 'Your call has started.']);

    $db->commit();

    logCallError("START: SUCCESS - Call ID: $callId");

    sendResponse(true, 'Call started successfully.', [
        'call_id' => $callId,
        'meeting_id' => $callRequest['meeting_id'],
        'meeting_token' => $callRequest['meeting_token'],
        'billing_mode' => $billingMode,
        'price_per_minute' => $pricePerMinute,
        'price_per_second' => $pricePerSecond,
        'coins' => (float)$initialCoins,
        'paid_duration_seconds' => $initialDurationSeconds,
        'status' => 'active',
    ]);

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    logCallError("START ERROR: " . $e->getMessage());
    logCallError("START ERROR TRACE: " . $e->getTraceAsString());
    sendError('Failed to start call.');
}