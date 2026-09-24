<?php
/**
 * FILE LOCATION: /api/misc/check_geoip.php  (same folder as detect-country.php)
 *
 * Temporary diagnostic. Visit in browser:
 *   https://<your-domain>/api/misc/check_geoip.php?key=<GEOIP_IMPORT_KEY>
 *
 * Delete this file once you've diagnosed the issue.
 */

$secretKey = getenv('GEOIP_IMPORT_KEY') ?: ''; // same variable used by import_geoip.php

$suppliedKey = $_GET['key'] ?? '';
if ($secretKey === '' || $suppliedKey === '' || !hash_equals($secretKey, $suppliedKey)) {
    http_response_code(403);
    echo "Forbidden.";
    exit;
}

header('Content-Type: text/plain');

$dbPath = __DIR__ . '/geoip.sqlite';

if (!file_exists($dbPath)) {
    echo "geoip.sqlite does not exist at $dbPath\n";
    exit;
}

echo "geoip.sqlite file size: " . filesize($dbPath) . " bytes\n\n";

$pdo = new PDO('sqlite:' . $dbPath);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$count = $pdo->query('SELECT COUNT(*) AS c FROM ranges')->fetch(PDO::FETCH_ASSOC);
echo "Total rows in ranges table: {$count['c']}\n";
echo "(A complete dbip-country-ipv4-num.csv import should be several hundred thousand rows.)\n\n";

$minMax = $pdo->query('SELECT MIN(start_ip) AS min_ip, MAX(end_ip) AS max_ip FROM ranges')->fetch(PDO::FETCH_ASSOC);
echo "start_ip range covered: {$minMax['min_ip']} to {$minMax['max_ip']}\n\n";

// Check whether the index actually got created
$indexes = $pdo->query("SELECT name FROM sqlite_master WHERE type = 'index'")->fetchAll(PDO::FETCH_COLUMN);
echo "Indexes present: " . (empty($indexes) ? '(none — import likely did not finish)' : implode(', ', $indexes)) . "\n\n";

// Test lookup against the IP that's actually hitting this script right now
function getClientIp(): string {
    $headerCandidates = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'];
    foreach ($headerCandidates as $header) {
        if (!empty($_SERVER[$header])) {
            $parts = explode(',', $_SERVER[$header]);
            $ip = trim($parts[0]);
            if (filter_var($ip, FILTER_VALIDATE_IP)) {
                return $ip;
            }
        }
    }
    return '0.0.0.0';
}

$ip = getClientIp();
$ipLong = ip2long($ip);
$ipUnsigned = $ipLong !== false ? sprintf('%u', $ipLong) : null;

echo "Detected client IP for this request: $ip\n";
echo "As unsigned integer: " . ($ipUnsigned ?? 'N/A - not a valid IPv4') . "\n\n";

if ($ipUnsigned !== null) {
    $stmt = $pdo->prepare(
        'SELECT * FROM ranges WHERE start_ip <= :ip AND end_ip >= :ip ORDER BY start_ip DESC LIMIT 3'
    );
    $stmt->execute([':ip' => $ipUnsigned]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($rows)) {
        echo "No matching range found for this IP.\n";

        // Show nearby ranges to see if data exists around this IP at all
        $nearby = $pdo->prepare('SELECT * FROM ranges WHERE start_ip <= :ip ORDER BY start_ip DESC LIMIT 3');
        $nearby->execute([':ip' => $ipUnsigned]);
        $nearbyRows = $nearby->fetchAll(PDO::FETCH_ASSOC);
        echo "\nClosest ranges below this IP (for comparison):\n";
        foreach ($nearbyRows as $r) {
            echo "  start={$r['start_ip']} end={$r['end_ip']} country={$r['country_code']}\n";
        }
    } else {
        echo "Match found:\n";
        foreach ($rows as $r) {
            echo "  start={$r['start_ip']} end={$r['end_ip']} country={$r['country_code']}\n";
        }
    }
}
