// FILE LOCATION: lib/services/referral_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maskedparty/services/session_manager.dart';
import 'package:flutter/foundation.dart';

class ReferralService {
  static const String baseUrl = 'https://maskedparty.name.ng/api';

  Future<Map<String, dynamic>> getMyReferralCode() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/referral/my-code.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch referral code');
      }
    } catch (e) {
      debugPrint('Error fetching referral code: $e');
      rethrow;
    }
  }
}