<?php
/**
 * POST /api/support/login.php
 *
 * Support agent login. Support agents are created by admin
 * (see admin/support.php action=add) — there is no self-registration.
 *
 * Request body (JSON):
 * {
 *   "email": "agent@example.com",
 *   "password": "SUPAB3XZ"
 * }
 *
 * Responses:
 *   200 { success: true, message: "Login successful.", data: { agent: {...}, token: "..." } }
 *   401 { success: false, message: "Invalid credentials." }
 *   403 { success: false, message: "Your support account has been suspended." }
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$data = getJsonInput();
$email = trim(strtolower($data['email'] ?? ''));
$password = $data['password'] ?? '';

if (empty($email) || empty($password)) {
    sendValidationError('Email and password are required.');
}

$db = getDatabaseConnection();

$stmt = $db->prepare("SELECT * FROM support_agents WHERE email = ? LIMIT 1");
$stmt->execute([$email]);
$agent = $stmt->fetch();

// Always run password_verify, even with a dummy hash when no agent is
// found, so response timing does not reveal whether an email is registered.
$storedHash = $agent['password_hash'] ?? '$2y$10$usedOnlyToEqualizeTimingXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
$passwordOk = password_verify($password, $storedHash);

if (!$agent || !$passwordOk) {
    sendError('Invalid credentials.', 401);
}

if ($agent['status'] === 'suspended') {
    sendError('Your support account has been suspended.', 403);
}

$token = generateSupportToken($agent['id']);

sendResponse(true, 'Login successful.', [
    'agent' => [
        'id'         => (int) $agent['id'],
        'first_name' => $agent['first_name'],
        'last_name'  => $agent['last_name'],
        'email'      => $agent['email'],
        'status'     => $agent['status'],
    ],
    'token' => $token,
]);
