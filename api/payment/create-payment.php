<?php
/**
 * Create Payment Endpoint (Flutterwave v3 Standard Checkout)
 *
 * Initialises a Flutterwave Standard payment and returns the hosted
 * checkout link. The client opens this URL in a WebView. Amount is
 * passed in major units (e.g. 10.00 GBP). Currency defaults to GBP
 * from coin_packages and is supported worldwide by Flutterwave.
 *
 * Response shape kept compatible with the previous Paystack flow:
 *   authorization_url, reference, payment_id, package_id, amount, currency
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

/**
 * Initialise a Flutterwave Standard payment (POST /v3/payments).
 * Returns the decoded response or null on failure.
 */
function initFlutterwavePayment(array $params, string $secretKey): ?array {
    $ch = curl_init("https://api.flutterwave.com/v3/payments");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode($params),
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_HTTPHEADER     => [
            "Authorization: Bearer " . $secretKey,
            "Content-Type: application/json",
            "Cache-Control: no-cache",
        ],
    ]);
    $response  = curl_exec($ch);
    $httpCode  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError !== "" || $response === false) {
        error_log("Flutterwave API cURL Error: " . $curlError);
        return null;
    }

    $decoded = json_decode($response, true);

    if ($httpCode < 200 || $httpCode >= 300 || !is_array($decoded) || ($decoded["status"] ?? "") !== "success") {
        error_log("Flutterwave API Error (HTTP {$httpCode}): " . $response);
        return null;
    }

    return $decoded;
}

$user      = getAuthenticatedUser();
$db        = getDatabaseConnection();
$data      = getJsonInput();

$packageId = (int)($data["package_id"] ?? 0);

if (!$packageId) {
    sendValidationError("Package ID is required.");
}

try {
    $stmt = $db->prepare("SELECT * FROM coin_packages WHERE id = ? AND is_active = TRUE");
    $stmt->execute([$packageId]);
    $package = $stmt->fetch();

    if (!$package) {
        sendError("Invalid or inactive coin package.", 404);
    }

    // Record a pending payment
    $stmt = $db->prepare("INSERT INTO payments (user_id, package_id, amount, currency, coins, status) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->execute([
        $user["id"],
        $package["id"],
        $package["price"],
        strtoupper($package["currency"] ?? "GBP"),
        $package["coins"],
        "pending"
    ]);
    $paymentId = (int)$db->lastInsertId();

    $packagePrice    = (float)$package["price"];
    $packageCurrency = strtoupper($package["currency"] ?? "GBP");

    // Unique merchant reference (must be unique per Flutterwave rules)
    $txRef = "mp_" . $paymentId . "_" . bin2hex(random_bytes(8));

    // Flutterwave Standard: amount in major units (not kobo/pence)
    $result = initFlutterwavePayment([
        "tx_ref"       => $txRef,
        "amount"       => number_format($packagePrice, 2, ".", ""),
        "currency"     => $packageCurrency,
        "redirect_url" => BASE_URL . "/api/payment/verify-payment.php?source=redirect",
        "customer"     => [
            "email" => $user["email"],
            "name"  => trim($user["full_name"] ?? "") ?: ($user["mystery_name"] ?? $user["email"]),
        ],
        "meta" => [
            "user_id"    => (string)$user["id"],
            "package_id" => (string)$package["id"],
            "coins"      => (string)$package["coins"],
            "payment_id" => (string)$paymentId,
        ],
        "customizations" => [
            "title"       => "MaskedParty Coins",
            "description" => $package["name"] . " — " . $package["coins"] . " coins",
        ],
        // Broad options; Flutterwave shows what is available for the currency
        "payment_options" => "card,banktransfer,ussd,mobilemoneyghana,mobilemoneyfranco,account,mpesa",
    ], FLUTTERWAVE_SECRET_KEY);

    if ($result === null || empty($result["data"]["link"])) {
        $stmt = $db->prepare("UPDATE payments SET status = 'failed' WHERE id = ?");
        $stmt->execute([$paymentId]);
        sendError("Failed to initialise payment. Please try again.", 502);
    }

    $checkoutLink = $result["data"]["link"];

    $stmt = $db->prepare("UPDATE payments SET payment_reference = ? WHERE id = ?");
    $stmt->execute([$txRef, $paymentId]);

    sendResponse(true, "Payment initialised.", [
        "authorization_url" => $checkoutLink,
        "access_code"       => null,
        "reference"         => $txRef,
        "payment_id"        => $paymentId,
        "package_id"        => $package["id"],
        "amount"            => $packagePrice,
        "currency"          => $packageCurrency,
    ]);

} catch (Exception $e) {
    error_log("Create Payment Error: " . $e->getMessage());
    sendError("Failed to initialise payment.");
}
