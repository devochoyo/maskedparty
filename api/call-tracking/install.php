<?php
/**
 * Call Tracking - Table Installer
 *
 * Creates the `call_tracking` table if it doesn't already exist. Safe to
 * run more than once (CREATE TABLE IF NOT EXISTS). Visit this file once in
 * your browser (or hit it once with Postman/cURL) after uploading this
 * folder, then you never need to touch it again.
 *
 *   GET/POST https://yourdomain.com/api/call-tracking/install.php
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';

$db = getDatabaseConnection();

try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `call_tracking` (
          `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `call_id`          INT NOT NULL,

          `influencer_id`    INT NOT NULL,
          `influencer_name`  VARCHAR(191) NOT NULL,

          `client_id`        INT NOT NULL,
          `client_name`      VARCHAR(191) NOT NULL,

          `ended_by_role`    ENUM('client', 'influencer', 'system') NOT NULL,
          `ended_by_user_id` INT NULL,
          `ended_by_name`    VARCHAR(191) NOT NULL,

          `duration_seconds` INT UNSIGNED NOT NULL DEFAULT 0,

          `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

          PRIMARY KEY (`id`),
          UNIQUE KEY `uniq_call_tracking_call_id` (`call_id`),
          KEY `idx_call_tracking_influencer` (`influencer_id`),
          KEY `idx_call_tracking_client` (`client_id`),
          KEY `idx_call_tracking_created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    sendResponse(true, 'call_tracking table is ready.');

} catch (Exception $e) {
    error_log("Call Tracking Install Error: " . $e->getMessage());
    sendError('Failed to create call_tracking table.');
}
