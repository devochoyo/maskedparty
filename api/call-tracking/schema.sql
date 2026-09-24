-- ============================================================================
-- call_tracking table
-- ============================================================================
-- One row per completed video call, recording who ended it and how long the
-- call lasted. Written automatically whenever a call is settled (either the
-- client/influencer manually ends it, or it times out and auto-ends).
--
-- You do NOT have to run this file by hand: install.php (in this same
-- folder) creates the table automatically the first time it's hit, using
-- the exact same definition below. This .sql file is provided as a
-- reference / for anyone who prefers to run it directly in phpMyAdmin.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `call_tracking` (
  `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `call_id`          INT NOT NULL,

  `influencer_id`    INT NOT NULL,
  `influencer_name`  VARCHAR(191) NOT NULL,

  `client_id`        INT NOT NULL,
  `client_name`      VARCHAR(191) NOT NULL,

  -- Who ended the call: 'client', 'influencer', or 'system' (auto/timeout).
  `ended_by_role`    ENUM('client', 'influencer', 'system') NOT NULL,
  `ended_by_user_id` INT NULL,
  `ended_by_name`    VARCHAR(191) NOT NULL,

  -- Time spent on the call before it ended, in seconds.
  `duration_seconds` INT UNSIGNED NOT NULL DEFAULT 0,

  `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_call_tracking_call_id` (`call_id`),
  KEY `idx_call_tracking_influencer` (`influencer_id`),
  KEY `idx_call_tracking_client` (`client_id`),
  KEY `idx_call_tracking_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
