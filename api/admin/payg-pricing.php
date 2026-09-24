<?php
/**
 * Admin Pay As You Go pricing.
 *
 * GET  ?action=list
 * POST ?action=update  { per_minute, per_second, is_active? }
 */
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireAdmin($user);
$db = getDatabaseConnection();
$action = $_GET['action'] ?? 'list';

try {
    if ($action === 'list') {
        $stmt = $db->query("SELECT id, per_minute, per_second, is_active, updated_at FROM payg_call_pricing WHERE id = 1 LIMIT 1");
        $row = $stmt->fetch();
        if (!$row) sendError('Pay As You Go pricing has not been configured.', 404);

        sendResponse(true, 'Pay As You Go pricing retrieved successfully.', [
            'pricing' => [
                'per_minute' => (float)$row['per_minute'],
                'per_second' => (float)$row['per_second'],
                'is_active' => (int)$row['is_active'],
                'updated_at' => $row['updated_at'],
            ],
        ]);
    }

    if ($action === 'update') {
        $data = getJsonInput();
        $perMinute = isset($data['per_minute']) ? (float)$data['per_minute'] : null;
        $perSecond = isset($data['per_second']) ? (float)$data['per_second'] : null;

        if ($perMinute === null || $perMinute <= 0) {
            sendValidationError('Per-minute coin cost must be greater than zero.');
        }
        if ($perSecond === null || $perSecond <= 0) {
            sendValidationError('Per-second coin cost must be greater than zero.');
        }

        $fields = ['per_minute = ?', 'per_second = ?'];
        $params = [$perMinute, $perSecond];

        if (isset($data['is_active'])) {
            $fields[] = 'is_active = ?';
            $params[] = (int)(bool)$data['is_active'];
        }

        $params[] = 1;
        $stmt = $db->prepare("UPDATE payg_call_pricing SET " . implode(', ', $fields) . " WHERE id = ?");
        $stmt->execute($params);

        sendResponse(true, 'Pay As You Go pricing updated successfully.');
    }

    sendError('Invalid action.', 400);
} catch (Exception $e) {
    error_log("Admin Pay As You Go Pricing Error: " . $e->getMessage());
    sendError('An error occurred while updating Pay As You Go pricing.');
}
