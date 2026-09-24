// FILE LOCATION: lib/services/api.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiConfig {
  static const String baseUrl = "https://maskedparty.name.ng/api/";

  // No Flutterwave keys needed here — the backend handles all payment processing.
  // The app only needs the authorization_url returned by the backend.

  static const Duration timeoutDuration = Duration(seconds: 30);

  static Map<String, String> headers() {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  static Map<String, String> authHeaders(String token) {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Map<String, String> multipartHeaders(String token) {
    return {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Builds a full request URI for an [ApiEndpoints] path, optionally with
  /// query parameters. Centralizing this means no service file needs to
  /// hand-concatenate `ApiConfig.baseUrl + "..."` strings.
  static Uri uri(String endpointPath, {Map<String, String>? queryParameters}) {
    final full = "$baseUrl$endpointPath";
    if (queryParameters == null || queryParameters.isEmpty) {
      return Uri.parse(full);
    }
    return Uri.parse(full).replace(queryParameters: queryParameters);
  }

  /// Parses an http.Response into the app's standard result shape.
  ///
  /// [isAuthenticatedRequest] should be true only when the request that
  /// produced this response actually sent a Bearer token (i.e. anything
  /// using [authHeaders] or [multipartHeaders]). For those calls, a 401
  /// really does mean "your session/token is no longer valid" (expired,
  /// revoked by logout, or the user was banned), so we show a session
  /// message and the caller should route back to the login screen.
  ///
  /// For public/unauthenticated requests (register, login, forgot-password,
  /// etc.) a 401 means something else entirely per the API — e.g.
  /// auth/login.php returns 401 for "Invalid credentials." Overwriting that
  /// with "Please login again" hides the real reason from the user, so in
  /// that case we just pass the server's actual message through.
  ///
  /// IMPORTANT: on a non-2xx response this now preserves the backend's
  /// full decoded body (merged under the returned map) instead of
  /// discarding everything but `message`. The backend's standard error
  /// shape is `{success, message, data}`, and for validation failures
  /// (HTTP 422) `data` holds a field -> error map (see
  /// `auth/register.php`, `influencer/complete-profile.php`, etc.). Callers
  /// that only read `success`/`message` are unaffected; callers that also
  /// want field-level errors can now read `result["data"]`. A
  /// `status_code` field is also added so callers can branch on 401 / 402
  /// (insufficient coins) / 403 / 404 / 409 (conflict) / 422 / 500 without
  /// re-parsing the response themselves.
  static dynamic handleResponse(
    http.Response response, {
    bool isAuthenticatedRequest = false,
  }) {
    try {
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      if (response.statusCode == 401 && isAuthenticatedRequest) {
        return {
          "success": false,
          "message": "Session expired. Please login again.",
          "status_code": response.statusCode,
        };
      }

      if (decoded is Map) {
        return {
          ...decoded,
          "success": false,
          "message": decoded["message"] ?? "Something went wrong. Please try again.",
          "status_code": response.statusCode,
        };
      }

      return {
        "success": false,
        "message": "Something went wrong. Please try again.",
        "status_code": response.statusCode,
      };
    } on FormatException {
      return {
        "success": false,
        "message": "Invalid response received from server.",
        "status_code": response.statusCode,
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Something went wrong while reading the server response.",
        "status_code": response.statusCode,
      };
    }
  }

  static dynamic handleError(dynamic error) {
    if (error is SocketException) {
      return {
        "success": false,
        "message": "No internet connection. Please check your network.",
      };
    }

    if (error is TimeoutException) {
      return {
        "success": false,
        "message": "Connection timed out. Please try again.",
      };
    }

    if (error is FormatException) {
      return {
        "success": false,
        "message": "Invalid response received from server.",
      };
    }

    return {
      "success": false,
      "message": "Unexpected error occurred. Please try again.",
    };
  }
}