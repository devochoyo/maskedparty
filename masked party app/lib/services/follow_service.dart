// FILE LOCATION: lib/services/follow_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';
import 'session_manager.dart';

class FollowService {
  /// Client follows an influencer.
  static Future<Map<String, dynamic>> follow(int influencerId) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Please login or register to follow.',
        'requires_auth': true,
      };
    }

    final response = await http
        .post(
          ApiConfig.uri(ApiEndpoints.followFollow),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'influencer_id': influencerId}),
        )
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
  }

  /// Client unfollows an influencer.
  static Future<Map<String, dynamic>> unfollow(int influencerId) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Please login again.',
        'requires_auth': true,
      };
    }

    final response = await http
        .post(
          ApiConfig.uri(ApiEndpoints.followUnfollow),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'influencer_id': influencerId}),
        )
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
  }

  /// Public list of followers for an influencer.
  static Future<Map<String, dynamic>> listFollowers({
    required int influencerId,
    int page = 1,
  }) async {
    final uri = ApiConfig.uri(
      ApiEndpoints.followFollowers,
      queryParameters: {
        'influencer_id': influencerId.toString(),
        'page': page.toString(),
      },
    );

    final response = await http
        .get(uri, headers: ApiConfig.headers())
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(response, isAuthenticatedRequest: false);
  }

  /// Follower count + is_following (optional auth).
  static Future<Map<String, dynamic>> status(int influencerId) async {
    final token = await SessionManager.getToken();
    final uri = ApiConfig.uri(
      ApiEndpoints.followStatus,
      queryParameters: {'influencer_id': influencerId.toString()},
    );

    final headers = (token != null && token.isNotEmpty)
        ? ApiConfig.authHeaders(token)
        : ApiConfig.headers();

    final response = await http
        .get(uri, headers: headers)
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(
      response,
      isAuthenticatedRequest: token != null && token.isNotEmpty,
    );
  }
}
