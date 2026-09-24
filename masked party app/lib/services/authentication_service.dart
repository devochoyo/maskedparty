// FILE LOCATION: lib/services/authentication_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class AuthenticationService {

  // Check if user is authenticated after registration
  Future<dynamic> getAuthenticatedUser(String token) async {
    try {
      final response = await http.get(
        ApiConfig.uri('auth/check-status.php'),
        headers: ApiConfig.authHeaders(token),
      ).timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  // Send OTP to email
  Future<dynamic> sendOtp(String email) async {
    try {
      final response = await http.post(
        ApiConfig.uri('auth/send-otp.php'),
        headers: ApiConfig.headers(),
        body: jsonEncode({"email": email}),
      ).timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  // Check authentication status by email
  Future<dynamic> checkStatus(String email) async {
    try {
      final response = await http.post(
        ApiConfig.uri('auth/check-status.php'),
        headers: ApiConfig.headers(),
        body: jsonEncode({"email": email}),
      ).timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  // Verify OTP code
  Future<dynamic> verifyOtp(String email, String code) async {
    try {
      final response = await http.post(
        ApiConfig.uri('auth/verify-otp.php'),
        headers: ApiConfig.headers(),
        body: jsonEncode({"email": email, "code": code}),
      ).timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}