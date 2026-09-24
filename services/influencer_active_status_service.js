// FILE LOCATION: services/influencer_active_status_service.js
// Mirrors lib/services/influencer_active_status_service.dart.
(function (global) {
  "use strict";

  const InfluencerActiveStatusService = {
    async getStatus(token, influencerId) {
      try {
        const result = await ApiConfig.get(ApiEndpoints.influencerActiveStatus, token, { id: influencerId });
        if (result && result.success === true) return result.data || null;
        return null;
      } catch (e) {
        return null;
      }
    },

    // Batch, up to 50 ids.
    async getStatuses(token, influencerIds) {
      try {
        if (!influencerIds || influencerIds.length === 0 || influencerIds.length > 50) return [];
        const result = await ApiConfig.get(ApiEndpoints.influencerActiveStatus, token, { ids: influencerIds.join(",") });
        if (result && result.success === true && Array.isArray(result.data)) return result.data;
        return [];
      } catch (e) {
        return [];
      }
    },

    async isTrulyOnline(token, influencerId) {
      const status = await this.getStatus(token, influencerId);
      return !!(status && status.is_truly_online === true);
    },

    // NOTE: sending a heartbeat is NOT part of the Dart service class — the
    // Dart source calls ApiEndpoints.influencerHeartbeat directly from
    // home.dart. Kept here anyway since every caller needs it and there's
    // no reason to duplicate the raw ApiConfig.post call at each site.
    async sendHeartbeat(token) {
      try {
        await ApiConfig.post(ApiEndpoints.influencerHeartbeat, token, undefined);
      } catch (e) {
        /* silent fail, matches Dart source */
      }
    },
  };

  global.InfluencerActiveStatusService = InfluencerActiveStatusService;
})(window);
