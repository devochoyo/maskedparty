<?php
/**
 * Influencer Verification Endpoint
 */

// Guard against a hung request holding the connection open indefinitely.
// The three verification files together are small (ID photo, selfie, a
// ~2-3 second clip), so this script should never legitimately need more
// than a couple of minutes even on a slow connection. If it does, something
// is wrong server-side — better to fail fast with a real error than leave
// the client stuck with no response for 10-20 minutes.
set_time_limit(90);
ini_set('max_execution_time', 90);

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$requestStart = microtime(true);

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();

// Diagnostic logging: this is the key addition. If a future stuck upload
// never produces a "started" line in config/error.log for the timestamp
// the app was stuck, that PROVES the request never reached this script at
// all (i.e. the problem is at the hosting/proxy/security layer, not here).
// If it DOES log "started" but never logs "finished", that proves PHP
// itself hung inside this script, and the elapsed times per file below
// pinpoint exactly which upload stalled.
appLogError(
    'VERIFY DEBUG',
    "verification.php started for user {$user['id']}, " .
    "content-length=" . ($_SERVER['CONTENT_LENGTH'] ?? 'unknown') .
    ", files=" . implode(',', array_keys($_FILES))
);

$uploadedFiles = [];
$errors = [];

// Handle Government ID (front) — stored as id_front
if (isset($_FILES['government_id'])) {
    $t0 = microtime(true);
    $uploadResult = uploadVerificationFile($_FILES['government_id'], $user['id'], 'id_front');
    appLogError('VERIFY DEBUG', "government_id processed in " . round(microtime(true) - $t0, 2) . "s, success=" . ($uploadResult['success'] ? 'yes' : 'no'));
    if ($uploadResult['success']) {
        $uploadedFiles['government_id'] = $uploadResult['path'];   // relative path → DB
        $uploadedFiles['government_id_url'] = $uploadResult['url']; // public URL → response
    } else {
        $errors['government_id'] = $uploadResult['message'];
    }
}

// Handle Selfie — stored as selfie
if (isset($_FILES['selfie'])) {
    $t0 = microtime(true);
    $uploadResult = uploadVerificationFile($_FILES['selfie'], $user['id'], 'selfie');
    appLogError('VERIFY DEBUG', "selfie processed in " . round(microtime(true) - $t0, 2) . "s, success=" . ($uploadResult['success'] ? 'yes' : 'no'));
    if ($uploadResult['success']) {
        $uploadedFiles['selfie'] = $uploadResult['path'];
        $uploadedFiles['selfie_url'] = $uploadResult['url'];
    } else {
        $errors['selfie'] = $uploadResult['message'];
    }
}

// Handle Verification Video — stored as video
if (isset($_FILES['verification_video'])) {
    $t0 = microtime(true);
    $uploadResult = uploadVerificationFile($_FILES['verification_video'], $user['id'], 'video');
    appLogError('VERIFY DEBUG', "verification_video processed in " . round(microtime(true) - $t0, 2) . "s, success=" . ($uploadResult['success'] ? 'yes' : 'no'));
    if ($uploadResult['success']) {
        $uploadedFiles['verification_video'] = $uploadResult['path'];
        $uploadedFiles['verification_video_url'] = $uploadResult['url'];
    } else {
        $errors['verification_video'] = $uploadResult['message'];
    }
}

if (!empty($errors)) {
    appLogError('VERIFY DEBUG', "verification.php upload errors: " . json_encode($errors));
    sendError('Failed to upload all verification documents.', 400, ['upload_errors' => $errors]);
}

if (
    empty($uploadedFiles['government_id']) ||
    empty($uploadedFiles['selfie']) ||
    empty($uploadedFiles['verification_video'])
) {
    appLogError('VERIFY DEBUG', "verification.php missing files: " . json_encode(array_diff(['government_id', 'selfie', 'verification_video'], array_keys($uploadedFiles))));
    sendValidationError('All verification documents (Government ID, Selfie, Verification Video) are required.');
}

try {
    // Store relative paths in DB; never store full URLs
    $stmt = $db->prepare("
        UPDATE influencer_profiles SET
            government_id_url = ?, selfie_url = ?, verification_video_url = ?, verification_status = 'pending'
        WHERE user_id = ?
    ");
    $stmt->execute([
        $uploadedFiles['government_id'],
        $uploadedFiles['selfie'],
        $uploadedFiles['verification_video'],
        $user['id']
    ]);

    $elapsed = round(microtime(true) - $requestStart, 2);
    error_log("Influencer {$user['id']} submitted verification documents.");
    appLogError('VERIFY DEBUG', "verification.php completed successfully in {$elapsed}s for user {$user['id']}");

    sendResponse(true, 'Verification documents submitted successfully. Your profile is now pending review.');

} catch (Exception $e) {
    appLogError('VERIFY DEBUG', "verification.php DB error: " . $e->getMessage());
    error_log("Influencer Verification Error: " . $e->getMessage());
    sendError('Failed to submit verification documents.');
}
