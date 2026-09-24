// FILE LOCATION: services/follow_service.js
// Mirrors lib/services/follow_service.dart.
(function (global) {
  "use strict";

  const FollowService = {
    async follow(influencerId) {
      const token = SessionManager.getToken();
      if (!token) {
        return { success: false, message: "Please login or register to follow.", requires_auth: true };
      }
      return ApiConfig.post(ApiEndpoints.followFollow, token, { influencer_id: influencerId });
    },

    async unfollow(influencerId) {
      const token = SessionManager.getToken();
      if (!token) {
        return { success: false, message: "Please login again.", requires_auth: true };
      }
      return ApiConfig.post(ApiEndpoints.followUnfollow, token, { influencer_id: influencerId });
    },

    async listFollowers(influencerId, page) {
      return ApiConfig.get(ApiEndpoints.followFollowers, null, {
        influencer_id: influencerId,
        page: page || 1,
      });
    },

    // Follower count + is_following. Auth optional.
    async status(influencerId) {
      const token = SessionManager.getToken();
      return ApiConfig.get(ApiEndpoints.followStatus, token, { influencer_id: influencerId });
    },
  };

  global.FollowService = FollowService;
})(window);
