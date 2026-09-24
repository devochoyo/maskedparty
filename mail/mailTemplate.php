<?php
/**
 * mailTemplate.php — HTML email templates for the authentication system.
 * Returns full HTML strings ready for PHPMailer's ->Body property.
 */

/**
 * Shared wrapper — logo/header, content slot, branded footer.
 * Responsive: fluid table widths (no fixed min-width), plus a media query
 * for mail clients that support <style> (Apple Mail, Outlook mobile, most
 * modern webmail) so padding/font-size shrink gracefully on small screens.
 */
function baseEmailTemplate(string $preheader, string $bodyHtml): string
{
    $year    = date('Y');
    $appName = defined('APP_NAME') ? APP_NAME : 'Verification Code';

    return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>{$appName}</title>
  <style>
    body, table, td { -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%; }
    img { border:0; line-height:100%; outline:none; text-decoration:none; }
    a { text-decoration:none; }

    @media screen and (max-width:480px) {
      .outer-wrapper { padding:24px 12px !important; }
      .card-header { padding:22px 20px !important; }
      .card-header .app-name { font-size:20px !important; }
      .card-body { padding:28px 20px 24px !important; }
      .card-footer { padding:16px 20px 22px !important; }
      .otp-box { padding:20px 14px !important; }
      .otp-code { font-size:26px !important; letter-spacing:6px !important; padding:14px 18px !important; }
      h1 { font-size:20px !important; }
    }
  </style>
</head>
<body style="margin:0;padding:0;background:#f4f4f6;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <!--[if mso]><table width="100%" cellpadding="0" cellspacing="0"><tr><td><![endif]-->

  <!-- preheader hidden text -->
  <div style="display:none;max-height:0;overflow:hidden;mso-hide:all;">{$preheader}</div>

  <!-- outer wrapper -->
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f6;">
    <tr>
      <td align="center" class="outer-wrapper" style="padding:40px 16px;">

        <!-- card -->
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
               style="width:100%;max-width:500px;background:#ffffff;border-radius:16px;
                      overflow:hidden;box-shadow:0 4px 32px rgba(17,24,39,0.08);">

          <!-- ─── HEADER ─── -->
          <tr>
            <td class="card-header" style="background:#FF2D87;padding:28px 32px;text-align:center;">
              <span class="app-name" style="display:inline-block;font-size:24px;font-weight:800;
                           color:#000000;letter-spacing:-0.03em;line-height:1;">
                {$appName}
              </span>
            </td>
          </tr>

          <!-- ─── BODY ─── -->
          <tr>
            <td class="card-body" style="padding:40px 36px 32px;">
              {$bodyHtml}
            </td>
          </tr>

          <!-- ─── FOOTER ─── -->
          <tr>
            <td class="card-footer" style="padding:20px 36px 28px;border-top:1px solid #e5e7eb;text-align:center;">
              <p style="margin:0;font-size:12px;color:#9ca3af;line-height:1.7;">
                &copy; {$year} {$appName}. All rights reserved.<br>
                This is an automated message — please do not reply to this email.
              </p>
            </td>
          </tr>

        </table>
        <!-- /card -->

      </td>
    </tr>
  </table>
  <!-- /outer wrapper -->

  <!--[if mso]></td></tr></table><![endif]-->
</body>
</html>
HTML;
}

/**
 * Email-verification template — 6-digit OTP sent after registration.
 * The code is rendered as ONE rectangular container (not one box per
 * digit), so it never overflows or wraps oddly on narrow screens.
 *
 * @param string $name  Display name of the recipient.
 * @param string $code  The 6-digit code.
 * @param int    $ttlMinutes Expiry in minutes shown in the email body.
 */
function emailVerificationTemplate(string $name, string $code, int $ttlMinutes = 6): string
{
    $safeName = htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
    $safeCode = htmlspecialchars($code, ENT_QUOTES, 'UTF-8');

    $body = <<<HTML
    <h1 style="margin:0 0 10px;font-size:24px;font-weight:800;color:#111827;line-height:1.2;">
      Verify your email address
    </h1>
    <p style="margin:0 0 28px;font-size:15px;color:#6b7280;line-height:1.7;">
      Hi <strong style="color:#111827;">{$safeName}</strong>, welcome aboard!<br>
      Use the one-time code below to verify your email and activate your account.
    </p>

    <!-- OTP box: single rectangular container holding the whole code -->
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:28px;">
      <tr>
        <td align="center" class="otp-box"
            style="background:#faf8ff;border:1.5px solid #e0d0ff;border-radius:14px;
                   padding:28px 20px;">
          <span class="otp-code" style="display:inline-block;background:#f3eeff;border:2px solid #e0d0ff;
                       border-radius:10px;padding:16px 28px;font-size:32px;font-weight:800;
                       color:#6B2CF5;letter-spacing:10px;font-family:'Courier New',monospace;
                       max-width:100%;">{$safeCode}</span>
          <p style="margin:16px 0 0;font-size:13px;color:#9ca3af;">
            Enter this code in the app to confirm your email
          </p>
        </td>
      </tr>
    </table>

    <!-- warning block -->
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td style="background:#fff8f0;border-left:4px solid #f59e0b;border-radius:0 8px 8px 0;
                   padding:14px 16px;">
          <p style="margin:0;font-size:13px;color:#92400e;line-height:1.6;">
            ⏱ This code expires in <strong>{$ttlMinutes} minutes</strong>.<br>
            If you did not create an account, you can safely ignore this email.
          </p>
        </td>
      </tr>
    </table>
HTML;

    return baseEmailTemplate(
        "Your verification code is {$code} — expires in {$ttlMinutes} minutes",
        $body
    );
}

/**
 * Resend OTP template (same visual, tweaked copy).
 */
function resendVerificationTemplate(string $name, string $code, int $ttlMinutes = 6): string
{
    // Delegates to the same template — copy difference is minimal.
    return emailVerificationTemplate($name, $code, $ttlMinutes);
}