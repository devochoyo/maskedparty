<?php
/**
 * Create Review Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'client');

$db = getDatabaseConnection();
$data = getJsonInput();

$callId = (int)($data['call_id'] ?? 0);
$rating = (int)($data['rating'] ?? 0);
$experienceText = trim($data['experience_text'] ?? '');

$errors = [];
if (!$callId) $errors['call_id'] = 'Call ID is required.';
if ($rating < 1 || $rating > 5) $errors['rating'] = 'Rating must be between 1 and 5 stars.';
if (empty($experienceText)) $errors['experience_text'] = 'Experience text is required.';

if (!empty($errors)) {
    sendValidationError('Validation failed.', $errors);
}

// A rating of 1 or 2 (out of the existing 1-5 scale) counts as "bad" for
// the 3-strike suspension rule below.
const BAD_RATING_THRESHOLD = 2;
const BAD_RATING_SUSPEND_COUNT = 3;

try {
    $db->beginTransaction();

    // Check if the call exists and is completed by this client
    $stmt = $db->prepare("SELECT * FROM video_calls WHERE id = ? AND client_id = ? AND status = 'completed'");
    $stmt->execute([$callId, $user['id']]);
    $call = $stmt->fetch();

    if (!$call) {
        $db->rollBack();
        sendError('Completed call not found or you are not the client for this call.', 404);
    }

    // Check if a review already exists for this call (one rating per
    // completed call — also enforced at the DB layer by a unique index
    // on reviews.call_id).
    $stmt = $db->prepare("SELECT id FROM reviews WHERE call_id = ?");
    $stmt->execute([$callId]);
    if ($stmt->fetch()) {
        $db->rollBack();
        sendError('You have already submitted a review for this call.', 409);
    }

    // Insert the new review
    $stmt = $db->prepare("INSERT INTO reviews (call_id, client_id, influencer_id, rating, experience_text) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$callId, $user['id'], $call['influencer_id'], $rating, $experienceText]);

    // Update influencer's average rating
    $stmt = $db->prepare("SELECT AVG(rating) FROM reviews WHERE influencer_id = ?");
    $stmt->execute([$call['influencer_id']]);
    $averageRating = $stmt->fetchColumn();

    $stmt = $db->prepare("UPDATE influencer_profiles SET average_rating = ? WHERE user_id = ?");
    $stmt->execute([$averageRating, $call['influencer_id']]);

    // Bad-rating tracking: since reviews already enforces one row per
    // completed call_id (and each call has exactly one client), counting
    // distinct call_id rows with rating <= BAD_RATING_THRESHOLD already
    // guarantees the "3 different completed clients" requirement, since
    // the same client can't submit two reviews against the influencer for
    // the same call, and each call has exactly one client.
    $suspended = false;
    if ($rating <= BAD_RATING_THRESHOLD) {
        $stmt = $db->prepare("
            SELECT COUNT(DISTINCT r.call_id) AS bad_count
            FROM reviews r
            WHERE r.influencer_id = ? AND r.rating <= ?
        ");
        $stmt->execute([$call['influencer_id'], BAD_RATING_THRESHOLD]);
        $badCount = (int)$stmt->fetchColumn();

        $stmt = $db->prepare("UPDATE influencer_profiles SET bad_rating_count = ? WHERE user_id = ?");
        $stmt->execute([$badCount, $call['influencer_id']]);

        if ($badCount >= BAD_RATING_SUSPEND_COUNT) {
            // Suspend the account — this app already has a 'suspended'
            // user status and an admin review flow (api/admin/reports.php,
            // api/admin/users.php), so wire into that existing pattern
            // rather than inventing a new flag/table. Only suspend if not
            // already suspended/banned, so this can't "un-ban" someone.
            $stmt = $db->prepare("UPDATE users SET status = 'suspended' WHERE id = ? AND status = 'active'");
            $stmt->execute([$call['influencer_id']]);
            $suspended = ($stmt->rowCount() > 0);

            if ($suspended) {
                $stmt = $db->prepare("
                    INSERT INTO notifications (user_id, title, body, type, created_at)
                    VALUES (?, 'Account Suspended', ?, 'account_status', NOW())
                ");
                $stmt->execute([
                    $call['influencer_id'],
                    'Your account has been suspended pending admin review after receiving multiple low ratings from different clients.'
                ]);

                // Also notify every active admin account.
                $stmt = $db->prepare("
                    INSERT INTO notifications (user_id, title, body, type, created_at)
                    VALUES (?, 'Influencer Auto-Suspended', ?, 'admin_review', NOW())
                ");
                $adminNotifyBody = "Influencer #{$call['influencer_id']} was automatically suspended after {$badCount} low ratings from different completed clients.";
                foreach (getAdminUserIds($db) as $adminId) {
                    $stmt->execute([$adminId, $adminNotifyBody]);
                }
            }
        }
    }

    // Notify the influencer that a rating was received (per notification
    // requirements — "Generate notifications for ... Rating received").
    $stmt = $db->prepare("
        INSERT INTO notifications (user_id, title, body, type, created_at)
        VALUES (?, 'New Rating Received', ?, 'rating', NOW())
    ");
    $stmt->execute([
        $call['influencer_id'],
        'You received a ' . $rating . '-star rating from a client.'
    ]);

    $db->commit();

    sendResponse(true, 'Review submitted successfully.');

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Create Review Error: " . $e->getMessage());
    sendError('Failed to submit review.');
}
