<?php
/**
 * api/auth/register.php
 *
 * Changes over the original (pre-OTP) version of this file:
 *   • Sets authenticated = 0 on every new user row.
 *   • After commit, auto-sends the email OTP via the mail system.
 *   • Returns "authenticated": false in the response so the app knows to
 *     route the user to the email-verification screen.
 *
 * Everything else (roles, referral codes, wallets, influencer_profiles)
 * is preserved exactly as in the original register.php.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/../../mail/sendMail.php';

$data = getJsonInput();
$role = $data['role'] ?? '';

if (!in_array($role, ['client', 'influencer'])) {
    sendValidationError('Invalid role specified.');
}

$errors         = [];
$email          = filter_var($data['email'] ?? '', FILTER_VALIDATE_EMAIL);
$password       = $data['password'] ?? '';
$confirmPassword = $data['confirm_password'] ?? '';
$mysteryName    = trim($data['mystery_name'] ?? '');
$countryName    = trim($data['country_name'] ?? '');
$countryCode    = trim($data['country_code'] ?? '');
$referralCodeInput = strtoupper(trim($data['referral_code'] ?? ''));

if (!$email)              $errors['email']            = 'Valid email is required.';
if (strlen($password) < 8) $errors['password']         = 'Password must be at least 8 characters.';
if ($password !== $confirmPassword) $errors['confirm_password'] = 'Passwords do not match.';
if (empty($mysteryName))  $errors['mystery_name']      = 'Mystery name is required.';
if (empty($countryName))  $errors['country_name']      = 'Country name is required.';

$fullName = $bankName = $accountNumber = $bankCodeType = $bankCodeValue = '';
$maskStatus = 'masked';
if ($role === 'influencer') {
    $fullName       = trim($data['full_name'] ?? '');
    $bankName       = trim($data['bank_name'] ?? '');
    $accountNumber  = trim($data['account_number'] ?? '');
    $bankCodeType   = trim($data['bank_code_type'] ?? '');
    $bankCodeValue  = trim($data['bank_code_value'] ?? '');
    $maskStatusInput = trim($data['mask_status'] ?? '');

    // Bank details are NOT collected at registration any more. They are
    // asked for (and saved) when the influencer makes a withdrawal request.
    // Older app versions may still send them; they are accepted but optional.
    if (empty($fullName))       $errors['full_name']       = 'Full name is required.';

    if (!in_array($maskStatusInput, ['masked', 'unmasked'])) {
        $errors['mask_status'] = 'Mask status is required. Choose either "masked" or "unmasked".';
    } else {
        $maskStatus = $maskStatusInput;
    }
}

if (!empty($errors)) {
    sendValidationError('Validation failed.', $errors);
}

$db = getDatabaseConnection();

// Stop automatic mass sign-ups: at most 10 registrations per IP per hour.
rl_enforce($db, 'register_ip', client_ip(), 10, 3600, 'Too many sign-up attempts from this network. Please try again later.');

$stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
$stmt->execute([$email]);
if ($stmt->fetch()) {
    sendValidationError('Email already exists.', ['email' => 'Email is already registered.']);
}

$referredBy = null;
if ($referralCodeInput !== '') {
    $stmt = $db->prepare("SELECT id FROM users WHERE referral_code = ? AND status != 'banned'");
    $stmt->execute([$referralCodeInput]);
    $referrer = $stmt->fetch();
    if (!$referrer) {
        sendValidationError('Validation failed.', ['referral_code' => 'Invalid referral code.']);
    }
    $referredBy = (int) $referrer['id'];
}

try {
    $db->beginTransaction();

    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

    $stmt = $db->prepare("
        INSERT INTO users
            (email, password, mystery_name, full_name, role, country_name, country_code,
             bank_name, account_number, bank_code_type, bank_code_value, status, authenticated)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    ");
    $stmt->execute([
        $email, $hashedPassword, $mysteryName, $fullName, $role,
        $countryName, $countryCode, $bankName, $accountNumber,
        $bankCodeType, $bankCodeValue,
        ($role === 'influencer' ? 'pending_verification' : 'active'),
    ]);
    $userId = $db->lastInsertId();

    $ownReferralCode = generateReferralCode($db);
    $db->prepare("UPDATE users SET referral_code = ?, referred_by = ? WHERE id = ?")
       ->execute([$ownReferralCode, $referredBy, $userId]);

    $db->prepare("INSERT INTO wallets (user_id, balance, total_purchased, total_spent, escrow_balance) VALUES (?, 0, 0, 0, 0)")
       ->execute([$userId]);

    if ($role === 'influencer') {
        $db->prepare("
            INSERT INTO influencer_profiles
                (user_id, profile_completed, verification_status, online_status,
                 average_rating, bad_rating_count, total_calls, total_earnings, price_per_minute,
                 mask_status)
            VALUES (?, 0, 'pending', 'offline', 5.00, 0, 0, 0.00, 1.00, ?)
        ")->execute([$userId, $maskStatus]);
    }

    $token = generateToken($userId);

    $db->commit();

} catch (Exception $e) {
    $db->rollBack();
    error_log('Registration Error: ' . $e->getMessage());
    sendError('Failed to register user.');
}

$mailResult = sendMail('email_verify', [
    'user_id' => $userId,
    'email'   => $email,
    'name'    => $mysteryName,
]);

sendResponse(true, 'Registration successful. Please check your email for a verification code.', [
    'user' => [
        'id'              => $userId,
        'email'           => $email,
        'mystery_name'    => $mysteryName,
        'role'            => $role,
        'status'          => ($role === 'influencer' ? 'pending_verification' : 'active'),
        'referral_code'   => $ownReferralCode,
        'referred_by'     => $referredBy,
        'authenticated'   => false,
        'mask_status'     => ($role === 'influencer' ? $maskStatus : null),
        'bank_code_type'  => ($role === 'influencer' ? $bankCodeType : null),
        'bank_code_value' => ($role === 'influencer' ? $bankCodeValue : null),
    ],
    'token'          => $token,
    'otp_sent'       => $mailResult['success'],
    'otp_message'    => $mailResult['message'],
], 201);