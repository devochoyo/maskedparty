// FILE LOCATION: lib/services/chat_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class ChatService {
  /// Backend automatically filters phone numbers, emails, URLs, and social
  /// handles (WhatsApp/Telegram/Instagram/Facebook/TikTok) out of the
  /// message text server-side — do NOT add client-side filtering here.
  /// Backend: api/chat/send.php — body: {receiver_id, message}
  Future<dynamic> sendMessage(
    String token,
    String receiverId,
    String message,
  ) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.chatSend),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "receiver_id": receiverId,
              "message": message,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// List of conversations (one row per other participant), most recent
  /// first, each with its last message + unread count.
  /// Backend: api/chat/list.php — GET, no params.
  Future<dynamic> getConversations(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.chatList),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Message history with one other user, oldest-first. Opening a thread
  /// marks that other user's messages to us as read.
  ///
  /// Backend: api/chat/messages.php — GET — query params:
  ///   - other_user_id (required) — the OTHER participant's user id.
  ///     (NOT "conversation_id" — this backend has no conversation entity,
  ///     conversations are just grouped by the other participant's id.)
  ///   - limit (optional, 1-100, default 50)
  ///   - before_id (optional) — pass the oldest message id currently
  ///     loaded to page further back in history.
  Future<dynamic> getMessages(
    String token,
    String otherUserId, {
    int? limit,
    int? beforeId,
  }) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.chatMessages, queryParameters: {
              "other_user_id": otherUserId,
              if (limit != null) "limit": limit.toString(),
              if (beforeId != null) "before_id": beforeId.toString(),
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
