<?php
/**
 * Shared Helper Functions
 */

require_once __DIR__ . '/response.php';

/**
 * Sanitize and validate input
 */
function getJsonInput() {
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        sendError('Invalid JSON request body.', 400);
    }

    return $data;
}

/**
 * NOTE: This escapes HTML special characters for safe display/output.
 * It does NOT protect against SQL injection (PDO prepared statements handle that)
 * and must NOT be applied to values before storing them, since it will
 * permanently corrupt data containing characters like & ' " < > (e.g. names,
 * O'Brien-style apostrophes, bios containing "<3", etc.), and will double-encode
 * on every subsequent edit. This API returns JSON, not rendered HTML, so
 * consumers (mobile/web clients) are responsible for escaping at their own
 * render layer. Use sanitize() only if/when building an HTML page directly
 * from stored data — never on the write path.
 */
function sanitize($data) {
    if (is_array($data)) {
        return array_map('sanitize', $data);
    }
    return trim(htmlspecialchars($data, ENT_QUOTES, 'UTF-8'));
}

/**
 * Lenient JSON body reader for endpoints that route their primary action
 * via query string (?action=...) but accept an optional JSON body for
 * extra fields (e.g. admin_note). Unlike getJsonInput(), this does NOT
 * call sendValidationError() on an empty or missing body — it simply
 * returns []. Only truly malformed (non-empty, invalid) JSON is rejected.
 */
function getJsonBody() {
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $data = json_decode($raw, true);
    if (json_last_error() !== JSON_ERROR_NONE || !is_array($data)) {
        sendValidationError('Invalid JSON request body.');
    }
    return $data;
}

/**
 * Returns the user_id of every active admin account, for notifications
 * that need to reach "the admins" (e.g. new withdrawal request, auto-
 * suspension alert). Replaces the old hardcoded "user id 1 is the admin"
 * convention, which silently breaks if the admin account isn't id 1 or
 * if there is more than one admin.
 *
 * @return int[]
 */
function getAdminUserIds(PDO $db) {
    $stmt = $db->prepare("SELECT id FROM users WHERE role = 'admin' AND status != 'banned'");
    $stmt->execute();
    return array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));
}

// ---------------------------------------------------------------------------
// Upload directory bootstrap
// ---------------------------------------------------------------------------

/**
 * Ensure the uploads/ directory tree exists and is safe.
 * Called once at startup so all subdirs are ready before any upload attempt.
 */
function ensureUploadDirectories() {
    $dirs = [
        UPLOAD_BASE_DIR . 'profiles',
        UPLOAD_BASE_DIR . 'gallery',
        UPLOAD_BASE_DIR . 'verification',
        UPLOAD_BASE_DIR . 'chat/images',
        UPLOAD_BASE_DIR . 'chat/videos',
        UPLOAD_BASE_DIR . 'chat/documents',
        UPLOAD_BASE_DIR . 'temp',
    ];
    foreach ($dirs as $dir) {
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
    }
}

/**
 * Safely create a directory, rejecting any path that escapes UPLOAD_BASE_DIR.
 *
 * @param  string $relativePath  e.g. "gallery/user_15"
 * @return string                Absolute path of the created directory.
 */
function safeCreateUploadDir($relativePath) {
    // Normalise: strip leading slashes, collapse dots
    $relativePath = ltrim($relativePath, '/\\');

    // Block traversal attempts
    if (preg_match('#(^|[\\\\/])\.\.#', $relativePath)) {
        error_log("Upload directory traversal attempt blocked: $relativePath");
        return false;
    }

    $absPath = rtrim(UPLOAD_BASE_DIR, '/') . '/' . $relativePath;

    // Resolve symlinks / relative components and re-check the prefix
    // realpath() returns false for non-existent paths, so work with the
    // already-validated string; after creation we verify the real path.
    if (!is_dir($absPath)) {
        if (!mkdir($absPath, 0755, true)) {
            return false;
        }
    }

    // After creation, verify the real path still lives under UPLOAD_BASE_DIR
    $real = realpath($absPath);
    $base = realpath(UPLOAD_BASE_DIR);
    if ($real === false || $base === false || strpos($real, $base) !== 0) {
        error_log("Upload directory traversal detected post-creation: $absPath");
        return false;
    }

    return $absPath;
}

