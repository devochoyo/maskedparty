// FILE LOCATION: services/influencer_service.js
// Mirrors lib/services/influencer_service.dart.
(function (global) {
  "use strict";

  const InfluencerService = {
    // The influencer's OWN gallery (view/delete). For a public profile's
    // gallery use ClientService.getInfluencerDetails instead.
    async getGallery(token) {
      return ApiConfig.get(ApiEndpoints.influencerGallery, token);
    },

    async deleteGalleryImage(token, imageId) {
      return ApiConfig.post(ApiEndpoints.influencerDeleteGalleryImage, token, { image_id: imageId });
    },

    // data keys: biography, age, complexion, favourite_food, hobby,
    // aspiration, financial_target, mask_status, willing_to_remove_mask.
    async completeProfile(token, data) {
      return ApiConfig.post(ApiEndpoints.influencerCompleteProfile, token, data);
    },

    // files: array of File objects. Field name MUST be "gallery_images"
    // (repeated). Backend caps at 10 gallery items total.
    async uploadGallery(token, files) {
      const fd = new FormData();
      files.forEach(function (f) { fd.append("gallery_images", f, f.name); });
      return ApiConfig.postMultipart(ApiEndpoints.influencerUploadGallery, token, fd);
    },

    // governmentIdFile, selfieFile: File objects (images).
    // verificationVideoFile: File/Blob (recorded clip). All three required.
    async submitVerification(token, { governmentIdFile, selfieFile, verificationVideoFile }) {
      if (!governmentIdFile) return { success: false, message: "Your government ID file is missing. Please re-upload it." };
      if (!selfieFile) return { success: false, message: "Your selfie photo is missing. Please take it again." };
      if (!verificationVideoFile) return { success: false, message: "Your verification video is missing. Please record it again." };

      const fd = new FormData();
      fd.append("government_id", governmentIdFile, governmentIdFile.name || "government_id.jpg");
      fd.append("selfie", selfieFile, selfieFile.name || "selfie.jpg");
      fd.append("verification_video", verificationVideoFile, verificationVideoFile.name || "verification_video.webm");
      return ApiConfig.postMultipart(ApiEndpoints.influencerVerification, token, fd);
    },

    // status: "online" | "offline" | "unavailable" (a string, not boolean).
    // "busy" is set automatically by the call lifecycle. Backend rejects
    // (HTTP 409) any change while on an active call.
    async updateOnlineStatus(token, status) {
      return ApiConfig.post(ApiEndpoints.influencerOnlineStatus, token, { status });
    },

    // -> { today, this_week, this_month, lifetime, wallet_balance,
    //      escrow_balance, call counts... }
    async getEarnings(token) {
      return ApiConfig.get(ApiEndpoints.influencerEarnings, token);
    },
  };

  global.InfluencerService = InfluencerService;
})(window);
