<?php
/**
 * POST /api/auth/send-otp.php
 *
 * Sends (or resends) the 6-digit email verification OTP.
 *
 * Called automatically by register.php after a successful registration,
 * OR by the app whenever the user requests a resend.
 *
 * Request body (JSON):
 * {
 *   "email": "user@example.com"
 * }
 *
 * Responses:
 *   200  { success: true,  message: "Verification code sent to ..." }
 *   400  { success: false, message: "..." }          — validation / cooldown
 *   404  { success: false, message: "User not found." }
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
$stmt = $db->prepare("SELECT id, mystery_name, authenticated FROM users WHERE email = ? LIMIT 1");
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    sendError('User not found.', 404);
}

// If already verified, no need to re-send
if ((int) $user['authenticated'] === 1) {
    sendResponse(true, 'Email address is already verified.', ['authenticated' => true]);
}

// Send (or resend) the OTP
$result = sendMail('email_verify', [
    'user_id' => (int) $user['id'],
    'email'   => $email,
    'name'    => $user['mystery_name'],
]);

if (!$result['success']) {
    sendError($result['message'], 400);
}

sendResponse(true, $result['message'], [
    'authenticated' => false,
    'email'         => $email,
]);
