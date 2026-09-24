<?php
/**
 * supportMailFunctions.php — email notifications for the support system.
 *
 * Kept separate from mailFunctions.php (which is OTP-specific) so the
 * existing auth mail flow is never touched by this feature.
 *
 * Include via:
 *   require_once __DIR__ . '/../../mail/supportMailFunctions.php';
 */

require_once __DIR__ . '/mail.php';

/**
 * Emails every active support agent when a new ticket (conversation) is
 * created by a customer. Failures for individual agents are logged but do
 * NOT stop the loop or bubble up as an API error — email delivery is
 * best-effort and must never block the customer's message from being saved.
 *
 * @param PDO    $db
 * @param string $customerName    Display name (mystery_name) of the customer
 * @param string $messagePreview  First message text, shown in the email
 */
function notifyAllSupportAgentsNewTicket(PDO $db, string $customerName, string $messagePreview): void
{
    $stmt = $db->prepare("SELECT id, first_name, email FROM support_agents WHERE status = 'active'");
    $stmt->execute();
    $agents = $stmt->fetchAll();

    if (!$agents) {
        return;
    }

    foreach ($agents as $agent) {
        try {
            $mail = getMailer();
            $mail->addAddress($agent['email'], $agent['first_name']);
            $mail->Subject = 'New Support Ticket — ' . $customerName;
            $mail->Body    = newSupportTicketTemplate($agent['first_name'], $customerName, $messagePreview);
            $mail->AltBody = "New support ticket from {$customerName}: {$messagePreview}";
            $mail->send();
        } catch (\Exception $e) {
            mailDebugLog('NEW TICKET NOTIFY FAILED — support_agent_id=' . $agent['id'] . ': ' . $e->getMessage());
        }
    }
}

/**
 * HTML template for the "new ticket" notification email sent to agents.
 * Reuses baseEmailTemplate() from mailTemplate.php for consistent branding.
 */
function newSupportTicketTemplate(string $agentFirstName, string $customerName, string $preview): string
{
    require_once __DIR__ . '/mailTemplate.php';

    $safeAgent    = htmlspecialchars($agentFirstName, ENT_QUOTES, 'UTF-8');
    $safeCustomer = htmlspecialchars($customerName, ENT_QUOTES, 'UTF-8');
    $safePreview  = htmlspecialchars(mb_substr($preview, 0, 200), ENT_QUOTES, 'UTF-8');

    $body = <<<HTML
    <h1 style="margin:0 0 10px;font-size:22px;font-weight:800;color:#111827;line-height:1.2;">
      New Support Ticket
    </h1>
    <p style="margin:0 0 20px;font-size:15px;color:#6b7280;line-height:1.7;">
      Hi {$safeAgent}, <strong style="color:#111827;">{$safeCustomer}</strong> just reached out to customer support.
    </p>

    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
      <tr>
        <td style="background:#faf8ff;border:1.5px solid #e0d0ff;border-radius:12px;padding:18px 20px;">
          <p style="margin:0;font-size:14px;color:#374151;line-height:1.6;font-style:italic;">
            "{$safePreview}"
          </p>
        </td>
      </tr>
    </table>

    <p style="margin:0;font-size:13px;color:#9ca3af;line-height:1.6;">
      Open the support app to view and attend to this ticket. Once another agent claims it, it will no longer be available to you.
    </p>
HTML;

    return baseEmailTemplate("New support ticket from {$customerName}", $body);
}
