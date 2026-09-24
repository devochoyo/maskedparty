// FILE LOCATION: services/call_service.js
// Mirrors lib/services/call_service.dart.
(function (global) {
  "use strict";

  const CallService = {
    // -------------------------------------------------------------------
    // Pricing
    // -------------------------------------------------------------------
    // GET /api/misc/call-minute-costs.php
    // -> { tiers: [{id, minutes, coin_cost}], price_per_minute } or null
    async getCallMinuteCosts(token) {
      try {
        const result = await ApiConfig.get(ApiEndpoints.callMinuteCosts, token);
        if (result && result.success === true && result.data) {
          const data = result.data;
          const toNum = (v) => (typeof v === "number" ? v : parseFloat(v) || 0);
          const tiers = Array.isArray(data.tiers)
            ? data.tiers.map((t) => ({
                id: toNum(t.id),
                minutes: toNum(t.minutes),
                coinCost: toNum(t.coin_cost),
                ratePerMinute: toNum(t.minutes) > 0 ? toNum(t.coin_cost) / toNum(t.minutes) : 0,
              }))
            : [];
          const pricePerMinute = typeof data.price_per_minute === "number" ? data.price_per_minute : (parseFloat(data.price_per_minute) || 1.0);
          return { tiers, pricePerMinute };
        }
        return null;
      } catch (e) {
        return null;
      }
    },

    // -------------------------------------------------------------------
    // Call request lifecycle (request_id)
    // -------------------------------------------------------------------
    async requestCall(token, influencerId, billingMode) {
      return ApiConfig.post(ApiEndpoints.callRequest, token, {
        influencer_id: influencerId,
        billing_mode: billingMode || "standard",
      });
    },

    async getPendingCall(token) {
      return ApiConfig.get(ApiEndpoints.callPending, token);
    },

    async acceptCall(token, requestId) {
      return ApiConfig.post(ApiEndpoints.callAccept, token, { request_id: requestId });
    },

    async rejectCall(token, requestId) {
      return ApiConfig.post(ApiEndpoints.callReject, token, { request_id: requestId });
    },

    async startCall(token, requestId) {
      return ApiConfig.post(ApiEndpoints.callStart, token, { request_id: requestId });
    },

    // -------------------------------------------------------------------
    // Active call management (call_id)
    // -------------------------------------------------------------------
    async getCountdown(token, callId) {
      return ApiConfig.post(ApiEndpoints.callCountdown, token, { call_id: callId });
    },

    async extendCall(token, callId, additionalMinutes) {
      return ApiConfig.post(ApiEndpoints.callExtend, token, {
        call_id: callId,
        additional_minutes: additionalMinutes || 5,
      });
    },

    // Does NOT release escrow. Idempotent.
    async endCall(token, callId) {
      return ApiConfig.post(ApiEndpoints.callEnd, token, { call_id: callId });
    },

    // Client manually releases escrowed coins. Idempotent.
    async releaseCoins(token, callId) {
      return ApiConfig.post(ApiEndpoints.callRelease, token, { call_id: callId });
    },

    async releaseEscrow(token, callId) {
      return this.releaseCoins(token, callId);
    },

    // Throws on failure (message from API), except when already_released
    // is true — that's treated as success, matching the Dart source.
    async manualReleaseEscrow(token, callId) {
      const result = await ApiConfig.post(ApiEndpoints.callManualRelease, token, { call_id: callId });
      if (result && result.success === true) {
        return result.data || {};
      }
      if (result && result.data && result.data.already_released === true) {
        return result.data;
      }
      throw new Error((result && result.message) || "Failed to manually release escrow");
    },

    // -------------------------------------------------------------------
    // Call tracking (post-call summary)
    // -------------------------------------------------------------------
    // Returns null on 404 (not ready yet) or any error, for graceful retry.
    async getCallTrackingDetails(token, callId) {
      try {
        const result = await ApiConfig.get(ApiEndpoints.callTrackingDetails, token, { call_id: callId });
        if (result && result.success === true) return result.data || null;
        return null;
      } catch (e) {
        return null;
      }
    },

    // -------------------------------------------------------------------
    // Post-call rating / reporting
    // -------------------------------------------------------------------
    async submitRating({ token, callId, rating, experienceText }) {
      return ApiConfig.post(ApiEndpoints.reviewCreate, token, {
        call_id: callId,
        rating,
        experience_text: experienceText,
      });
    },

    async reportUser({ token, reportedUserId, callId, reason, description }) {
      return ApiConfig.post(ApiEndpoints.reviewReport, token, {
        reported_user_id: reportedUserId,
        call_id: callId,
        reason,
        description,
      });
    },
  };

  global.CallService = CallService;
})(window);
