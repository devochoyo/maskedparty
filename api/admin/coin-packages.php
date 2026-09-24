<?php
/**
 * Admin Coin Package Management Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$action    = $_GET["action"]     ?? "list";
$packageId = (int) ($_GET["package_id"] ?? 0);

try {
    switch ($action) {

        case "list":
            $stmt = $db->prepare("SELECT * FROM coin_packages ORDER BY display_order ASC");
            $stmt->execute();
            $packages = $stmt->fetchAll();
            sendResponse(true, "Coin packages retrieved successfully.", ["packages" => $packages]);
            break;

        case "create":
            $data = getJsonInput();

            $name         = trim($data["name"]              ?? "");
            $price        = (float) ($data["price"]         ?? 0);
            $coins        = (int)   ($data["coins"]         ?? 0);
            $minutes      = (int)   ($data["minutes"]       ?? 0);
            $isPopular    = (bool)  ($data["is_popular"]    ?? false);
            $isBestValue  = (bool)  ($data["is_best_value"] ?? false);
            $displayOrder = (int)   ($data["display_order"] ?? 0);

            if ($name === "") {
                sendValidationError("Package name is required.");
            }
            if ($price <= 0) {
                sendValidationError("Price must be greater than zero.");
            }
            if ($coins <= 0) {
                sendValidationError("Coins must be greater than zero.");
            }
            if ($minutes <= 0) {
                sendValidationError("Minutes must be greater than zero.");
            }

            $stmt = $db->prepare("
                INSERT INTO coin_packages (name, price, coins, minutes, is_popular, is_best_value, display_order)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$name, $price, $coins, $minutes, $isPopular, $isBestValue, $displayOrder]);

            sendResponse(true, "Coin package created successfully.", ["package_id" => (int) $db->lastInsertId()]);
            break;

        case "update":
            if (!$packageId) sendValidationError("Package ID is required.");

            $data = getJsonInput();

            $updateFields = [];
            $params       = [];

            if (isset($data["name"])) {
                $name = trim($data["name"]);
                if ($name === "") sendValidationError("Package name cannot be empty.");
                $updateFields[] = "name = ?";
                $params[]       = $name;
            }
            if (isset($data["price"])) {
                $price = (float) $data["price"];
                if ($price <= 0) sendValidationError("Price must be greater than zero.");
                $updateFields[] = "price = ?";
                $params[]       = $price;
            }
            if (isset($data["coins"])) {
                $coins = (int) $data["coins"];
                if ($coins <= 0) sendValidationError("Coins must be greater than zero.");
                $updateFields[] = "coins = ?";
                $params[]       = $coins;
            }
            if (isset($data["minutes"])) {
                $minutes = (int) $data["minutes"];
                if ($minutes <= 0) sendValidationError("Minutes must be greater than zero.");
                $updateFields[] = "minutes = ?";
                $params[]       = $minutes;
            }
            if (isset($data["is_popular"])) {
                $updateFields[] = "is_popular = ?";
                $params[]       = (bool) $data["is_popular"];
            }
            if (isset($data["is_best_value"])) {
                $updateFields[] = "is_best_value = ?";
                $params[]       = (bool) $data["is_best_value"];
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

            $params[] = $packageId;
            $stmt = $db->prepare("UPDATE coin_packages SET " . implode(", ", $updateFields) . " WHERE id = ?");
            $stmt->execute($params);

            if ($stmt->rowCount() === 0) sendError("Coin package not found.", 404);

            sendResponse(true, "Coin package updated successfully.");
            break;

        case "enable":
        case "disable":
            if (!$packageId) sendValidationError("Package ID is required.");

            $isActive = ($action === "enable");

            $stmt = $db->prepare("UPDATE coin_packages SET is_active = ? WHERE id = ?");
            $stmt->execute([$isActive, $packageId]);

            if ($stmt->rowCount() === 0) sendError("Coin package not found.", 404);

            sendResponse(true, "Coin package " . ($isActive ? "enabled" : "disabled") . ".");
            break;

        default:
            sendError("Invalid action.", 400);
            break;
    }

} catch (Exception $e) {
    error_log("Admin Coin Package Management Error: " . $e->getMessage());
    sendError("An error occurred during coin package management.");
}
