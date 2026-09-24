<?php
/**
 * POST /api/auth/verify-otp.php
 *
 * Validates the 6-digit OTP entered by the user.
 * On success → sets users.authenticated = 1.
 *
 * Request body (JSON):
 * {
 *   "email": "user@example.com",
 *   "code":  "847291"
 * }
 *
 * Responses:
 *   200  success  { success: true,  message: "Email verified.",       authenticated: true  }
 *   200  fail     { success: false, message: "<reason>",              authenticated: false }
 *   400  invalid input
 *   404  user not found
 *
 * Reason strings for authenticated: false (handle in app):
 *   "Invalid verification code."
 *   "Verification code has expired. Please request a new one."
 *   "No active verification code found. Please request a new one."
 *   "Too many incorrect attempts. Please request a new code."
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../mail/mailFunctions.php';

$data  = getJsonInput();
$email = trim(strtolower($data['email'] ?? ''));
$code  = trim($data['code'] ?? '');

// ── Validation ────────────────────────────────────────────────────────────────
$errors = [];
if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors['email'] = 'A valid email address is required.';
}
if (empty($code) || !preg_match('/^\d{6}$/', $code)) {
    $errors['code'] = 'A 6-digit verification code is required.';
}
if ($errors) {
    sendValidationError('Validation failed.', $errors);
}

$db = getDatabaseConnection();

// ── Look up user ──────────────────────────────────────────────────────────────
$stmt = $db->prepare("SELECT id, authenticated FROM users WHERE email = ? LIMIT 1");
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    sendError('User not found.', 404);
}

// Already verified?
if ((int) $user['authenticated'] === 1) {
    sendResponse(true, 'Email is already verified.', ['authenticated' => true]);
}

// ── Validate the OTP ──────────────────────────────────────────────────────────
$result = validateVerificationCode($db, (int) $user['id'], 'email_verify', $code);

switch ($result) {
    case 'ok':
        sendResponse(true, 'Email verified successfully. You can now log in.', [
            'authenticated' => true,
        ]);
        break;

    case 'invalid':
        sendResponse(false, 'Invalid verification code.', [
            'authenticated' => false,
        ]);
        break;

    case 'expired':
        sendResponse(false, 'Verification code has expired. Please request a new one.', [
            'authenticated' => false,
        ]);
        break;

    case 'locked':
        sendResponse(false, 'Too many incorrect attempts. Please request a new code.', [
            'authenticated' => false,
        ]);
        break;

    case 'none':
    default:
        sendResponse(false, 'No active verification code found. Please request a new one.', [
            'authenticated' => false,
        ]);
        break;
}
