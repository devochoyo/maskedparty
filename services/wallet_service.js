// FILE LOCATION: services/wallet_service.js
// Mirrors lib/services/wallet_service.dart.
(function (global) {
  "use strict";

  const WalletService = {
    // -> { current_balance, total_purchased, total_spent, escrow_balance, available_balance }
    async getBalance(token) {
      return ApiConfig.get(ApiEndpoints.walletBalance, token);
    },

    async buyCoins(token, packageId) {
      return ApiConfig.post(ApiEndpoints.walletBuyCoins, token, { package_id: packageId });
    },

    async getHistory(token, { limit, offset } = {}) {
      const q = {};
      if (limit != null) q.limit = String(limit);
      if (offset != null) q.offset = String(offset);
      return ApiConfig.get(ApiEndpoints.walletHistory, token, q);
    },
  };

  global.WalletService = WalletService;
})(window);
