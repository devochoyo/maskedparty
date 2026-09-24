// FILE LOCATION: lib/services/payment_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class PaymentService {
  /// Step 1 — Initialise Payment (Flutterwave)
  ///
  /// POST /api/payment/create-payment.php
  ///
  /// Asks the backend to create a Flutterwave transaction for the given coin
  /// package. The backend calls Flutterwave's API server-side (using its
  /// SECRET key) and returns the authorization_url, access_code, and
  /// reference so the app can open the checkout page — the app never
  /// touches the secret key directly.
  ///
  /// Backend: api/payment/create-payment.php — body: {package_id}. The
  /// backend prices the package itself from coin_packages — it does not
  /// accept or trust a client-supplied amount, so no `amount` is sent.
  ///
  /// Response data:
  /// {
  ///   "authorization_url": "https://checkout.flutterwave.com/...",
  ///   "access_code": "0peioxfhpn",
  ///   "reference": "7PVGX8MEk85tgeEpVDtD",
  ///   "payment_id": 42,
  ///   "package_id": 3,
  ///   "amount": 10.00,
  ///   "currency": "GBP"
  /// }
  Future<dynamic> createPayment(String token, String packageId) async {
    try {
      final uri = ApiConfig.uri(ApiEndpoints.paymentCreate);
      print('🔗 Payment URL: $uri');
      print('📦 Package ID: $packageId');
      print('🔑 Token: ${token.substring(0, 20)}...');
      
      final body = jsonEncode({
        "package_id": int.tryParse(packageId) ?? 0,
      });
      print('📤 Request body: $body');
      
      final response = await http
          .post(
            uri,
            headers: ApiConfig.authHeaders(token),
            body: body,
          )
          .timeout(ApiConfig.timeoutDuration);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      print('❌ Error: $e');
      return ApiConfig.handleError(e);
    }
  }

  /// Step 3 — Verify Payment (Flutterwave)
  ///
  /// POST /api/payment/verify-payment.php
  ///
  /// Verifies a Flutterwave transaction server-side and credits the wallet.
  /// Idempotent — verifying an already-completed payment just returns the
  /// current wallet balance instead of double-crediting.
  ///
  /// Backend: api/payment/verify-payment.php — body: {reference}
  ///
  /// Success response: { "wallet_balance": 155.00 }
  ///
  /// Error responses:
  /// - 400: "Payment not successful."
  /// - 403: "This payment does not belong to the authenticated user."
  /// - 409: "No matching pending payment found." (treat as success)
  /// - 502: "Unable to verify payment with Flutterwave." (retry)
  Future<dynamic> verifyPayment(String token, String reference) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.paymentVerify),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "reference": reference,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Step 4 — Payment History
  ///
  /// GET /api/payment/payment-history.php
  ///
  /// Query params: limit (1-100, default 50), offset (default 0)
  Future<dynamic> getPaymentHistory(
    String token, {
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.paymentHistory, queryParameters: {
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