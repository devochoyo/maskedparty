<?php
require_once __DIR__ . '/_bootstrap.php';

// Best-effort: tell the API to invalidate the token server-side too,
// so it can't be reused if it ever leaked.
if (admin_is_logged_in()) {
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $url = $scheme . '://' . $_SERVER['HTTP_HOST'] . '/api/auth/logout.php';

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . $_SESSION['admin_token']],
        CURLOPT_TIMEOUT => 8,
    ]);
    curl_exec($ch);
    curl_close($ch);
}

$_SESSION = [];
session_destroy();
header('Location: /admin/login.php');
exit;
