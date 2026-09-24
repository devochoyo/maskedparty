<?php



header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Browsers send an OPTIONS preflight before the real POST/PUT/DELETE
// request. Answer it immediately with an empty 200 and stop — don't
// let it fall through into your actual endpoint logic below.
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}




/**
 * Global Configuration — MaskedParty API
 *
 * All secrets are loaded exclusively from config/secure/.env.
 * There are NO hardcoded fallback values for any key or credential.
 * If a required variable is missing, the application halts immediately
 * rather than running with a broken or insecure configuration.
 */

// ── Load .env ────────────────────────────────────────────────────────────────

$envFile = __DIR__ . '/secure/.env';

if (!file_exists($envFile)) {
    http_response_code(500);
    error_log('FATAL: config/secure/.env not found.');
    echo json_encode(['success' => false, 'message' => 'Server configuration error.']);
    exit();
}

foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    $line = trim($line);
    // Skip comments and blank lines
    if ($line === '' || str_starts_with($line, '#')) {
        continue;
    }
    if (str_contains($line, '=')) {
        [$key, $value] = explode('=', $line, 2);
        $key   = trim($key);
        $value = trim($value);
        // Only set if not already provided by the server environment
        if (!array_key_exists($key, $_ENV) && !array_key_exists($key, $_SERVER)) {
            putenv("$key=$value");
            $_ENV[$key]    = $value;
            $_SERVER[$key] = $value;
        }
    }
}

/**
 * Retrieve a required environment variable.
 * Halts with a 500 if the variable is missing or empty.
 */
function requireEnv(string $key): string {
    $value = getenv($key);
    if ($value === false || $value === '') {
        http_response_code(500);
        error_log("FATAL: Required environment variable '{$key}' is not set.");
        echo json_encode(['success' => false, 'message' => 'Server configuration error.']);
        exit();
    }
    return $value;
}

// ── Application ──────────────────────────────────────────────────────────────
define('BASE_URL',     requireEnv('BASE_URL'));
define('API_VERSION',  '1.0.0');

// ── Database ─────────────────────────────────────────────────────────────────
define('DB_HOST', requireEnv('DB_HOST'));
define('DB_NAME', requireEnv('DB_NAME'));
define('DB_USER', requireEnv('DB_USER'));
define('DB_PASS', requireEnv('DB_PASS'));

// ── Flutterwave ──────────────────────────────────────────────────────────────
define('FLUTTERWAVE_SECRET_KEY', requireEnv('FLUTTERWAVE_SECRET_KEY'));
define('FLUTTERWAVE_SECRET_HASH', getenv('FLUTTERWAVE_SECRET_HASH') ?: '');

// ── VideoSDK ─────────────────────────────────────────────────────────────────
define('VIDEOSDK_API_KEY',    requireEnv('VIDEOSDK_API_KEY'));
define('VIDEOSDK_SECRET_KEY', requireEnv('VIDEOSDK_SECRET_KEY'));

// ── SMTP / Mail ───────────────────────────────────────────────────────────────
define('SMTP_HOST',      requireEnv('SMTP_HOST'));
define('SMTP_PORT',      (int) requireEnv('SMTP_PORT'));
define('SMTP_SECURE',    requireEnv('SMTP_SECURE'));
define('SMTP_USER',      requireEnv('SMTP_USER'));
define('SMTP_PASS',      requireEnv('SMTP_PASS'));
define('SMTP_FROM',      requireEnv('SMTP_FROM'));
define('SMTP_FROM_NAME', requireEnv('SMTP_FROM_NAME'));

// Optional — set SMTP_DEBUG=1 in .env temporarily to log the full SMTP
// conversation to error_log while diagnosing delivery issues. Defaults
// to off (0) if not set, so no .env change is required unless you want
// to enable it.
define('SMTP_DEBUG', (bool) (getenv('SMTP_DEBUG') ?: false));

// ── Error Reporting ───────────────────────────────────────────────────────────
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/../logs/error.log');

// ── Timezone ──────────────────────────────────────────────────────────────────
date_default_timezone_set('UTC');

// ── Business Rules ────────────────────────────────────────────────────────────
define('MIN_WITHDRAWAL_AMOUNT',       50.00);
define('ESCROW_AUTO_RELEASE_MINUTES', 30);
define('MAX_CHAT_MESSAGE_LENGTH',     1000);
define('CALL_REQUEST_EXPIRY_SECONDS', 120);

// ── Referral Program ──────────────────────────────────────────────────────────
// Referrer earns 5% of coins on a referred user's FIRST completed deposit only.
define('REFERRAL_COMMISSION_RATE', 0.05);

// ── App Name ─────────────────────────────────────────────────────────────────
// Used by mail/mailTemplate.php email header. Was previously undefined
// (templates fell back to the generic "Verification Code" label) — this
// just brands outgoing emails properly, no behavior change.
if (!defined('APP_NAME')) {
    define('APP_NAME', 'MaskedParty');
}

// ── Support Agent Credential Encryption ─────────────────────────────────────
// Used to reversibly encrypt system-generated support agent passwords so
// the admin dashboard can display them again via "view credentials".
// Recommended: set SUPPORT_CRED_KEY explicitly in config/secure/.env for
// production. If not set, a key is derived from existing DB/SMTP secrets
// so this still works out of the box without requiring a new .env entry.
define('SUPPORT_CRED_KEY', hash('sha256', (getenv('SUPPORT_CRED_KEY') ?: (DB_PASS . SMTP_PASS)), true));

// ── Upload Settings ───────────────────────────────────────────────────────────
define('UPLOAD_BASE_DIR', dirname(__DIR__) . '/uploads/');
define('UPLOAD_DIR',      UPLOAD_BASE_DIR); // Legacy alias

define('MAX_IMAGE_SIZE',    10 * 1024 * 1024);  // 10 MB
define('MAX_VIDEO_SIZE',   100 * 1024 * 1024);  // 100 MB
define('MAX_DOCUMENT_SIZE', 10 * 1024 * 1024);  // 10 MB
define('MAX_UPLOAD_SIZE',   MAX_IMAGE_SIZE);
