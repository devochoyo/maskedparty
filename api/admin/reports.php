<?php
/**
 * Admin Report Management Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$action   = $_GET["action"]    ?? "list";
$reportId = (int) ($_GET["report_id"] ?? 0);

// Allowed values for the list status filter
$allowedStatusFilters = ["pending", "resolved", "dismissed", "all"];

try {
    switch ($action) {

        case "list":
            $statusFilter = $_GET["status"] ?? "pending";
            $page         = max(1, (int) ($_GET["page"] ?? 1));
            $limit        = 20;
            $offset       = ($page - 1) * $limit;

            if (!in_array($statusFilter, $allowedStatusFilters, true)) sendValidationError("Invalid status filter.");

            $query  = "
                SELECT r.id, r.reason, r.description, r.status, r.created_at, r.call_id,
                       u_reporter.mystery_name AS reporter_name,
                       u_reported.mystery_name AS reported_name
                FROM reports r
                JOIN users u_reporter ON r.reporter_id   = u_reporter.id
                JOIN users u_reported ON r.reported_user_id = u_reported.id
            ";
            $params = [];

            if ($statusFilter !== "all") {
                $query   .= " WHERE r.status = ?";
                $params[] = $statusFilter;
            }

            $query   .= " ORDER BY r.created_at DESC LIMIT ? OFFSET ?";
            $params[] = $limit;
            $params[] = $offset;

            $stmt = $db->prepare($query);
            $stmt->execute($params);
            $reports = $stmt->fetchAll();

            sendResponse(true, "Reports retrieved successfully.", [
                "reports" => $reports,
                "page"    => $page,
                "limit"   => $limit,
            ]);
            break;

        case "details":
            if (!$reportId) sendValidationError("Report ID is required.");

            $stmt = $db->prepare("
                SELECT r.*,
                       u_reporter.mystery_name AS reporter_name,
                       u_reported.mystery_name AS reported_name
                FROM reports r
                JOIN users u_reporter ON r.reporter_id      = u_reporter.id
                JOIN users u_reported ON r.reported_user_id = u_reported.id
                WHERE r.id = ?
            ");
            $stmt->execute([$reportId]);
            $reportDetails = $stmt->fetch();

            if (!$reportDetails) sendError("Report not found.", 404);

            sendResponse(true, "Report details retrieved.", $reportDetails);
            break;

        case "dismiss":
            if (!$reportId) sendValidationError("Report ID is required.");

            $body      = getJsonBody();
            $adminNote = trim($body["admin_note"] ?? "");

            $stmt = $db->prepare("UPDATE reports SET status = 'dismissed', admin_note = ? WHERE id = ?");
            $stmt->execute([$adminNote, $reportId]);

            if ($stmt->rowCount() === 0) sendError("Report not found.", 404);

            sendResponse(true, "Report dismissed.");
            break;

        case "suspend_user":
        case "ban_user":
            if (!$reportId) sendValidationError("Report ID is required.");

            // Fetch the report to get the user to act on
            $stmt = $db->prepare("SELECT reported_user_id FROM reports WHERE id = ?");
            $stmt->execute([$reportId]);
            $report = $stmt->fetch();

            if (!$report) sendError("Report not found.", 404);

            $newStatus = ($action === "suspend_user") ? "suspended" : "banned";

            // Update the reported user's account status
            $stmt = $db->prepare("UPDATE users SET status = ? WHERE id = ?");
            $stmt->execute([$newStatus, $report["reported_user_id"]]);

            // Mark the report as resolved
            $stmt = $db->prepare("UPDATE reports SET status = 'resolved', admin_note = ? WHERE id = ?");
            $stmt->execute(["User " . $newStatus . ".", $reportId]);

            sendResponse(true, "Reported user status updated to {$newStatus}.");
            break;

        default:
            sendError("Invalid action.", 400);
            break;
    }

} catch (Exception $e) {
    error_log("Admin Report Management Error: " . $e->getMessage());
    sendError("An error occurred during report management.");
}
