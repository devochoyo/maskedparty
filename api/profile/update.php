<?php
/**
 * Update Profile Endpoint
 */
require_once __DIR__ . "/../../config/database.php";
require_once __DIR__ . "/../../config/functions.php";
require_once __DIR__ . "/../../config/auth.php";

$user = getAuthenticatedUser();
$db = getDatabaseConnection();
$data = getJsonInput();
$errors = [];
$updateFields = [];
$params = [];

// Fields that cannot be changed
$forbiddenFields = ["role", "country_name", "country_code", "email", "full_name"];
foreach ($forbiddenFields as $field) {
    if (isset($data[$field])) {
        sendError("Cannot update '{$field}'.", 403);
    }
}

// Common fields for both client and influencer
if (isset($data["mystery_name"])) {
    $mysteryName = trim($data["mystery_name"]);
    if (empty($mysteryName)) {
        $errors["mystery_name"] = "Mystery name cannot be empty.";
    } else {
        $updateFields[] = "mystery_name = ?";
        $params[] = $mysteryName;
    }
}

// Profile photo: accept a relative stored path (preferred) or a full URL.
// Store only the relative path in the DB; never trust a raw client-supplied URL.
if (isset($data["profile_photo"])) {
    $profilePhoto = trim($data["profile_photo"]);
    // Strip BASE_URL prefix if the client sent a full URL back
    $prefix = BASE_URL . '/uploads/';
    if (strpos($profilePhoto, $prefix) === 0) {
        $profilePhoto = substr($profilePhoto, strlen($prefix));
    }
    $updateFields[] = "profile_photo = ?";
    $params[] = $profilePhoto;
}

if ($user["role"] === "influencer") {
    // Influencer specific fields
    $influencerUpdateFields = [];
    $influencerParams = [];

    if (isset($data["biography"])) {
        $biography = trim($data["biography"]);
        $influencerUpdateFields[] = "biography = ?";
        $influencerParams[] = $biography;
    }

    if (isset($data["age"])) {
        $age = (int)$data["age"];
        if ($age <= 0) {
            $errors["age"] = "Age must be a positive number.";
        } else {
            $influencerUpdateFields[] = "age = ?";
            $influencerParams[] = $age;
        }
    }

    if (isset($data["complexion"])) {
        $complexion = trim($data["complexion"]);
        $influencerUpdateFields[] = "complexion = ?";
        $influencerParams[] = $complexion;
    }

    if (isset($data["favourite_food"])) {
        $favouriteFood = trim($data["favourite_food"]);
        $influencerUpdateFields[] = "favourite_food = ?";
        $influencerParams[] = $favouriteFood;
    }

    if (isset($data["hobby"])) {
        $hobby = trim($data["hobby"]);
        $influencerUpdateFields[] = "hobby = ?";
        $influencerParams[] = $hobby;
    }

    if (isset($data["aspiration"])) {
        $aspiration = trim($data["aspiration"]);
        $influencerUpdateFields[] = "aspiration = ?";
        $influencerParams[] = $aspiration;
    }

    if (isset($data["financial_target"])) {
        $financialTarget = (float)$data["financial_target"];
        if ($financialTarget < 0) {
            $errors["financial_target"] = "Financial target cannot be negative.";
        } else {
            $influencerUpdateFields[] = "financial_target = ?";
            $influencerParams[] = $financialTarget;
        }
    }

    // price_per_minute is now platform-controlled via coin packages.
    // Silently ignore any attempt by the influencer to set it.

    if (isset($data["mask_status"])) {
        $maskStatus = trim($data["mask_status"]);
        if (!in_array($maskStatus, ["masked", "unmasked"])) {
            $errors["mask_status"] = "Invalid mask status.";
        } else {
            $influencerUpdateFields[] = "mask_status = ?";
            $influencerParams[] = $maskStatus;
        }
    }

    if (isset($data["willing_to_remove_mask"])) {
        $willingToRemoveMask = (int)(bool)$data["willing_to_remove_mask"]; // force 0 or 1
        $influencerUpdateFields[] = "willing_to_remove_mask = ?";
        $influencerParams[] = $willingToRemoveMask;
    }

    if (isset($data["intro_video"])) {
        $introVideo = trim($data["intro_video"]);
        // Strip BASE_URL prefix if the client sent a full URL back
        $prefix = BASE_URL . '/uploads/';
        if (strpos($introVideo, $prefix) === 0) {
            $introVideo = substr($introVideo, strlen($prefix));
        }
        $influencerUpdateFields[] = "intro_video = ?";
        $influencerParams[] = $introVideo;
    }

    // Gallery uploads are handled by api/influencer/upload-gallery.php
    if (!empty($influencerUpdateFields)) {
        $influencerParams[] = $user["id"];
        $stmt = $db->prepare("UPDATE influencer_profiles SET " . implode(", ", $influencerUpdateFields) . " WHERE user_id = ?");
        $stmt->execute($influencerParams);
    }
}

if (!empty($errors)) {
    sendValidationError("Validation failed.", $errors);
}

if (!empty($updateFields)) {
    $params[] = $user["id"];
    $stmt = $db->prepare("UPDATE users SET " . implode(", ", $updateFields) . " WHERE id = ?");
    $stmt->execute($params);
}

sendResponse(true, "Profile updated successfully.");