/**
 * Generate a cryptographically random filename (no extension yet).
 */
function randomFilename() {
    return bin2hex(random_bytes(16));
}

// ---------------------------------------------------------------------------
// MIME / extension maps
// ---------------------------------------------------------------------------

/** Allowed MIME types and their safe extensions, keyed by upload category. */
function getAllowedMimeMap() {
    return [
        'image' => [
            'image/jpeg'  => 'jpg',
            'image/png'   => 'png',
            'image/webp'  => 'webp',
            'image/gif'   => 'gif',
        ],
        'video' => [
            'video/mp4'       => 'mp4',
            'video/quicktime' => 'mov',
            'video/x-msvideo' => 'avi',
            'video/webm'      => 'webm',
        ],
        'document' => [
            'image/jpeg'      => 'jpg',
            'image/png'       => 'png',
            'application/pdf' => 'pdf',
        ],
    ];
}

/** Never-allow extensions regardless of declared MIME type. */
function getDangerousExtensions() {
    return [
        'php', 'php3', 'php4', 'php5', 'php7', 'phtml', 'phar',
        'asp', 'aspx', 'jsp', 'jspx', 'cfm',
        'cgi', 'pl', 'py', 'rb', 'sh', 'bash', 'bat', 'cmd',
        'exe', 'dll', 'so', 'bin',
        'htaccess', 'htpasswd',
        'svg',   // can embed JS
        'xml',
        'html', 'htm', 'xhtml',
        'js', 'ts', 'json',
    ];
}

// ---------------------------------------------------------------------------
// Core validation helper
// ---------------------------------------------------------------------------

/**
 * Validate an uploaded $_FILES entry.
 *
 * Returns ['ok' => true, 'mime' => string, 'ext' => string]
 * or      ['ok' => false, 'message' => string]
 *
 * @param  array  $file      One entry from $_FILES
 * @param  string $category  'image' | 'video' | 'document'
 * @param  int    $maxBytes  Maximum allowed file size in bytes
 */
function validateUploadedFile(array $file, $category, $maxBytes) {
    $allowedMap = getAllowedMimeMap();

    if (!isset($allowedMap[$category])) {
        return ['ok' => false, 'message' => 'Invalid upload category.'];
    }

    // PHP upload error check
    if (!isset($file['error']) || $file['error'] !== UPLOAD_ERR_OK) {
        $codes = [
            UPLOAD_ERR_INI_SIZE   => 'File exceeds server upload size limit.',
            UPLOAD_ERR_FORM_SIZE  => 'File exceeds form upload size limit.',
            UPLOAD_ERR_PARTIAL    => 'File was only partially uploaded.',
            UPLOAD_ERR_NO_FILE    => 'No file was uploaded.',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder.',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk.',
            UPLOAD_ERR_EXTENSION  => 'Upload stopped by a PHP extension.',
        ];
        $msg = $codes[$file['error'] ?? -1] ?? 'Unknown upload error.';
        return ['ok' => false, 'message' => $msg];
    }

    // Must be a genuine HTTP upload
    if (!is_uploaded_file($file['tmp_name'])) {
        return ['ok' => false, 'message' => 'Invalid upload source.'];
    }

    // Size check
    if ($file['size'] > $maxBytes) {
        $mb = round($maxBytes / 1048576);
        return ['ok' => false, 'message' => "File exceeds the {$mb} MB size limit."];
    }

    // Verify via libmagic — do NOT trust the client-supplied MIME or filename
    $finfo    = new finfo(FILEINFO_MIME_TYPE);
    $mimeType = $finfo->file($file['tmp_name']);

    $mimeToExt = $allowedMap[$category];

    if (!array_key_exists($mimeType, $mimeToExt)) {
        return ['ok' => false, 'message' => "File type '{$mimeType}' is not allowed for {$category} uploads."];
    }

    $ext = $mimeToExt[$mimeType];

    // Guard against dangerous extensions derived from the MIME map itself
    if (in_array(strtolower($ext), getDangerousExtensions(), true)) {
        return ['ok' => false, 'message' => 'File type is not permitted.'];
    }

    // Also validate the client-supplied filename extension as a secondary check
    $originalExt = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
    if (in_array($originalExt, getDangerousExtensions(), true)) {
        return ['ok' => false, 'message' => 'File extension is not permitted.'];
    }

    return ['ok' => true, 'mime' => $mimeType, 'ext' => $ext];
}

