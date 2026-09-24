<?php
/**
 * Admin Support Management Endpoint
 *
 * GET  /api/admin/support.php?action=list
 * GET  /api/admin/support.php?action=view-credentials&support_id=5
 * GET  /api/admin/support.php?action=feedback
 * GET  /api/admin/support.php?action=feedback&support_id=5
 * POST /api/admin/support.php?action=add            body: { first_name, last_name, email }
 * POST /api/admin/support.php?action=suspend&support_id=5
 * POST /api/admin/support.php?action=activate&support_id=5
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$action = $_GET["action"] ?? "list";
$supportId = (int) ($_GET["support_id"] ?? 0);

try {
    switch ($action) {

        case "add":
            $data = getJsonInput();
            $firstName = trim($data['first_name'] ?? '');
            $lastName  = trim($data['last_name'] ?? '');
            $email     = trim(strtolower($data['email'] ?? ''));

            if (empty($firstName) || empty($lastName) || empty($email)) {
                sendValidationError('First name, last name and email are required.');
            }
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                sendValidationError('A valid email address is required.');
            }

            $stmt = $db->prepare("SELECT id FROM support_agents WHERE email = ?");
            $stmt->execute([$email]);
            if ($stmt->fetch()) {
                sendError('This email address has already been added as a support representative.', 409);
            }

            $generated = generateSupportPassword($db);
            $plainPassword = $generated['plain'];
            $checksum = $generated['checksum'];

            $passwordHash = password_hash($plainPassword, PASSWORD_DEFAULT);
            $passwordEncrypted = encryptSupportPassword($plainPassword);

            $stmt = $db->prepare("
                INSERT INTO support_agents
                    (first_name, last_name, email, password_hash, password_encrypted, password_checksum, status, added_by)
                VALUES (?, ?, ?, ?, ?, ?, 'active', ?)
            ");
            $stmt->execute([$firstName, $lastName, $email, $passwordHash, $passwordEncrypted, $checksum, $user['id']]);

            $newId = (int) $db->lastInsertId();

            sendResponse(true, "This email address has been added as a customer care representative.", [
                'support_id' => $newId,
                'first_name' => $firstName,
                'last_name'  => $lastName,
                'email'      => $email,
            ], 201);
            break;

        case "list":
            $search = trim($_GET["search"] ?? "");
            $status = $_GET["status"] ?? "";
            $allowedStatuses = ["active", "suspended"];

            if ($status !== "" && !in_array($status, $allowedStatuses, true)) {
                sendValidationError("Invalid status filter.");
            }

            $query = "
                SELECT id, first_name, last_name, email, status, good_feedback_count, bad_feedback_count, created_at
                FROM support_agents WHERE 1=1
            ";
            $params = [];

            if ($search !== "") {
                $query .= " AND (email LIKE ? OR first_name LIKE ? OR last_name LIKE ?)";
                $like = "%" . $search . "%";
                $params[] = $like;
                $params[] = $like;
                $params[] = $like;
            }
            if ($status !== "") {
                $query .= " AND status = ?";
                $params[] = $status;
            }

            $query .= " ORDER BY created_at DESC";

            $stmt = $db->prepare($query);
            $stmt->execute($params);
            $agents = $stmt->fetchAll();

            foreach ($agents as &$agent) {
                $agent['id'] = (int) $agent['id'];
                $agent['good_feedback_count'] = (int) $agent['good_feedback_count'];
                $agent['bad_feedback_count']  = (int) $agent['bad_feedback_count'];
                // 5-point scale, starts at 5, -1 per bad feedback, floor 0.
                $agent['rating'] = max(0, 5 - $agent['bad_feedback_count']);
            }
            unset($agent);

            sendResponse(true, "Support agents retrieved successfully.", [
                "agents" => $agents,
            ]);
            break;

        case "view-credentials":
            if (!$supportId) sendValidationError("support_id is required.");

            $stmt = $db->prepare("SELECT id, first_name, last_name, email, password_encrypted, status FROM support_agents WHERE id = ?");
            $stmt->execute([$supportId]);
            $agent = $stmt->fetch();

            if (!$agent) sendError("Support agent not found.", 404);

            $plainPassword = decryptSupportPassword($agent['password_encrypted']);

            if ($plainPassword === false) {
                sendError("Could not decrypt credentials.", 500);
            }

            sendResponse(true, "Credentials retrieved.", [
                'support_id' => (int) $agent['id'],
                'first_name' => $agent['first_name'],
                'last_name'  => $agent['last_name'],
                'email'      => $agent['email'],
                'password'   => $plainPassword,
                'status'     => $agent['status'],
            ]);
            break;

        case "suspend":
        case "activate":
            if (!$supportId) sendValidationError("support_id is required.");

            $newStatus = $action === "suspend" ? "suspended" : "active";

            $stmt = $db->prepare("UPDATE support_agents SET status = ? WHERE id = ?");
            $stmt->execute([$newStatus, $supportId]);

            if ($stmt->rowCount() === 0) sendError("Support agent not found.", 404);

            sendResponse(true, "Support agent status updated to {$newStatus}.");
            break;

        case "feedback":
            $params = [];
            $query = "
                SELECT
                    sf.id, sf.conversation_id, sf.satisfied, sf.issue_resolved, sf.professional,
                    sf.feedback_text, sf.is_bad, sf.created_at,
                    CONCAT(sa.first_name, ' ', sa.last_name) AS agent_name,
                    sa.id AS support_agent_id,
                    u.mystery_name AS customer_name
                FROM support_feedback sf
                JOIN support_agents sa ON sf.support_agent_id = sa.id
                JOIN users u ON sf.customer_id = u.id
                WHERE 1=1
            ";

            if ($supportId) {
                $query .= " AND sf.support_agent_id = ?";
                $params[] = $supportId;
            }

            $query .= " ORDER BY sf.created_at DESC";

            $stmt = $db->prepare($query);
            $stmt->execute($params);
            $feedback = $stmt->fetchAll();

            foreach ($feedback as &$row) {
                $row['id'] = (int) $row['id'];
                $row['conversation_id'] = (int) $row['conversation_id'];
                $row['support_agent_id'] = (int) $row['support_agent_id'];
                $row['satisfied'] = (bool) $row['satisfied'];
                $row['issue_resolved'] = (bool) $row['issue_resolved'];
                $row['professional'] = (bool) $row['professional'];
                $row['is_bad'] = (bool) $row['is_bad'];
            }
            unset($row);

            sendResponse(true, "Support feedback retrieved.", [
                "feedback" => $feedback,
            ]);
            break;

        default:
            sendError("Invalid action.", 400);
            break;
    }

} catch (Exception $e) {
    error_log("Admin Support Management Error: " . $e->getMessage());
    sendError("An error occurred during support management.");
}
