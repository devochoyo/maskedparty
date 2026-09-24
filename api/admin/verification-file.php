<?php
/**
 * GET /api/admin/verification-file.php?influencer_id=123&field=selfie_url
 *
 * Streams a single verification document (government ID, selfie, or
 * verification video) to an authenticated admin only.
 *
 * These files live under uploads/verification/, which is blocked from
 * direct web access (see uploads/verification/.htaccess). This endpoint
 * is the only way to view them — it checks the admin's Bearer token,
 * looks up the stored relative path from the DB (never trusts a path
 * from the client), and streams the file with the correct headers.
 *
 * Query params:
 *   influencer_id  (int)    required — users.id of the influencer
 *   field          (string) required — one of:
 *                             government_id_url | selfie_url | verification_video_url
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$influencerId  = (int) ($_GET["influencer_id"] ?? 0);
$field         = $_GET["field"] ?? "";

$allowedFields = ["government_id_url", "selfie_url", "verification_video_url"];

if (!$influencerId || !in_array($field, $allowedFields, true)) {
    sendError("A valid influencer_id and field are required.", 400);
}

$stmt = $db->prepare("SELECT {$field} AS path FROM influencer_profiles WHERE user_id = ?");
$stmt->execute([$influencerId]);
$row = $stmt->fetch();

if (!$row || empty($row["path"])) {
    sendError("Document not found.", 404);
}

// Stored path is always relative (e.g. "verification/user_12/selfie.jpg").
// Re-validate it can't escape the upload directory before touching disk.
$relativePath = ltrim($row["path"], "/\\");
if (preg_match('#(^|[\\\\/])\.\.#', $relativePath)) {
    sendError("Invalid document path.", 400);
}

$absPath = rtrim(UPLOAD_BASE_DIR, "/") . "/" . $relativePath;

if (!is_file($absPath)) {
    sendError("Document file is missing on disk.", 404);
}

$finfo    = new finfo(FILEINFO_MIME_TYPE);
$mimeType = $finfo->file($absPath) ?: "application/octet-stream";

header("Content-Type: " . $mimeType);
header("Content-Length: " . filesize($absPath));
header("Content-Disposition: inline; filename=\"" . basename($absPath) . "\"");
header("Cache-Control: private, max-age=0, no-store");
header("X-Content-Type-Options: nosniff");

readfile($absPath);
exit;
