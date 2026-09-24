// FILE LOCATION: services/authentication_service.js
// Mirrors lib/services/authentication_service.dart.
(function (global) {
  "use strict";

  const AuthenticationService = {
    async getAuthenticatedUser(token) {
      return ApiConfig.get("auth/check-status.php", token);
    },
    async sendOtp(email) {
      return ApiConfig.post("auth/send-otp.php", null, { email });
    },
    async checkStatus(email) {
      return ApiConfig.post("auth/check-status.php", null, { email });
    },
    async verifyOtp(email, code) {
      return ApiConfig.post(ApiEndpoints.verifyOtp, null, { email, code });
    },
  };

  global.AuthenticationService = AuthenticationService;
})(window);
