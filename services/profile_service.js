// FILE LOCATION: services/profile_service.js
// Mirrors lib/services/profile_service.dart.
(function (global) {
  "use strict";

  const ProfileService = {
    // Also functions as "refresh profile" — no separate endpoint exists.
    async getProfile(token) {
      return ApiConfig.get(ApiEndpoints.profileGet, token);
    },

    // Accepts any subset of the editable fields. The backend rejects
    // (HTTP 403) attempts to change role/country/email/full_name here.
    async updateProfile(token, data) {
      return ApiConfig.post(ApiEndpoints.profileUpdate, token, data);
    },
  };

  global.ProfileService = ProfileService;
})(window);
