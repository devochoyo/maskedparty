<?php
/**
 * config/security.php
 *
 * Small security helpers that work on plain shared hosting (no Redis, no
 * Composer, no terminal). Loaded automatically by config/database.php.
 *
 *   - client_ip()                      real visitor IP (safe fallback)
 *   - rl_blocked / rl_hit / rl_clear   attempt limiter stored in MySQL
 *   - rl_enforce()                     one-call limiter that answers 429
 *
 * The limiter table is created automatically the first time it is needed
 * (same approach the project already uses for api_tokens). If the table
 * cannot be created for any reason the limiter simply does nothing, so a
 * hosting hiccup can never lock everybody out.
 */

require_once __DIR__ . '/response.php';

if (!headers_sent()) {
    header('X-Content-Type-Options: nosniff');
    header('Referrer-Policy: no-referrer');
}

/**
 * Visitor IP address. Only REMOTE_ADDR is trusted, because a client can
 * fake X-Forwarded-For. Cloudflare's header is used only when the request
 * really came from Cloudflare's network headers (CF-Connecting-IP plus
 * a Cloudflare ray id), which a plain visitor cannot supply to Apache
 * through a normal Cloudflare proxy.
 */
function client_ip(): string
{
    $ip = (string) ($_SERVER['REMOTE_ADDR'] ?? '');
    if (!empty($_SERVER['HTTP_CF_CONNECTING_IP']) && !empty($_SERVER['HTTP_CF_RAY'])) {
        $cf = trim((string) $_SERVER['HTTP_CF_CONNECTING_IP']);
        if (filter_var($cf, FILTER_VALIDATE_IP)) {
            $ip = $cf;
        }
    }
    return filter_var($ip, FILTER_VALIDATE_IP) ? $ip : '0.0.0.0';
}

function rl_ensure_table(PDO $pdo): bool
{
    static $ready = null;
    if ($ready !== null) {
        return $ready;
    }
    try {
        $pdo->exec(
            "CREATE TABLE IF NOT EXISTS rate_limits (
                rl_key CHAR(64) NOT NULL,
                hits INT UNSIGNED NOT NULL DEFAULT 0,
                window_start INT UNSIGNED NOT NULL,
                PRIMARY KEY (rl_key),
                KEY idx_rate_limits_window (window_start)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
        );
        $ready = true;
        // Tidy old rows now and then (about 1 request in 200).
        if (random_int(1, 200) === 1) {
            $pdo->prepare('DELETE FROM rate_limits WHERE window_start < :t')
                ->execute(['t' => time() - 86400]);
        }
    } catch (Throwable $e) {
        $ready = false;
    }
    return $ready;
}

function rl_key(string $bucket, string $subject): string
{
    return hash('sha256', $bucket . '|' . strtolower($subject));
}

/** True when this bucket/subject already used up its allowance. */
function rl_blocked(PDO $pdo, string $bucket, string $subject, int $max, int $windowSeconds): bool
{
    if (!rl_ensure_table($pdo)) {
        return false;
    }
    try {
        $stmt = $pdo->prepare('SELECT hits, window_start FROM rate_limits WHERE rl_key = :k LIMIT 1');
        $stmt->execute(['k' => rl_key($bucket, $subject)]);
        $row = $stmt->fetch();
        if (!$row) {
            return false;
        }
        if ((int) $row['window_start'] < time() - $windowSeconds) {
            return false;
        }
        return (int) $row['hits'] >= $max;
    } catch (Throwable $e) {
        return false;
    }
}

/** Count one attempt. */
function rl_hit(PDO $pdo, string $bucket, string $subject, int $windowSeconds): void
{
    if (!rl_ensure_table($pdo)) {
        return;
    }
    try {
        $now    = time();
        $cutoff = $now - $windowSeconds;
        $stmt = $pdo->prepare(
            'INSERT INTO rate_limits (rl_key, hits, window_start) VALUES (:k, 1, :now)
             ON DUPLICATE KEY UPDATE
                hits = IF(window_start < :cutoff, 1, hits + 1),
                window_start = IF(window_start < :cutoff2, :now2, window_start)'
        );
        $stmt->execute([
            'k'       => rl_key($bucket, $subject),
            'now'     => $now,
            'cutoff'  => $cutoff,
            'cutoff2' => $cutoff,
            'now2'    => $now,
        ]);
    } catch (Throwable $e) {
        // never break the request because of the limiter
    }
}

/** Forget attempts (for example after a successful login). */
function rl_clear(PDO $pdo, string $bucket, string $subject): void
{
    if (!rl_ensure_table($pdo)) {
        return;
    }
    try {
        $pdo->prepare('DELETE FROM rate_limits WHERE rl_key = :k')
            ->execute(['k' => rl_key($bucket, $subject)]);
    } catch (Throwable $e) {
    }
}

/**
 * Count this request and answer HTTP 429 when the allowance is used up.
 * Use for things that should be limited whatever the outcome
 * (registration, sending codes).
 */
function rl_enforce(PDO $pdo, string $bucket, string $subject, int $max, int $windowSeconds, string $message = 'Too many attempts. Please wait a while and try again.'): void
{
    if (rl_blocked($pdo, $bucket, $subject, $max, $windowSeconds)) {
        header('Retry-After: ' . $windowSeconds);
        sendError($message, 429);
    }
    rl_hit($pdo, $bucket, $subject, $windowSeconds);
}

/** Stop the request early (HTTP 429) if the bucket is already full. */
function rl_guard(PDO $pdo, string $bucket, string $subject, int $max, int $windowSeconds, string $message = 'Too many attempts. Please wait a while and try again.'): void
{
    if (rl_blocked($pdo, $bucket, $subject, $max, $windowSeconds)) {
        header('Retry-After: ' . $windowSeconds);
        sendError($message, 429);
    }
}
