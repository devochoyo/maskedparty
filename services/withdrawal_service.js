// FILE LOCATION: services/withdrawal_service.js
// Mirrors lib/services/withdrawal_service.dart. Payout goes to the
// bank_name/account_number captured at registration — no bank fields are
// sent per request. Only one pending withdrawal allowed at a time (HTTP
// 409); server-side minimum enforced (HTTP 422 with the limit in the message).
(function (global) {
  "use strict";

  const WithdrawalService = {
    async requestWithdrawal(token, amount) {
      return ApiConfig.post(ApiEndpoints.withdrawalRequest, token, { amount });
    },

    async getWithdrawalHistory(token) {
      return ApiConfig.get(ApiEndpoints.withdrawalHistory, token);
    },
  };

  global.WithdrawalService = WithdrawalService;
})(window);
