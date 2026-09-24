// FILE LOCATION: lib/services/profile_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class ProfileService {
  /// Backend: api/profile/get.php — GET — returns the shared user fields
  /// plus, for influencers, the full influencer_profiles row merged in
  /// (biography, age, verification/gallery/intro-video URLs, etc.).
  /// This also functions as the app's "Refresh Profile" call — the
  /// backend has no separate refresh-profile endpoint.
  Future<dynamic> getProfile(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.profileGet),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/profile/update.php — generic partial update. Accepts
  /// any subset of: mystery_name, profile_photo (relative stored path or
  /// full URL — the backend strips the BASE_URL prefix itself), and for
  /// influencers: biography, age, complexion, favourite_food, hobby,
  /// aspiration, financial_target, price_per_minute, mask_status,
  /// willing_to_remove_mask, intro_video. The backend rejects (HTTP 403)
  /// any attempt to change role, country_name, country_code, email, or
  /// full_name through this endpoint — those are immutable post-registration.
  Future<dynamic> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.profileUpdate),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}
