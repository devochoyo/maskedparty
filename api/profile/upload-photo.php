<?php
/**
 * Upload Profile Photo Endpoint
 *
 * FIX (2026-08-24): Previously there was no endpoint calling the existing
 * uploadProfilePhoto() helper in config/functions.php, so the mobile app
 * uploaded avatars through the generic chat endpoints (api/upload/image.php
 * or api/upload/document.php), which store files under uploads/chat/... or
 * uploads/chat/documents/... instead of uploads/profiles/.
 *
 * This endpoint uploads the file to the correct uploads/profiles/ folder
 * AND persists the resulting relative path to users.profile_photo in one
 * call, mirroring the pattern already used by api/influencer/verification.php.
 *
 * Multipart field name: "photo"
 */

// Guard against a hung request holding the connection open indefinitely.
// If something on the server side stalls, fail fast with a real error
// instead of leaving the client stuck with no response.
set_time_limit(60);
ini_set('max_execution_time', 60);

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$requestStart = microtime(true);

$user = getAuthenticatedUser();
$db = getDatabaseConnection();

appLogError(
    'UPLOAD DEBUG',
    "profile/upload-photo.php started for user {$user['id']}, " .
    "content-length=" . ($_SERVER['CONTENT_LENGTH'] ?? 'unknown')
);

if (empty($_FILES["photo"]) || $_FILES["photo"]["error"] === UPLOAD_ERR_NO_FILE) {
    sendValidationError("No photo file provided.");
}

if ($_FILES["photo"]["error"] !== UPLOAD_ERR_OK) {
    sendValidationError("File upload failed with error code: " . $_FILES["photo"]["error"]);
}

$uploadResult = uploadProfilePhoto($_FILES["photo"]);

if (!$uploadResult["success"]) {
    appLogError('UPLOAD DEBUG', "profile/upload-photo.php failed: " . $uploadResult["message"]);
    sendError($uploadResult["message"], 400);
}

try {
    $stmt = $db->prepare("UPDATE users SET profile_photo = ? WHERE id = ?");
    $stmt->execute([$uploadResult["path"], $user["id"]]);
} catch (Exception $e) {
    appLogError('UPLOAD DEBUG', "profile/upload-photo.php DB update failed: " . $e->getMessage());
    sendError("Photo uploaded but failed to save to your profile. Please try again.", 500);
}

$elapsed = round(microtime(true) - $requestStart, 2);
appLogError('UPLOAD DEBUG', "profile/upload-photo.php completed in {$elapsed}s for user {$user['id']}");

sendResponse(true, "Profile photo updated successfully.", [
    "url"  => $uploadResult["url"],
    "path" => $uploadResult["path"],
]);
