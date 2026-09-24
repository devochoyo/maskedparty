<?php
/**
 * sendMail.php — single entry-point for all outbound email.
 *
 * Authentication endpoints include this file and call sendMail().
 * It is the ONLY mail file they should include directly.
 *
 * Usage:
 *   require_once __DIR__ . '/../../mail/sendMail.php';
 *
 *   $result = sendMail('email_verify', [
 *       'user_id' => $userId,
 *       'email'   => $email,
 *       'name'    => $displayName,   // mystery_name or full_name
 *   ]);
 *   // $result = ['success' => bool, 'message' => string]
 */

require_once __DIR__ . '/mailFunctions.php';

function sendMail(string $type, array $data): array
{
    global $pdo;          // set by getDatabaseConnection() callers (or pass explicitly below)

    // Prefer the global $pdo; fall back to getting a connection so this works
    // even when the caller used getDatabaseConnection() without setting $pdo.
    if (!($pdo instanceof PDO)) {
        if (function_exists('getDatabaseConnection')) {
            $pdo = getDatabaseConnection();
        }
    }

    if (!($pdo instanceof PDO)) {
        return ['success' => false, 'message' => 'Database connection unavailable.'];
    }

    if (empty($data['user_id']) || empty($data['email']) || empty($data['name'])) {
        return ['success' => false, 'message' => 'Missing required fields: user_id, email, name.'];
    }

    $userId = (int)    $data['user_id'];
    $email  = (string) $data['email'];
    $name   = (string) $data['name'];

    switch ($type) {
        case 'email_verify':
            return sendEmailVerification($pdo, $userId, $email, $name);

        default:
            error_log('[' . date('Y-m-d H:i:s') . '] sendMail() — unknown type: ' . $type);
            return ['success' => false, 'message' => 'Unknown mail type.'];
    }
}
