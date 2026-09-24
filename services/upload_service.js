// FILE LOCATION: services/upload_service.js
// Mirrors lib/services/upload_service.dart. Generic single-file uploads.
// Each method takes a browser File object (from an <input type="file">).
(function (global) {
  "use strict";

  const UploadService = {
    // field name MUST be "image" — backend checks $_FILES["image"] specifically.
    async uploadImage(token, file) {
      const fd = new FormData();
      fd.append("image", file, file.name);
      return ApiConfig.postMultipart(ApiEndpoints.uploadImage, token, fd);
    },

    // field name MUST be "video".
    async uploadVideo(token, file) {
      const fd = new FormData();
      fd.append("video", file, file.name);
      return ApiConfig.postMultipart(ApiEndpoints.uploadVideo, token, fd);
    },

    // field name MUST be "document".
    async uploadDocument(token, file) {
      const fd = new FormData();
      fd.append("document", file, file.name);
      return ApiConfig.postMultipart(ApiEndpoints.uploadDocument, token, fd);
    },

    // Dedicated profile-photo endpoint — field name MUST be "photo".
    // Stores under uploads/profiles/ and persists straight to
    // users.profile_photo — no separate ProfileService.updateProfile call needed.
    async uploadProfilePhoto(token, file) {
      const fd = new FormData();
      fd.append("photo", file, file.name);
      return ApiConfig.postMultipart(ApiEndpoints.profileUploadPhoto, token, fd);
    },
  };

  global.UploadService = UploadService;
})(window);
