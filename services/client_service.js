// FILE LOCATION: services/client_service.js
// Mirrors lib/services/client_service.dart.
(function (global) {
  "use strict";

  const ClientService = {
    // GET /api/influencer/list.php — public
    async getInfluencers(token, { page, country, maskStatus, search, sortBy } = {}) {
      const q = {};
      if (page != null) q.page = String(page);
      if (country) q.country = country;
      if (maskStatus) q.mask_status = maskStatus;
      if (search) q.search = search;
      if (sortBy) q.sort_by = sortBy;
      return ApiConfig.get(ApiEndpoints.influencerList, token, q);
    },

    async getInfluencerDetails(token, influencerId) {
      return ApiConfig.get(ApiEndpoints.influencerDetails, token, { id: influencerId });
    },

    async getSavedInfluencers(token) {
      return ApiConfig.get(ApiEndpoints.savedInfluencers, token);
    },

    async saveInfluencer(token, influencerId) {
      return ApiConfig.post(ApiEndpoints.saveInfluencer, token, { influencer_id: influencerId });
    },

    async removeSavedInfluencer(token, influencerId) {
      return ApiConfig.post(ApiEndpoints.unsaveInfluencer, token, { influencer_id: influencerId });
    },
  };

  global.ClientService = ClientService;
})(window);
