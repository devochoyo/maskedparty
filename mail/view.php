<?php
/**
 * view.php — one file, two jobs:
 *   GET  -> verify the signed link, show the message, render the reply UI
 *   POST -> (called via fetch() from that same page) verify the token
 *           again, send the reply FROM the monitored mailbox, file a
 *           copy in its Sent folder, return JSON
 *
 * Reuses your existing mail.php only for mailDebugLog(); sending the
 * reply uses its own PHPMailer instance below, authenticated as the
 * monitored mailbox — never your personal address.
 *
 * >>> Edit only the MAILBOX_PASSWORD line below (same value you put in
 * mailPoller.php). NOTIFY_TO_EMAIL is NOT needed here — this file
 * never sends the notification email, only mailPoller.php does. <<<
 */

require_once __DIR__ . '/mail.php'; // mailDebugLog() only
$_phpMailerSrc = dirname(__DIR__) . '/vendor/phpmailer/phpmailer/src/';
require_once $_phpMailerSrc . 'Exception.php';
require_once $_phpMailerSrc . 'PHPMailer.php';
require_once $_phpMailerSrc . 'SMTP.php';
use PHPMailer\PHPMailer\PHPMailer;

// ==================== CONFIG — edit only the MAILBOX_PASSWORD line ====================
if (!defined('MAILBOX_EMAIL')) {
    define('MAILBOX_EMAIL', 'support@careerkings.name.ng');
    define('MAILBOX_PASSWORD', 'Az568253@');
    define('MAILBOX_IMAP_HOST', 'mail.careerkings.name.ng');
    define('MAILBOX_IMAP_PORT', 993);
    define('MAILBOX_IMAP_ENCRYPTION', 'ssl');
    define('MAILBOX_SMTP_HOST', 'mail.careerkings.name.ng');
    define('MAILBOX_SMTP_PORT', 587);
    define('MAILBOX_SMTP_ENCRYPTION', 'tls');
    define('MAIL_LINK_SECRET', '3a5ac989c686706b3d4538c42fe0e201c08f7fc6b0732c75b9f1bfaf363727ae');
    define('APP_BASE_URL', 'https://maskedparty.name.ng');
}
// ======================================================================================

function b64url(string $d): string { return rtrim(strtr(base64_encode($d), '+/', '-_'), '='); }

function signToken(int $uid, int $exp): string
{
    return b64url(hash_hmac('sha256', $uid . '.' . $exp, MAIL_LINK_SECRET, true));
}

