import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Handles persisting and retrieving the logged-in user's session
/// (auth token, role, and basic profile info) across app restarts.
///
/// NOTE: This requires the `shared_preferences` package.
/// Add this to your pubspec.yaml if it isn't already there:
///
///   dependencies:
///     shared_preferences: ^2.2.2
class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'auth_role';
  static const String _userKey = 'auth_user';

  /// Save the session after a successful login (or auto-login after register).
  static Future<void> saveSession({
    required String token,
    required String role,
    Map<String, dynamic>? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    if (user != null) {
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// True if a token is currently stored (i.e. the user has an active session).
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears the session. Call this on logout, or when the API returns 401.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userKey);
  }

  /// Best-effort extraction of a token from a variety of common API response
  /// shapes, since backends differ (top-level `token`, nested under `data`,
  /// or `access_token`). Adjust this if your API uses a different key.
  static String? extractToken(dynamic result) {
    if (result is! Map) return null;
    if (result['token'] is String) return result['token'];
    if (result['access_token'] is String) return result['access_token'];
    final data = result['data'];
    if (data is Map) {
      if (data['token'] is String) return data['token'];
      if (data['access_token'] is String) return data['access_token'];
    }
    return null;
  }

  /// Best-effort extraction of the user's role from common response shapes.
  static String extractRole(dynamic result, {String fallback = 'client'}) {
    if (result is! Map) return fallback;
    if (result['role'] is String) return result['role'];
    final user = result['user'];
    if (user is Map && user['role'] is String) return user['role'];
    final data = result['data'];
    if (data is Map) {
      if (data['role'] is String) return data['role'];
      final dataUser = data['user'];
      if (dataUser is Map && dataUser['role'] is String) return dataUser['role'];
    }
    return fallback;
  }

  /// Best-effort extraction of a user profile map from common response shapes.
  static Map<String, dynamic>? extractUser(dynamic result) {
    if (result is! Map) return null;
    if (result['user'] is Map) return Map<String, dynamic>.from(result['user']);
    final data = result['data'];
    if (data is Map && data['user'] is Map) {
      return Map<String, dynamic>.from(data['user']);
    }
    return null;
  }
}
