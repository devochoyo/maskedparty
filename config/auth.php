<?php
/**
 * Authentication Helpers
 */

require_once __DIR__ . '/database.php';
require_once __DIR__ . '/response.php';

function generateToken($userId) {
    $token = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+30 days'));

    $db = getDatabaseConnection();
    $stmt = $db->prepare("INSERT INTO user_tokens (user_id, token, expires_at) VALUES (?, ?, ?)");
    $stmt->execute([$userId, $token, $expiresAt]);

    return $token;
}

/**
 * Reads the Authorization header in a way that works across different
 * SAPIs/server setups, since getallheaders() is not always available
 * (e.g. some PHP-FPM/Nginx configurations).
 */
function getAuthorizationHeader() {
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        if (isset($headers['Authorization'])) {
            return $headers['Authorization'];
        }
        if (isset($headers['authorization'])) {
            return $headers['authorization'];
        }
    }

    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        return $_SERVER['HTTP_AUTHORIZATION'];
    }

    if (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        return $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }

    return '';
}

function getAuthenticatedUser() {
    $authHeader = getAuthorizationHeader();

    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        sendError('Unauthorized. Bearer token required.', 401);
    }

    $token = $matches[1];
    $db = getDatabaseConnection();

    $stmt = $db->prepare("
        SELECT u.* FROM users u
        JOIN user_tokens ut ON u.id = ut.user_id
        WHERE ut.token = ? AND ut.expires_at > NOW() AND u.status != 'banned'
        LIMIT 1
    ");
    $stmt->execute([$token]);
    $user = $stmt->fetch();

    if (!$user) {
        sendError('Unauthorized. Invalid or expired token.', 401);
    }

    return $user;
}

function requireRole($user, $role) {
    if ($user['role'] !== $role) {
        sendError('Forbidden. You do not have permission for this action.', 403);
    }
}

function requireAdmin($user) {
    if ($user['role'] !== 'admin') {
        sendError('Forbidden. Admin access required.', 403);
    }
}

// ---------------------------------------------------------------------------
// Support Agent Authentication
//
// Support agents are NOT rows in `users` — they live in their own
// `support_agents` table with their own `support_tokens` table, mirroring
// the users/user_tokens pattern above but kept completely separate.
// ---------------------------------------------------------------------------

function generateSupportToken($supportAgentId) {
    $token = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+30 days'));

    $db = getDatabaseConnection();
    $stmt = $db->prepare("INSERT INTO support_tokens (support_agent_id, token, expires_at) VALUES (?, ?, ?)");
    $stmt->execute([$supportAgentId, $token, $expiresAt]);

    return $token;
}

/**
 * Authenticates the Bearer token as a support agent. Sends 401 and exits
 * if missing/invalid/expired, or if the agent has been suspended.
 */
function getAuthenticatedSupportAgent() {
    $authHeader = getAuthorizationHeader();

    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        sendError('Unauthorized. Bearer token required.', 401);
    }

    $token = $matches[1];
    $db = getDatabaseConnection();

    $stmt = $db->prepare("
        SELECT sa.* FROM support_agents sa
        JOIN support_tokens st ON sa.id = st.support_agent_id
        WHERE st.token = ? AND st.expires_at > NOW()
        LIMIT 1
    ");
    $stmt->execute([$token]);
    $agent = $stmt->fetch();

    if (!$agent) {
        sendError('Unauthorized. Invalid or expired token.', 401);
    }

    if ($agent['status'] === 'suspended') {
        sendError('Your support account has been suspended.', 403);
    }

    return $agent;
}

/**
 * Tries to resolve the Bearer token against EITHER a customer (client/
 * influencer, from `users`) OR a support agent, for endpoints that both
 * sides call (e.g. sending a message, ending a conversation).
 *
 * Returns ['type' => 'customer', 'data' => $user]
 *      or ['type' => 'support',  'data' => $agent]
 * Sends 401 and exits if neither matches.
 */
function getAuthenticatedCustomerOrSupport() {
    $authHeader = getAuthorizationHeader();

    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        sendError('Unauthorized. Bearer token required.', 401);
    }

    $token = $matches[1];
    $db = getDatabaseConnection();

    $stmt = $db->prepare("
        SELECT u.* FROM users u
        JOIN user_tokens ut ON u.id = ut.user_id
        WHERE ut.token = ? AND ut.expires_at > NOW() AND u.status != 'banned'
        LIMIT 1
    ");
    $stmt->execute([$token]);
    $user = $stmt->fetch();

    if ($user) {
        return ['type' => 'customer', 'data' => $user];
    }

    $stmt = $db->prepare("
        SELECT sa.* FROM support_agents sa
        JOIN support_tokens st ON sa.id = st.support_agent_id
        WHERE st.token = ? AND st.expires_at > NOW() AND sa.status != 'suspended'
        LIMIT 1
    ");
    $stmt->execute([$token]);
    $agent = $stmt->fetch();

    if ($agent) {
        return ['type' => 'support', 'data' => $agent];
    }

    sendError('Unauthorized. Invalid or expired token.', 401);
}
