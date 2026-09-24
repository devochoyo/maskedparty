<?php
/**
 * /admin/index.php is kept only as a stable redirect target — login.php
 * sends people here after signing in. The actual dashboard now lives in
 * dashboard.php, split out like every other section.
 */
require_once __DIR__ . '/_bootstrap.php';
header('Location: /admin/dashboard.php');
exit;
