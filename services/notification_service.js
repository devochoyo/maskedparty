// FILE LOCATION: services/notification_service.js
// Mirrors lib/services/notification_service.dart.
(function (global) {
  "use strict";

  const NotificationService = {
    // data includes `unread_count` so a badge can be shown without a 2nd call.
    async getNotifications(token, page) {
      return ApiConfig.get(ApiEndpoints.notificationList, token, page ? { page: String(page) } : undefined);
    },

    async markAsRead(token, notificationId) {
      return ApiConfig.post(ApiEndpoints.notificationRead, token, { notification_id: notificationId });
    },

    async markAllAsRead(token) {
      return ApiConfig.post(ApiEndpoints.notificationRead, token, { mark_all: true });
    },
  };

  global.NotificationService = NotificationService;
})(window);
