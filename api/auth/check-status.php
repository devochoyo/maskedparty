<?php
/**
 * POST /api/auth/check-status.php
 *
 * Returns whether a user's email has been verified.
 * The app calls this after login to decide whether to route to the
 * dashboard or to the email-verification screen.
 *
 * Request body (JSON):
 * {
 *   "email": "user@example.com"
 * }
 *
 * Responses:
 *   200  { success: true,  authenticated: true,  message: "User is authenticated."     }
 *   200  { success: true,  authenticated: false, message: "User is not authenticated." }
 *   400  invalid input
 *   404  user not found
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';

$data  = getJsonInput();
$email = trim(strtolower($data['email'] ?? ''));

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendValidationError('A valid email address is required.');
}

$db = getDatabaseConnection();

$stmt = $db->prepare("SELECT authenticated FROM users WHERE email = ? LIMIT 1");
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    sendError('User not found.', 404);
}

$isAuthenticated = (int) $user['authenticated'] === 1;

sendResponse(true, $isAuthenticated ? 'User is authenticated.' : 'User is not authenticated.', [
    'authenticated' => $isAuthenticated,
]);
