<?php
/**
 * Upload Image Endpoint (chat/general images)
 */

// Guard against a hung request holding the connection open indefinitely.
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
    "upload/image.php started for user {$user['id']}, " .
    "content-length=" . ($_SERVER['CONTENT_LENGTH'] ?? 'unknown')
);

if (empty($_FILES["image"]) || $_FILES["image"]["error"] === UPLOAD_ERR_NO_FILE) {
    sendValidationError("No image file provided.");
}

if ($_FILES["image"]["error"] !== UPLOAD_ERR_OK) {
    sendValidationError("File upload failed with error code: " . $_FILES["image"]["error"]);
}

$uploadResult = uploadChatFile($_FILES["image"], "image");

$elapsed = round(microtime(true) - $requestStart, 2);
appLogError('UPLOAD DEBUG', "upload/image.php finished in {$elapsed}s, success=" . ($uploadResult["success"] ? 'yes' : 'no'));

if ($uploadResult["success"]) {
    sendResponse(true, "Image uploaded successfully.", ["url" => $uploadResult["url"]]);
} else {
    sendError($uploadResult["message"], 400);
}
