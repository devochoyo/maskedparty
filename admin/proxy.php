<?php
/**
 * Admin API Proxy
 *
 * The frontend JS never sees the Bearer token. It calls this proxy with a
 * whitelisted relative path (e.g. path=admin/users.php), and this file
 * forwards the request to /api/{path} with the admin's token attached
 * server-side, then streams the JSON response straight back.
 *
 * Only paths under api/admin/ are allowed — this proxy is not a general
 * API gateway.
 */

require_once __DIR__ . '/_bootstrap.php';

header('Content-Type: application/json');

if (!admin_is_logged_in()) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Not signed in.']);
    exit;
}

$path = $_GET['path'] ?? '';

// Whitelist: only relative paths starting with admin/, ending in .php,
// no traversal.
if (!preg_match('#^admin/[a-z0-9\-]+\.php$#i', $path)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid proxy path.']);
    exit;
}

$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$targetUrl = admin_api_origin() . '/api/' . $path;

// Forward the original query string (minus our own "path" param) so
// ?action=list&page=2 etc. reach the real endpoint untouched.
$query = $_GET;
unset($query['path']);
if ($query) {
    $targetUrl .= '?' . http_build_query($query);
}

$method = $_SERVER['REQUEST_METHOD'];
$body = ($method !== 'GET') ? file_get_contents('php://input') : null;

$ch = curl_init($targetUrl);
$headers = [
    'Authorization: Bearer ' . $_SESSION['admin_token'],
    'Content-Type: application/json',
];

curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CUSTOMREQUEST => $method,
    CURLOPT_HTTPHEADER => $headers,
    CURLOPT_TIMEOUT => 25,
]);
if ($body !== null) {
    curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
}

$response = curl_exec($ch);
$curlErrno = curl_errno($ch);
$curlErr = curl_error($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($curlErrno) {
    http_response_code(502);
    echo json_encode(['success' => false, 'message' => 'Could not reach the API: ' . $curlErr]);
    exit;
}

// If the token was rejected (expired/invalid), clear the session so the
// next page load bounces to login instead of looping on 401s.
if ($httpCode === 401) {
    $_SESSION = [];
    session_destroy();
}

http_response_code($httpCode ?: 500);
echo $response;
