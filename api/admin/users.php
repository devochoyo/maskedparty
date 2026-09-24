<?php
/**
 * Admin User Management Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$action = $_GET["action"] ?? "list";
$userId = (int) ($_GET["user_id"] ?? 0);

// Allowed values for status filter to avoid open-ended string injection via the query builder
$allowedRoles    = ["client", "influencer", "admin"];
$allowedStatuses = ["active", "suspended", "banned", "pending_verification"];

try {
    switch ($action) {

        case "list":
            $search = trim($_GET["search"] ?? "");
            $role   = $_GET["role"]   ?? "";
            $status = $_GET["status"] ?? "";
            $page   = max(1, (int) ($_GET["page"] ?? 1));
            $limit  = 20;
            $offset = ($page - 1) * $limit;

            // Reject unknown role/status values early so no garbage reaches the DB
            if ($role   !== "" && !in_array($role,   $allowedRoles,    true)) sendValidationError("Invalid role filter.");
            if ($status !== "" && !in_array($status, $allowedStatuses, true)) sendValidationError("Invalid status filter.");

            $query  = "SELECT id, email, mystery_name, full_name, role, country_name, status, created_at FROM users WHERE 1=1";
            $params = [];

            if ($search !== "") {
                $query   .= " AND (email LIKE ? OR mystery_name LIKE ? OR full_name LIKE ?)";
                $like     = "%" . $search . "%";
                $params[] = $like;
                $params[] = $like;
                $params[] = $like;
            }
            if ($role !== "") {
                $query   .= " AND role = ?";
                $params[] = $role;
            }
            if ($status !== "") {
                $query   .= " AND status = ?";
                $params[] = $status;
            }

            $query   .= " ORDER BY created_at DESC LIMIT ? OFFSET ?";
            $params[] = $limit;
            $params[] = $offset;

            $stmt = $db->prepare($query);
            $stmt->execute($params);
            $users = $stmt->fetchAll();

            sendResponse(true, "Users retrieved successfully.", [
                "users" => $users,
                "page"  => $page,
                "limit" => $limit,
            ]);
            break;

        case "details":
            if (!$userId) sendValidationError("User ID is required.");

            $stmt = $db->prepare("
                SELECT u.id, u.email, u.mystery_name, u.full_name, u.role, u.country_name, u.status, u.created_at,
                       w.balance, w.total_purchased, w.total_spent, w.escrow_balance
                FROM users u
                JOIN wallets w ON u.id = w.user_id
                WHERE u.id = ?
            ");
            $stmt->execute([$userId]);
            $userDetails = $stmt->fetch();

            if (!$userDetails) sendError("User not found.", 404);

            sendResponse(true, "User details retrieved.", $userDetails);
            break;

        case "suspend":
        case "activate":
        case "ban":
            if (!$userId) sendValidationError("User ID is required.");

            // Prevent an admin from changing their own status
            if ($userId === (int) $user["id"]) sendError("You cannot change your own account status.", 403);

            $newStatus = match ($action) {
                "suspend"  => "suspended",
                "activate" => "active",
                "ban"      => "banned",
            };

            $stmt = $db->prepare("UPDATE users SET status = ? WHERE id = ?");
            $stmt->execute([$newStatus, $userId]);

            if ($stmt->rowCount() === 0) sendError("User not found.", 404);

            sendResponse(true, "User status updated to {$newStatus}.");
            break;

        default:
            sendError("Invalid action.", 400);
            break;
    }

} catch (Exception $e) {
    error_log("Admin User Management Error: " . $e->getMessage());
    sendError("An error occurred during user management.");
}
