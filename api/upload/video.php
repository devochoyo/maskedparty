<?php
/**
 * Upload Video Endpoint (chat/general videos)
 */

// Guard against a hung request holding the connection open indefinitely.
// Videos are larger, so this gets a bit more room than image/document.
set_time_limit(180);
ini_set('max_execution_time', 180);

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$requestStart = microtime(true);

$user = getAuthenticatedUser();

$db = getDatabaseConnection();

appLogError(
    'UPLOAD DEBUG',
    "upload/video.php started for user {$user['id']}, " .
    "content-length=" . ($_SERVER['CONTENT_LENGTH'] ?? 'unknown')
);

if (empty($_FILES["video"]) || $_FILES["video"]["error"] === UPLOAD_ERR_NO_FILE) {
    sendValidationError("No video file provided.");
}

if ($_FILES["video"]["error"] !== UPLOAD_ERR_OK) {
    sendValidationError("File upload failed with error code: " . $_FILES["video"]["error"]);
}

$uploadResult = uploadChatFile($_FILES["video"], "video");

$elapsed = round(microtime(true) - $requestStart, 2);
appLogError('UPLOAD DEBUG', "upload/video.php finished in {$elapsed}s, success=" . ($uploadResult["success"] ? 'yes' : 'no'));

if ($uploadResult["success"]) {
    sendResponse(true, "Video uploaded successfully.", ["url" => $uploadResult["url"]]);
} else {
    sendError($uploadResult["message"], 400);
}
