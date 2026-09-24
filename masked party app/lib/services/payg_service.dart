// FILE LOCATION: lib/services/payg_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maskedparty/services/api.dart';
import 'package:maskedparty/services/api_endpoints.dart';

class PaygService {
  Future<dynamic> _get(String path, String token) async {
    try {
      final response = await http.get(
        ApiConfig.uri(path),
        headers: ApiConfig.authHeaders(token),
      ).timeout(ApiConfig.timeoutDuration);
      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  Future<dynamic> _post(String path, String token, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        ApiConfig.uri(path),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      ).timeout(ApiConfig.timeoutDuration);
      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  Future<PaygPricing?> getPricing(String token) async {
    final result = await _get(ApiEndpoints.paygPricing, token);
    if (result is Map && result['success'] == true && result['data'] is Map) {
      return PaygPricing.fromJson(Map<String, dynamic>.from(result['data']));
    }
    return null;
  }

  Future<dynamic> getWhatOffer(String token) async {
    return _get(ApiEndpoints.influencerWhatOffer, token);
  }

  Future<dynamic> saveWhatOffer(String token, String offer) async {
    return _post(ApiEndpoints.influencerWhatOffer, token, {'what_offer': offer});
  }
}

class PaygPricing {
  final double perMinute;
  final double perSecond;

  const PaygPricing({required this.perMinute, required this.perSecond});

  factory PaygPricing.fromJson(Map<String, dynamic> json) {
    double number(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return PaygPricing(
      perMinute: number(json['per_minute']),
      perSecond: number(json['per_second']),
    );
  }
}