function verifyToken($uid, $exp, $sig): int
{
    if ($uid === null || $exp === null || $sig === null || $uid === '' || $exp === '' || $sig === '') {
        throw new InvalidArgumentException('Missing link parameters.');
    }
    $uid = (int) $uid;
    $exp = (int) $exp;
    if (!hash_equals(signToken($uid, $exp), (string) $sig)) {
        throw new InvalidArgumentException('This link is invalid.');
    }
    if (time() > $exp) {
        throw new InvalidArgumentException('This link has expired.');
    }
    return $uid;
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

function decodeBody(string $data, int $encoding): string
{
    if ($encoding === 3) return base64_decode($data);   // BASE64
    if ($encoding === 4) return quoted_printable_decode($data); // QUOTED-PRINTABLE
    return $data;
}

function fetchFull($imap, int $uid): array
{
    $structure = imap_fetchstructure($imap, $uid, FT_UID);
    $header    = imap_fetchheader($imap, $uid, FT_UID);
    $h         = imap_rfc822_parse_headers($header);

    $html = null; $plain = null;
    $extract = function ($struct, $part = null) use ($imap, $uid, &$extract, &$html, &$plain) {
        if (isset($struct->parts) && $struct->parts) {
            foreach ($struct->parts as $i => $p) {
                $extract($p, $part === null ? (string) ($i + 1) : $part . '.' . ($i + 1));
            }
            return;
        }
        $section = $part ?? '1';
        $raw = decodeBody(imap_fetchbody($imap, $uid, $section, FT_UID | FT_PEEK), $struct->encoding ?? 0);
        $subtype = strtoupper($struct->subtype ?? '');
        if ($struct->type == 0 && $subtype === 'HTML' && $html === null) $html = $raw;
        elseif ($struct->type == 0 && $subtype === 'PLAIN' && $plain === null) $plain = $raw;
        elseif ($plain === null && $struct->type == 0) $plain = $raw;
    };
    $extract($structure);

    return [
        'uid'        => $uid,
        'subject'    => isset($h->subject) ? decodeHeader($h->subject) : '(no subject)',
        'from_email' => $h->from[0]->mailbox . '@' . $h->from[0]->host,
        'from_name'  => isset($h->from[0]->personal) ? decodeHeader($h->from[0]->personal) : '',
        'date'       => $h->date ?? '',
        'message_id' => isset($h->message_id) ? trim($h->message_id) : '',
        'body_html'  => $html,
        'body_plain' => $plain,
    ];
}

function mailboxMailer(): PHPMailer
{
    $mail = new PHPMailer(true);
    $mail->isSMTP();
    $mail->Host     = MAILBOX_SMTP_HOST;
    $mail->SMTPAuth = true;
    $mail->Username = MAILBOX_EMAIL;
    $mail->Password = MAILBOX_PASSWORD;
    $mail->Port     = defined('MAILBOX_SMTP_PORT') ? (int) MAILBOX_SMTP_PORT : 587;
    $mail->SMTPSecure = (defined('MAILBOX_SMTP_ENCRYPTION') && strtolower(MAILBOX_SMTP_ENCRYPTION) === 'ssl')
        ? PHPMailer::ENCRYPTION_SMTPS : PHPMailer::ENCRYPTION_STARTTLS;
    $mail->setFrom(MAILBOX_EMAIL, defined('MAILBOX_FROM_NAME') ? MAILBOX_FROM_NAME : MAILBOX_EMAIL);
    $mail->CharSet = 'UTF-8';
    $mail->Timeout = 20;
    return $mail;
}

function imapMailboxString(string $folder): string
{
    $enc = (defined('MAILBOX_IMAP_ENCRYPTION') && strtolower(MAILBOX_IMAP_ENCRYPTION) === 'tls') ? 'tls' : 'ssl';
    $port = defined('MAILBOX_IMAP_PORT') ? (int) MAILBOX_IMAP_PORT : 993;
    return '{' . MAILBOX_IMAP_HOST . ':' . $port . '/imap/' . $enc . '}' . $folder;
}

// ============================================================
// POST — AJAX reply endpoint (fetch() posts back to this same URL)
// ============================================================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: application/json');
    $in = json_decode(file_get_contents('php://input'), true) ?: [];
    $replyBody = isset($in['body']) ? trim((string) $in['body']) : '';

    try {
        $uid = verifyToken($in['uid'] ?? null, $in['exp'] ?? null, $in['sig'] ?? null);
    } catch (\Throwable $e) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        exit;
    }
    if ($replyBody === '') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Reply cannot be empty.']);
        exit;
    }

    try {
        $imap = imapConnect();
        $orig = fetchFull($imap, $uid);
    } catch (\Throwable $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Could not load the original message.']);
        exit;
    }

    $subject = (stripos($orig['subject'], 'Re:') === 0 ? '' : 'Re: ') . $orig['subject'];
    $htmlBody = nl2br(htmlspecialchars($replyBody, ENT_QUOTES, 'UTF-8'));

    try {
        $mailer = mailboxMailer();
        $mailer->addAddress($orig['from_email'], $orig['from_name'] ?: $orig['from_email']);
        $mailer->Subject = $subject;
        if ($orig['message_id']) {
            $mailer->addCustomHeader('In-Reply-To', $orig['message_id']);
            $mailer->addCustomHeader('References', $orig['message_id']);
        }
        $mailer->isHTML(true);
        $mailer->Body    = $htmlBody;
        $mailer->AltBody = $replyBody;
        $mailer->send();
    } catch (\Exception $e) {
        mailDebugLog('REPLY send failed uid=' . $uid . ': ' . $mailer->ErrorInfo);
        imap_close($imap);
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Could not send the reply. Please try again.']);
        exit;
    }

    // Best-effort: file a copy into Sent so webmail matches.
    try {
        $raw = "From: " . MAILBOX_EMAIL . "\r\nTo: {$orig['from_email']}\r\nSubject: {$subject}\r\n"
             . "Content-Type: text/html; charset=UTF-8\r\nDate: " . date('r') . "\r\n\r\n{$htmlBody}";
        if (!@imap_append($imap, imapMailboxString('Sent'), $raw, '\\Seen')) {
            @imap_append($imap, imapMailboxString('INBOX.Sent'), $raw, '\\Seen');
        }
    } catch (\Throwable $e) {
        mailDebugLog('REPLY: Sent-folder append failed uid=' . $uid . ': ' . $e->getMessage());
    }

    imap_close($imap);
    echo json_encode(['success' => true, 'message' => 'Reply sent.']);
    exit;
}

// ============================================================
// GET — render the message + reply UI
// ============================================================
try {
    $uid = verifyToken($_GET['uid'] ?? null, $_GET['exp'] ?? null, $_GET['sig'] ?? null);
} catch (\Throwable $e) {
    http_response_code(403);
    echo '<!doctype html><meta charset="utf-8"><p style="font-family:sans-serif;padding:40px;">'
        . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8') . '</p>';
    exit;
}

try {
    $imap = imapConnect();
    $message = fetchFull($imap, $uid);
    imap_setflag_full($imap, (string) $uid, '\\Seen', FT_UID);
    imap_close($imap);
} catch (\Throwable $e) {
    http_response_code(500);
    echo '<!doctype html><meta charset="utf-8"><p style="font-family:sans-serif;padding:40px;">Could not load this message: '
        . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8') . '</p>';
    exit;
}

