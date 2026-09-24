<?php
/**
 * Admin Call Minute Cost Management Endpoint
 *
 * Lets the admin define coin cost tiers by call minute, e.g.
 * "1 minute = 10 coins", "12 minutes = 22 coins". The app bills calls
 * using the cheapest coins-per-minute tier here (see call/start.php and
 * influencer/details.php, which read this table).
 *
 * Upload this file to: /api/admin/call-minute-costs.php
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$action = $_GET["action"] ?? "list";
$costId = (int) ($_GET["cost_id"] ?? 0);

try {
    switch ($action) {

        case "list":
            $stmt = $db->prepare("SELECT * FROM call_minute_costs ORDER BY display_order ASC, minutes ASC");
            $stmt->execute();
            $costs = $stmt->fetchAll();
            sendResponse(true, "Call minute costs retrieved successfully.", ["costs" => $costs]);
            break;

        case "create":
            $data = getJsonInput();

            $minutes      = (int)   ($data["minutes"]       ?? 0);
            $coinCost     = (float) ($data["coin_cost"]     ?? 0);
            $displayOrder = (int)   ($data["display_order"] ?? 0);

            if ($minutes <= 0) {
                sendValidationError("Minutes must be greater than zero.");
            }
            if ($coinCost <= 0) {
                sendValidationError("Coin cost must be greater than zero.");
            }

            $stmt = $db->prepare("SELECT id FROM call_minute_costs WHERE minutes = ?");
            $stmt->execute([$minutes]);
            if ($stmt->fetch()) {
                sendValidationError("A cost for $minutes minute(s) already exists. Edit it instead.");
            }

            $stmt = $db->prepare("
                INSERT INTO call_minute_costs (minutes, coin_cost, display_order)
                VALUES (?, ?, ?)
            ");
            $stmt->execute([$minutes, $coinCost, $displayOrder]);

            sendResponse(true, "Call minute cost created successfully.", ["cost_id" => (int) $db->lastInsertId()]);
            break;

        case "update":
            if (!$costId) sendValidationError("Cost ID is required.");

            $data = getJsonInput();

            $updateFields = [];
            $params       = [];

            if (isset($data["minutes"])) {
                $minutes = (int) $data["minutes"];
                if ($minutes <= 0) sendValidationError("Minutes must be greater than zero.");

                $stmt = $db->prepare("SELECT id FROM call_minute_costs WHERE minutes = ? AND id != ?");
                $stmt->execute([$minutes, $costId]);
                if ($stmt->fetch()) sendValidationError("A cost for $minutes minute(s) already exists.");

                $updateFields[] = "minutes = ?";
                $params[]       = $minutes;
            }
            if (isset($data["coin_cost"])) {
                $coinCost = (float) $data["coin_cost"];
                if ($coinCost <= 0) sendValidationError("Coin cost must be greater than zero.");
                $updateFields[] = "coin_cost = ?";
                $params[]       = $coinCost;
            }
            if (isset($data["display_order"])) {
                $updateFields[] = "display_order = ?";
                $params[]       = (int) $data["display_order"];
            }
            if (isset($data["is_active"])) {
                $updateFields[] = "is_active = ?";
                $params[]       = (bool) $data["is_active"];
            }

            if (empty($updateFields)) {
                sendValidationError("No fields provided for update.");
            }

            $params[] = $costId;
            $stmt = $db->prepare("UPDATE call_minute_costs SET " . implode(", ", $updateFields) . " WHERE id = ?");
            $stmt->execute($params);

            if ($stmt->rowCount() === 0) sendError("Call minute cost not found.", 404);

            sendResponse(true, "Call minute cost updated successfully.");
            break;

        case "enable":
        case "disable":
            if (!$costId) sendValidationError("Cost ID is required.");

            $isActive = ($action === "enable");

            $stmt = $db->prepare("UPDATE call_minute_costs SET is_active = ? WHERE id = ?");
            $stmt->execute([$isActive, $costId]);

            if ($stmt->rowCount() === 0) sendError("Call minute cost not found.", 404);

            sendResponse(true, "Call minute cost " . ($isActive ? "enabled" : "disabled") . ".");
            break;

        case "delete":
            if (!$costId) sendValidationError("Cost ID is required.");

            $stmt = $db->prepare("DELETE FROM call_minute_costs WHERE id = ?");
            $stmt->execute([$costId]);

            if ($stmt->rowCount() === 0) sendError("Call minute cost not found.", 404);

            sendResponse(true, "Call minute cost deleted successfully.");
            break;

        default:
            sendError("Invalid action.", 400);
            break;
    }

} catch (Exception $e) {
    error_log("Admin Call Minute Cost Management Error: " . $e->getMessage());
    sendError("An error occurred during call minute cost management.");
}
