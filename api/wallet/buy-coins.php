<?php
/**
 * Buy Coins Endpoint
 *
 * Creates a real Stripe Checkout Session via a direct HTTPS call to the
 * Stripe REST API (no Stripe SDK / Composer dependency needed).
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

/**
 * Create a Stripe Checkout Session via a plain cURL call, so no Composer
 * package is required. Returns null on any transport/API error.
 */
function createStripeCheckoutSession(array $params, string $secretKey): ?array {
    $ch = curl_init("https://api.stripe.com/v1/checkout/sessions");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => http_build_query($params),
        CURLOPT_USERPWD        => $secretKey . ":",
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_HTTPHEADER     => ["Stripe-Version: 2023-10-16"],
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError !== "" || $response === false) {
        error_log("Stripe API cURL Error: " . $curlError);
        return null;
    }

    $decoded = json_decode($response, true);

    if ($httpCode !== 200 || !is_array($decoded) || empty($decoded["id"])) {
        error_log("Stripe API Error (HTTP {$httpCode}): " . $response);
        return null;
    }

    return $decoded;
}

$user = getAuthenticatedUser();
$db = getDatabaseConnection();
$data = getJsonInput();

$packageId = (int)($data['package_id'] ?? 0);

if (!$packageId) {
    sendValidationError('Package ID is required.');
}

try {
    $stmt = $db->prepare("SELECT * FROM coin_packages WHERE id = ? AND is_active = TRUE");
    $stmt->execute([$packageId]);
    $package = $stmt->fetch();

    if (!$package) {
        sendError('Invalid or inactive coin package.', 404);
    }

    // Record pending payment first so we have an internal payment_id to
    // pass to Stripe as metadata (used by stripe-webhook.php to find the
    // exact matching row later).
    $stmt = $db->prepare("INSERT INTO payments (user_id, package_id, amount, coins, status) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$user['id'], $package['id'], $package['price'], $package['coins'], 'pending']);
    $paymentId = (int)$db->lastInsertId();

    $usingPlaceholderKey = (STRIPE_SECRET_KEY === "sk_test_your_secret_key");
    $checkoutUrl = null;

    if ($usingPlaceholderKey) {
        // No real Stripe key configured — this should only ever happen in
        // local/dev environments. STRIPE_SECRET_KEY must be set via the
        // environment in production.
        error_log("Buy Coins WARNING: STRIPE_SECRET_KEY is not configured — using simulated session ID.");
        $stripeSessionId = "cs_mock_" . bin2hex(random_bytes(12));
    } else {
        $session = createStripeCheckoutSession([
            "line_items" => [[
                "price_data" => [
                    "currency" => strtolower($package['currency']),
                    "product_data" => ["name" => $package['name']],
                    "unit_amount" => (int)round($package['price'] * 100), // Amount in cents
                ],
                "quantity" => 1,
            ]],
            "mode" => "payment",
            "success_url" => BASE_URL . "/payment/success?session_id={CHECKOUT_SESSION_ID}",
            "cancel_url" => BASE_URL . "/payment/cancel",
            "metadata" => [
                "user_id" => $user['id'],
                "package_id" => $package['id'],
                "coins" => $package['coins'],
                "payment_id" => $paymentId,
            ],
        ], STRIPE_SECRET_KEY);

        if ($session === null) {
            sendError('Failed to initiate coin purchase.', 502);
        }

        $stripeSessionId = $session['id'];
        $checkoutUrl = $session['url'] ?? null;
    }

    // Store the session ID against the pending payment so
    // stripe-webhook.php's idempotency check (by stripe_session_id) can
    // find this row immediately.
    $stmt = $db->prepare("UPDATE payments SET stripe_session_id = ? WHERE id = ?");
    $stmt->execute([$stripeSessionId, $paymentId]);

    $responseData = [
        'stripe_session_id' => $stripeSessionId,
        'package_id' => $package['id'],
        'amount' => $package['price'],
        'currency' => $package['currency'],
    ];

    // Only present when a real Stripe session was created — additive field,
    // existing clients that only read the fields above are unaffected.
    if ($checkoutUrl !== null) {
        $responseData['checkout_url'] = $checkoutUrl;
    }

    sendResponse(true, 'Stripe checkout session created.', $responseData);

} catch (Exception $e) {
    error_log("Buy Coins Error: " . $e->getMessage());
    sendError('Failed to initiate coin purchase.');
}