$exp = time() + 30 * 24 * 60 * 60;
$sig = signToken($uid, $exp);

$safeSubject  = htmlspecialchars($message['subject'], ENT_QUOTES, 'UTF-8');
$safeFromName = htmlspecialchars($message['from_name'], ENT_QUOTES, 'UTF-8');
$safeFromMail = htmlspecialchars($message['from_email'], ENT_QUOTES, 'UTF-8');
$safeDate     = htmlspecialchars($message['date'], ENT_QUOTES, 'UTF-8');

$bodyIsHtml   = $message['body_html'] !== null;
$iframeSrcdoc = $bodyIsHtml ? htmlspecialchars($message['body_html'], ENT_QUOTES, 'UTF-8') : '';
$plainBody    = $bodyIsHtml ? '' : nl2br(htmlspecialchars($message['body_plain'] ?? '', ENT_QUOTES, 'UTF-8'));
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= $safeSubject ?></title>
<style>
  :root { color-scheme: light; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
         background:#f4f4f6; margin:0; padding:24px 16px; color:#111827; }
  .card { max-width:680px; margin:0 auto; background:#fff; border-radius:16px;
          box-shadow:0 4px 32px rgba(17,24,39,.08); overflow:hidden; }
  .header { padding:24px 28px; border-bottom:1px solid #e5e7eb; }
  .header h1 { margin:0 0 6px; font-size:19px; }
  .meta { font-size:13px; color:#6b7280; }
  .body { padding:24px 28px; }
  .body iframe { width:100%; min-height:200px; border:0; }
  .reply-box { padding:20px 28px 28px; border-top:1px solid #e5e7eb; }
  .reply-box textarea { width:100%; min-height:140px; box-sizing:border-box; padding:12px 14px;
                         border:1.5px solid #e5e7eb; border-radius:10px; font-size:14px;
                         font-family:inherit; resize:vertical; }
  .reply-box button { margin-top:12px; background:#FF2D87; color:#000; font-weight:800;
                       border:0; border-radius:10px; padding:12px 26px; font-size:14px; cursor:pointer; }
  .reply-box button:disabled { opacity:.6; cursor:default; }
  .status { margin-top:12px; font-size:13px; }
  .status.ok { color:#15803d; }
  .status.err { color:#b91c1c; }
</style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1><?= $safeSubject ?></h1>
      <div class="meta">From <?= $safeFromName ? $safeFromName . ' ' : '' ?>&lt;<?= $safeFromMail ?>&gt; · <?= $safeDate ?></div>
    </div>
    <div class="body">
      <?php if ($bodyIsHtml): ?>
        <iframe sandbox="" srcdoc="<?= $iframeSrcdoc ?>" id="bodyFrame"></iframe>
      <?php else: ?>
        <div><?= $plainBody ?></div>
      <?php endif; ?>
    </div>
    <div class="reply-box">
      <textarea id="replyText" placeholder="Type your reply…"></textarea>
      <br>
      <button id="sendBtn">Send Reply</button>
      <div id="status" class="status"></div>
    </div>
  </div>

<script>
(function () {
  var uid = <?= json_encode($uid) ?>;
  var exp = <?= json_encode($exp) ?>;
  var sig = <?= json_encode($sig) ?>;

  var btn = document.getElementById('sendBtn');
  var textarea = document.getElementById('replyText');
  var statusEl = document.getElementById('status');
  var iframe = document.getElementById('bodyFrame');

  if (iframe) {
    iframe.addEventListener('load', function () {
      try {
        var h = iframe.contentWindow.document.documentElement.scrollHeight;
        iframe.style.height = Math.max(h + 20, 200) + 'px';
      } catch (e) {}
    });
  }

  btn.addEventListener('click', function () {
    var text = textarea.value.trim();
    if (!text) {
      statusEl.textContent = 'Write a reply first.';
      statusEl.className = 'status err';
      return;
    }
    btn.disabled = true;
    statusEl.textContent = 'Sending…';
    statusEl.className = 'status';

    fetch(window.location.pathname, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ uid: uid, exp: exp, sig: sig, body: text })
    })
      .then(function (res) { return res.json().then(function (data) { return { ok: res.ok, data: data }; }); })
      .then(function (result) {
        if (result.ok && result.data.success) {
          statusEl.textContent = 'Reply sent.';
          statusEl.className = 'status ok';
          textarea.value = '';
          btn.disabled = false;
        } else {
          statusEl.textContent = result.data.message || 'Could not send reply.';
          statusEl.className = 'status err';
          btn.disabled = false;
        }
      })
      .catch(function () {
        statusEl.textContent = 'Network error — please try again.';
        statusEl.className = 'status err';
        btn.disabled = false;
      });
  });
})();
</script>
</body>
</html>

