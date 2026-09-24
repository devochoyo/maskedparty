<?php
/**
 * POST /api/auth/reset-password.php
 *
 * Verifies the 6-digit OTP (from email_verification_tokens,
 * type='password_reset') and sets the new password.
 * Attempt-lockout / expiry mirror verify-otp.php's behavior.
 */
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$data = getJsonInput();
$email = trim(strtolower($data["email"] ?? ""));
$otp = trim($data["otp"] ?? "");
$newPassword = $data["new_password"] ?? "";
$confirmPassword = $data["confirm_password"] ?? "";

$errors = [];
if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors["email"] = "A valid email address is required.";
}
if (!preg_match('/^\d{6}$/', $otp)) {
    $errors["otp"] = "A valid 6-digit code is required.";
}
if (strlen($newPassword) < 8) {
    $errors["new_password"] = "New password must be at least 8 characters.";
}
if ($newPassword !== $confirmPassword) {
    $errors["confirm_password"] = "Passwords do not match.";
}
if (!empty($errors)) {
    sendValidationError("Validation failed.", $errors);
}

$db = getDatabaseConnection();

$stmt = $db->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    sendError("Invalid or expired reset code.", 400);
}
$userId = (int) $user["id"];

$stmt = $db->prepare(
    "SELECT id, code, attempts, expires_at, used FROM email_verification_tokens
     WHERE user_id = ? AND type = 'password_reset'
     ORDER BY created_at DESC LIMIT 1"
);
$stmt->execute([$userId]);
$reset = $stmt->fetch();

if (!$reset || (int) $reset["used"] === 1) {
    sendError("No active reset code found. Please request a new one.", 400);
}
if (strtotime($reset["expires_at"]) < time()) {
    sendError("Reset code has expired. Please request a new one.", 400);
}
if ((int) $reset["attempts"] >= 5) {
    sendError("Too many incorrect attempts. Please request a new code.", 400);
}
if (!hash_equals($reset["code"], $otp)) {
    $stmt = $db->prepare("UPDATE email_verification_tokens SET attempts = attempts + 1 WHERE id = ?");
    $stmt->execute([$reset["id"]]);
    sendError("Invalid reset code.", 400);
}

try {
    $db->beginTransaction();

    $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
    $stmt = $db->prepare("UPDATE users SET password = ? WHERE id = ?");
    $stmt->execute([$hashedPassword, $userId]);

    // Mark the OTP as used
    $stmt = $db->prepare("UPDATE email_verification_tokens SET used = 1 WHERE id = ?");
    $stmt->execute([$reset["id"]]);

    // Invalidate all existing login sessions/tokens for this user
    $stmt = $db->prepare("DELETE FROM user_tokens WHERE user_id = ?");
    $stmt->execute([$userId]);

    $db->commit();
    sendResponse(true, "Password has been reset successfully.");
} catch (Exception $e) {
    $db->rollBack();
    error_log("Reset Password Error: " . $e->getMessage());
    sendError("Failed to reset password.");
}