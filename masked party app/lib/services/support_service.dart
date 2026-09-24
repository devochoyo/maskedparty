// FILE LOCATION: lib/services/support_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class SupportService {
  // Contact support - start a new conversation or continue existing one
  Future<Map<String, dynamic>> contactSupport(String token, String message) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/support/contact.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server',
      };
    }
  }

  // Get current/latest conversation for the customer
  Future<Map<String, dynamic>> getMyConversation(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/support/my-conversation.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load conversation',
      };
    }
  }

  // Send message in a conversation (shared with support agents)
  Future<Map<String, dynamic>> sendMessage(
    String token, 
    int conversationId, 
    String message,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/support/send.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'message': message,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send message',
      };
    }
  }

  // Submit feedback after conversation ends
  Future<Map<String, dynamic>> submitFeedback({
    required String token,
    required int conversationId,
    required bool satisfied,
    required bool issueResolved,
    required bool professional,
    String? feedbackText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/support/submit-feedback.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'satisfied': satisfied,
          'issue_resolved': issueResolved,
          'professional': professional,
          'feedback_text': feedbackText ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to submit feedback',
      };
    }
  }
}