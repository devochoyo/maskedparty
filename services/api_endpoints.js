// FILE LOCATION: services/api_endpoints.js
// Mirrors lib/services/api_endpoints.dart. No page should ever write a raw
// "auth/login.php"-style string literal — reference these constants instead.
(function (global) {
  "use strict";

  global.ApiEndpoints = Object.freeze({
    // Auth
    registerUser: "auth/register.php",
    login: "auth/login.php",
    logout: "auth/logout.php",
    forgotPassword: "auth/forgot-password.php",
    resetPassword: "auth/reset-password.php",
    influencerActiveStatus: "influencer/active-status.php",
    influencerHeartbeat: "influencer/heartbeat.php",
    verifyOtp: "auth/verify-otp.php",

    // Profile (shared)
    profileGet: "profile/get.php",
    profileUpdate: "profile/update.php",
    profileUploadPhoto: "profile/upload-photo.php",

    // Influencer discovery + saved
    influencerList: "influencer/list.php",
    influencerDetails: "influencer/details.php",
    savedInfluencers: "influencer/saved.php",
    saveInfluencer: "influencer/save.php",
    unsaveInfluencer: "influencer/unsave.php",

    // Influencer self-management
    influencerCompleteProfile: "influencer/complete-profile.php",
    influencerGallery: "influencer/gallery.php",
    influencerUploadGallery: "influencer/upload-gallery.php",
    influencerDeleteGalleryImage: "influencer/delete-gallery-image.php",
    influencerVerification: "influencer/verification.php",
    influencerOnlineStatus: "influencer/online-status.php",
    influencerEarnings: "influencer/earnings.php",
    influencerWhatOffer: "influencer/what-offer.php",

    // Calls
    callPending: "call/pending.php",
    callRequest: "call/request.php",
    paygPricing: "misc/payg-pricing.php",
    callAccept: "call/accept.php",
    callReject: "call/reject.php",
    callStart: "call/start.php",
    callEnd: "call/end.php",
    callExtend: "call/extend.php",
    callRelease: "call/release.php",
    callCountdown: "call/countdown.php",
    callManualRelease: "call/manual_release.php",
    callTrackingDetails: "call-tracking/details.php",

    // Chat
    chatList: "chat/list.php",
    chatMessages: "chat/messages.php",
    chatSend: "chat/send.php",

    // Notifications
    notificationList: "notification/list.php",
    notificationRead: "notification/read.php",

    // Reviews / Reports
    reviewCreate: "review/create.php",
    reviewReport: "review/report.php",

    // Wallet / Payments
    walletBalance: "wallet/balance.php",
    walletBuyCoins: "wallet/buy-coins.php",
    walletHistory: "wallet/history.php",
    walletPackages: "wallet/packages.php",
    paymentCreate: "payment/create-payment.php",
    paymentVerify: "payment/verify-payment.php",
    paymentHistory: "payment/payment-history.php",

    // Withdrawals
    withdrawalRequest: "withdrawal/request.php",
    withdrawalHistory: "withdrawal/history.php",

    // Generic uploads
    uploadImage: "upload/image.php",
    uploadVideo: "upload/video.php",
    uploadDocument: "upload/document.php",

    // Misc
    detectCountry: "misc/detect-country.php",
    callMinuteCosts: "misc/call-minute-costs.php",

    // Posts
    postList: "post/list.php",
    postGet: "post/get.php",
    postCreate: "post/create.php",
    postLike: "post/like.php",
    postUnlike: "post/unlike.php",
    postComment: "post/comment.php",
    postComments: "post/comments.php",

    // Follow system
    followFollow: "follow/follow.php",
    followUnfollow: "follow/unfollow.php",
    followFollowers: "follow/followers.php",
    followStatus: "follow/status.php",

    // Referrals
    referralMyCode: "referral/my-code.php",
  });
})(window);
