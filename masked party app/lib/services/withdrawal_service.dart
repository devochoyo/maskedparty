// FILE LOCATION: lib/services/withdrawal_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class WithdrawalService {
  /// Backend: api/withdrawal/request.php — role: influencer — body:
  /// {amount, bank_name, account_number, bank_code_type, bank_code_value}.
  /// Bank details are asked for here (at withdrawal time), not at
  /// registration. The backend saves them so they are pre-filled next time.
  /// Only one pending withdrawal is allowed at a time
  /// (HTTP 409 if one already exists); minimum amount is enforced
  /// server-side (HTTP 422 with the configured minimum in the message).
  Future<dynamic> requestWithdrawal(
    String token,
    double amount, {
    String? bankName,
    String? accountNumber,
    String? bankCodeType,
    String? bankCodeValue,
  }) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.withdrawalRequest),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "amount": amount,
              "bank_name": bankName,
              "account_number": accountNumber,
              "bank_code_type": bankCodeType,
              "bank_code_value": bankCodeValue,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/withdrawal/history.php — GET — role: influencer.
  Future<dynamic> getWithdrawalHistory(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.withdrawalHistory),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}