// ---------------------------------------------------------------------------
// Specific upload handlers
// ---------------------------------------------------------------------------

/**
 * Upload a profile picture.
 * Stored at: uploads/profiles/profile_<random>.<ext>
 * DB path  : profiles/profile_<random>.<ext>
 *
 * @param  array $file  $_FILES entry
 * @return array        ['success' => bool, 'url' => string, 'path' => string] or error
 */
function uploadProfilePhoto(array $file) {
    $validation = validateUploadedFile($file, 'image', MAX_IMAGE_SIZE);
    if (!$validation['ok']) {
        return ['success' => false, 'message' => $validation['message']];
    }

    $dir = safeCreateUploadDir('profiles');
    if (!$dir) {
        return ['success' => false, 'message' => 'Failed to prepare upload directory.'];
    }

    $filename    = 'profile_' . randomFilename() . '.' . $validation['ext'];
    $absPath     = $dir . '/' . $filename;
    $storedPath  = 'profiles/' . $filename;           // relative — store in DB
    $publicUrl   = BASE_URL . '/uploads/' . $storedPath;

    if (!move_uploaded_file($file['tmp_name'], $absPath)) {
        return ['success' => false, 'message' => 'Failed to save uploaded file.'];
    }

    return ['success' => true, 'url' => $publicUrl, 'path' => $storedPath];
}

/**
 * Upload a gallery image or video for an influencer.
 * Stored at: uploads/gallery/user_<id>/<random>.<ext>
 * DB path  : gallery/user_<id>/<random>.<ext>
 *
 * @param  array $file    $_FILES entry
 * @param  int   $userId  Influencer user ID
 * @return array
 */
function uploadGalleryFile(array $file, $userId) {
    // Detect whether it is an image or video by trying both MIME maps
    $mimeMap   = getAllowedMimeMap();
    $finfo     = new finfo(FILEINFO_MIME_TYPE);
    $mimeType  = $finfo->file($file['tmp_name'] ?? '');

    if (array_key_exists($mimeType, $mimeMap['image'])) {
        $category = 'image';
        $maxBytes = MAX_IMAGE_SIZE;
    } elseif (array_key_exists($mimeType, $mimeMap['video'])) {
        $category = 'video';
        $maxBytes = MAX_VIDEO_SIZE;
    } else {
        return ['success' => false, 'message' => "File type '{$mimeType}' is not allowed in gallery uploads."];
    }

    $validation = validateUploadedFile($file, $category, $maxBytes);
    if (!$validation['ok']) {
        return ['success' => false, 'message' => $validation['message']];
    }

    $userId  = (int)$userId;
    $subDir  = 'gallery/user_' . $userId;
    $dir     = safeCreateUploadDir($subDir);
    if (!$dir) {
        return ['success' => false, 'message' => 'Failed to prepare upload directory.'];
    }

    // Use sequential naming inside the user folder
    $prefix     = ($category === 'video') ? 'video' : 'img';
    $filename   = $prefix . '_' . randomFilename() . '.' . $validation['ext'];
    $absPath    = $dir . '/' . $filename;
    $storedPath = $subDir . '/' . $filename;
    $publicUrl  = BASE_URL . '/uploads/' . $storedPath;

    if (!move_uploaded_file($file['tmp_name'], $absPath)) {
        return ['success' => false, 'message' => 'Failed to save uploaded file.'];
    }

    return ['success' => true, 'url' => $publicUrl, 'path' => $storedPath];
}

/**
 * Upload an influencer verification document.
 * Stored at: uploads/verification/user_<id>/<slot>.<ext>
 * Slot is one of: id_front, id_back, selfie  (or a random name for video)
 * DB path  : verification/user_<id>/<slot>.<ext>
 *
 * @param  array  $file    $_FILES entry
 * @param  int    $userId  Influencer user ID
 * @param  string $slot    Logical slot: 'id_front' | 'id_back' | 'selfie' | 'video'
 * @return array
 */
