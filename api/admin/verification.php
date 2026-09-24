<?php
/**
 * Admin Verification Management Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$action       = $_GET["action"]        ?? "list";
$influencerId = (int) ($_GET["influencer_id"] ?? 0);

// Allowed values for the list status filter
$allowedStatusFilters = ["pending", "approved", "rejected"];

try {
    switch ($action) {

        case "list":
            $statusFilter = $_GET["status"] ?? "pending";
            $page         = max(1, (int) ($_GET["page"] ?? 1));
            $limit        = 20;
            $offset       = ($page - 1) * $limit;

            if (!in_array($statusFilter, $allowedStatusFilters, true)) sendValidationError("Invalid status filter.");

            $stmt = $db->prepare("
                SELECT u.id, u.mystery_name, u.email,
                       ip.government_id_url, ip.selfie_url, ip.verification_video_url,
                       ip.verification_status, ip.biography
                FROM users u
                JOIN influencer_profiles ip ON u.id = ip.user_id
                WHERE ip.verification_status = ?
                ORDER BY u.created_at ASC
                LIMIT ? OFFSET ?
            ");
            $stmt->execute([$statusFilter, $limit, $offset]);
            $verifications = $stmt->fetchAll();

            // Verification documents are private (government ID, selfie,
            // video). They are never exposed as a direct public URL — the
            // uploads/verification/ folder is blocked at the web server
            // level. Instead, point the panel at admin/verification-file.php,
            // a session-authenticated proxy page (img/video tags can't send
            // a Bearer header, but they do send the admin's session cookie).
            // That page in turn calls this API's sibling endpoint,
            // api/admin/verification-file.php, using the same server-side
            // Bearer token admin/proxy.php already uses for JSON calls.
            foreach ($verifications as &$v) {
                foreach (['government_id_url', 'selfie_url', 'verification_video_url'] as $field) {
                    if (!empty($v[$field])) {
                        $v[$field] = '/admin/verification-file.php'
                            . '?influencer_id=' . urlencode($v['id'])
                            . '&field=' . urlencode($field);
                    } else {
                        $v[$field] = null;
                    }
                }
            }
            unset($v);

            sendResponse(true, "Verification requests retrieved successfully.", [
                "verifications" => $verifications,
                "page"          => $page,
                "limit"         => $limit,
            ]);
            break;

        case "approve":
        case "reject":
        case "request_resubmission":
            if (!$influencerId) sendValidationError("Influencer ID is required.");
            $body      = getJsonBody();
            $adminNote = trim($body["admin_note"] ?? "");

            $db->beginTransaction();

            $stmt = $db->prepare("SELECT * FROM influencer_profiles WHERE user_id = ? AND verification_status = 'pending'");
            $stmt->execute([$influencerId]);
            $profile = $stmt->fetch();

            if (!$profile) {
                $db->rollBack();
                sendError("Pending verification request not found for this influencer.", 404);
            }

            // Determine the new status and notification content based on the action
            if ($action === "approve") {
                // Guard against approving a profile that never actually
                // submitted (or is missing) one or more required documents.
                if (
                    empty($profile['government_id_url']) ||
                    empty($profile['selfie_url']) ||
                    empty($profile['verification_video_url'])
                ) {
                    $db->rollBack();
                    sendError("Cannot approve — one or more verification documents are missing.", 400);
                }

                $newStatus         = "approved";
                $notificationTitle = "Verification Approved";
                $notificationBody  = "Congratulations! Your influencer profile has been approved.";

                // Activate the user account if it was awaiting verification
                $stmt = $db->prepare("UPDATE users SET status = 'active' WHERE id = ? AND status = 'pending_verification'");
                $stmt->execute([$influencerId]);

            } elseif ($action === "reject") {
                $newStatus         = "rejected";
                $notificationTitle = "Verification Rejected";
                $notificationBody  = "Unfortunately, your influencer verification request has been rejected. Reason: " . $adminNote;

            } else {
                // request_resubmission — keep status as pending, just add the admin note
                $newStatus         = "pending";
                $notificationTitle = "Verification Resubmission Requested";
                $notificationBody  = "Your influencer verification requires resubmission. Reason: " . $adminNote;
            }

            $stmt = $db->prepare("UPDATE influencer_profiles SET verification_status = ?, admin_note = ? WHERE user_id = ?");
            $stmt->execute([$newStatus, $adminNote, $influencerId]);

            // Notify the influencer
            $stmt = $db->prepare("INSERT INTO notifications (user_id, title, body, type, created_at) VALUES (?, ?, ?, 'verification_status', NOW())");
            $stmt->execute([$influencerId, $notificationTitle, $notificationBody]);

            $db->commit();
            sendResponse(true, "Influencer verification status updated to {$newStatus}.");
            break;

        default:
            sendError("Invalid action.", 400);
            break;
    }

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Admin Verification Management Error: " . $e->getMessage());
    sendError("An error occurred during verification management.");
}
