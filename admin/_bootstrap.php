<?php
/**
 * Admin Panel Bootstrap
 *
 * This admin panel is a thin, server-rendered client for the existing
 * JSON API in /api/admin/*. It does not touch the database directly —
 * every action goes through the same endpoints the mobile app uses, so
 * business logic (escrow math, notifications, validation) lives in one
 * place only: the API.
 *
 * Auth model: the API is Bearer-token only (no cookies/sessions). This
 * panel logs in against /api/auth/login.php on the admin's behalf, then
 * keeps the resulting token server-side in $_SESSION — never sent to the
 * browser as JS-readable storage — and attaches it to every API call
 * made from admin/proxy.php.
 */

session_start();

// Adjust this if the admin/ folder is not placed directly next to api/
// at the project root (e.g. https://yourdomain.com/admin/ + https://yourdomain.com/api/).
define('API_BASE', dirname(__DIR__) . '/api');

// Same value as config/config.php's BASE_URL — used only to build links
// back to uploaded media (verification docs, gallery images, etc.)
define('ADMIN_PANEL_TITLE', 'Masked Party — Admin');

function admin_is_logged_in() {
    return !empty($_SESSION['admin_token']) && !empty($_SESSION['admin_user']);
}

function admin_require_login() {
    if (!admin_is_logged_in()) {
        header('Location: /admin/login.php');
        exit;
    }
}

function admin_current_user() {
    return $_SESSION['admin_user'] ?? null;
}
