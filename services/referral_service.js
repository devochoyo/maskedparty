// FILE LOCATION: services/referral_service.js
// Mirrors lib/services/referral_service.dart.
(function (global) {
  "use strict";

  const ReferralService = {
    async getMyReferralCode(token) {
      return ApiConfig.get(ApiEndpoints.referralMyCode, token);
    },
  };

  global.ReferralService = ReferralService;
})(window);
