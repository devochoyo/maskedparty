// FILE LOCATION: lib/services/notification_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class NotificationService {
  /// Backend: api/notification/list.php — GET — optional query param:
  /// page (default 1, 20 per page). Response data includes `unread_count`
  /// so a badge can be shown without a second request.
  Future<dynamic> getNotifications(String token, {int? page}) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.notificationList, queryParameters: {
              if (page != null) "page": page.toString(),
            }),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Marks a single notification as read.
  /// Backend: api/notification/read.php — body: {notification_id}
  Future<dynamic> markAsRead(String token, String notificationId) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.notificationRead),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "notification_id": notificationId,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// NEW — the backend also supports marking every notification read in
  /// one call, which no Flutter service previously exposed.
  /// Backend: api/notification/read.php — body: {mark_all: true}
  Future<dynamic> markAllAsRead(String token) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.notificationRead),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "mark_all": true,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}
