<?php
/**
 * POST /api/auth/forgot-password.php
 *
 * Sends a 6-digit OTP for password reset, by forwarding to the
 * exact same sendMail() call used by authentication/send-otp.php.
 * send-otp.php itself is untouched.
 *
 * Request body (JSON):
 * {
 *   "email": "user@example.com"
 * }
 *
 * Responses:
 *   200  { success: true, message: "..." }  — always, to prevent email enumeration
 *   400  { success: false, message: "..." } — validation
 */
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../mail/sendMail.php';

$data  = getJsonInput();
$email = trim(strtolower($data['email'] ?? ''));

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendValidationError('A valid email address is required.');
}

$db = getDatabaseConnection();

// Look up user
$stmt = $db->prepare("SELECT id, mystery_name FROM users WHERE email = ? LIMIT 1");
$stmt->execute([$email]);
$user = $stmt->fetch();

// Generic message either way — prevents email enumeration
$genericMessage = 'If an account with that email exists, a password reset code has been sent.';

if (!$user) {
    sendResponse(true, $genericMessage);
}

// Forward to the SAME sendMail() call send-otp.php already uses successfully.
// send-otp.php is not modified — this just reuses its proven working path.
$result = sendMail('email_verify', [
    'user_id' => (int) $user['id'],
    'email'   => $email,
    'name'    => $user['mystery_name'],
]);

if (!$result['success']) {
    error_log("Password reset OTP failed to send for {$email}: " . $result['message']);
}

sendResponse(true, $genericMessage);