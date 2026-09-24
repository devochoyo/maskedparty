// FILE LOCATION: lib/services/review_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class ReviewService {
  /// Submits a review for a COMPLETED call the authenticated client took
  /// part in — one review per call_id (enforced by a unique DB index).
  ///
  /// Backend: api/review/create.php — role: client — body:
  ///   {call_id, rating, experience_text}
  ///
  /// NOTE: reviews are keyed by call_id, NOT influencer_id — the backend
  /// looks up the influencer from the call record itself. rating must be
  /// 1-5. Three low ratings (<=2) from three different completed clients
  /// auto-suspends the influencer's account server-side.
  Future<dynamic> submitReview(
    String token,
    String callId,
    int rating,
    String experienceText,
  ) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.reviewCreate),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "call_id": callId,
              "rating": rating,
              "experience_text": experienceText,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}
