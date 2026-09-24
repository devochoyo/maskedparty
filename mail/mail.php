<?php
/**
 * mail.php — SMTP / PHPMailer bootstrap.
 * Include via sendMail.php; do not include directly.
 *
 * PHPMailer lives at: <project_root>/vendor/phpmailer/phpmailer/src/
 * SMTP keys read from config/config.php constants (already loaded by the time
 * any authentication endpoint runs).
 *
 * Required constants in config/config.php:
 *   SMTP_HOST, SMTP_PORT, SMTP_SECURE (ssl|tls), SMTP_USER, SMTP_PASS,
 *   SMTP_FROM, SMTP_FROM_NAME
 */

$_phpMailerSrc = dirname(__DIR__) . '/vendor/phpmailer/phpmailer/src/';
require_once $_phpMailerSrc . 'Exception.php';
require_once $_phpMailerSrc . 'PHPMailer.php';
require_once $_phpMailerSrc . 'SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

/**
 * Builds and returns a configured PHPMailer instance ready to send.
 * Callers add addresses, Subject, Body then call ->send().
 */
function getMailer(): PHPMailer
{
    $mail = new PHPMailer(true);

    $mail->isSMTP();
    $mail->Host     = defined('SMTP_HOST') ? SMTP_HOST : '';
    $mail->SMTPAuth = true;
    $mail->Username = defined('SMTP_USER') ? SMTP_USER : '';
    $mail->Password = defined('SMTP_PASS') ? SMTP_PASS : '';
    $mail->Port     = defined('SMTP_PORT') ? (int) SMTP_PORT : 587;

    $secure           = defined('SMTP_SECURE') ? strtolower(SMTP_SECURE) : 'tls';
    $mail->SMTPSecure = ($secure === 'ssl')
        ? PHPMailer::ENCRYPTION_SMTPS
        : PHPMailer::ENCRYPTION_STARTTLS;

    $mail->setFrom(
        defined('SMTP_FROM')      ? SMTP_FROM      : 'no-reply@example.com',
        defined('SMTP_FROM_NAME') ? SMTP_FROM_NAME : 'App'
    );

    $mail->isHTML(true);
    $mail->CharSet = 'UTF-8';
    $mail->Timeout = 15;

    // Optional verbose SMTP logging for debugging "success but never
    // arrives" issues. Enable by setting SMTP_DEBUG=1 in your .env, then
    // trigger a send/resend and check mail/error.log for the full SMTP
    // conversation — this shows the real response from your mail server
    // (e.g. "250 OK" vs a rejection/deferral you weren't seeing).
    // Turn this back off in production once diagnosed (verbose SMTP
    // logs can include header data you don't want kept long-term).
    if (defined('SMTP_DEBUG') && SMTP_DEBUG) {
        $mail->SMTPDebug   = 2; // client -> server and server -> client messages
        $mail->Debugoutput = function ($str, $level) {
            mailDebugLog('[SMTP DEBUG] ' . trim($str));
        };
    }

    return $mail;
}

/**
 * Appends a timestamped line to mail/error.log (this folder, not the
 * shared PHP/server error log), so SMTP debug output is easy to find
 * without needing server-level log access.
 */
function mailDebugLog(string $line): void
{
    $logFile = __DIR__ . '/error.log';
    $entry   = '[' . date('Y-m-d H:i:s') . '] ' . $line . PHP_EOL;
    file_put_contents($logFile, $entry, FILE_APPEND | LOCK_EX);
}
