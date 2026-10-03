<?php
/**
 * User Login Endpoint
 *
 * NOTE: This endpoint has no built-in rate limiting / brute-force
 * protection. Consider adding throttling (e.g. by IP or email) at the
 * web server, gateway, or a shared middleware layer.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$data = getJsonInput();
$email = $data['email'] ?? '';
$password = $data['password'] ?? '';

if (empty($email) || empty($password)) {
    sendValidationError('Email and password are required.');
}

$db = getDatabaseConnection();

// Brute-force protection: after 8 wrong passwords for one email (from one IP),
// or 40 from one IP, wait 15 minutes.
$loginIp    = client_ip();
$loginEmail = strtolower(trim((string)$email));
rl_guard($db, 'login_email', $loginIp . '|' . $loginEmail, 8, 900, 'Too many failed login attempts. Please try again in 15 minutes.');
rl_guard($db, 'login_ip', $loginIp, 40, 900, 'Too many failed login attempts. Please try again in 15 minutes.');

$stmt = $db->prepare("
    SELECT u.*, w.balance as wallet_balance, ip.profile_completed
    FROM users u
    JOIN wallets w ON u.id = w.user_id
    LEFT JOIN influencer_profiles ip ON u.id = ip.user_id
    WHERE u.email = ?
    LIMIT 1
");
$stmt->execute([$email]);
$user = $stmt->fetch();

// Always run password_verify, even with a dummy hash when no user is found,
// so response timing does not reveal whether an email is registered.
$storedHash = $user['password'] ?? '$2y$10$usedOnlyToEqualizeTimingXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
$passwordOk = password_verify($password, $storedHash);

if (!$user || !$passwordOk) {
    rl_hit($db, 'login_email', $loginIp . '|' . $loginEmail, 900);
    rl_hit($db, 'login_ip', $loginIp, 900);
    sendError('Invalid credentials.', 401);
}

rl_clear($db, 'login_email', $loginIp . '|' . $loginEmail);

if ($user['status'] === 'banned') {
    sendError('Your account has been banned.', 403);
}

$token = generateToken($user['id']);

// User Status Automation: Login → ONLINE (for influencers)
if ($user['role'] === 'influencer') {
    $stmt = $db->prepare("UPDATE influencer_profiles SET online_status = 'online', last_seen = NOW() WHERE user_id = ?");
    $stmt->execute([$user['id']]);
}

sendResponse(true, 'Login successful.', [
    'user' => [
        'id'           => $user['id'],
        'email'        => $user['email'],
        'mystery_name' => $user['mystery_name'],
        'role'         => $user['role'],
        'status'       => $user['status'],
    ],
    'token'              => $token,
    'wallet_balance'     => (float)$user['wallet_balance'],
    'role'               => $user['role'],
    // Only meaningful for influencers — clients/admins have no
    // influencer_profiles row, so default to true (no redirect needed).
    'profile_completed'  => ($user['role'] === 'influencer') ? (bool)$user['profile_completed'] : true,
]);