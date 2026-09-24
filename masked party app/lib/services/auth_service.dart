// FILE LOCATION: lib/services/auth_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';
import 'session_manager.dart';

class AuthService {
  Future<dynamic> register({
    required String role,
    required String email,
    required String password,
    required String confirmPassword,
    required String mysteryName,
    required String countryName,
    String? countryCode,
    String? fullName,
    String? bankName,
    String? accountNumber,
    String? bankCodeType,
    String? bankCodeValue,
    String? referralCode,
    String? maskStatus,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "role": role,
        "email": email,
        "password": password,
        "confirm_password": confirmPassword,
        "mystery_name": mysteryName,
        "country_name": countryName,
        if (countryCode != null) "country_code": countryCode,
        if (referralCode != null && referralCode.isNotEmpty) "referral_code": referralCode,
        if (role == "influencer") ...{
          if (fullName != null) "full_name": fullName,
          if (bankName != null) "bank_name": bankName,
          if (accountNumber != null) "account_number": accountNumber,
          if (bankCodeType != null && bankCodeType.isNotEmpty) "bank_code_type": bankCodeType,
          if (bankCodeValue != null && bankCodeValue.isNotEmpty) "bank_code_value": bankCodeValue,
          if (maskStatus != null) "mask_status": maskStatus,
        },
      };

      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.registerUser),
            headers: ApiConfig.headers(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeoutDuration);

      final result = ApiConfig.handleResponse(response);

      if (result is Map && result['success'] == true) {
        final token = SessionManager.extractToken(result);
        final extractedRole = SessionManager.extractRole(result, fallback: role);
        final user = SessionManager.extractUser(result);

        if (token != null) {
          await SessionManager.saveSession(
            token: token,
            role: extractedRole,
            user: user,
          );
        }
      }

      return result;
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.login),
            headers: ApiConfig.headers(),
            body: jsonEncode(<String, dynamic>{
              "email": email,
              "password": password,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      final result = ApiConfig.handleResponse(response);

      if (result is Map && result['success'] == true) {
        final token = SessionManager.extractToken(result);
        final extractedRole = SessionManager.extractRole(result);
        final user = SessionManager.extractUser(result);
        final data = result['data'];

        bool profileCompleted = true;
        if (data is Map && data.containsKey('profile_completed')) {
          final value = data['profile_completed'];
          if (value is bool) {
            profileCompleted = value;
          } else if (value is int) {
            profileCompleted = value == 1;
          } else if (value is String) {
            profileCompleted = value == '1' || value.toLowerCase() == 'true';
          }
        }

        if (token != null) {
          await SessionManager.saveSession(
            token: token,
            role: extractedRole,
            user: user,
          );
        }

        return {
          'success': true,
          'data': data,
          'message': result['message'],
          'profile_completed': profileCompleted,
          'role': extractedRole,
          'token': token,
        };
      }

      return result is Map ? Map<String, dynamic>.from(result) : {'success': false, 'message': 'Login failed'};
    } catch (e) {
      final errorResult = ApiConfig.handleError(e);
      return errorResult is Map ? Map<String, dynamic>.from(errorResult) : {'success': false, 'message': 'Login failed'};
    }
  }

  Future<dynamic> logout(String token) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.logout),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      final result = ApiConfig.handleResponse(response, isAuthenticatedRequest: true);

      await SessionManager.clearSession();

      return result;
    } catch (e) {
      await SessionManager.clearSession();
      return ApiConfig.handleError(e);
    }
  }

  Future<dynamic> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.forgotPassword),
            headers: ApiConfig.headers(),
            body: jsonEncode(<String, dynamic>{
              "email": email,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  Future<dynamic> resetPassword({
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.resetPassword),
            headers: ApiConfig.headers(),
            body: jsonEncode(<String, dynamic>{
              "otp": code,
              "new_password": newPassword,
              "confirm_password": confirmPassword,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  Future<Map<String, dynamic>> checkProfileCompletion(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.profileGet),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      final result = ApiConfig.handleResponse(response);

      if (result is Map && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final role = data?['role'] as String?;

        if (role != 'influencer') {
          return {
            'success': true,
            'role': role,
            'profile_completed': true,
            'data': data,
          };
        }

        bool profileCompleted = false;

        if (data?.containsKey('profile_completed') == true) {
          final value = data!['profile_completed'];

          if (value is bool) {
            profileCompleted = value;
          } else if (value is int) {
            profileCompleted = value == 1;
          } else if (value is double) {
            profileCompleted = value == 1.0;
          } else if (value is String) {
            profileCompleted = value == '1' || value.toLowerCase() == 'true';
          }
        }

        if (!profileCompleted && data != null) {
          final biography = data['biography'];
          final age = data['age'];

          final hasBiography = biography != null &&
              biography.toString().isNotEmpty &&
              biography.toString() != 'null';
          final hasAge = age != null && age != 0 && age.toString() != '0';

          profileCompleted = hasBiography && hasAge;
        }

        return {
          'success': true,
          'role': role,
          'profile_completed': profileCompleted,
          'data': data,
        };
      }

      return {'success': false, 'profile_completed': true};
    } catch (e) {
      return {'success': false, 'profile_completed': true, 'error': e.toString()};
    }
  }

  static Future<void> checkAndNavigateProfile(
    BuildContext context,
    String token,
    String role,
  ) async {
    if (role != 'influencer') {
      if (context.mounted) {
        if (role == 'client') {
          Navigator.pushNamedAndRemoveUntil(context, '/clientHome', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/clientHome', (route) => false);
        }
      }
      return;
    }

    try {
      final authService = AuthService();
      final result = await authService.checkProfileCompletion(token);

      if (!context.mounted) return;

      final isProfileComplete = result['profile_completed'] == true;

      if (isProfileComplete) {
        Navigator.pushNamedAndRemoveUntil(context, '/influencerHome', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/completeProfile', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/influencerHome', (route) => false);
      }
    }
  }

  Future<dynamic> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.verifyOtp),
            headers: ApiConfig.headers(),
            body: jsonEncode(<String, dynamic>{
              "email": email,
              "code": code,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}