function uploadVerificationFile(array $file, $userId, $slot) {
    $allowedSlots = ['id_front', 'id_back', 'selfie', 'video'];
    if (!in_array($slot, $allowedSlots, true)) {
        return ['success' => false, 'message' => 'Invalid verification slot.'];
    }

    $isVideo  = ($slot === 'video');
    $category = $isVideo ? 'video'    : 'document';
    $maxBytes = $isVideo ? MAX_VIDEO_SIZE : MAX_DOCUMENT_SIZE;

    $validation = validateUploadedFile($file, $category, $maxBytes);
    if (!$validation['ok']) {
        return ['success' => false, 'message' => $validation['message']];
    }

    $userId  = (int)$userId;
    $subDir  = 'verification/user_' . $userId;
    $dir     = safeCreateUploadDir($subDir);
    if (!$dir) {
        return ['success' => false, 'message' => 'Failed to prepare upload directory.'];
    }

    $filename   = $slot . '.' . $validation['ext'];
    $absPath    = $dir . '/' . $filename;
    $storedPath = $subDir . '/' . $filename;
    $publicUrl  = BASE_URL . '/uploads/' . $storedPath;

    if (!move_uploaded_file($file['tmp_name'], $absPath)) {
        return ['success' => false, 'message' => 'Failed to save uploaded file.'];
    }

    return ['success' => true, 'url' => $publicUrl, 'path' => $storedPath];
}

/**
 * Upload a chat media file (image, video, or document).
 * Stored at: uploads/chat/<type>s/<random>.<ext>   (e.g. chat/images/abc.jpg)
 * DB path  : chat/images/<random>.jpg
 *
 * @param  array  $file      $_FILES entry
 * @param  string $category  'image' | 'video' | 'document'
 * @return array
 */
function uploadChatFile(array $file, $category) {
    $maxBytes = ($category === 'video') ? MAX_VIDEO_SIZE :
                (($category === 'document') ? MAX_DOCUMENT_SIZE : MAX_IMAGE_SIZE);

    $validation = validateUploadedFile($file, $category, $maxBytes);
    if (!$validation['ok']) {
        return ['success' => false, 'message' => $validation['message']];
    }

    // Subfolder mapping
    $subfolderMap = [
        'image'    => 'images',
        'video'    => 'videos',
        'document' => 'documents',
    ];
    $subfolder  = $subfolderMap[$category];
    $subDir     = 'chat/' . $subfolder;
    $dir        = safeCreateUploadDir($subDir);
    if (!$dir) {
        return ['success' => false, 'message' => 'Failed to prepare upload directory.'];
    }

    $filename   = randomFilename() . '.' . $validation['ext'];
    $absPath    = $dir . '/' . $filename;
    $storedPath = $subDir . '/' . $filename;
    $publicUrl  = BASE_URL . '/uploads/' . $storedPath;

    if (!move_uploaded_file($file['tmp_name'], $absPath)) {
        return ['success' => false, 'message' => 'Failed to save uploaded file.'];
    }

    return ['success' => true, 'url' => $publicUrl, 'path' => $storedPath];
}

/**
 * Upload a temporary file.
 * Stored at: uploads/temp/<random>.<ext>
 * DB path  : temp/<random>.<ext>
 *
 * @param  array  $file      $_FILES entry
 * @param  string $category  'image' | 'video' | 'document'
 * @return array
 */
function uploadTempFile(array $file, $category) {
    $maxBytes = ($category === 'video') ? MAX_VIDEO_SIZE :
                (($category === 'document') ? MAX_DOCUMENT_SIZE : MAX_IMAGE_SIZE);

    $validation = validateUploadedFile($file, $category, $maxBytes);
    if (!$validation['ok']) {
        return ['success' => false, 'message' => $validation['message']];
    }

    $dir = safeCreateUploadDir('temp');
    if (!$dir) {
        return ['success' => false, 'message' => 'Failed to prepare upload directory.'];
    }

    $filename   = randomFilename() . '.' . $validation['ext'];
    $absPath    = $dir . '/' . $filename;
    $storedPath = 'temp/' . $filename;
    $publicUrl  = BASE_URL . '/uploads/' . $storedPath;

    if (!move_uploaded_file($file['tmp_name'], $absPath)) {
        return ['success' => false, 'message' => 'Failed to save uploaded file.'];
    }

    return ['success' => true, 'url' => $publicUrl, 'path' => $storedPath];
}

