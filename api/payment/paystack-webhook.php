<?php
/**
 * DEPRECATED — replaced by flutterwave-webhook.php
 * Keep temporarily if Paystack webhook is still registered; remove after cutover.
 */
http_response_code(410);
echo json_encode(["error" => "This endpoint is deprecated. Use /api/payment/flutterwave-webhook.php"]);
