// FILE LOCATION: services/support_service.js
// Mirrors lib/services/support_service.dart.
(function (global) {
  "use strict";

  const SupportService = {
    async contactSupport(token, message) {
      return ApiConfig.post("support/contact.php", token, { message });
    },
    async getMyConversation(token) {
      return ApiConfig.get("support/my-conversation.php", token);
    },
    async sendMessage(token, conversationId, message) {
      return ApiConfig.post("support/send.php", token, { conversation_id: conversationId, message });
    },
    async submitFeedback({ token, conversationId, satisfied, issueResolved, professional, feedbackText }) {
      return ApiConfig.post("support/submit-feedback.php", token, {
        conversation_id: conversationId,
        satisfied,
        issue_resolved: issueResolved,
        professional,
        feedback_text: feedbackText || "",
      });
    },
  };

  global.SupportService = SupportService;
})(window);
