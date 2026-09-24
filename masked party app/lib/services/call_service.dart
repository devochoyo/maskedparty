// FILE LOCATION: lib/services/call_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maskedparty/services/api_endpoints.dart';
import 'package:maskedparty/services/api.dart';

class CallService {
  // ---------------------------------------------------------------------------
  // Private helpers (standardized on ApiConfig helpers)
  // ---------------------------------------------------------------------------
  Future<dynamic> _post(String path, String token,
      [Map<String, dynamic>? body]) async {
    try {
      final response = await http.post(
        ApiConfig.uri(path),
        headers: ApiConfig.authHeaders(token),
        body: body != null ? jsonEncode(body) : null,
      );
      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  Future<dynamic> _get(String path, String token,
      {Map<String, String>? queryParameters}) async {
    try {
      final response = await http.get(
        ApiConfig.uri(path, queryParameters: queryParameters),
        headers: ApiConfig.authHeaders(token),
      );
      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Pricing
  // ---------------------------------------------------------------------------
  /// Admin-configured coin cost tiers by call minute (e.g. "1 minute = 10
  /// coins", "12 minutes = 22 coins"), plus the effective platform
  /// coins-per-minute rate that call/start.php actually bills with.
  /// GET /api/misc/call-minute-costs.php
  /// -> { success, data: { tiers: [{id, minutes, coin_cost}], price_per_minute } }
  ///
  /// Returns null on failure so callers can fall back to a flat estimate.
  Future<CallMinuteCosts?> getCallMinuteCosts(String token) async {
    try {
      final result = await _get(ApiEndpoints.callMinuteCosts, token);
      if (result is Map && result['success'] == true) {
        final data = result['data'];
        if (data is Map) {
          return CallMinuteCosts.fromJson(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e) {
      print('Error fetching call minute costs: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Call request lifecycle (uses request_id, from call/request.php or
  // call/pending.php — NOT the same as call_id below)
  // ---------------------------------------------------------------------------
  /// Client requests a call with an online, verified influencer.
  /// POST /api/call/request.php  body: { influencer_id }
  /// -> { success, data: { request_id, expires_at } }
  Future<dynamic> requestCall(
    String token,
    String influencerId, {
    String billingMode = 'standard',
  }) async {
    return _post(ApiEndpoints.callRequest, token, {
      'influencer_id': influencerId,
      'billing_mode': billingMode,
    });
  }

  /// Influencer's own view of the oldest still-pending incoming request.
  /// GET /api/call/pending.php
  /// -> { success, data: { request_id, client_id, expires_at, ... } | null }
  Future<dynamic> getPendingCall(String token) async {
    return _get(ApiEndpoints.callPending, token);
  }

  /// Influencer accepts an incoming call request.
  /// POST /api/call/accept.php  body: { request_id }
  /// -> { success, data: { meeting_id, meeting_token, client_id, influencer_id } }
  Future<dynamic> acceptCall(String token, String requestId) async {
    return _post(ApiEndpoints.callAccept, token, {'request_id': requestId});
  }

  /// Influencer rejects an incoming call request.
  /// POST /api/call/reject.php  body: { request_id }
  Future<dynamic> rejectCall(String token, String requestId) async {
    return _post(ApiEndpoints.callReject, token, {'request_id': requestId});
  }

  /// Starts an accepted call (creates the video_calls row, holds first
  /// minute of coins in escrow). Idempotent for the same request_id.
  /// POST /api/call/start.php  body: { request_id }
  /// -> { success, data: { call_id, meeting_id, meeting_token,
  ///        price_per_minute, paid_duration_seconds, status } }
  Future<dynamic> startCall(String token, String requestId) async {
    return _post(ApiEndpoints.callStart, token, {'request_id': requestId});
  }

  // ---------------------------------------------------------------------------
  // Active call management (uses call_id, returned by call/start.php)
  // ---------------------------------------------------------------------------
  /// POST /api/call/countdown.php  body: { call_id }
  /// -> { success, data: { call_id, status, remaining_seconds, paid_duration_seconds } }
  /// Auto-ends the call server-side if remaining_seconds has hit zero.
  Future<dynamic> getCountdown(String token, String callId) async {
    return _post(ApiEndpoints.callCountdown, token, {'call_id': callId});
  }

  /// Client purchases additional minutes on an active call.
  /// POST /api/call/extend.php  body: { call_id, additional_minutes }
  /// -> { success, data: { call_id, additional_minutes, additional_coins,
  ///        paid_duration_seconds, remaining_seconds } }
  Future<dynamic> extendCall(String token, String callId,
      [int additionalMinutes = 5]) async {
    return _post(ApiEndpoints.callExtend, token, {
      'call_id': callId,
      'additional_minutes': additionalMinutes,
    });
  }

  /// Ends an active call early. Does NOT release escrow.
  /// POST /api/call/end.php  body: { call_id }
  /// -> { success, data: { call_id, status, actual_duration_seconds } }
  ///
  /// IMPORTANT: The backend records WHO ended the call based on the Bearer
  /// token sent with this request. Do NOT send any "ended_by" parameter.
  /// This endpoint is idempotent — calling it again on an already-ended
  /// call just returns the existing result.
  Future<dynamic> endCall(String token, String callId) async {
    return _post(ApiEndpoints.callEnd, token, {'call_id': callId});
  }

  /// Client manually releases escrowed coins to the influencer for a
  /// completed call. Idempotent. Auto-releases after 30 min if unused.
  /// POST /api/call/release.php  body: { call_id }
  /// -> { success, data: { call_id, escrow_status, amount_released } }
  Future<dynamic> releaseCoins(String token, String callId) async {
    return _post(ApiEndpoints.callRelease, token, {'call_id': callId});
  }

  /// Alias kept for existing call sites.
  Future<dynamic> releaseEscrow(String token, String callId) async {
    return releaseCoins(token, callId);
  }

  /// Manually releases escrow and returns detailed release information.
  /// POST /api/call/manual_release.php  body: { call_id: <int> }
  /// -> { success: true, data: { call_id, escrow_status, release_trigger,
  ///      amount_released, influencer_id, released_at, confirmation_ref,
  ///      already_released } }
  /// If already_released is true, treat as success — do not throw.
  /// If success is false, throw an Exception using the message field.
  Future<Map<String, dynamic>> manualReleaseEscrow(String token, int callId) async {
    try {
      final response = await http.post(
        ApiConfig.uri(ApiEndpoints.callManualRelease),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'call_id': callId}),
      );
      final result = ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
      if (result is Map && result['success'] == true) {
        return Map<String, dynamic>.from(result['data'] ?? {});
      }
      // If already_released is true in the response, treat as success
      if (result is Map && result['data'] is Map) {
        final data = result['data'] as Map;
        if (data['already_released'] == true) {
          return Map<String, dynamic>.from(data);
        }
      }
      final message = result is Map ? result['message']?.toString() : null;
      throw Exception(message ?? 'Failed to manually release escrow');
    } catch (e) {
      if (e is Exception) rethrow;
      return ApiConfig.handleError(e) is Map
          ? throw Exception('Failed to manually release escrow')
          : throw e;
    }
  }

  // ---------------------------------------------------------------------------
  // Call tracking (post-call summary)
  // ---------------------------------------------------------------------------
  /// Fetches who ended the call and its actual duration.
  /// GET /api/call-tracking/details.php?call_id=<int>
  /// -> { success, data: { call_id, influencer_name, client_name,
  ///        ended_by_role, ended_by_name, duration_seconds, ... } }
  ///
  /// Returns null on 404 (record not ready yet — retry after a short delay)
  /// or on network/unexpected errors, so callers can fall back gracefully.
  Future<Map<String, dynamic>?> getCallTrackingDetails(
      String token, String callId) async {
    try {
      final result = await _get(
        ApiEndpoints.callTrackingDetails,
        token,
        queryParameters: {'call_id': callId},
      );
      if (result is Map && result['success'] == true) {
        return result['data'] as Map<String, dynamic>?;
      }
      // 404 means record isn't ready yet — return null, not an error
      if (result is Map && result['status_code'] == 404) {
        return null;
      }
      // Other errors — return null so caller falls back gracefully
      return null;
    } catch (e) {
      print('Error fetching call tracking details: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Post-call rating / reporting
  // ---------------------------------------------------------------------------
  /// Client submits a rating + written review for a completed call.
  /// (There is no separate influencer-side "rating" endpoint — only
  /// review/create.php, and only the client can call it.)
  /// POST /api/review/create.php  body: { call_id, rating, experience_text }
  Future<dynamic> submitRating({
    required String token,
    required String callId,
    required int rating, // 1-5
    required String experienceText,
  }) async {
    return _post(ApiEndpoints.reviewCreate, token, {
      'call_id': callId,
      'rating': rating,
      'experience_text': experienceText,
    });
  }

  /// Either party in a completed call can report the other.
  /// POST /api/review/report.php
  /// body: { reported_user_id, call_id, reason, description }
  Future<dynamic> reportUser({
    required String token,
    required String reportedUserId,
    required String callId,
    required String reason,
    required String description,
  }) async {
    return _post(ApiEndpoints.reviewReport, token, {
      'reported_user_id': reportedUserId,
      'call_id': callId,
      'reason': reason,
      'description': description,
    });
  }
}

/// A single admin-defined tier: "N minutes cost X coins".
class CallMinuteCostTier {
  final int id;
  final int minutes;
  final double coinCost;

  const CallMinuteCostTier({
    required this.id,
    required this.minutes,
    required this.coinCost,
  });

  /// Coins per minute for this specific tier (e.g. a 12-minute bundle at
  /// 22 coins is 1.83 coins/min, cheaper than a 1-minute tier at 10).
  double get ratePerMinute => minutes > 0 ? coinCost / minutes : 0;

  factory CallMinuteCostTier.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return CallMinuteCostTier(
      id: toInt(json['id']),
      minutes: toInt(json['minutes']),
      coinCost: toDouble(json['coin_cost']),
    );
  }
}

/// Response wrapper for GET /api/misc/call-minute-costs.php
class CallMinuteCosts {
  final List<CallMinuteCostTier> tiers;
  /// The effective flat coins-per-minute rate call/start.php bills with
  /// (the cheapest ratio among all active tiers).
  final double pricePerMinute;

  const CallMinuteCosts({required this.tiers, required this.pricePerMinute});

  factory CallMinuteCosts.fromJson(Map<String, dynamic> json) {
    final rawTiers = json['tiers'];
    final tiers = rawTiers is List
        ? rawTiers
            .whereType<Map>()
            .map((t) => CallMinuteCostTier.fromJson(Map<String, dynamic>.from(t)))
            .toList()
        : <CallMinuteCostTier>[];

    final rawRate = json['price_per_minute'];
    final rate = rawRate is num
        ? rawRate.toDouble()
        : (rawRate is String ? double.tryParse(rawRate) ?? 1.0 : 1.0);

    return CallMinuteCosts(tiers: tiers, pricePerMinute: rate);
  }
}
