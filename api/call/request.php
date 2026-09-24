<?php
/**
 * Call Request Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'client');

$data = getJsonInput();
$influencerId = (int)($data['influencer_id'] ?? 0);
$billingMode = trim((string)($data['billing_mode'] ?? 'standard'));
$allowedBillingModes = ['standard', 'payg_minute', 'payg_second'];
if (!in_array($billingMode, $allowedBillingModes, true)) {
    sendValidationError('Invalid billing mode.');
}

if (!$influencerId) {
    sendValidationError('Influencer ID is required.');
}

$db = getDatabaseConnection();

try {
    // Validate Influencer
    $stmt = $db->prepare("
        SELECT u.id, ip.online_status, ip.verification_status 
        FROM users u 
        JOIN influencer_profiles ip ON u.id = ip.user_id 
        WHERE u.id = ? AND u.role = 'influencer' AND u.status = 'active'
    ");
    $stmt->execute([$influencerId]);
    $influencer = $stmt->fetch();

    if (!$influencer) {
        sendError('Influencer not found or inactive.', 404);
    }

    if ($influencer['verification_status'] !== 'approved') {
        sendError('Influencer is not verified.', 400);
    }

    if ($influencer['online_status'] !== 'online') {
        sendError('Influencer is currently ' . $influencer['online_status'] . '.', 409);
    }

    // Check the minimum amount needed to begin the selected billing mode.
    $stmt = $db->prepare("SELECT balance FROM wallets WHERE user_id = ?");
    $stmt->execute([$user['id']]);
    $wallet = $stmt->fetch();

    $minimumCoins = 5.0; // preserve the existing standard-call rule
    if ($billingMode !== 'standard') {
        require_once __DIR__ . '/_payg_billing.php';
        $pricing = getPaygPricing($db);
        $minimumCoins = $billingMode === 'payg_second'
            ? $pricing['per_second']
            : $pricing['per_minute'];
    }

    if (!$wallet || (float)$wallet['balance'] + 0.0000001 < $minimumCoins) {
        sendError('Insufficient coins. Please buy more coins.', 402);
    }

    // Prevent a client from flooding multiple influencers with simultaneous
    // pending requests — each one independently notifies someone and
    // expires on its own, so without this check a client could rack up many
    // unresolved requests at once.
    $stmt = $db->prepare("SELECT id FROM call_requests WHERE client_id = ? AND status = 'pending' AND expires_at > NOW()");
    $stmt->execute([$user['id']]);
    if ($stmt->fetch()) {
        sendError('You already have a pending call request.', 409);
    }

    $stmt = $db->prepare("
        INSERT INTO call_requests (client_id, influencer_id, status, billing_mode, expires_at)
        VALUES (?, ?, 'pending', ?, DATE_ADD(NOW(), INTERVAL ? SECOND))
    ");
    $stmt->execute([$user['id'], $influencerId, $billingMode, CALL_REQUEST_EXPIRY_SECONDS]);
    $requestId = $db->lastInsertId();

    // Notify the influencer that a call request is waiting.
    $stmt = $db->prepare("INSERT INTO notifications (user_id, title, body, type, created_at) VALUES (?, 'New Call Request', ?, 'call_requested', NOW())");
    $stmt->execute([
        $influencerId,
        "You have a new call request from " . $user['mystery_name'] . "."
    ]);

    sendResponse(true, 'Call request sent.', [
        'request_id' => $requestId,
        'billing_mode' => $billingMode,
        'expires_at' => date('Y-m-d H:i:s', time() + CALL_REQUEST_EXPIRY_SECONDS)
    ]);

} catch (Exception $e) {
    error_log("Call Request Error: " . $e->getMessage());
    sendError('Failed to send call request.');
}
