// FILE LOCATION: lib/services/wallet_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class WalletService {
  /// Backend: api/wallet/balance.php — GET — returns current_balance,
  /// total_purchased, total_spent, escrow_balance, and available_balance
  /// (balance - escrow_balance).
  Future<dynamic> getBalance(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.walletBalance),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Creates a Stripe Checkout Session for the given coin package and
  /// returns a hosted checkout_url to open (falls back to a simulated
  /// session id in dev environments where STRIPE_SECRET_KEY isn't
  /// configured — checkout_url will be absent in that case).
  /// Backend: api/wallet/buy-coins.php — body: {package_id}
  Future<dynamic> buyCoins(String token, String packageId) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.walletBuyCoins),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "package_id": packageId,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/wallet/history.php — GET — optional query params:
  /// limit (1-100, default 50), offset (default 0).
  Future<dynamic> getHistory(String token, {int? limit, int? offset}) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.walletHistory, queryParameters: {
              if (limit != null) "limit": limit.toString(),
              if (offset != null) "offset": offset.toString(),
            }),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}
