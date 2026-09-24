<?php
/**
 * Complete Influencer Profile Endpoint
 */

require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
requireRole($user, 'influencer');

$db = getDatabaseConnection();
$data = getJsonInput();

$errors = [];
$updateFields = [];
$params = [];

// Required fields for completing profile
$requiredFields = [
    'biography', 'age', 'complexion', 'favourite_food', 'hobby', 'aspiration', 
    'financial_target', 'mask_status', 'willing_to_remove_mask'
];

foreach ($requiredFields as $field) {
    if (!isset($data[$field]) || empty(trim($data[$field]))) {
        $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required.';
    }
}

if (!empty($errors)) {
    sendValidationError('Validation failed.', $errors);
}

// Validate and sanitize fields
$biography = trim($data['biography']);
$age = (int)$data['age'];
$complexion = trim($data['complexion']);
$favouriteFood = trim($data['favourite_food']);
$hobby = trim($data['hobby']);
$aspiration = trim($data['aspiration']);
$financialTarget = (float)$data['financial_target'];
$maskStatus = trim($data['mask_status']);
$willingToRemoveMask = (bool)$data['willing_to_remove_mask'];

if ($age <= 0) {
    $errors['age'] = 'Age must be a positive number.';
}
if ($financialTarget < 0) {
    $errors['financial_target'] = 'Financial target cannot be negative.';
}
if (!in_array($maskStatus, ['masked', 'unmasked'])) {
    $errors['mask_status'] = 'Invalid mask status.';
}

if (!empty($errors)) {
    sendValidationError('Validation failed.', $errors);
}

try {
    $stmt = $db->prepare("SELECT 1 FROM influencer_profiles WHERE user_id = ?");
    $stmt->execute([$user['id']]);
    if (!$stmt->fetch()) {
        // Should not happen — registration always creates a matching
        // influencer_profiles row — but guard against a missing row
        // (e.g. a pre-existing account from before this row was
        // created automatically) rather than silently reporting success.
        sendError('Influencer profile not found. Please contact support.', 404);
    }

    $stmt = $db->prepare("
        UPDATE influencer_profiles SET
            biography = ?, age = ?, complexion = ?, favourite_food = ?, hobby = ?, aspiration = ?, 
            financial_target = ?, mask_status = ?, willing_to_remove_mask = ?, profile_completed = 1
        WHERE user_id = ?
    ");
    $stmt->execute([
        $biography, $age, $complexion, $favouriteFood, $hobby, $aspiration, 
        $financialTarget, $maskStatus, $willingToRemoveMask, $user['id']
    ]);

    sendResponse(true, 'Influencer profile completed successfully.', ['profile_completed' => true]);

} catch (Exception $e) {
    error_log("Complete Profile Error: " . $e->getMessage());
    sendError('Failed to complete influencer profile.');
}