// FILE LOCATION: lib/services/report_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class ReportService {
  /// Reports a user from a COMPLETED call both the reporter and the
  /// reported user took part in.
  ///
  /// Backend: api/review/report.php — body:
  ///   {reported_user_id, call_id, reason, description}
  /// All four fields are required. One report per (reporter, call_id) —
  /// duplicate reports for the same call are rejected with HTTP 409.
  Future<dynamic> submitReport(
    String token,
    String reportedUserId,
    String callId,
    String reason,
    String description,
  ) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.reviewReport),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "reported_user_id": reportedUserId,
              "call_id": callId,
              "reason": reason,
              "description": description,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}
