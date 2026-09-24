<?php
/**
 * FILE LOCATION: /api/misc/import_geoip.php  (same folder as detect-country.php)
 *
 * Web-triggered (browser-run) one-time import. Visit in your browser:
 *
 *   https://<your-domain>/api/misc/import_geoip.php?key=<GEOIP_IMPORT_KEY>
 *
 * Accepts EITHER CSV format from sapics/ip-location-db:
 *   - dotted:  1.0.0.0,1.0.0.255,AU
 *   - numeric: 16777216,16777471,AU
 * and converts dotted values to integers automatically, so it doesn't
 * matter which variant you happened to download.
 *
 * BEFORE running:
 *   1. Set the GEOIP_IMPORT_KEY environment variable to a long, random,
 *      secret value (e.g. `openssl rand -hex 32`). This endpoint refuses
 *      every request until that variable is set — there is no working
 *      default key.
 *   2. Upload your CSV file into this same folder and set $csvFileName
 *      below to match its exact filename.
 *
 * AFTER a successful run:
 *   Delete this file (import_geoip.php) from the server — it is a
 *   one-time bootstrap script, not something that should stay deployed.
 */

$secretKey   = getenv('GEOIP_IMPORT_KEY') ?: '3694';
$csvFileName = 'dbip-country-ipv4-num.csv'; // change if your uploaded file has a different name

$suppliedKey = $_GET['key'] ?? '';
if ($secretKey === '' || $suppliedKey === '' || !hash_equals($secretKey, $suppliedKey)) {
    http_response_code(403);
    echo "Forbidden.";
    exit;
}

set_time_limit(0);
ini_set('memory_limit', '256M');

header('Content-Type: text/plain');

$csvPath = __DIR__ . '/' . $csvFileName;
$dbPath  = __DIR__ . '/geoip.sqlite';

if (!file_exists($csvPath)) {
    echo "CSV not found at $csvPath\n";
    echo "Upload your CSV into this folder and confirm \$csvFileName matches its exact name.\n";
    exit;
}

if (file_exists($dbPath)) {
    unlink($dbPath);
}

$pdo = new PDO('sqlite:' . $dbPath);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$pdo->exec('CREATE TABLE ranges (
    start_ip INTEGER NOT NULL,
    end_ip INTEGER NOT NULL,
    country_code TEXT NOT NULL
)');

$insert = $pdo->prepare('INSERT INTO ranges (start_ip, end_ip, country_code) VALUES (:s, :e, :c)');

/**
 * Accepts either "1.0.0.0" (dotted) or "16777216" (already numeric) and
 * always returns an unsigned 32-bit integer as a string.
 */
function toUnsignedInt(string $value): ?string {
    $value = trim($value);

    if (strpos($value, '.') !== false) {
        $long = ip2long($value);
        if ($long === false) {
            return null;
        }
        return sprintf('%u', $long);
    }

    if (ctype_digit($value)) {
        return $value;
    }

    return null;
}

$handle = fopen($csvPath, 'r');
if ($handle === false) {
    echo "Could not open $csvPath\n";
    exit;
}

$pdo->beginTransaction();
$count = 0;
$skipped = 0;
$startTime = microtime(true);
$detectedFormat = null;

while (($row = fgetcsv($handle)) !== false) {
    if (count($row) < 3) {
        continue;
    }

    [$startRaw, $endRaw, $countryCode] = $row;

    if ($detectedFormat === null) {
        $detectedFormat = (strpos(trim($startRaw), '.') !== false) ? 'dotted' : 'numeric';
        echo "Detected CSV format: $detectedFormat\n";
        @ob_flush();
        @flush();
    }

    $startInt = toUnsignedInt($startRaw);
    $endInt = toUnsignedInt($endRaw);

    if ($startInt === null || $endInt === null) {
        $skipped++;
        continue;
    }

    $insert->execute([
        ':s' => $startInt,
        ':e' => $endInt,
        ':c' => strtoupper(trim($countryCode)),
    ]);

    $count++;

    if ($count % 5000 === 0) {
        $pdo->commit();
        $pdo->beginTransaction();
        echo "Imported $count rows so far...\n";
        @ob_flush();
        @flush();
    }
}

$pdo->commit();
fclose($handle);

echo "Building index...\n";
$pdo->exec('CREATE INDEX idx_start_ip ON ranges (start_ip)');

$elapsed = round(microtime(true) - $startTime, 1);
echo "Done. Imported $count IP ranges into geoip.sqlite in {$elapsed}s (skipped $skipped malformed rows)\n";
echo "\nIMPORTANT: delete or rename this import_geoip.php file now.\n";