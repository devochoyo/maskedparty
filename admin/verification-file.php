<?php
/**
 * Admin Verification File Proxy
 *
 * GET /admin/verification-file.php?influencer_id=123&field=selfie_url
 *
 * <img>/<video> tags in the browser can't send an Authorization header,
 * so they can't call api/admin/verification-file.php directly. This page
 * bridges that gap: it checks the admin's session (same as every other
 * admin/*.php page), then forwards the request to the real API with the
 * admin's Bearer token attached server-side — exactly like admin/proxy.php
 * does for JSON calls — and streams the binary response straight back.
 *
 * This is the ONLY way verification documents are ever served. The
 * uploads/verification/ folder itself is blocked at the web server level
 * (see uploads/verification/.htaccess).
 */

require_once __DIR__ . '/_bootstrap.php';

if (!admin_is_logged_in()) {
    http_response_code(401);
    exit;
}

$influencerId = (int) ($_GET['influencer_id'] ?? 0);
$field        = $_GET['field'] ?? '';

$allowedFields = ['government_id_url', 'selfie_url', 'verification_video_url'];

if (!$influencerId || !in_array($field, $allowedFields, true)) {
    http_response_code(400);
    exit;
}

$scheme    = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$targetUrl = admin_api_origin() . '/api/admin/verification-file.php'
    . '?influencer_id=' . urlencode($influencerId)
    . '&field=' . urlencode($field);

$ch = curl_init($targetUrl);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER     => ['Authorization: Bearer ' . $_SESSION['admin_token']],
    CURLOPT_TIMEOUT        => 25,
    CURLOPT_HEADER         => true,
]);

$raw       = curl_exec($ch);
$curlErrno = curl_errno($ch);
$httpCode  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$headerLen = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
curl_close($ch);

if ($curlErrno) {
    http_response_code(502);
    exit;
}

if ($httpCode === 401) {
    // Admin token expired/invalid — clear session so the panel bounces
    // to login on the next full page load instead of showing broken media.
    $_SESSION = [];
    session_destroy();
    http_response_code(401);
    exit;
}

if ($httpCode !== 200) {
    http_response_code($httpCode);
    exit;
}

$rawHeaders = substr($raw, 0, $headerLen);
$body       = substr($raw, $headerLen);

// Forward only the headers the browser actually needs to render the file.
foreach (explode("\r\n", $rawHeaders) as $line) {
    if (preg_match('#^(Content-Type|Content-Length|Content-Disposition|Cache-Control):#i', $line)) {
        header($line);
    }
}

echo $body;
