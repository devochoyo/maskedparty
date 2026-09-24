<?php
/**
 * Standard API Response Helper
 */

function sendResponse($success, $message, $data = null, $httpCode = 200) {
    header('Content-Type: application/json');
    http_response_code($httpCode);

    $response = [
        'success' => $success,
        'message' => $message
    ];

    if ($data !== null) {
        $response['data'] = $data;
    }

    echo json_encode($response);
    exit;
}

function sendValidationError($message, $errors = []) {
    header('Content-Type: application/json');
    http_response_code(422);

    echo json_encode([
        'success' => false,
        'message' => $message,
        'errors' => $errors
    ]);
    exit;
}

function sendError($message, $httpCode = 500) {
    sendResponse(false, $message, null, $httpCode);
}
