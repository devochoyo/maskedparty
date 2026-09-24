<?php
/**
 * VideoSDK Helper - Creates real meeting rooms and tokens
 */
function generateAuthToken() {
    $apiKey = VIDEOSDK_API_KEY;
    $secretKey = VIDEOSDK_SECRET_KEY;
    
    $header = json_encode(['alg' => 'HS256', 'typ' => 'JWT']);
    $payload = json_encode([
        'apikey' => $apiKey,
        'permissions' => ['allow_join', 'allow_mod'],
        'iat' => time(),
        'exp' => time() + 3600,
    ]);
    
    $base64UrlHeader = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $base64UrlPayload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');
    $signature = hash_hmac('sha256', "$base64UrlHeader.$base64UrlPayload", $secretKey, true);
    $base64UrlSignature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
    
    return "$base64UrlHeader.$base64UrlPayload.$base64UrlSignature";
}
function createVideoSDKRoom() {
    $authToken = generateAuthToken();
    
    $url = 'https://api.videosdk.live/v2/rooms';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: ' . $authToken,
        'Content-Type: application/json',
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    error_log("VideoSDK Create Room - HTTP: $httpCode, Response: $response");
    
    if ($httpCode === 200) {
        $data = json_decode($response, true);
        return $data['roomId'] ?? null;
    }
    
    return null;
}
function generateVideoSDKToken($roomId) {
    $apiKey = VIDEOSDK_API_KEY;
    $secretKey = VIDEOSDK_SECRET_KEY;
    
    // NOTE: participantId is intentionally NOT included here.
    // This token is shared by BOTH the client and the influencer (it's
    // generated once in accept.php and returned to whichever side calls
    // start.php). If a participantId were baked in here, both devices
    // would try to join the VideoSDK room as the same participant,
    // causing one side to be dropped shortly after joining. Each
    // client SDK assigns its own unique participant identity at
    // room.join() time via displayName instead.
    $header = json_encode(['alg' => 'HS256', 'typ' => 'JWT']);
    $payload = json_encode([
        'apikey' => $apiKey,
        'permissions' => ['allow_join', 'allow_mod'],
        'roomId' => $roomId,
        'iat' => time(),
        'exp' => time() + 86400,
    ]);
    
    $base64UrlHeader = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $base64UrlPayload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');
    $signature = hash_hmac('sha256', "$base64UrlHeader.$base64UrlPayload", $secretKey, true);
    $base64UrlSignature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
    
    return "$base64UrlHeader.$base64UrlPayload.$base64UrlSignature";
}