<?php
/**
 * Create Post Endpoint
 * POST /post/create.php
 * Authenticated influencer only.
 * Body (JSON): caption (required), body (optional)
 * Multipart alternative: also accepts image[] files.
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();

// Support both JSON and multipart
$caption = '';
$body    = null;

if (!empty($_POST)) {
    $caption = trim($_POST['caption'] ?? '');
    $body    = isset($_POST['body']) ? trim($_POST['body']) : null;
} else {
    $data    = getJsonInput();
    $caption = trim($data['caption'] ?? '');
    $body    = isset($data['body']) ? trim($data['body']) : null;
}

if ($caption === '') {
    sendValidationError('caption is required.');
}

if (mb_strlen($caption) > 255) {
    sendValidationError('caption must be 255 characters or less.');
}

if ($body !== null && $body === '') {
    $body = null;
}

try {
    $db->beginTransaction();

    $stmt = $db->prepare("
        INSERT INTO posts (influencer_id, caption, body)
        VALUES (?, ?, ?)
    ");
    $stmt->execute([$user['id'], $caption, $body]);
    $postId = (int)$db->lastInsertId();

    $uploadedImages = [];

    // Handle multiple image uploads (field name: images[] or image)
    $files = [];
    if (!empty($_FILES['images'])) {
        // Normalize multi-file structure
        if (is_array($_FILES['images']['name'])) {
            $count = count($_FILES['images']['name']);
            for ($i = 0; $i < $count; $i++) {
                if ($_FILES['images']['error'][$i] === UPLOAD_ERR_NO_FILE) continue;
                $files[] = [
                    'name'     => $_FILES['images']['name'][$i],
                    'type'     => $_FILES['images']['type'][$i],
                    'tmp_name' => $_FILES['images']['tmp_name'][$i],
                    'error'    => $_FILES['images']['error'][$i],
                    'size'     => $_FILES['images']['size'][$i],
                ];
            }
        } else {
            $files[] = $_FILES['images'];
        }
    } elseif (!empty($_FILES['image'])) {
        $files[] = $_FILES['image'];
    }

    $order = 0;
    foreach ($files as $file) {
        if ($file['error'] === UPLOAD_ERR_NO_FILE) continue;

        $uploadResult = uploadGalleryFile($file, $user['id']);
        if (!$uploadResult['success']) {
            $db->rollBack();
            sendError($uploadResult['message'], 400);
        }

        $stmt = $db->prepare("
            INSERT INTO post_images (post_id, image_url, display_order)
            VALUES (?, ?, ?)
        ");
        $stmt->execute([$postId, $uploadResult['path'], $order]);
        $uploadedImages[] = [
            'id'  => (int)$db->lastInsertId(),
            'url' => $uploadResult['url'],
        ];
        $order++;
    }

    $db->commit();

    sendResponse(true, 'Post created successfully.', [
        'post' => [
            'id'            => $postId,
            'influencer_id' => (int)$user['id'],
            'caption'       => $caption,
            'body'          => $body,
            'images'        => $uploadedImages,
            'created_at'    => date('Y-m-d H:i:s'),
        ],
    ]);

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    error_log('Create Post Error: ' . $e->getMessage());
    sendError('Failed to create post.');
}
