<?php
/**
 * Report User Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
$db = getDatabaseConnection();
$data = getJsonInput();

$reportedUserId = (int)($data["reported_user_id"] ?? 0);
$callId = (int)($data["call_id"] ?? 0);
$reason = trim($data["reason"] ?? "");
$description = trim($data["description"] ?? "");

$errors = [];
if (!$reportedUserId) $errors["reported_user_id"] = "Reported user ID is required.";
if (!$callId) $errors["call_id"] = "Call ID is required.";
if (empty($reason)) $errors["reason"] = "Reason for report is required.";
if (empty($description)) $errors["description"] = "Description is required.";

if (!empty($errors)) {
    sendValidationError("Validation failed.", $errors);
}

try {
    $db->beginTransaction();

    // Check if the call exists and is completed
    $stmt = $db->prepare("SELECT * FROM video_calls WHERE id = ? AND status = 'completed'");
    $stmt->execute([$callId]);
    $call = $stmt->fetch();

    if (!$call) {
        $db->rollBack();
        sendError("Completed call not found.", 404);
    }

    // Ensure the reporting user was part of the call
    if ($user["id"] !== $call["client_id"] && $user["id"] !== $call["influencer_id"]) {
        $db->rollBack();
        sendError("You can only report users from calls you participated in.", 403);
    }

    // Ensure the reported user was part of the call
    if ($reportedUserId !== $call["client_id"] && $reportedUserId !== $call["influencer_id"]) {
        $db->rollBack();
        sendError("The reported user was not part of this call.", 403);
    }

    // Prevent self-reporting
    if ($reportedUserId === $user["id"]) {
        $db->rollBack();
        sendError("You cannot report yourself.", 400);
    }

    // Check for duplicate reports for this call by this user
    $stmt = $db->prepare("SELECT id FROM reports WHERE reporter_id = ? AND call_id = ?");
    $stmt->execute([$user["id"], $callId]);
    if ($stmt->fetch()) {
        $db->rollBack();
        sendError("You have already reported this call.", 409);
    }

    // Store the report
    $stmt = $db->prepare("INSERT INTO reports (reporter_id, reported_user_id, call_id, reason, description, status) VALUES (?, ?, ?, ?, ?, 'pending')");
    $stmt->execute([$user["id"], $reportedUserId, $callId, $reason, $description]);

    // Create admin notification
    $stmt = $db->prepare("INSERT INTO notifications (user_id, title, body, type, created_at) VALUES (?, ?, ?, ?, NOW())");
    $stmt->execute([
        1, // Assuming admin user ID is 1, or fetch dynamically
        "New User Report",
        "User " . $user["mystery_name"] . " reported user " . $reportedUserId . " for call " . $callId . ". Reason: " . $reason,
        "admin_report"
    ]);

    $db->commit();

    sendResponse(true, "User reported successfully. An admin will review it shortly.");

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Report User Error: " . $e->getMessage());
    sendError("Failed to submit report.");
}
