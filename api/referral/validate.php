<?php
/**
 * Referral - Validate Code Endpoint (Public)
 *
 * Lets the signup screen confirm a referral code exists (and show who
 * the new user would be referred by) BEFORE they submit registration.
 * Intentionally public / no auth — a person doesn't have an account yet
 * at this point.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';

$db = getDatabaseConnection();

$code = strtoupper(trim($_GET['code'] ?? ''));
if ($code === '') {
    sendValidationError('Validation failed.', ['code' => 'Referral code is required.']);
}

$stmt = $db->prepare("SELECT mystery_name, role FROM users WHERE referral_code = ? AND status != 'banned'");
$stmt->execute([$code]);
$referrer = $stmt->fetch();

if (!$referrer) {
    sendResponse(false, 'Invalid referral code.', ['valid' => false], 404);
}

sendResponse(true, 'Valid referral code.', [
    'valid'                 => true,
    'referrer_mystery_name' => $referrer['mystery_name'],
    'referrer_role'         => $referrer['role'],
]);
