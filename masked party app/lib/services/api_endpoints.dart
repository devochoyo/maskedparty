// FILE LOCATION: lib/services/api_endpoints.dart
//
// Centralized list of every backend endpoint PATH (relative to
// ApiConfig.baseUrl). No service file should ever write a raw
// "auth/login.php"-style string literal directly — reference these
// constants instead. This is the single place to update if an endpoint
// is ever renamed on the backend.
//
// Endpoints intentionally NOT listed here because they are not meant to
// be called from the Flutter app:
//   - api/admin/*                     (admin-panel only)
//   - api/cron/*                      (server cron job only)
//   - api/payment/flutterwave-webhook.php  (Flutterwave server-to-server webhook)
//   - api/call/_release_escrow.php    (internal include, not routable)
//   - api/call/_settle_call.php       (internal include, not routable)
//   - api/misc/check_geoip.php        (internal/admin tooling)
//   - api/misc/import_geoip.php       (internal/admin tooling)
class ApiEndpoints {
  ApiEndpoints._();
  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------
  static const String registerUser = 'auth/register.php';
  static const String login = 'auth/login.php';
  static const String logout = 'auth/logout.php';
  static const String forgotPassword = 'auth/forgot-password.php';
  static const String resetPassword = 'auth/reset-password.php';
  static const String influencerActiveStatus = 'influencer/active-status.php'; 
  static const String influencerHeartbeat = 'influencer/heartbeat.php';
  static const String verifyOtp = 'auth/verify-otp.php';
  // ---------------------------------------------------------------------
  // Profile (shared client + influencer)
  // ---------------------------------------------------------------------
  static const String profileGet = 'profile/get.php';
  static const String profileUpdate = 'profile/update.php';
  // FIX: dedicated endpoint so avatars land in uploads/profiles/ instead of
  // being routed through the generic chat upload endpoints.
  static const String profileUploadPhoto = 'profile/upload-photo.php';
  // ---------------------------------------------------------------------
  // Influencer discovery (client-facing) + saved influencers
  // ---------------------------------------------------------------------
  static const String influencerList = 'influencer/list.php';
  static const String influencerDetails = 'influencer/details.php';
  static const String savedInfluencers = 'influencer/saved.php';
  static const String saveInfluencer = 'influencer/save.php';
  static const String unsaveInfluencer = 'influencer/unsave.php';
  // ---------------------------------------------------------------------
  // Influencer self-management
  // ---------------------------------------------------------------------
  static const String influencerCompleteProfile =
      'influencer/complete-profile.php';
  static const String influencerGallery = 'influencer/gallery.php';
  static const String influencerUploadGallery =
      'influencer/upload-gallery.php';
  static const String influencerDeleteGalleryImage =
      'influencer/delete-gallery-image.php';
  static const String influencerVerification = 'influencer/verification.php';
  static const String influencerOnlineStatus =
      'influencer/online-status.php';
  static const String influencerEarnings = 'influencer/earnings.php';
  static const String influencerWhatOffer = 'influencer/what-offer.php';
  // ---------------------------------------------------------------------
  // Calls
  // ---------------------------------------------------------------------
  static const String callPending = 'call/pending.php';
  static const String callRequest = 'call/request.php';
  static const String paygPricing = 'misc/payg-pricing.php';
  static const String callAccept = 'call/accept.php';
  static const String callReject = 'call/reject.php';
  static const String callStart = 'call/start.php';
  static const String callEnd = 'call/end.php';
  static const String callExtend = 'call/extend.php';
  static const String callRelease = 'call/release.php';
  static const String callCountdown = 'call/countdown.php';
  static const String callManualRelease = 'call/manual_release.php';

  // Call tracking (post-call summary)
  static const String callTrackingDetails = 'call-tracking/details.php';
  // ---------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------
  static const String chatList = 'chat/list.php';
  static const String chatMessages = 'chat/messages.php';
  static const String chatSend = 'chat/send.php';
  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------
  static const String notificationList = 'notification/list.php';
  static const String notificationRead = 'notification/read.php';
  // ---------------------------------------------------------------------
  // Reviews / Reports
  // ---------------------------------------------------------------------
  static const String reviewCreate = 'review/create.php';
  static const String reviewReport = 'review/report.php';
  // ---------------------------------------------------------------------
  // Wallet / Payments (Flutterwave)
  // ---------------------------------------------------------------------
  static const String walletBalance = 'wallet/balance.php';
  static const String walletBuyCoins = 'wallet/buy-coins.php';
  static const String walletHistory = 'wallet/history.php';
  static const String walletPackages = 'wallet/packages.php';
  // Flutterwave payment endpoints (from API documentation)
  static const String paymentCreate = 'payment/create-payment.php';
  static const String paymentVerify = 'payment/verify-payment.php';
  static const String paymentHistory = 'payment/payment-history.php';
  // ---------------------------------------------------------------------
  // Withdrawals
  // ---------------------------------------------------------------------
  static const String withdrawalRequest = 'withdrawal/request.php';
  static const String withdrawalHistory = 'withdrawal/history.php';
  // ---------------------------------------------------------------------
  // Generic uploads (chat attachments, etc.)
  // ---------------------------------------------------------------------
  static const String uploadImage = 'upload/image.php';
  static const String uploadVideo = 'upload/video.php';
  static const String uploadDocument = 'upload/document.php';
  // ---------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------
  static const String detectCountry = 'misc/detect-country.php';
  // Admin-configured coin cost tiers by call minute (e.g. "1 minute = 10
  // coins", "12 minutes = 22 coins"), plus the effective platform
  // coins-per-minute rate used for billing. Read-only, any logged-in user.
  static const String callMinuteCosts = 'misc/call-minute-costs.php';

  // ---------------------------------------------------------------------
  // Posts (public feed + influencer create)
  // ---------------------------------------------------------------------
  static const String postList     = 'post/list.php';
  static const String postGet      = 'post/get.php';
  static const String postCreate   = 'post/create.php';
  static const String postLike     = 'post/like.php';
  static const String postUnlike   = 'post/unlike.php';
  static const String postComment  = 'post/comment.php';
  static const String postComments = 'post/comments.php';

  // ---------------------------------------------------------------------
  // Follow system
  // ---------------------------------------------------------------------
  static const String followFollow    = 'follow/follow.php';
  static const String followUnfollow  = 'follow/unfollow.php';
  static const String followFollowers = 'follow/followers.php';
  static const String followStatus    = 'follow/status.php';
}
