<?php
/**
 * Masked Party API Entry Point & Documentation
 *
 * GET /              -> Readable HTML reference page (password-protected).
 * GET /?format=json  -> Same reference, as raw JSON.
 *
 * All other endpoints are plain PHP files under /api/**, called directly
 * by path (e.g. POST /api/auth/login.php). This file does not route those
 * requests; it only documents them.
 */

require_once __DIR__ . '/config/response.php';

// ---------------------------------------------------------------------------
// Password protection — HTML view only
// ---------------------------------------------------------------------------
define('DOC_PASSWORD', '0976');

$format = $_GET['format'] ?? 'html';

if ($format === 'html') {
    session_start();

    $loginError = '';

    if (isset($_POST['doc_password'])) {
        if ($_POST['doc_password'] === DOC_PASSWORD) {
            $_SESSION['doc_authed'] = true;
        } else {
            $loginError = 'Incorrect password. Please try again.';
        }
    }

    if (empty($_SESSION['doc_authed'])) {
        // Show password gate
        header('Content-Type: text/html; charset=utf-8');
        ?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Masked Party API &middot; Access Required</title>
<link rel="icon" href="data:,">
<style>
  *{margin:0;padding:0;box-sizing:border-box;}
  body{background:#141119;color:#f0ecf8;font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;}
  .gate{width:100%;max-width:420px;padding:24px;}
  .gate-card{background:#1c1826;border:1px solid #332c46;border-radius:16px;padding:42px 40px 38px;text-align:center;}
  h1{font-size:26px;font-weight:600;margin-bottom:8px;}
  .sub{color:#736a8a;margin-bottom:30px;font-size:13.5px;}
  input[type="password"]{width:100%;background:#0f0d14;border:1px solid #332c46;color:#f0ecf8;border-radius:10px;padding:13px;font-size:18px;text-align:center;margin-bottom:14px;}
  input[type="password"]:focus{outline:none;border-color:#cda149;}
  .error{background:rgba(234,110,136,.12);border:1px solid rgba(234,110,136,.3);color:#ea6e88;border-radius:8px;padding:10px 14px;margin-bottom:14px;font-size:13px;}
  .btn{width:100%;background:#cda149;color:#1a1522;border:none;border-radius:10px;padding:14px;font-size:14.5px;font-weight:700;cursor:pointer;}
  .btn:hover{opacity:.88;}
  .foot{margin-top:20px;font-size:12px;color:#736a8a;}
</style>
</head>
<body>
<div class="gate">
  <div class="gate-card">
    <h1>Masked Party API</h1>
    <p class="sub">Enter the access password to continue.</p>
    <?php if ($loginError): ?>
    <div class="error"><?= htmlspecialchars($loginError) ?></div>
    <?php endif; ?>
    <form method="POST">
      <input type="password" name="doc_password" placeholder="Enter password" autofocus>
      <button type="submit" class="btn">Unlock Documentation &rarr;</button>
    </form>
    <p class="foot">Masked Party &middot; Internal API Reference</p>
  </div>
</div>
</body>
</html>
        <?php
        exit;
    }
}

// Handle logout POST
if (isset($_POST['doc_logout'])) {
    session_start();
    session_destroy();
    header('Location: ' . $_SERVER['PHP_SELF']);
    exit;
}

// ---------------------------------------------------------------------------
// Shared response envelope reference
// ---------------------------------------------------------------------------
$responseEnvelope = [
    'success' => [
        'description' => 'Always present. true on success, false on failure.',
        'shape' => ['success' => true, 'message' => 'Human-readable summary.', 'data' => '(optional) endpoint-specific payload']
    ],
    'validation_error' => [
        'http_status' => 422,
        'description' => 'Field-level errors keyed by field name.',
        'shape' => ['success' => false, 'message' => 'Validation failed.', 'errors' => ['field_name' => 'Error description']]
    ],
    'generic_error' => [
        'description' => 'HTTP status varies by case (400/401/403/404/409/410/422/500/502).',
        'shape' => ['success' => false, 'message' => 'Human-readable error description.']
    ]
];

// ---------------------------------------------------------------------------
// Auth reference
// ---------------------------------------------------------------------------
$auth = [
    'type' => 'Bearer token',
    'header' => 'Authorization: Bearer {token}',
    'how_to_get_a_token' => 'POST /api/authentication/register.php or /api/auth/login.php returns a token in data.token.',
    'token_lifetime' => '30 days from issue. Expired/invalid tokens return 401.',
    'notes' => [
        'Tokens are opaque random strings, not JWTs — do not attempt to decode them client-side.',
        'A banned user\'s token is rejected (401) even if not expired.',
        'Logout (POST /api/auth/logout.php) deletes the token server-side; treat it as unusable immediately after.',
        'After registration, the user\'s authenticated field is false until they verify their email via the OTP flow.'
    ]
];

// ---------------------------------------------------------------------------
// File / media URL convention
// ---------------------------------------------------------------------------
$mediaUrls = [
    'description' => 'Any field ending in _url, _photo, or _video is returned as a full, ready-to-use URL (BASE_URL + /uploads/...).',
    'uploads' => [
        'image' => ['max_size_mb' => 10, 'allowed' => ['jpg', 'png', 'webp', 'gif']],
        'video' => ['max_size_mb' => 100, 'allowed' => ['mp4', 'mov', 'avi', 'webm']],
        'document' => ['max_size_mb' => 10, 'allowed' => ['jpg', 'png', 'pdf']]
    ],
    'upload_encoding' => 'multipart/form-data for all file-upload endpoints (never JSON).'
];

// ---------------------------------------------------------------------------
// Endpoint catalogue with request/response examples
// ---------------------------------------------------------------------------
$endpoints = [

    'Authentication' => [
        [
            'method' => 'POST',
            'path' => '/api/authentication/register.php',
            'auth' => false,
            'desc' => 'Register new account. Returns authenticated: false + OTP sent.',
            'req' => [
                'role' => "'client' | 'influencer' (required)",
                'email' => 'string, required',
                'password' => 'string, min 8 chars, required',
                'confirm_password' => 'string, required',
                'mystery_name' => 'string, required',
                'country_name' => 'string, required',
                'country_code' => 'string',
                'full_name' => "string, required if role='influencer'",
                'bank_name' => "string, required if role='influencer'",
                'account_number' => "string, required if role='influencer'",
                'referral_code' => "string, optional"
            ],
            'req_ex' => ['role' => 'client', 'email' => 'user@example.com', 'password' => 'SecurePass123', 'confirm_password' => 'SecurePass123', 'mystery_name' => 'ShadowGhost', 'country_name' => 'Nigeria', 'country_code' => 'NG'],
            'res_ex' => ['success' => true, 'message' => 'Registration successful. Please verify your email.', 'data' => ['user' => ['id' => 1, 'email' => 'user@example.com', 'mystery_name' => 'ShadowGhost', 'role' => 'client', 'status' => 'active', 'referral_code' => 'T9XJ4RQK', 'authenticated' => false], 'token' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', 'otp_sent' => true, 'otp_message' => 'Verification code sent to user@example.com']],
            'err' => ['422' => ['success' => false, 'message' => 'Validation failed.', 'errors' => ['email' => 'Email already exists.']]],
            'notes' => 'After registration, route to OTP screen immediately. Influencer accounts start as pending_verification.'
        ],
        [
            'method' => 'POST',
            'path' => '/api/authentication/send-otp.php',
            'auth' => false,
            'desc' => 'Send/resend 6-digit OTP. 60-second cooldown.',
            'req' => ['email' => 'string, required'],
            'req_ex' => ['email' => 'user@example.com'],
            'res_ex' => ['success' => true, 'message' => 'Verification code sent to user@example.com', 'data' => ['authenticated' => false, 'email' => 'user@example.com']],
            'err' => ['400' => ['success' => false, 'message' => 'Please wait 60 seconds before requesting another code.']],
            'notes' => 'OTP expires after 6 minutes. Each new code invalidates previous ones.'
        ],
        [
            'method' => 'POST',
            'path' => '/api/authentication/verify-otp.php',
            'auth' => false,
            'desc' => 'Submit 6-digit OTP. On success sets authenticated: true.',
            'req' => ['email' => 'string, required', 'code' => 'string, exactly 6 digits, required'],
            'req_ex' => ['email' => 'user@example.com', 'code' => '123456'],
            'res_ex' => ['success' => true, 'message' => 'Email verified successfully. You can now log in.', 'data' => ['authenticated' => true]],
            'err' => ['200' => ['success' => false, 'message' => 'Invalid verification code.', 'data' => ['authenticated' => false]]],
            'notes' => 'Returns HTTP 200 with authenticated: false for wrong/expired codes.'
        ],
        [
            'method' => 'POST',
            'path' => '/api/authentication/check-status.php',
            'auth' => false,
            'desc' => 'Check if email is verified. Call after login to decide OTP screen vs dashboard.',
            'req' => ['email' => 'string, required'],
            'req_ex' => ['email' => 'user@example.com'],
            'res_ex' => ['success' => true, 'message' => 'User is authenticated.', 'data' => ['authenticated' => true]],
            'err' => ['404' => ['success' => false, 'message' => 'User not found.']]
        ],
    ],

    'Auth' => [
        [
            'method' => 'POST',
            'path' => '/api/auth/login.php',
            'auth' => false,
            'desc' => 'Login. Returns token + authenticated flag.',
            'req' => ['email' => 'string, required', 'password' => 'string, required'],
            'req_ex' => ['email' => 'user@example.com', 'password' => 'SecurePass123'],
            'res_ex' => ['success' => true, 'message' => 'Login successful.', 'data' => ['user' => ['id' => 1, 'email' => 'user@example.com', 'mystery_name' => 'ShadowGhost', 'role' => 'client', 'authenticated' => true], 'token' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', 'wallet_balance' => 120.00]],
            'err' => ['401' => ['success' => false, 'message' => 'Invalid credentials.'], '403' => ['success' => false, 'message' => 'Your account has been banned.']],
            'notes' => 'Always check authenticated field. If false, redirect to OTP screen.'
        ],
        [
            'method' => 'POST',
            'path' => '/api/auth/logout.php',
            'auth' => true,
            'desc' => 'Delete token server-side.',
            'res_ex' => ['success' => true, 'message' => 'Logged out successfully.']
        ],
        [
            'method' => 'POST',
            'path' => '/api/auth/forgot-password.php',
            'auth' => false,
            'desc' => 'Request password reset link. Always returns success to prevent email enumeration.',
            'req' => ['email' => 'string, required'],
            'req_ex' => ['email' => 'user@example.com'],
            'res_ex' => ['success' => true, 'message' => 'If an account with that email exists, a password reset link has been sent.']
        ],
        [
            'method' => 'POST',
            'path' => '/api/auth/reset-password.php',
            'auth' => false,
            'desc' => 'Reset password with token. Invalidates all existing sessions.',
            'req' => ['token' => 'string, required', 'new_password' => 'string, min 8 chars, required', 'confirm_password' => 'string, required'],
            'req_ex' => ['token' => 'reset_token_abc123', 'new_password' => 'NewSecurePass456', 'confirm_password' => 'NewSecurePass456'],
            'res_ex' => ['success' => true, 'message' => 'Password has been reset successfully.']
        ],
    ],

    'Profile' => [
        [
            'method' => 'GET',
            'path' => '/api/profile/get.php',
            'auth' => true,
            'desc' => 'Get own profile. price_per_minute derived from coin packages.',
            'res_ex' => ['success' => true, 'message' => 'Profile retrieved successfully.', 'data' => ['id' => 1, 'email' => 'user@example.com', 'mystery_name' => 'ShadowGhost', 'role' => 'influencer', 'country_name' => 'Nigeria', 'status' => 'active', 'authenticated' => true, 'profile_photo' => 'https://api.maskedparty.com/uploads/profiles/xxx.jpg', 'wallet_balance' => 50.00, 'escrow_balance' => 0, 'biography' => 'I love connecting...', 'age' => 24, 'mask_status' => 'masked', 'average_rating' => 4.5, 'verification_status' => 'approved', 'price_per_minute' => 100.00]]
        ],
        [
            'method' => 'POST',
            'path' => '/api/profile/update.php',
            'auth' => true,
            'desc' => 'Partial update. All fields optional. Cannot update role/country/email.',
            'req' => ['mystery_name' => 'string', 'profile_photo' => 'string', '(influencer only)' => 'biography, age, mask_status, etc.'],
            'req_ex' => ['mystery_name' => 'GhostMaster', 'biography' => 'Updated biography', 'mask_status' => 'unmasked'],
            'res_ex' => ['success' => true, 'message' => 'Profile updated successfully.'],
            'err' => ['403' => ['success' => false, 'message' => 'Cannot update role/country/email.']]
        ],
    ],

    'Influencer' => [
        [
            'method' => 'GET',
            'path' => '/api/influencer/list.php',
            'auth' => false,
            'desc' => 'Browse verified influencers. 20 per page.',
            'req' => ['page' => 'int, default 1', 'country' => 'string', 'mask_status' => "'masked' | 'unmasked'", 'search' => 'string', 'sort_by' => "'newest' | 'highest_rated' | 'most_popular'"],
            'res_ex' => ['success' => true, 'message' => 'Influencers retrieved successfully.', 'data' => ['influencers' => [['id' => 5, 'mystery_name' => 'Fox', 'country_name' => 'Kenya', 'profile_photo' => 'https://api.maskedparty.com/uploads/profiles/fox.jpg', 'mask_status' => 'masked', 'online_status' => 'online', 'average_rating' => 4.8, 'price_per_minute' => 100.00]], 'page' => 1, 'limit' => 20]]
        ],
        [
            'method' => 'GET',
            'path' => '/api/influencer/details.php',
            'auth' => false,
            'desc' => 'Public influencer profile.',
            'req' => ['id' => 'int, required'],
            'res_ex' => ['success' => true, 'message' => 'Influencer details retrieved.', 'data' => ['id' => 5, 'mystery_name' => 'Fox', 'biography' => 'I love making connections...', 'age' => 24, 'mask_status' => 'masked', 'average_rating' => 4.8, 'online_status' => 'online', 'price_per_minute' => 100.00, 'total_calls' => 34, 'intro_video' => 'https://api.maskedparty.com/uploads/videos/intro.mp4', 'gallery' => [['id' => 1, 'url' => 'https://api.maskedparty.com/uploads/gallery/1.jpg']]]],
            'err' => ['404' => ['success' => false, 'message' => 'Influencer not found.']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/influencer/complete-profile.php',
            'auth' => true,
            'role' => 'influencer',
            'desc' => 'One-time completion of influencer profile. All fields required.',
            'req' => ['biography' => 'string, required', 'age' => 'int > 0, required', 'complexion' => 'string, required', 'favourite_food' => 'string, required', 'hobby' => 'string, required', 'aspiration' => 'string, required', 'financial_target' => 'number >= 0, required', 'mask_status' => "'masked' | 'unmasked', required", 'willing_to_remove_mask' => 'bool, required'],
            'req_ex' => ['biography' => 'I am passionate...', 'age' => 25, 'complexion' => 'dark', 'favourite_food' => 'Jollof Rice', 'hobby' => 'Photography', 'aspiration' => 'Become a top creator', 'financial_target' => 10000.00, 'mask_status' => 'masked', 'willing_to_remove_mask' => true],
            'res_ex' => ['success' => true, 'message' => 'Influencer profile completed successfully.']
        ],
        [
            'method' => 'POST',
            'path' => '/api/influencer/online-status.php',
            'auth' => true,
            'role' => 'influencer',
            'desc' => 'Update online status.',
            'req' => ['status' => "'online' | 'offline' | 'busy', required"],
            'req_ex' => ['status' => 'online'],
            'res_ex' => ['success' => true, 'message' => 'Status updated.', 'data' => ['online_status' => 'online']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/influencer/upload-gallery.php',
            'auth' => true,
            'role' => 'influencer',
            'content_type' => 'multipart/form-data',
            'desc' => 'Upload gallery images. Max 10 images.',
            'req' => ['gallery_images' => 'one or more image files'],
            'res_ex' => ['success' => true, 'message' => 'Gallery images uploaded.', 'data' => ['uploaded_urls' => ['https://api.maskedparty.com/uploads/gallery/1.jpg']]]
        ],
        [
            'method' => 'POST',
            'path' => '/api/influencer/verification.php',
            'auth' => true,
            'role' => 'influencer',
            'content_type' => 'multipart/form-data',
            'desc' => 'Submit KYC documents (3 files required). Sets verification_status to pending.',
            'req' => ['government_id' => 'image file, required', 'selfie' => 'image file, required', 'verification_video' => 'video file, required'],
            'res_ex' => ['success' => true, 'message' => 'Verification documents submitted. Your profile is now pending review.']
        ],
        [
            'method' => 'GET',
            'path' => '/api/influencer/gallery.php',
            'auth' => true,
            'role' => 'influencer',
            'desc' => 'View own gallery for management.',
            'res_ex' => ['success' => true, 'message' => 'Gallery retrieved.', 'data' => ['gallery' => [['id' => 1, 'url' => 'https://api.maskedparty.com/uploads/gallery/1.jpg']]]]
        ],
        [
            'method' => 'POST',
            'path' => '/api/influencer/delete-gallery-image.php',
            'auth' => true,
            'role' => 'influencer',
            'desc' => 'Delete a gallery image (owned by authenticated influencer).',
            'req' => ['image_id' => 'int, required'],
            'req_ex' => ['image_id' => 1],
            'res_ex' => ['success' => true, 'message' => 'Gallery image deleted successfully.'],
            'err' => ['404' => ['success' => false, 'message' => 'Gallery image not found.']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/influencer/save.php',
            'auth' => true,
            'role' => 'client',
            'desc' => 'Save influencer to favourites. Idempotent.',
            'req' => ['influencer_id' => 'int, required'],
            'req_ex' => ['influencer_id' => 5],
            'res_ex' => ['success' => true, 'message' => 'Influencer saved successfully.']
        ],
        [
            'method' => 'POST',
            'path' => '/api/influencer/unsave.php',
            'auth' => true,
            'role' => 'client',
            'desc' => 'Remove from favourites.',
            'req' => ['influencer_id' => 'int, required'],
            'req_ex' => ['influencer_id' => 5],
            'res_ex' => ['success' => true, 'message' => 'Influencer removed from saved list.']
        ],
        [
            'method' => 'GET',
            'path' => '/api/influencer/saved.php',
            'auth' => true,
            'role' => 'client',
            'desc' => 'Get saved influencers.',
            'res_ex' => ['success' => true, 'message' => 'Saved influencers retrieved.', 'data' => ['influencers' => [['id' => 5, 'mystery_name' => 'Fox', 'online_status' => 'online', 'average_rating' => 4.8, 'saved_at' => '2026-07-01 10:00:00']]]]
        ],
        [
            'method' => 'GET',
            'path' => '/api/influencer/earnings.php',
            'auth' => true,
            'role' => 'influencer',
            'desc' => 'Earnings dashboard.',
            'res_ex' => ['success' => true, 'message' => 'Earnings retrieved.', 'data' => ['earnings' => ['today' => 12.50, 'this_week' => 87.00, 'this_month' => 320.00, 'lifetime' => 1540.00], 'wallet_balance' => 200.00, 'total_calls' => 48]]
        ],
    ],

    'Wallet' => [
        [
            'method' => 'GET',
            'path' => '/api/wallet/balance.php',
            'auth' => true,
            'desc' => 'Get wallet balance including escrow.',
            'res_ex' => ['success' => true, 'message' => 'Balance retrieved.', 'data' => ['current_balance' => 100.00, 'total_purchased' => 200.00, 'total_spent' => 100.00, 'escrow_balance' => 10.00, 'available_balance' => 90.00]]
        ],
        [
            'method' => 'GET',
            'path' => '/api/wallet/packages.php',
            'auth' => true,
            'desc' => 'Coin packages available for purchase.',
            'res_ex' => ['success' => true, 'message' => 'Packages retrieved.', 'data' => ['packages' => [['package_id' => 1, 'package_name' => 'Starter', 'price' => 4.99, 'currency' => 'usd', 'coins' => 500, 'minutes' => 5, 'is_popular' => false, 'is_best_value' => true]]]]
        ],
        [
            'method' => 'GET',
            'path' => '/api/wallet/history.php',
            'auth' => true,
            'desc' => 'Transaction history.',
            'req' => ['limit' => 'int, default 50, max 100', 'offset' => 'int, default 0'],
            'res_ex' => ['success' => true, 'message' => 'History retrieved.', 'data' => ['history' => [['transaction_id' => 1, 'type' => 'purchase', 'coins' => 50, 'amount' => 4.99, 'reference' => 'Paystack Reference: 7PVGX8MEk85tgeEpVDtD', 'status' => 'completed', 'created_at' => '2026-01-01 10:00:00']]]]
        ],
        [
            'method' => 'POST',
            'path' => '/api/wallet/buy-coins.php',
            'auth' => true,
            'desc' => 'Initialise a Paystack transaction to buy coins.',
            'req' => ['package_id' => 'int, required'],
            'req_ex' => ['package_id' => 1],
            'res_ex' => ['success' => true, 'message' => 'Payment initialised.', 'data' => ['authorization_url' => 'https://checkout.paystack.com/0peioxfhpn', 'access_code' => '0peioxfhpn', 'reference' => '7PVGX8MEk85tgeEpVDtD', 'payment_id' => 42, 'package_id' => 1, 'amount' => 4.99, 'currency' => 'NGN']],
            'notes' => 'Open authorization_url (or use access_code with the Paystack Flutter SDK). After payment, call /api/payment/verify-payment.php to credit the wallet.'
        ],
    ],

    'Payment' => [
        [
            'method' => 'POST',
            'path' => '/api/payment/create-payment.php',
            'auth' => true,
            'desc' => 'Initialise a Paystack transaction. Returns authorization_url and access_code to launch checkout.',
            'req' => ['package_id' => 'int, required'],
            'req_ex' => ['package_id' => 1],
            'res_ex' => ['success' => true, 'message' => 'Payment initialised.', 'data' => ['authorization_url' => 'https://checkout.paystack.com/0peioxfhpn', 'access_code' => '0peioxfhpn', 'reference' => '7PVGX8MEk85tgeEpVDtD', 'payment_id' => 42, 'package_id' => 1, 'amount' => 4.99, 'currency' => 'NGN']],
            'notes' => 'Open authorization_url in a WebView or pass access_code to the Paystack Flutter SDK. Store reference — required for verify-payment.php.'
        ],
        [
            'method' => 'POST',
            'path' => '/api/payment/verify-payment.php',
            'auth' => true,
            'desc' => 'Verify Paystack transaction server-side and credit wallet. Idempotent — safe to call multiple times with the same reference.',
            'req' => ['reference' => 'string, required — the reference returned by create-payment.php and echoed by Paystack after checkout'],
            'req_ex' => ['reference' => '7PVGX8MEk85tgeEpVDtD'],
            'res_ex' => ['success' => true, 'message' => 'Payment verified and wallet credited.', 'data' => ['wallet_balance' => 104.99]],
            'err' => ['400' => ['success' => false, 'message' => 'Payment not successful.'], '403' => ['success' => false, 'message' => 'This payment does not belong to the authenticated user.'], '409' => ['success' => false, 'message' => 'No matching pending payment found.']],
            'notes' => 'Always call this after Paystack checkout — never trust the SDK result alone. First-ever deposit also credits referrer 5% of coins.'
        ],
        [
            'method' => 'GET',
            'path' => '/api/payment/payment-history.php',
            'auth' => true,
            'desc' => 'Payment history.',
            'req' => ['limit' => 'int, default 50, max 100', 'offset' => 'int, default 0'],
            'res_ex' => ['success' => true, 'message' => 'Payment history retrieved.', 'data' => ['payment_history' => [['payment_id' => 1, 'package_name' => 'Starter', 'amount' => 4.99, 'coins' => 50, 'status' => 'completed', 'created_at' => '2026-01-01 10:00:00']]]]
        ],
        [
            'method' => 'POST',
            'path' => '/api/payment/paystack-webhook.php',
            'auth' => false,
            'desc' => 'Paystack webhook endpoint (server-to-server only). Register this URL in Paystack Dashboard → Settings → API Keys & Webhooks.',
            'notes' => 'Verified via x-paystack-signature header (HMAC-SHA512), not Bearer token. Handles charge.success event to credit wallets when the app cannot reach verify-payment.php.'
        ],
    ],

    'Call' => [
        [
            'method' => 'GET',
            'path' => '/api/call/pending.php',
            'auth' => true,
            'role' => 'influencer',
            'desc' => 'Poll for incoming call request.',
            'res_ex' => ['success' => true, 'message' => 'Pending call retrieved.', 'data' => ['request_id' => 10, 'client_id' => 3, 'expires_at' => '2026-07-20 10:01:00', 'client_mystery_name' => 'Ghost', 'client_profile_photo' => 'https://api.maskedparty.com/uploads/profiles/ghost.jpg']],
            'notes' => 'data is null when nothing pending.'
        ],
        [
            'method' => 'POST',
            'path' => '/api/call/request.php',
            'auth' => true,
            'role' => 'client',
            'desc' => 'Request call with influencer. Expires after 60s.',
            'req' => ['influencer_id' => 'int, required'],
            'req_ex' => ['influencer_id' => 5],
            'res_ex' => ['success' => true, 'message' => 'Call request sent.', 'data' => ['request_id' => 10, 'expires_at' => '2026-07-20 10:01:00']],
            'err' => ['402' => ['success' => false, 'message' => 'Insufficient coins.'], '409' => ['success' => false, 'message' => 'Influencer is currently offline/busy.']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/call/accept.php',
            'auth' => true,
            'role' => 'influencer',
            'desc' => 'Accept call request. Creates VideoSDK room.',
            'req' => ['request_id' => 'int, required'],
            'req_ex' => ['request_id' => 10],
            'res_ex' => ['success' => true, 'message' => 'Call accepted.', 'data' => ['meeting_id' => 'mock_meeting_abc123', 'meeting_token' => 'mock_token_xyz789', 'client_id' => 3, 'influencer_id' => 5]],
            'err' => ['404' => ['success' => false, 'message' => 'Call request not found.'], '410' => ['success' => false, 'message' => 'Call request has expired.']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/call/reject.php',
            'auth' => true,
            'role' => 'influencer',
            'desc' => 'Reject call request.',
            'req' => ['request_id' => 'int, required'],
            'req_ex' => ['request_id' => 10],
            'res_ex' => ['success' => true, 'message' => 'Call request rejected.']
        ],
        [
            'method' => 'POST',
            'path' => '/api/call/start.php',
            'auth' => true,
            'desc' => 'Start accepted call. Holds first minute in escrow. Idempotent.',
            'req' => ['request_id' => 'int, required'],
            'req_ex' => ['request_id' => 10],
            'res_ex' => ['success' => true, 'message' => 'Call started.', 'data' => ['call_id' => 42, 'meeting_id' => 'mock_meeting_abc123', 'meeting_token' => 'mock_token_xyz789', 'price_per_minute' => 100.00, 'paid_duration_seconds' => 60, 'status' => 'active']],
            'err' => ['402' => ['success' => false, 'message' => 'Insufficient coins to start call.']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/call/countdown.php',
            'auth' => true,
            'desc' => 'Get remaining seconds on active call. Auto-ends at zero.',
            'req' => ['call_id' => 'int, required'],
            'req_ex' => ['call_id' => 42],
            'res_ex' => ['success' => true, 'message' => 'Countdown retrieved.', 'data' => ['call_id' => 42, 'status' => 'active', 'remaining_seconds' => 45, 'paid_duration_seconds' => 60]]
        ],
        [
            'method' => 'POST',
            'path' => '/api/call/extend.php',
            'auth' => true,
            'role' => 'client',
            'desc' => 'Purchase additional minutes during active call.',
            'req' => ['call_id' => 'int, required', 'additional_minutes' => 'int > 0, required'],
            'req_ex' => ['call_id' => 42, 'additional_minutes' => 5],
            'res_ex' => ['success' => true, 'message' => 'Call extended.', 'data' => ['call_id' => 42, 'additional_minutes' => 5, 'additional_coins' => 500.00, 'paid_duration_seconds' => 360, 'remaining_seconds' => 320]],
            'err' => ['402' => ['success' => false, 'message' => 'Insufficient coins to extend call.']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/call/end.php',
            'auth' => true,
            'desc' => 'End active call early. Returns influencer to ONLINE.',
            'req' => ['call_id' => 'int, required'],
            'req_ex' => ['call_id' => 42],
            'res_ex' => ['success' => true, 'message' => 'Call ended.', 'data' => ['call_id' => 42, 'status' => 'completed', 'actual_duration_seconds' => 187]]
        ],
        [
            'method' => 'POST',
            'path' => '/api/call/release.php',
            'auth' => true,
            'role' => 'client',
            'desc' => 'Release escrow to influencer. Auto-releases after 30 min.',
            'req' => ['call_id' => 'int, required'],
            'req_ex' => ['call_id' => 42],
            'res_ex' => ['success' => true, 'message' => 'Escrow released.', 'data' => ['call_id' => 42, 'escrow_status' => 'released', 'amount_released' => 187.50]]
        ],
    ],

    'Chat' => [
        [
            'method' => 'GET',
            'path' => '/api/chat/list.php',
            'auth' => true,
            'desc' => 'List conversations with last message.',
            'res_ex' => ['success' => true, 'message' => 'Conversations retrieved.', 'data' => ['conversations' => [['user' => ['id' => 5, 'mystery_name' => 'Fox', 'role' => 'influencer', 'profile_photo' => 'https://api.maskedparty.com/uploads/profiles/fox.jpg'], 'last_message' => 'Hey there!', 'last_message_at' => '2026-07-20 09:00:00', 'last_message_is_mine' => false, 'unread_count' => 2]]]]
        ],
        [
            'method' => 'GET',
            'path' => '/api/chat/messages.php',
            'auth' => true,
            'desc' => 'Message history with one user. Marks messages as read.',
            'req' => ['other_user_id' => 'int, required', 'limit' => 'int, default 50', 'before_id' => 'int, for pagination'],
            'res_ex' => ['success' => true, 'message' => 'Messages retrieved.', 'data' => ['messages' => [['id' => 55, 'sender_id' => 5, 'receiver_id' => 3, 'message' => 'Hey there!', 'is_read' => true, 'created_at' => '2026-07-20 09:00:00']], 'other_user_id' => 5, 'limit' => 50]]
        ],
        [
            'method' => 'POST',
            'path' => '/api/chat/send.php',
            'auth' => true,
            'desc' => 'Send message. Contact info redacted to [BLOCKED].',
            'req' => ['receiver_id' => 'int, required', 'message' => 'string, max 1000 chars, required'],
            'req_ex' => ['receiver_id' => 5, 'message' => 'Call me later?'],
            'res_ex' => ['success' => true, 'message' => 'Message sent.', 'data' => ['message_id' => 55, 'message' => 'Call me later?']],
            'err' => ['403' => ['success' => false, 'message' => 'You can only message users after a successful video call.']]
        ],
    ],

    'Upload' => [
        [
            'method' => 'POST',
            'path' => '/api/upload/image.php',
            'auth' => true,
            'content_type' => 'multipart/form-data',
            'desc' => 'General image upload (chat attachments).',
            'req' => ['image' => 'file, required - jpg/png/webp/gif, max 10MB'],
            'res_ex' => ['success' => true, 'message' => 'Image uploaded.', 'data' => ['url' => 'https://api.maskedparty.com/uploads/chat/images/xxx.jpg']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/upload/video.php',
            'auth' => true,
            'content_type' => 'multipart/form-data',
            'desc' => 'General video upload (chat attachments).',
            'req' => ['video' => 'file, required - mp4/mov/avi/webm, max 100MB'],
            'res_ex' => ['success' => true, 'message' => 'Video uploaded.', 'data' => ['url' => 'https://api.maskedparty.com/uploads/chat/videos/xxx.mp4']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/upload/document.php',
            'auth' => true,
            'content_type' => 'multipart/form-data',
            'desc' => 'General document upload (chat attachments).',
            'req' => ['document' => 'file, required - jpg/png/pdf, max 10MB'],
            'res_ex' => ['success' => true, 'message' => 'Document uploaded.', 'data' => ['url' => 'https://api.maskedparty.com/uploads/chat/documents/xxx.pdf']]
        ],
    ],

    'Review & Report' => [
        [
            'method' => 'POST',
            'path' => '/api/review/create.php',
            'auth' => true,
            'role' => 'client',
            'desc' => 'Submit review for completed call.',
            'req' => ['call_id' => 'int, required', 'rating' => 'int 1-5, required', 'experience_text' => 'string, required'],
            'req_ex' => ['call_id' => 42, 'rating' => 5, 'experience_text' => 'Amazing conversation!'],
            'res_ex' => ['success' => true, 'message' => 'Review submitted successfully.'],
            'err' => ['409' => ['success' => false, 'message' => 'You have already submitted a review for this call.']]
        ],
        [
            'method' => 'POST',
            'path' => '/api/review/report.php',
            'auth' => true,
            'desc' => 'Report a user from a completed call.',
            'req' => ['reported_user_id' => 'int, required', 'call_id' => 'int, required', 'reason' => 'string, required', 'description' => 'string, required'],
            'req_ex' => ['reported_user_id' => 5, 'call_id' => 42, 'reason' => 'Inappropriate behavior', 'description' => 'The user was rude during the call.'],
            'res_ex' => ['success' => true, 'message' => 'User reported successfully. An admin will review it shortly.'],
            'err' => ['409' => ['success' => false, 'message' => 'You have already reported this call.']]
        ],
    ],

    'Admin' => [
        [
            'method' => 'GET/POST',
            'path' => '/api/admin/dashboard.php',
            'auth' => true,
            'role' => 'admin',
            'desc' => 'Platform stats dashboard.',
            'res_ex' => ['success' => true, 'message' => 'Dashboard data retrieved.', 'data' => ['total_users' => 1250, 'total_influencers' => 85, 'total_calls' => 320, 'total_revenue' => 1250.00, 'pending_verifications' => 12]]
        ],
        [
            'method' => 'GET/POST',
            'path' => '/api/admin/users.php',
            'auth' => true,
            'role' => 'admin',
            'desc' => 'User management: list, suspend, activate, ban.',
            'req' => ['action' => 'list | details | suspend | activate | ban'],
            'res_ex' => ['success' => true, 'message' => 'User list retrieved.', 'data' => ['users' => [['id' => 1, 'email' => 'user@example.com', 'mystery_name' => 'ShadowGhost', 'role' => 'client', 'status' => 'active']]]]
        ],
        [
            'method' => 'GET/POST',
            'path' => '/api/admin/verification.php',
            'auth' => true,
            'role' => 'admin',
            'desc' => 'KYC verification management.',
            'req' => ['action' => 'list | approve | reject | request_resubmission'],
            'res_ex' => ['success' => true, 'message' => 'Verification list retrieved.', 'data' => ['pending' => [['influencer_id' => 5, 'mystery_name' => 'Fox', 'submitted_at' => '2026-07-19 10:00:00']]]]
        ],
        [
            'method' => 'GET/POST',
            'path' => '/api/admin/withdrawals.php',
            'auth' => true,
            'role' => 'admin',
            'desc' => 'Withdrawal management.',
            'req' => ['action' => 'list | approve | reject'],
            'res_ex' => ['success' => true, 'message' => 'Withdrawal list retrieved.', 'data' => ['pending' => [['withdrawal_id' => 1, 'influencer_id' => 5, 'mystery_name' => 'Fox', 'amount' => 50.00]]]]
        ],
        [
            'method' => 'GET/POST',
            'path' => '/api/admin/reports.php',
            'auth' => true,
            'role' => 'admin',
            'desc' => 'Report management.',
            'req' => ['action' => 'list | details | dismiss | suspend_user | ban_user'],
            'res_ex' => ['success' => true, 'message' => 'Reports list retrieved.', 'data' => ['reports' => [['report_id' => 1, 'reported_user_id' => 5, 'reason' => 'Inappropriate behavior', 'status' => 'pending']]]]
        ],
        [
            'method' => 'GET/POST',
            'path' => '/api/admin/coin-packages.php',
            'auth' => true,
            'role' => 'admin',
            'desc' => 'Manage coin packages. Determines platform-wide call price.',
            'req' => ['action' => 'list | create | update | enable | disable'],
            'res_ex' => ['success' => true, 'message' => 'Packages retrieved.', 'data' => ['packages' => [['package_id' => 1, 'package_name' => 'Starter', 'price' => 4.99, 'currency' => 'usd', 'coins' => 500, 'minutes' => 5, 'is_popular' => false, 'is_best_value' => true, 'is_active' => true]]]]
        ],
    ],
];

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------
$reference = [
    'api_name' => 'Masked Party API',
    'version' => defined('API_VERSION') ? API_VERSION : '1.0.0',
    'base_url' => defined('BASE_URL') ? BASE_URL : null,
    'status' => 'healthy',
    'how_to_use_this_doc' => 'Call endpoints by literal file path. Send JSON bodies with Content-Type: application/json for POST endpoints. File uploads use multipart/form-data.',
    'authentication' => $auth,
    'response_envelope' => $responseEnvelope,
    'media_and_uploads' => $mediaUrls,
    'endpoints' => $endpoints,
];

if ($format === 'html') {
    header('Content-Type: text/html; charset=utf-8');

    $slugify = function ($s) {
        $s = strtolower($s);
        $s = preg_replace('/[^a-z0-9]+/', '-', $s);
        return trim($s, '-');
    };

    $totalEndpoints = 0;
    foreach ($endpoints as $items) { $totalEndpoints += count($items); }
    ?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Masked Party API &middot; Reference</title>
<link rel="icon" href="data:,">
<style>
  *{margin:0;padding:0;box-sizing:border-box;}
  body{background:#141119;color:#f0ecf8;font-family:system-ui,-apple-system,sans-serif;line-height:1.6;}
  ::selection{background:#cda149;color:#1a1522;}
  a{color:#c6aaf0;text-decoration:none;}
  a:hover{text-decoration:underline;}
  code{font-family:monospace;font-size:12.5px;background:#0f0d14;padding:2px 6px;border-radius:4px;color:#e7c882;}

  .shell{display:flex;min-height:100vh;}
  .sidebar{width:280px;flex:0 0 280px;background:#0f0d14;border-right:1px solid #2a2438;position:sticky;top:0;height:100vh;overflow-y:auto;padding:20px 14px;}
  .brand{font-size:18px;font-weight:600;padding:0 6px 16px;display:flex;align-items:center;gap:10px;}
  .brand small{font-size:11px;font-weight:400;color:#736a8a;display:block;}
  #search{width:100%;background:#1c1826;border:1px solid #332c46;color:#f0ecf8;border-radius:8px;padding:8px 12px;font-size:13px;margin-bottom:16px;}
  #search:focus{outline:none;border-color:#cda149;}
  .nav-group{margin-bottom:4px;}
  .nav-group-title{font-size:11px;text-transform:uppercase;color:#736a8a;padding:10px 6px 4px;font-weight:600;letter-spacing:.08em;}
  .nav-link{display:flex;align-items:center;gap:8px;padding:5px 8px;border-radius:6px;font-size:12px;color:#b3a9c9;font-family:monospace;}
  .nav-link:hover{background:#1c1826;color:#f0ecf8;text-decoration:none;}
  .nav-link.active{background:#231e30;color:#e7c882;}
  .tag{font-size:9px;font-weight:700;padding:1px 5px;border-radius:4px;flex:none;}
  .tag-get{background:rgba(104,211,160,.14);color:#68d3a0;}
  .tag-post{background:rgba(166,127,224,.16);color:#c6aaf0;}
  .tag-mixed{background:rgba(205,161,73,.16);color:#e7c882;}
  .nav-count{font-size:10px;color:#736a8a;}
  .sidebar-foot{margin-top:16px;padding-top:12px;border-top:1px solid #2a2438;font-size:11px;color:#736a8a;}
  .logout-link{color:#ea6e88;cursor:pointer;background:none;border:none;font-size:11px;}

  .content{flex:1;padding:0 0 80px;}
  .topbar{display:none;position:sticky;top:0;background:rgba(20,17,25,.92);backdrop-filter:blur(6px);padding:12px 20px;border-bottom:1px solid #2a2438;}
  .menu-btn{background:#1c1826;border:1px solid #332c46;color:#f0ecf8;border-radius:6px;padding:6px 10px;}

  .hero{padding:48px 48px 36px;border-bottom:1px solid #2a2438;}
  h1{font-size:34px;font-weight:600;margin:8px 0 6px;}
  .hero p{color:#b3a9c9;max-width:600px;}
  .meta{display:flex;flex-wrap:wrap;gap:8px;margin-top:16px;}
  .pill{background:#1c1826;border:1px solid #332c46;padding:4px 12px;border-radius:999px;font-size:12px;font-family:monospace;color:#b3a9c9;}

  .section{padding:32px 48px;border-bottom:1px solid #2a2438;scroll-margin-top:16px;}
  h2{font-size:22px;font-weight:600;margin-bottom:4px;}
  .sec-desc{color:#b3a9c9;margin-bottom:16px;}

  .endpoint{background:#1c1826;border:1px solid #332c46;border-radius:10px;margin-bottom:12px;overflow:hidden;}
  .endpoint-head{display:flex;align-items:center;flex-wrap:wrap;gap:8px;padding:12px 16px;border-bottom:1px solid #2a2438;}
  .method{font-family:monospace;font-weight:700;font-size:11px;padding:3px 8px;border-radius:4px;}
  .method-get{background:rgba(104,211,160,.15);color:#68d3a0;border:1px solid rgba(104,211,160,.3);}
  .method-post{background:rgba(166,127,224,.16);color:#c6aaf0;border:1px solid rgba(166,127,224,.32);}
  .method-mixed{background:rgba(205,161,73,.16);color:#e7c882;border:1px solid rgba(205,161,73,.32);}
  .path{font-family:monospace;font-size:13px;color:#f0ecf8;word-break:break-all;}
  .badge{font-size:10px;font-weight:600;padding:2px 8px;border-radius:999px;}
  .badge-auth{background:rgba(205,161,73,.14);color:#e7c882;border:1px solid rgba(205,161,73,.28);}
  .badge-public{color:#736a8a;border:1px solid #332c46;}
  .badge-role{background:rgba(122,179,236,.14);color:#7ab3ec;border:1px solid rgba(122,179,236,.28);}

  .endpoint-body{padding:14px 16px;}
  .desc{color:#b3a9c9;font-size:13.5px;margin-bottom:10px;}
  .subhead{font-size:10.5px;text-transform:uppercase;color:#736a8a;font-weight:700;letter-spacing:.08em;margin:12px 0 4px;}
  .kv{width:100%;border-collapse:collapse;font-size:12.5px;margin:4px 0 8px;}
  .kv td{padding:4px 8px;border-bottom:1px solid #2a2438;vertical-align:top;}
  .kv td:first-child{font-family:monospace;color:#e7c882;white-space:nowrap;width:1%;}
  .kv td:last-child{color:#b3a9c9;}
  .example{background:#0f0d14;border:1px solid #2a2438;border-radius:6px;padding:10px 12px;margin:4px 0 8px;overflow-x:auto;font-family:monospace;font-size:12px;color:#b3a9c9;}
  .example .label{font-size:10px;text-transform:uppercase;color:#736a8a;margin-bottom:4px;}
  .err{background:#0f0d14;border-left:2px solid #ea6e88;border-radius:4px;padding:6px 10px;margin:4px 0 8px;font-family:monospace;font-size:12px;color:#b3a9c9;}
  .notes{font-size:12px;color:#736a8a;padding:8px 10px;background:#0f0d14;border-radius:6px;border:1px dashed #332c46;margin-top:8px;}

  .no-results{display:none;color:#736a8a;padding:30px 4px;text-align:center;}

  @media(max-width:900px){
    .sidebar{position:fixed;left:0;top:0;z-index:20;transform:translateX(-100%);transition:transform .2s;box-shadow:0 0 40px rgba(0,0,0,.5);}
    .sidebar.open{transform:translateX(0);}
    .topbar{display:flex;}
    .hero{padding:32px 20px;}
    .section{padding:24px 20px;}
  }
</style>
</head>
<body>

<div class="shell">
  <aside class="sidebar" id="sidebar">
    <div class="brand">🎭 Masked Party <small>API Ref</small></div>
    <input id="search" type="text" placeholder="Search endpoints...">
    <nav>
      <div class="nav-group"><div class="nav-group-title">Guide</div>
        <a class="nav-link" href="#auth">🔐 Auth</a>
        <a class="nav-link" href="#response">📦 Response</a>
        <a class="nav-link" href="#uploads">📤 Uploads</a>
      </div>
      <?php foreach ($endpoints as $group => $items): ?>
      <div class="nav-group">
        <div class="nav-group-title"><?= htmlspecialchars($group) ?> <span class="nav-count"><?= count($items) ?></span></div>
        <?php foreach ($items as $ep):
          $tag = 'tag-mixed';
          if ($ep['method'] === 'GET') $tag = 'tag-get';
          elseif ($ep['method'] === 'POST') $tag = 'tag-post';
          $id = $slugify($ep['method'] . '-' . $ep['path']);
          $short = preg_replace('#^/api/#', '', $ep['path']);
        ?>
        <a class="nav-link" data-search="<?= strtolower($ep['method'] . ' ' . $ep['path']) ?>" href="#<?= $id ?>">
          <span class="tag <?= $tag ?>"><?= htmlspecialchars($ep['method']) ?></span>
          <span><?= htmlspecialchars($short) ?></span>
        </a>
        <?php endforeach; ?>
      </div>
      <?php endforeach; ?>
    </nav>
    <div class="sidebar-foot">
      <?= $totalEndpoints ?> endpoints &middot; v<?= htmlspecialchars($reference['version']) ?><br>
      <a href="?format=json">JSON</a> &middot;
      <form method="POST" style="display:inline;">
        <input type="hidden" name="doc_logout" value="1">
        <button type="submit" class="logout-link">🔒 Lock</button>
      </form>
    </div>
  </aside>

  <main class="content">
    <div class="topbar">
      <button class="menu-btn" id="menuBtn">☰ Menu</button>
    </div>

    <div class="hero">
      <span style="color:#e7c882;font-family:monospace;font-size:12px;">● <?= htmlspecialchars($reference['status']) ?> &middot; v<?= htmlspecialchars($reference['version']) ?></span>
      <h1>Masked Party API</h1>
      <p>Every request and response shape the mobile app needs. Each endpoint called directly by its file path.</p>
      <div class="meta">
        <span class="pill">Base: <?= htmlspecialchars($reference['base_url'] ?: $_SERVER['HTTP_HOST'] ?? 'api.maskedparty.com') ?></span>
        <span class="pill"><?= $totalEndpoints ?> endpoints</span>
        <span class="pill">Bearer token auth</span>
        <span class="pill" style="border-color:rgba(94,207,207,.3);color:#5ecfcf;">✓ OTP verification</span>
      </div>
    </div>

    <section class="section" id="auth">
      <h2>Authentication</h2>
      <p class="sec-desc">Bearer token from login or registration.</p>
      <table class="kv">
        <?php foreach ($auth as $k => $v): if ($k === 'notes') continue; ?>
        <tr><td><?= htmlspecialchars($k) ?></td><td><?= htmlspecialchars(is_string($v) ? $v : json_encode($v)) ?></td></tr>
        <?php endforeach; ?>
      </table>
      <div style="font-size:13px;color:#b3a9c9;margin-top:8px;">
        <?php foreach ($auth['notes'] as $n): ?>• <?= htmlspecialchars($n) ?><br><?php endforeach; ?>
      </div>
    </section>

    <section class="section" id="response">
      <h2>Response Format</h2>
      <p class="sec-desc">Every response follows the same envelope.</p>
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:8px;margin:8px 0;">
        <?php foreach ($responseEnvelope as $key => $info): ?>
        <div style="background:#1c1826;border:1px solid #332c46;border-radius:8px;padding:10px 12px;">
          <div style="font-family:monospace;font-size:11px;color:#e7c882;"><?= htmlspecialchars(str_replace('_', ' ', $key)) ?><?= isset($info['http_status']) ? ' (HTTP ' . $info['http_status'] . ')' : '' ?></div>
          <div style="font-size:12px;color:#b3a9c9;"><?= htmlspecialchars($info['description']) ?></div>
        </div>
        <?php endforeach; ?>
      </div>
    </section>

    <section class="section" id="uploads">
      <h2>Media & Uploads</h2>
      <p class="sec-desc"><?= htmlspecialchars($mediaUrls['description']) ?></p>
      <table class="kv">
        <?php foreach ($mediaUrls['uploads'] as $type => $rules): ?>
        <tr><td><?= htmlspecialchars($type) ?></td><td>max <?= (int)$rules['max_size_mb'] ?>MB &middot; <?= htmlspecialchars(implode(', ', $rules['allowed'])) ?></td></tr>
        <?php endforeach; ?>
      </table>
      <p style="font-size:13px;color:#b3a9c9;margin-top:6px;">Encoding: <?= htmlspecialchars($mediaUrls['upload_encoding']) ?></p>
    </section>

    <?php foreach ($endpoints as $group => $items): ?>
    <section class="section" id="group-<?= $slugify($group) ?>">
      <h2><?= htmlspecialchars($group) ?></h2>
      <?php foreach ($items as $ep):
        $methodClass = 'method-mixed';
        if ($ep['method'] === 'GET') $methodClass = 'method-get';
        elseif ($ep['method'] === 'POST') $methodClass = 'method-post';
        $id = $slugify($ep['method'] . '-' . $ep['path']);
      ?>
      <div class="endpoint" id="<?= $id ?>" data-search="<?= strtolower($ep['method'] . ' ' . $ep['path']) ?>">
        <div class="endpoint-head">
          <span class="method <?= $methodClass ?>"><?= htmlspecialchars($ep['method']) ?></span>
          <span class="path"><?= htmlspecialchars($ep['path']) ?></span>
          <?php if (!empty($ep['auth'])): ?>
            <span class="badge badge-auth">🔒 auth<?= isset($ep['role']) ? ' · ' . htmlspecialchars($ep['role']) : '' ?></span>
          <?php else: ?>
            <span class="badge badge-public">public</span>
          <?php endif; ?>
          <?php if (!empty($ep['role'])): ?><span class="badge badge-role">🎯 <?= htmlspecialchars($ep['role']) ?></span><?php endif; ?>
        </div>
        <div class="endpoint-body">
          <div class="desc"><?= htmlspecialchars($ep['desc'] ?? '') ?></div>
          <?php if (!empty($ep['content_type'])): ?>
            <div style="font-family:monospace;font-size:12px;color:#e7c882;margin-bottom:8px;">Content-Type: <?= htmlspecialchars($ep['content_type']) ?></div>
          <?php endif; ?>

          <?php if (!empty($ep['req']) && is_array($ep['req'])): ?>
            <div class="subhead">Request fields</div>
            <table class="kv">
              <?php foreach ($ep['req'] as $k => $v): ?>
                <tr><td><?= htmlspecialchars($k) ?></td><td><?= htmlspecialchars($v) ?></td></tr>
              <?php endforeach; ?>
            </table>
          <?php endif; ?>

          <?php if (!empty($ep['req_ex'])): ?>
            <div class="subhead">Example request</div>
            <div class="example"><div class="label">Request body</div><pre style="margin:0;"><?= htmlspecialchars(json_encode($ep['req_ex'], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)) ?></pre></div>
          <?php endif; ?>

          <?php if (!empty($ep['res_ex'])): ?>
            <div class="subhead">Example response</div>
            <div class="example"><div class="label">Response body</div><pre style="margin:0;"><?= htmlspecialchars(json_encode($ep['res_ex'], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)) ?></pre></div>
          <?php endif; ?>

          <?php if (!empty($ep['err'])): ?>
            <div class="subhead">Error responses</div>
            <?php foreach ($ep['err'] as $code => $body): ?>
              <div class="err"><strong style="color:#ea6e88;">HTTP <?= htmlspecialchars($code) ?></strong><br><pre style="margin:4px 0 0;font-size:11px;"><?= htmlspecialchars(json_encode($body, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)) ?></pre></div>
            <?php endforeach; ?>
          <?php endif; ?>

          <?php if (!empty($ep['notes'])): ?>
            <div class="notes">💡 <?= htmlspecialchars($ep['notes']) ?></div>
          <?php endif; ?>
        </div>
      </div>
      <?php endforeach; ?>
    </section>
    <?php endforeach; ?>

    <p class="no-results" id="noResults">No endpoints match your search.</p>

    <footer style="padding:24px 48px 40px;color:#736a8a;font-size:12px;">
      Masked Party API &middot; v<?= htmlspecialchars($reference['version']) ?> &middot; <a href="?format=json">View raw JSON</a>
    </footer>
  </main>
</div>

<script>
(function(){
  var sidebar = document.getElementById('sidebar');
  var menuBtn = document.getElementById('menuBtn');
  if (menuBtn) menuBtn.addEventListener('click', function(){ sidebar.classList.toggle('open'); });
  sidebar.addEventListener('click', function(e){ if (e.target.tagName === 'A' && window.innerWidth <= 900) sidebar.classList.remove('open'); });

  var search = document.getElementById('search');
  var endpoints = Array.from(document.querySelectorAll('[data-search]'));
  var noResults = document.getElementById('noResults');

  search.addEventListener('input', function(){
    var q = this.value.trim().toLowerCase();
    var any = false;
    endpoints.forEach(function(el){
      var match = !q || (el.getAttribute('data-search') || '').indexOf(q) !== -1;
      el.style.display = match ? '' : 'none';
      if (match) any = true;
    });
    noResults.style.display = (q && !any) ? 'block' : 'none';
  });

  // Copy buttons
  document.querySelectorAll('.example pre').forEach(function(pre){
    var btn = document.createElement('button');
    btn.textContent = 'Copy';
    btn.style.cssText = 'position:absolute;top:4px;right:4px;background:#1c1826;border:1px solid #332c46;color:#b3a9c9;border-radius:4px;padding:2px 8px;font-size:10px;cursor:pointer;';
    var wrapper = pre.parentElement;
    wrapper.style.position = 'relative';
    wrapper.appendChild(btn);
    btn.addEventListener('click', function(){
      navigator.clipboard && navigator.clipboard.writeText(pre.textContent).then(function(){
        btn.textContent = 'Copied!';
        setTimeout(function(){ btn.textContent = 'Copy'; }, 1200);
      });
    });
  });
})();
</script>
</body>
</html>
    <?php
    exit;
}

// Default: JSON reference
sendResponse(true, 'Masked Party API reference. Add ?format=json to view this as raw JSON.', $reference);