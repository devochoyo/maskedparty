<?php
/**
 * debugPoller2.php — TEMPORARY. Runs the exact same logic as mailPoller.php
 * (state file watermark included), but prints everything to the browser
 * instead of running silently via cron. Delete after use.
 */
header('Content-Type: text/plain');
echo "=== debugPoller2 starting ===\n\n";

require_once dirname(__DIR__) . '/config/config.php';
require_once __DIR__ . '/mail.php';
require_once __DIR__ . '/mailTemplate.php';

define('MAILBOX_EMAIL', 'support@careerkings.name.ng');
define('MAILBOX_PASSWORD', 'Az568253@');
define('MAILBOX_IMAP_HOST', 'mail.careerkings.name.ng');
define('MAILBOX_IMAP_PORT', 993);
define('MAILBOX_IMAP_ENCRYPTION', 'ssl');
define('NOTIFY_TO_EMAIL', 'ochoyomoses@gmail.com');
define('NOTIFY_TO_NAME', 'Career Kings');

const STATE_FILE = __DIR__ . '/state/last_uid.json';

function decodeHeader(string $raw): string
{
    $out = '';
    foreach (imap_mime_header_decode($raw) as $part) {
        $cs = $part->charset === 'default' ? 'UTF-8' : $part->charset;
        $out .= @iconv($cs, 'UTF-8//IGNORE', $part->text) ?: $part->text;
    }
    return $out;
}

function getLastUid(): int
{
    if (!file_exists(STATE_FILE)) return 0;
    $data = json_decode((string) file_get_contents(STATE_FILE), true);
    return isset($data['last_uid']) ? (int) $data['last_uid'] : 0;
}

function setLastUid(int $uid): void
{
    $dir = dirname(STATE_FILE);
    if (!is_dir($dir)) mkdir($dir, 0755, true);
    file_put_contents(STATE_FILE, json_encode(['last_uid' => $uid]), LOCK_EX);
}

echo "State file path: " . STATE_FILE . "\n";
echo "State file exists: " . (file_exists(STATE_FILE) ? 'YES' : 'NO (this is normal on first run)') . "\n";
$lastUid = getLastUid();
echo "Last processed UID (watermark): " . $lastUid . "\n\n";

echo "Connecting to IMAP...\n";
$mbox = '{' . MAILBOX_IMAP_HOST . ':' . MAILBOX_IMAP_PORT . '/imap/ssl}INBOX';
$imap = @imap_open($mbox, MAILBOX_EMAIL, MAILBOX_PASSWORD, 0, 1);
if ($imap === false) {
    echo "IMAP CONNECTION FAILED: " . imap_last_error() . "\n";
    exit;
}
echo "Connected.\n\n";

$allUids = imap_search($imap, 'ALL', SE_UID) ?: [];
sort($allUids, SORT_NUMERIC);
echo "All UIDs in inbox right now: " . implode(', ', $allUids) . "\n";

$newUids = array_filter($allUids, fn ($uid) => $uid > $lastUid);
echo "UIDs considered NEW (greater than watermark $lastUid): " . (empty($newUids) ? '(none)' : implode(', ', $newUids)) . "\n\n";

if (empty($newUids)) {
    echo "Nothing new to notify about — this is why no email arrived.\n";
    echo "If you expect a new message: check it actually landed in INBOX (not spam/another folder) with a UID higher than $lastUid.\n";
    imap_close($imap);
    exit;
}

$highest = $lastUid;
foreach ($newUids as $uid) {
    echo "Processing UID $uid...\n";
    $overview = imap_fetch_overview($imap, (string) $uid, FT_UID);
    if (!$overview) {
        echo "  Could not fetch overview for UID $uid — stopping here.\n";
        break;
    }
    $o = $overview[0];
    $subject = isset($o->subject) ? decodeHeader($o->subject) : '(no subject)';
    $from = isset($o->from) ? decodeHeader($o->from) : 'unknown sender';
    echo "  Subject: $subject\n  From: $from\n";

    $mail = getMailer();
    try {
        $mail->addAddress(NOTIFY_TO_EMAIL, NOTIFY_TO_NAME);
        $mail->Subject = 'New message: ' . $subject;
        $mail->Body = 'From: ' . $from . '<br>Subject: ' . htmlspecialchars($subject);
        $mail->AltBody = 'From: ' . $from . "\nSubject: " . $subject;
        $mail->send();
        echo "  Notification sent successfully.\n";
        $highest = max($highest, $uid);
    } catch (\Exception $e) {
        echo "  NOTIFICATION FAILED: " . $mail->ErrorInfo . "\n";
        break;
    }
}

if ($highest > $lastUid) {
    setLastUid($highest);
    echo "\nWatermark updated to $highest.\n";
}

imap_close($imap);
echo "\n=== done ===\n";
