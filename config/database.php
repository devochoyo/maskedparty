<?php
/**
 * Database Connection using PDO
 */

require_once __DIR__ . '/config.php';

/**
 * --------------------------------------------------------------------
 * Centralized error logging
 * --------------------------------------------------------------------
 * Every API file that includes database.php (directly or indirectly)
 * automatically gets:
 *   - PHP errors, warnings, notices, and uncaught exceptions logged to
 *     /config/error.log (this file's own directory).
 *   - A consistent, timestamped log line including the requesting
 *     script path, so you can trace which API endpoint an error came
 *     from.
 *
 * This does NOT change any existing behavior of getDatabaseConnection()
 * or the JSON responses APIs return - it only adds logging hooks.
 */
if (!defined('APP_ERROR_LOG_INITIALIZED')) {
    define('APP_ERROR_LOG_INITIALIZED', true);

    define('APP_ERROR_LOG_FILE', __DIR__ . '/error.log');

    // Route PHP's own error logging (warnings, notices, fatal errors, etc.)
    // into config/error.log, without touching error_reporting level
    // already configured in config.php.
    ini_set('log_errors', 1);
    ini_set('error_log', APP_ERROR_LOG_FILE);

    /**
     * Write a single line to config/error.log in a consistent format.
     *
     * @param string $type    Short label, e.g. 'PHP ERROR', 'EXCEPTION', 'DB ERROR'
     * @param string $message The error message
     * @param string $file    File where the error occurred (optional)
     * @param int    $line    Line where the error occurred (optional)
     */
    function appLogError($type, $message, $file = '', $line = 0) {
        $timestamp = date('Y-m-d H:i:s');

        // Identify which API endpoint triggered this, so logs are easy
        // to trace back to a specific API file.
        $requestScript = isset($_SERVER['SCRIPT_NAME']) ? $_SERVER['SCRIPT_NAME'] : (php_sapi_name() === 'cli' ? 'CLI' : 'unknown');
        $requestMethod = isset($_SERVER['REQUEST_METHOD']) ? $_SERVER['REQUEST_METHOD'] : '-';

        $location = '';
        if ($file !== '') {
            $location = " in {$file}" . ($line ? ":{$line}" : '');
        }

        $line_out = "[{$timestamp}] [{$type}] [{$requestMethod} {$requestScript}] {$message}{$location}" . PHP_EOL;

        // Fail silently if the log can't be written (e.g. permissions) so
        // logging never breaks the API response itself.
        @error_log($line_out, 3, APP_ERROR_LOG_FILE);
    }

    /**
     * Custom error handler: catches warnings/notices/deprecated/etc. and
     * writes them to config/error.log, then lets PHP's normal internal
     * handling continue (return false) so nothing is suppressed.
     */
    set_error_handler(function ($errno, $errstr, $errfile, $errline) {
        $levels = [
            E_ERROR             => 'ERROR',
            E_WARNING           => 'WARNING',
            E_NOTICE            => 'NOTICE',
            E_DEPRECATED        => 'DEPRECATED',
            E_STRICT            => 'STRICT',
            E_USER_ERROR        => 'USER ERROR',
            E_USER_WARNING      => 'USER WARNING',
            E_USER_NOTICE       => 'USER NOTICE',
            E_USER_DEPRECATED   => 'USER DEPRECATED',
        ];
        $type = isset($levels[$errno]) ? $levels[$errno] : 'PHP ERROR';

        appLogError($type, $errstr, $errfile, $errline);

        // Returning false keeps PHP's normal error handling/logging too.
        return false;
    });

    /**
     * Catch uncaught exceptions so they're logged with a full message
     * and stack trace before PHP's default handler takes over.
     */
    set_exception_handler(function ($e) {
        appLogError(
            'UNCAUGHT EXCEPTION',
            $e->getMessage() . " | Trace: " . str_replace(["\r\n", "\n"], ' | ', $e->getTraceAsString()),
            $e->getFile(),
            $e->getLine()
        );

        // Preserve existing behavior for API consumers: respond with a
        // generic JSON error rather than leaking a raw stack trace.
        if (!headers_sent()) {
            header('Content-Type: application/json');
        }
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Internal server error.'
        ]);
        exit;
    });

    /**
     * Catch fatal errors (parse errors, uncaught TypeErrors, memory
     * exhaustion, etc.) that don't go through set_error_handler.
     */
    register_shutdown_function(function () {
        $error = error_get_last();
        if ($error !== null && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR], true)) {
            appLogError('FATAL ERROR', $error['message'], $error['file'], $error['line']);
        }
    });
}

function getDatabaseConnection() {
    static $pdo = null;

    if ($pdo === null) {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
            // Keep MySQL's NOW()/session clock aligned with PHP's UTC
            // setting above (date_default_timezone_set('UTC') in config.php).
            // Without this, NOW() uses the DB server's local timezone,
            // which can silently disagree with PHP's time()/strtotime()
            // and make expires_at comparisons wrong in either direction.
            $pdo->exec("SET time_zone = '+00:00'");
        } catch (PDOException $e) {
            // Log error internally (now written to config/error.log)
            appLogError('DB CONNECTION ERROR', $e->getMessage(), $e->getFile(), $e->getLine());

            // Return generic JSON error
            header('Content-Type: application/json');
            echo json_encode([
                'success' => false,
                'message' => 'Internal server error.'
            ]);
            exit;
        }
    }

    return $pdo;
}

