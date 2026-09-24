<?php
/**
 * debugPoller.php — TEMPORARY. Same logic as mailPoller.php but prints
 * every step so we can see exactly where it stops. Delete after use —
 * this is not meant to stay live (it can be run repeatedly by anyone
 * who finds the URL, unlike mailPoller.php which is cron/CLI-only).
 */
header('Content-Type: text/plain');
echo "=== debugPoller starting ===\n\n";

require_once dirname(__DIR__) . '/config/config.php'; // defines SMTP_* from your .env
require_once __DIR__ . '/mail.php';

// Same values as in mailPoller.php — paste your real password/email here too
// (this file is a separate request, so it can't "see" mailPoller.php's config).
define('MAILBOX_EMAIL', 'support@careerkings.name.ng');
define('MAILBOX_PASSWORD', 'Az568253@');
define('MAILBOX_IMAP_HOST', 'mail.careerkings.name.ng');
define('MAILBOX_IMAP_PORT', 993);
define('MAILBOX_IMAP_ENCRYPTION', 'ssl');
define('NOTIFY_TO_EMAIL', 'ochoyomoses@gmail.com');
define('NOTIFY_TO_NAME', 'Career Kings');

echo "MAILBOX_EMAIL: " . MAILBOX_EMAIL . "\n";
echo "MAILBOX_IMAP_HOST: " . MAILBOX_IMAP_HOST . ":" . MAILBOX_IMAP_PORT . " (" . MAILBOX_IMAP_ENCRYPTION . ")\n";
echo "imap extension loaded: " . (function_exists('imap_open') ? 'YES' : 'NO — this is the problem, enable it in MultiPHP INI Editor') . "\n\n";

if (!function_exists('imap_open')) {
    exit;
}

echo "Attempting IMAP connection...\n";
$enc = strtolower(MAILBOX_IMAP_ENCRYPTION) === 'tls' ? 'tls' : 'ssl';
$mbox = '{' . MAILBOX_IMAP_HOST . ':' . MAILBOX_IMAP_PORT . '/imap/' . $enc . '}INBOX';
echo "Mailbox string: $mbox\n";

$conn = @imap_open($mbox, MAILBOX_EMAIL, MAILBOX_PASSWORD, 0, 1);

if ($conn === false) {
    echo "\nCONNECTION FAILED.\n";
    echo "imap_last_error(): " . imap_last_error() . "\n";
    echo "imap_errors(): " . print_r(imap_errors(), true) . "\n";
    exit;
}

echo "Connected successfully!\n\n";

$uids = imap_search($conn, 'ALL', SE_UID);
echo "Messages found in INBOX: " . ($uids ? count($uids) : 0) . "\n";
if ($uids) {
    sort($uids, SORT_NUMERIC);
    echo "UIDs: " . implode(', ', $uids) . "\n";
}

echo "\n--- Now testing the notification email ---\n";
require_once __DIR__ . '/mailTemplate.php';
$mail = getMailer();
try {
    $mail->addAddress(NOTIFY_TO_EMAIL, defined('NOTIFY_TO_NAME') ? NOTIFY_TO_NAME : '');
    $mail->Subject = 'debugPoller test notification';
    $mail->Body = 'If you got this, your NOTIFY_TO_EMAIL delivery path works.';
    $mail->AltBody = 'If you got this, your NOTIFY_TO_EMAIL delivery path works.';
    $mail->send();
    echo "Test notification SENT successfully to " . NOTIFY_TO_EMAIL . " — check that inbox now.\n";
} catch (\Exception $e) {
    echo "Test notification FAILED: " . $mail->ErrorInfo . "\n";
}

imap_close($conn);
echo "\n=== done ===\n";

