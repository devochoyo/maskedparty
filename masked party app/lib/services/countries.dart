// FILE LOCATION: lib/services/countries.dart
//
// Shared country-detection service. Both registration screens call this
// instead of duplicating their own HTTP logic. Detects the user's country
// via the backend's misc/detect-country.php endpoint (public, no auth).

import 'dart:convert';

import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class CountryService {
  /// Detects the user's country name via the backend.
  /// Returns the country name on success, or null if detection failed
  /// (network error, timeout, non-200 response, or success:false).
  static Future<String?> detectCountry() async {
    try {
      final response = await http
          .get(ApiConfig.uri(ApiEndpoints.detectCountry))
          .timeout(const Duration(seconds: 6));



      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['success'] == true) {
          final country = decoded['data']?['country_name'];
          if (country is String && country.isNotEmpty) {
            return country;
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
       
      }
      return null;
    }
  }
}