/**
 * Legacy generic upload helper — kept for backwards compatibility.
 * New code should use the specific helpers above.
 *
 * @param  array  $file  $_FILES entry
 * @param  string $type  'image' | 'video' | 'document'
 * @return array
 */
function handleUpload($file, $type) {
    return uploadChatFile($file, $type);
}

/**
 * Build the public URL from a relative stored path.
 * e.g. storedPathToUrl('profiles/profile_abc.jpg')
 *      => 'https://api.maskedparty.com/uploads/profiles/profile_abc.jpg'
 */
function storedPathToUrl($storedPath) {
    if (empty($storedPath)) return null;
    // If it already looks like a full URL, return as-is
    if (preg_match('#^https?://#i', $storedPath)) return $storedPath;
    return BASE_URL . '/uploads/' . ltrim($storedPath, '/');
}

// ---------------------------------------------------------------------------
// Bootstrap upload directories on every request
// ---------------------------------------------------------------------------
ensureUploadDirectories();

// ---------------------------------------------------------------------------
// Chat Filter
// ---------------------------------------------------------------------------

/**
 * Chat Filter
 *
 * filterContactInfo() is the source of truth: it redacts every matched
 * span with [BLOCKED] and returns the filtered string, per spec ("Block
 * phone numbers / WhatsApp / Telegram / Instagram usernames / Facebook
 * links / TikTok usernames / email addresses / URLs. Replace blocked
 * content with [BLOCKED]. Store filtered message.").
 *
 * Order matters: more specific patterns (emails, URLs, handles) run before
 * the generic bare-keyword pattern, so e.g. an email isn't first partially
 * eaten by a broader match.
 */
function filterContactInfo($message) {
    $filtered = $message;

    $patterns = [
        // Email addresses
        '/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}/i',

        // URLs (with or without scheme/www), including bare domains like
        // example.com, and Facebook links specifically (facebook.com/...,
        // fb.com/..., m.facebook.com/...)
        '/(?:https?:\/\/)?(?:www\.|m\.)?(?:facebook\.com|fb\.com)\/[^\s]+/i',
        '/(?:https?:\/\/)?(?:www\.)?[a-z0-9-]+(?:\.[a-z0-9-]+)+(?:\/[^\s]*)?/i',

        // Social handles: @username style, used across Instagram, TikTok,
        // Telegram, Snapchat, etc.
        '/(?<!\w)@[a-z0-9._]{2,30}/i',

        // Phone numbers (various separators/groupings, with optional
        // country code)
        '/(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}/',

        // Bare platform keywords, so a message like "add me on whatsapp"
        // (no handle/number attached) still gets caught
        '/\b(whatsapp|telegram|instagram|facebook|tiktok|snapchat|discord|wechat|skype)\b/i',
    ];

    foreach ($patterns as $pattern) {
        $filtered = preg_replace($pattern, '[BLOCKED]', $filtered);
    }

    // Collapse a run of adjacent [BLOCKED] tags (e.g. an @handle followed
    // immediately by a keyword match) into a single tag for readability.
    $filtered = preg_replace('/(\[BLOCKED\]\s*){2,}/', '[BLOCKED] ', $filtered);

    // Written-out numbers (simplified heuristic): 7+ number-words in a row
    // is very likely someone spelling out a phone number to dodge the
    // digit-based regex above.
    $writtenNumbers = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
    $words = preg_split('/\s+/', strtolower($filtered));
    $count = 0;
    foreach ($words as $word) {
        $word = trim($word, ".,!?");
        if (in_array($word, $writtenNumbers, true)) {
            $count++;
        }
    }
    if ($count >= 7) {
        $filtered = '[BLOCKED]';
    }

    return $filtered;
}

/**
 * Legacy boolean check — kept for backward compatibility in case any other
 * code still calls it. New code should use filterContactInfo() so the
 * message can be redacted and stored rather than rejected outright.
 */
