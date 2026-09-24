<?php
/**
 * mailFunctions.php — OTP generation, persistence, validation and dispatch
 *                      for email-address verification and password reset.
 *
 * Called exclusively by sendMail.php — pages should never include this directly.
 */

require_once __DIR__ . '/mail.php';
require_once __DIR__ . '/mailTemplate.php';

// How long (minutes) before an OTP expires
define('OTP_TTL_MINUTES', 6);

// Resend cool-down in seconds (prevents spam)
define('OTP_RESEND_COOLDOWN_SECONDS', 60);

// Maximum wrong-attempt limit before a code is locked
define('OTP_MAX_ATTEMPTS', 5);

/**
 * Generates a cryptographically secure 6-digit code (zero-padded).
 */
function generateSixDigitCode(): string
{
    return str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
}

/**
 * Issues a fresh OTP for a user/type combination.
 *
 * Steps:
 *  1. Enforce resend cooldown.
 *  2. Invalidate all previous unused codes of this type.
 *  3. Insert a new code with an expiry timestamp.
 *
 * @return string|null  The new 6-digit code, or NULL when still in cooldown.
 */
function issueVerificationCode(PDO $pdo, int $userId, string $type): ?string
{
    // --- cooldown guard ---
    $stmt = $pdo->prepare(
        "SELECT created_at
           FROM email_verification_tokens
          WHERE user_id = ? AND type = ? AND used = 0
          ORDER BY created_at DESC
          LIMIT 1"
    );
    $stmt->execute([$userId, $type]);
    $lastCreated = $stmt->fetchColumn();

    if ($lastCreated && (time() - strtotime($lastCreated)) < OTP_RESEND_COOLDOWN_SECONDS) {
        return null; // still in cool-down
    }

    // --- invalidate old unused codes ---
    $pdo->prepare(
        "UPDATE email_verification_tokens
            SET used = 1
          WHERE user_id = ? AND type = ? AND used = 0"
    )->execute([$userId, $type]);

    // --- insert new code ---
    $code      = generateSixDigitCode();
    $expiresAt = date('Y-m-d H:i:s', strtotime('+' . OTP_TTL_MINUTES . ' minutes'));

    $pdo->prepare(
        "INSERT INTO email_verification_tokens (user_id, code, type, expires_at)
         VALUES (?, ?, ?, ?)"
    )->execute([$userId, $code, $type, $expiresAt]);

    return $code;
}

/**
 * Validates a submitted OTP.
 *
 * Returns one of:
 *   'ok'      — correct, marks it used + sets users.authenticated = 1
 *   'invalid' — wrong code (increments attempt counter)
 *   'expired' — code is past its expiry time
 *   'none'    — no active (unused) code exists for this user/type
 *   'locked'  — attempt limit reached
 *
 * NOTE: this helper sets users.authenticated = 1 on success, which is
 * correct for type='email_verify'. It is NOT used for type='password_reset'
 * — reset-password.php validates that OTP with its own inline query instead,
 * since a password reset must never toggle the authenticated flag.
 */
function validateVerificationCode(PDO $pdo, int $userId, string $type, string $submitted): string
{
    $stmt = $pdo->prepare(
        "SELECT id, code, expires_at, attempts
           FROM email_verification_tokens
          WHERE user_id = ? AND type = ? AND used = 0
          ORDER BY created_at DESC
          LIMIT 1"
    );
    $stmt->execute([$userId, $type]);
    $row = $stmt->fetch();

    if (!$row) return 'none';

    if ((int) $row['attempts'] >= OTP_MAX_ATTEMPTS) return 'locked';

    if (strtotime($row['expires_at']) < time()) return 'expired';

    if (!hash_equals($row['code'], $submitted)) {
        $pdo->prepare(
            "UPDATE email_verification_tokens SET attempts = attempts + 1 WHERE id = ?"
        )->execute([$row['id']]);
        return 'invalid';
    }

    // --- success: mark token used and authenticate the user ---
    $pdo->prepare(
        "UPDATE email_verification_tokens SET used = 1 WHERE id = ?"
    )->execute([$row['id']]);

    $pdo->prepare(
        "UPDATE users SET authenticated = 1 WHERE id = ?"
    )->execute([$userId]);

    return 'ok';
}

/**
 * Sends the email-verification OTP immediately after registration (or on resend).
 *
 * @param PDO    $pdo
 * @param int    $userId
 * @param string $email
 * @param string $name    Display name shown in the email
 */
function sendEmailVerification(PDO $pdo, int $userId, string $email, string $name): array
{
    $code = issueVerificationCode($pdo, $userId, 'email_verify');

    if ($code === null) {
        return [
            'success' => false,
            'message' => 'Please wait ' . OTP_RESEND_COOLDOWN_SECONDS . ' seconds before requesting another code.',
        ];
    }

    $mail = getMailer();
    try {
        $mail->addAddress($email, $name);
        $mail->Subject = 'Verify your email address';
        $mail->Body    = emailVerificationTemplate($name, $code, OTP_TTL_MINUTES);
        $mail->AltBody = "Your verification code is: {$code} (expires in " . OTP_TTL_MINUTES . " minutes)";
        $mail->send();

        return ['success' => true, 'message' => 'Verification code sent to ' . $email];

    } catch (\Exception $e) {
        mailDebugLog('SEND VERIFICATION FAILED — user_id=' . $userId . ': ' . $mail->ErrorInfo);
        return ['success' => false, 'message' => 'Could not send verification email. Please try again.'];
    }
}

/**
 * Sends the password-reset OTP, requested via auth/forgot-password.php.
 *
 * Uses type='password_reset' (distinct from 'email_verify') so
 * auth/reset-password.php's lookup (WHERE type = 'password_reset') actually
 * finds the code. Previously forgot-password.php called sendMail('email_verify', ...),
 * which stored the code under the wrong type and made every reset attempt
 * fail with "No active reset code found."
 *
 * @param PDO    $pdo
 * @param int    $userId
 * @param string $email
 * @param string $name    Display name shown in the email
 */
function sendPasswordReset(PDO $pdo, int $userId, string $email, string $name): array
{
    $code = issueVerificationCode($pdo, $userId, 'password_reset');

    if ($code === null) {
        return [
            'success' => false,
            'message' => 'Please wait ' . OTP_RESEND_COOLDOWN_SECONDS . ' seconds before requesting another code.',
        ];
    }

    $mail = getMailer();
    try {
        $mail->addAddress($email, $name);
        $mail->Subject = 'Reset your password';
        $mail->Body    = passwordResetTemplate($name, $code, OTP_TTL_MINUTES);
        $mail->AltBody = "Your password reset code is: {$code} (expires in " . OTP_TTL_MINUTES . " minutes)";
        $mail->send();

        return ['success' => true, 'message' => 'Password reset code sent to ' . $email];

    } catch (\Exception $e) {
        mailDebugLog('SEND PASSWORD RESET FAILED — user_id=' . $userId . ': ' . $mail->ErrorInfo);
        return ['success' => false, 'message' => 'Could not send reset email. Please try again.'];
    }
}