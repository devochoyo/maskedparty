<?php
/**
 * Upload Document Endpoint (chat/general documents)
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
    "upload/document.php started for user {$user['id']}, " .
    "content-length=" . ($_SERVER['CONTENT_LENGTH'] ?? 'unknown')
);

if (empty($_FILES["document"]) || $_FILES["document"]["error"] === UPLOAD_ERR_NO_FILE) {
    sendValidationError("No document file provided.");
}

if ($_FILES["document"]["error"] !== UPLOAD_ERR_OK) {
    sendValidationError("File upload failed with error code: " . $_FILES["document"]["error"]);
}

$uploadResult = uploadChatFile($_FILES["document"], "document");

$elapsed = round(microtime(true) - $requestStart, 2);
appLogError('UPLOAD DEBUG', "upload/document.php finished in {$elapsed}s, success=" . ($uploadResult["success"] ? 'yes' : 'no'));

if ($uploadResult["success"]) {
    sendResponse(true, "Document uploaded successfully.", ["url" => $uploadResult["url"]]);
} else {
    sendError($uploadResult["message"], 400);
}