function containsContactInfo($message) {
    return filterContactInfo($message) !== $message;
}

// ---------------------------------------------------------------------------
// Support Agent Credentials
// ---------------------------------------------------------------------------

/**
 * Generates a unique 8-character support agent password: "SUP" followed by
 * 5 random characters from an ambiguity-free charset (matches the referral
 * code charset already used elsewhere in this codebase).
 *
 * Uniqueness is enforced globally across all support agents via the
 * UNIQUE KEY on support_agents.password_checksum — this function loops
 * until it finds a checksum not already in use.
 *
 * @return array{plain: string, checksum: string}
 */
function generateSupportPassword(PDO $db) {
    $charset = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    $charsetLen = strlen($charset);

    do {
        $suffix = '';
        for ($i = 0; $i < 5; $i++) {
            $suffix .= $charset[random_int(0, $charsetLen - 1)];
        }
        $plain = 'SUP' . $suffix;
        $checksum = hash('sha256', $plain);

        $stmt = $db->prepare("SELECT id FROM support_agents WHERE password_checksum = ?");
        $stmt->execute([$checksum]);
    } while ($stmt->fetch());

    return ['plain' => $plain, 'checksum' => $checksum];
}

/**
 * Reversibly encrypts a support agent's plaintext password (AES-256-CBC)
 * so the admin dashboard can display it again later via "view credentials".
 * This is intentionally NOT a one-way hash — that's what password_hash is
 * for (used to actually verify login). This encrypted copy exists solely
 * for admin recovery/display of a system-generated password.
 */
function encryptSupportPassword($plain) {
    $iv = random_bytes(16);
    $cipher = openssl_encrypt($plain, 'aes-256-cbc', SUPPORT_CRED_KEY, OPENSSL_RAW_DATA, $iv);
    return base64_encode($iv . $cipher);
}

function decryptSupportPassword($encoded) {
    $raw = base64_decode($encoded);
    $iv = substr($raw, 0, 16);
    $cipher = substr($raw, 16);
    return openssl_decrypt($cipher, 'aes-256-cbc', SUPPORT_CRED_KEY, OPENSSL_RAW_DATA, $iv);
}

// ---------------------------------------------------------------------------
// Referral Program
// ---------------------------------------------------------------------------

/**
 * Generate a unique, human-friendly referral code and return it.
 * Does NOT write it anywhere — caller is responsible for persisting it.
 *
 * Charset excludes visually-ambiguous characters (0/O, 1/I/L) so codes
 * are easy to read aloud or retype from a screenshot.
 *
 * @param  PDO $db
 * @param  int $length
 * @return string
 */
function generateReferralCode(PDO $db, $length = 8) {
    $charset = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    $charsetLen = strlen($charset);

    do {
        $code = '';
        for ($i = 0; $i < $length; $i++) {
            $code .= $charset[random_int(0, $charsetLen - 1)];
        }
        $stmt = $db->prepare("SELECT id FROM users WHERE referral_code = ?");
        $stmt->execute([$code]);
    } while ($stmt->fetch());

    return $code;
}

/**
 * Credit a referral commission to a user's referrer, but ONLY the first
 * time that user's coin purchase (payment) completes — subsequent
 * deposits by the same referred user never pay out again.
 *
 * The commission is paid in coins (5% of the coins just credited to the
 * buyer, by default — see REFERRAL_COMMISSION_RATE), added directly to
 * the referrer's existing wallet balance so it is immediately usable /
 * withdrawable through the same wallet + withdrawal_requests flow every
 * other coin balance already goes through. No new balance type is
 * introduced.
 *
 * IMPORTANT: call this from INSIDE the same DB transaction that just
 * marked the payment 'completed' and credited the buyer's wallet (i.e.
 * from api/payment/stripe-webhook.php or api/payment/verify-payment.php,
 * before $db->commit()). That way, if anything after this point fails
 * and the transaction rolls back, the commission rolls back with it —
 * and this function's own row locking (FOR UPDATE on the referrer's
 * wallet) participates in the same lock/rollback scope.
 *
 * Idempotency: guarded three ways —
 *   1) Callers only invoke this once per payment, inside the same
 *      transaction that flips that payment to 'completed'.
 *   2) The "first completed payment" check below means a payment can
 *      only ever trigger a commission once per buyer, ever.
 *   3) A UNIQUE KEY on referral_commissions.payment_id (see
 *      sql/referral_migration.sql) makes a duplicate INSERT impossible
 *      even under a race (e.g. a webhook retry racing verify-payment.php
 *      for the same payment) — the second attempt's SELECT-then-INSERT
 *      will violate the unique key and throw, which the caller's
 *      existing try/catch + rollback already handles safely.
 *
 * @param PDO   $db
 * @param int   $userId          The buyer (referred user) who just paid.
 * @param int   $paymentId       payments.id for this completed purchase.
 * @param float $coinsPurchased  Coins credited to the buyer for this purchase.
 * @param float $depositAmount   Fiat amount paid, kept for reporting only.
 */
