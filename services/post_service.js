// FILE LOCATION: services/post_service.js
// Mirrors lib/services/post_service.dart.
(function (global) {
  "use strict";

  const PostService = {
    // Public home feed — works for guests too. Logged-in responses include
    // `liked_by_me` per post.
    async listPosts(page) {
      const token = SessionManager.getToken();
      return ApiConfig.get(ApiEndpoints.postList, token, { page: page || 1 });
    },

    async getPost(postId) {
      const token = SessionManager.getToken();
      return ApiConfig.get(ApiEndpoints.postGet, token, { id: postId });
    },

    // images: array of File objects (influencer only)
    async createPost({ caption, body, images }) {
      const token = SessionManager.getToken();
      if (!token) return { success: false, message: "Please login again." };

      const formData = new FormData();
      formData.append("caption", caption);
      if (body && body.trim()) formData.append("body", body.trim());
      if (images) {
        images.forEach(function (file) {
          formData.append("images[]", file, file.name);
        });
      }
      return ApiConfig.postMultipart(ApiEndpoints.postCreate, token, formData);
    },

    async likePost(postId) {
      const token = SessionManager.getToken();
      if (!token) return { success: false, message: "Please login to like posts." };
      return ApiConfig.post(ApiEndpoints.postLike, token, { post_id: postId });
    },

    async unlikePost(postId) {
      const token = SessionManager.getToken();
      if (!token) return { success: false, message: "Please login again." };
      return ApiConfig.post(ApiEndpoints.postUnlike, token, { post_id: postId });
    },

    async addComment({ postId, comment }) {
      const token = SessionManager.getToken();
      if (!token) return { success: false, message: "Please login to comment." };
      return ApiConfig.post(ApiEndpoints.postComment, token, { post_id: postId, comment });
    },

    async listComments({ postId, page }) {
      return ApiConfig.get(ApiEndpoints.postComments, null, { post_id: postId, page: page || 1 });
    },
  };

  global.PostService = PostService;
})(window);
