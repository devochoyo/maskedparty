// FILE: lib/services/influencer_active_status_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'api_endpoints.dart';

class InfluencerActiveStatusService {
  /// Get real-time active status for a single influencer
  ///
  /// Returns a Map with the status data, or null if the request fails.
  Future<Map<String, dynamic>?> getStatus(String token, String influencerId) async {
    try {
      final uri = ApiConfig.uri(ApiEndpoints.influencerActiveStatus)
          .replace(queryParameters: {
        'id': influencerId,
      });

      final response = await http
          .get(
            uri,
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      final result = ApiConfig.handleResponse(
        response,
        isAuthenticatedRequest: true,
      );

      if (result is Map && result['success'] == true) {
        return result['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get real-time active status for multiple influencers (batch up to 50)
  ///
  /// Returns a List of status data Maps, or empty list if the request fails.
  Future<List<Map<String, dynamic>>> getStatuses(
    String token,
    List<String> influencerIds,
  ) async {
    try {
      if (influencerIds.isEmpty) return [];
      if (influencerIds.length > 50) {
        return [];
      }

      final uri = ApiConfig.uri(ApiEndpoints.influencerActiveStatus)
          .replace(queryParameters: {
        'ids': influencerIds.join(','),
      });

      final response = await http
          .get(
            uri,
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      final result = ApiConfig.handleResponse(
        response,
        isAuthenticatedRequest: true,
      );

      if (result is Map && result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Check if an influencer is truly online
  ///
  /// Returns true if the influencer is online and has pinged within the
  /// last 30 seconds, false otherwise.
  Future<bool> isTrulyOnline(String token, String influencerId) async {
    final status = await getStatus(token, influencerId);
    if (status == null) return false;
    return status['is_truly_online'] == true;
  }
}