// FILE LOCATION: lib/services/client_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class ClientService {
  /// Backend: api/influencer/list.php — GET, public (no auth required, but
  /// the header is harmless to send). Optional filters:
  ///   - page (default 1)
  ///   - country
  ///   - mask_status ("masked" | "unmasked")
  ///   - search (matches mystery_name)
  ///   - sort_by ("newest" [default] | "highest_rated" | "most_popular")
  Future<dynamic> getInfluencers(
    String token, {
    int? page,
    String? country,
    String? maskStatus,
    String? search,
    String? sortBy,
  }) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.influencerList, queryParameters: {
              if (page != null) "page": page.toString(),
              if (country != null && country.isNotEmpty) "country": country,
              if (maskStatus != null && maskStatus.isNotEmpty)
                "mask_status": maskStatus,
              if (search != null && search.isNotEmpty) "search": search,
              if (sortBy != null && sortBy.isNotEmpty) "sort_by": sortBy,
            }),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/influencer/details.php — GET — query param: id
  Future<dynamic> getInfluencerDetails(
    String token,
    String influencerId,
  ) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.influencerDetails, queryParameters: {
              "id": influencerId,
            }),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// NEW — no Flutter service previously called this endpoint.
  /// Backend: api/influencer/saved.php — GET — role: client
  Future<dynamic> getSavedInfluencers(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.savedInfluencers),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// NEW — no Flutter service previously called this endpoint.
  /// Backend: api/influencer/save.php — role: client — body: {influencer_id}
  /// Idempotent — saving an already-saved influencer is a no-op success.
  Future<dynamic> saveInfluencer(String token, String influencerId) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.saveInfluencer),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({"influencer_id": influencerId}),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// NEW — no Flutter service previously called this endpoint.
  /// Backend: api/influencer/unsave.php — role: client — body: {influencer_id}
  Future<dynamic> removeSavedInfluencer(
    String token,
    String influencerId,
  ) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.unsaveInfluencer),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({"influencer_id": influencerId}),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}
