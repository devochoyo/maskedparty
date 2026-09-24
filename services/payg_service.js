// FILE LOCATION: services/payg_service.js
// Mirrors lib/services/payg_service.dart.
(function (global) {
  "use strict";

  const PaygService = {
    async getPricing(token) {
      const result = await ApiConfig.get(ApiEndpoints.paygPricing, token);
      if (result && result.success === true && result.data) {
        const toNum = (v) => (typeof v === "number" ? v : parseFloat(v) || 0);
        return { perMinute: toNum(result.data.per_minute), perSecond: toNum(result.data.per_second) };
      }
      return null;
    },

    async getWhatOffer(token) {
      return ApiConfig.get(ApiEndpoints.influencerWhatOffer, token);
    },

    async saveWhatOffer(token, offer) {
      return ApiConfig.post(ApiEndpoints.influencerWhatOffer, token, { what_offer: offer });
    },
  };

  global.PaygService = PaygService;
})(window);
