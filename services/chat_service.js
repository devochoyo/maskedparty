// FILE LOCATION: services/chat_service.js
// Mirrors lib/services/chat_service.dart. NOTE: the backend auto-filters
// phone numbers/emails/URLs/social handles out of message text server-side
// — do NOT add client-side filtering here, matching the Dart source.
(function (global) {
  "use strict";

  const ChatService = {
    async sendMessage(token, receiverId, message) {
      return ApiConfig.post(ApiEndpoints.chatSend, token, { receiver_id: receiverId, message });
    },

    // One row per other participant, most recent first, with last message + unread count.
    async getConversations(token) {
      return ApiConfig.get(ApiEndpoints.chatList, token);
    },

    // Message history with one other user, oldest-first. Opening a thread
    // marks that other user's messages to us as read (server-side).
    async getMessages(token, otherUserId, { limit, beforeId } = {}) {
      const q = { other_user_id: otherUserId };
      if (limit != null) q.limit = String(limit);
      if (beforeId != null) q.before_id = String(beforeId);
      return ApiConfig.get(ApiEndpoints.chatMessages, token, q);
    },
  };

  global.ChatService = ChatService;
})(window);
