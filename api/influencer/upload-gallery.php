<?php
/**
 * Upload Influencer Gallery Images/Videos Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();

$uploadedUrls = [];
$errors = [];

// Define max images per influencer
define('MAX_GALLERY_IMAGES', 10);

// Check current number of images in gallery
$stmt = $db->prepare("SELECT COUNT(*) FROM influencer_gallery WHERE influencer_id = ?");
$stmt->execute([$user['id']]);
$currentImageCount = $stmt->fetchColumn();

if (isset($_FILES['gallery_images'])) {
    $files = $_FILES['gallery_images'];

    // Ensure $files['name'] is an array for multiple uploads
    if (!is_array($files['name'])) {
        $files = [
            'name'     => [$files['name']],
            'type'     => [$files['type']],
            'tmp_name' => [$files['tmp_name']],
            'error'    => [$files['error']],
            'size'     => [$files['size']],
        ];
    }

    foreach ($files['name'] as $index => $name) {
        if ($currentImageCount >= MAX_GALLERY_IMAGES) {
            $errors[] = 'Maximum gallery image limit reached (' . MAX_GALLERY_IMAGES . '). No more images can be uploaded.';
            break; // Stop processing further uploads
        }

        $file = [
            'name'     => $name,
            'type'     => $files['type'][$index],
            'tmp_name' => $files['tmp_name'][$index],
            'error'    => $files['error'][$index],
            'size'     => $files['size'][$index],
        ];

        // Use dedicated gallery uploader — stores in uploads/gallery/user_<id>/
        $uploadResult = uploadGalleryFile($file, $user['id']);

        if ($uploadResult['success']) {
            $uploadedUrls[] = $uploadResult['url'];

            // Save relative path to database
            $stmt = $db->prepare("INSERT INTO influencer_gallery (influencer_id, image_url) VALUES (?, ?)");
            $stmt->execute([$user['id'], $uploadResult['path']]);
            $currentImageCount++;
        } else {
            $errors[] = 'Failed to upload ' . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . ': ' . $uploadResult['message'];
        }
    }
}

if (!empty($errors)) {
    sendError('Some files failed to upload.', 400, ['upload_errors' => $errors, 'uploaded_urls' => $uploadedUrls]);
} elseif (empty($uploadedUrls)) {
    sendValidationError('No files were uploaded.');
} else {
    sendResponse(true, 'Gallery files uploaded successfully.', ['uploaded_urls' => $uploadedUrls]);
}