function processReferralCommission(PDO $db, $userId, $paymentId, $coinsPurchased, $depositAmount) {
    // Only the buyer's first-ever completed deposit triggers a commission.
    // This runs AFTER the caller has already flipped this payment's status
    // to 'completed', so a count of exactly 1 means "this payment is (and
    // always will be) the buyer's one and only first deposit."
    $stmt = $db->prepare("SELECT COUNT(*) AS cnt FROM payments WHERE user_id = ? AND status = 'completed'");
    $stmt->execute([$userId]);
    $row = $stmt->fetch();
    if ((int)($row['cnt'] ?? 0) !== 1) {
        return;
    }

    $stmt = $db->prepare("SELECT referred_by FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $buyer = $stmt->fetch();
    $referrerId = $buyer['referred_by'] ?? null;
    if (!$referrerId) {
        return; // This user wasn't referred by anyone.
    }

    $rate = defined('REFERRAL_COMMISSION_RATE') ? REFERRAL_COMMISSION_RATE : 0.05;
    $commissionCoins = round(((float)$coinsPurchased) * $rate, 2);
    if ($commissionCoins <= 0) {
        return;
    }

    // Insert the audit/ledger row first — the UNIQUE KEY on payment_id is
    // the real idempotency backstop. If this throws (duplicate), the
    // caller's surrounding try/catch rolls the whole transaction back,
    // which is the correct, safe outcome.
    $stmt = $db->prepare("
        INSERT INTO referral_commissions
            (referrer_id, referred_user_id, payment_id, deposit_amount, coins_purchased, commission_rate, commission_coins, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'completed')
    ");
    $stmt->execute([$referrerId, $userId, $paymentId, $depositAmount, $coinsPurchased, $rate, $commissionCoins]);

    $stmt = $db->prepare('SELECT balance FROM wallets WHERE user_id = ? FOR UPDATE');
    $stmt->execute([$referrerId]);
    $referrerWallet = $stmt->fetch();
    $balanceBefore = (float)($referrerWallet['balance'] ?? 0);
    $balanceAfter  = $balanceBefore + $commissionCoins;

    $stmt = $db->prepare('UPDATE wallets SET balance = balance + ?, referral_earnings = referral_earnings + ? WHERE user_id = ?');
    $stmt->execute([$commissionCoins, $commissionCoins, $referrerId]);

    $stmt = $db->prepare("
        INSERT INTO wallet_transactions
            (user_id, type, coins_change, balance_before, balance_after, reference, description, status)
        VALUES (?, 'referral_commission', ?, ?, ?, ?, ?, 'completed')
    ");
    $stmt->execute([
        $referrerId,
        $commissionCoins,
        $balanceBefore,
        $balanceAfter,
        'Referral commission for payment #' . $paymentId,
        'Referral commission: ' . ($rate * 100) . '% (' . $commissionCoins . ' coins) from a referred user\'s first deposit.',
    ]);

    $stmt = $db->prepare("
        INSERT INTO notifications (user_id, title, body, type, created_at)
        VALUES (?, 'Referral Commission Earned', ?, 'referral_commission', NOW())
    ");
    $stmt->execute([
        $referrerId,
        'You earned ' . $commissionCoins . ' coins (' . ($rate * 100) . '%) from a referral\'s first deposit.',
    ]);
}
