<?php
/**
 * mailPoller.php — triggered by cron via wget/curl hitting this URL
 * with a secret key, NOT by running the php binary directly. Your
 * host's CLI PHP setup (lsphp) was silently failing every attempt, so
 * this uses the same web-request path that already worked reliably
 * for every debug test.
 *
 * Cron command (replace the old one with this):
 *   wget -q -O /dev/null "https://maskedparty.name.ng/mail/mailPoller.php?key=SECRET_KEY_BELOW"
 *
 * The ?key= value must match POLL_SECRET below — this stops random
 * visitors from triggering it, since the URL itself is now public-ish
 * (visible in your cron job settings).
 */

$POLL_SECRET = 'kP9v2Qz7mR4xT8wL1nY6bF3sJ0dH5cE';

if (($_GET['key'] ?? '') !== $POLL_SECRET) {
    http_response_code(403);
    exit('Forbidden.');
}

require_once dirname(__DIR__) . '/config/config.php'; // defines SMTP_* from your .env
require_once __DIR__ . '/mail.php';         // your existing getMailer()
require_once __DIR__ . '/mailTemplate.php'; // your existing baseEmailTemplate()

// ==================== CONFIG (already filled in) ====================
define('MAILBOX_EMAIL', 'support@careerkings.name.ng');
define('MAILBOX_PASSWORD', 'Az568253@');
define('MAILBOX_IMAP_HOST', 'mail.careerkings.name.ng');
define('MAILBOX_IMAP_PORT', 993);
define('MAILBOX_IMAP_ENCRYPTION', 'ssl');
define('MAILBOX_SMTP_HOST', 'mail.careerkings.name.ng');
define('MAILBOX_SMTP_PORT', 465);
define('MAILBOX_SMTP_ENCRYPTION', 'ssl');
define('NOTIFY_TO_EMAIL', 'careerkingsconsult@gmail.com');
define('NOTIFY_TO_NAME', 'Career Kings');
define('MAIL_LINK_SECRET', '3a5ac989c686706b3d4538c42fe0e201c08f7fc6b0732c75b9f1bfaf363727ae');
define('APP_BASE_URL', 'https://maskedparty.name.ng');
// ======================================================================================

header('Content-Type: text/plain');

const STATE_FILE = __DIR__ . '/state/last_uid.json';

function b64url(string $d): string { return rtrim(strtr(base64_encode($d), '+/', '-_'), '='); }

function signToken(int $uid, int $exp): string
{
    return b64url(hash_hmac('sha256', $uid . '.' . $exp, MAIL_LINK_SECRET, true));
}

function imapConnect()
{
    if (!function_exists('imap_open')) {
        throw new RuntimeException('PHP imap extension not enabled.');
    }
    $host = MAILBOX_IMAP_HOST;
    $port = defined('MAILBOX_IMAP_PORT') ? (int) MAILBOX_IMAP_PORT : 993;
    $enc  = (defined('MAILBOX_IMAP_ENCRYPTION') && strtolower(MAILBOX_IMAP_ENCRYPTION) === 'tls') ? 'tls' : 'ssl';
    $mbox = '{' . $host . ':' . $port . '/imap/' . $enc . '}INBOX';
    $conn = @imap_open($mbox, MAILBOX_EMAIL, MAILBOX_PASSWORD, 0, 1);
    if ($conn === false) {
        throw new RuntimeException('IMAP connect failed: ' . imap_last_error());
    }
    return $conn;
}

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

function notify(array $msg): bool
{
    $base = rtrim(APP_BASE_URL, '/');
    $exp  = time() + 30 * 24 * 60 * 60;
    $sig  = signToken($msg['uid'], $exp);
    $url  = $base . '/mail/view.php?' . http_build_query(['uid' => $msg['uid'], 'exp' => $exp, 'sig' => $sig]);

    $safeFrom = htmlspecialchars($msg['from'], ENT_QUOTES, 'UTF-8');
    $safeSubj = htmlspecialchars($msg['subject'], ENT_QUOTES, 'UTF-8');
    $safeUrl  = htmlspecialchars($url, ENT_QUOTES, 'UTF-8');

    $body = <<<HTML
    <h1 style="margin:0 0 10px;font-size:22px;font-weight:800;color:#111827;">New Message</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#6b7280;">You've received a new message on your support mailbox.</p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
      <tr><td style="background:#faf8ff;border:1.5px solid #e0d0ff;border-radius:12px;padding:18px 20px;">
        <p style="margin:0 0 6px;font-size:13px;color:#9ca3af;">From</p>
        <p style="margin:0 0 14px;font-size:15px;color:#111827;font-weight:600;">{$safeFrom}</p>
        <p style="margin:0 0 6px;font-size:13px;color:#9ca3af;">Subject</p>
        <p style="margin:0;font-size:15px;color:#111827;">{$safeSubj}</p>
      </td></tr>
    </table>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center">
      <a href="{$safeUrl}" style="display:inline-block;background:#FF2D87;color:#000;font-weight:800;font-size:15px;padding:14px 32px;border-radius:10px;text-decoration:none;">View Email</a>
    </td></tr></table>
HTML;

    $mail = getMailer();
    try {
        $mail->addAddress(NOTIFY_TO_EMAIL, NOTIFY_TO_NAME);
        $mail->Subject = 'New message: ' . $msg['subject'];
        $mail->Body    = baseEmailTemplate("New message: {$msg['subject']}", $body);
        $mail->AltBody = "New message from {$msg['from']}\nSubject: {$msg['subject']}\n\nView: {$url}";
        $mail->send();
        return true;
    } catch (\Exception $e) {
        mailDebugLog('POLLER notify failed uid=' . $msg['uid'] . ': ' . $mail->ErrorInfo);
        echo "NOTIFY FAILED uid={$msg['uid']}: " . $mail->ErrorInfo . "\n";
        return false;
    }
}

// ---- main ----
echo "Poller run at " . date('c') . "\n";

try {
    $imap = imapConnect();
} catch (\Throwable $e) {
    mailDebugLog('POLLER: ' . $e->getMessage());
    echo "IMAP FAILED: " . $e->getMessage() . "\n";
    exit;
}

$lastUid = getLastUid();
$allUids = imap_search($imap, 'ALL', SE_UID) ?: [];
sort($allUids, SORT_NUMERIC);
$newUids = array_filter($allUids, fn ($uid) => $uid > $lastUid);

echo "Watermark: $lastUid | New UIDs: " . (empty($newUids) ? 'none' : implode(',', $newUids)) . "\n";

$highest = $lastUid;
foreach ($newUids as $uid) {
    $overview = imap_fetch_overview($imap, (string) $uid, FT_UID);
    if (!$overview) {
        mailDebugLog('POLLER: overview missing uid=' . $uid);
        break;
    }
    $o = $overview[0];
    $msg = [
        'uid'     => $uid,
        'subject' => isset($o->subject) ? decodeHeader($o->subject) : '(no subject)',
        'from'    => isset($o->from) ? decodeHeader($o->from) : 'unknown sender',
    ];
    if (!notify($msg)) {
        break;
    }
    echo "Notified for uid=$uid\n";
    $highest = max($highest, $uid);
}

if ($highest > $lastUid) {
    setLastUid($highest);
    echo "Watermark advanced to $highest\n";
}
imap_close($imap);
echo "Done.\n";

