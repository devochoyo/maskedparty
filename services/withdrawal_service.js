// FILE LOCATION: services/withdrawal_service.js
// Mirrors lib/services/withdrawal_service.dart. Bank details are asked for
// here (at withdrawal time), not at registration; the server saves them so
// they are pre-filled next time. Only one pending withdrawal allowed at a
// time (HTTP 409); server-side minimum enforced (HTTP 422 with the limit in
// the message).
(function (global) {
  "use strict";

  const WithdrawalService = {
    async requestWithdrawal(token, amount, bank) {
      bank = bank || {};
      return ApiConfig.post(ApiEndpoints.withdrawalRequest, token, {
        amount: amount,
        bank_name: bank.bankName,
        account_number: bank.accountNumber,
        bank_code_type: bank.bankCodeType,
        bank_code_value: bank.bankCodeValue,
      });
    },

    async getWithdrawalHistory(token) {
      return ApiConfig.get(ApiEndpoints.withdrawalHistory, token);
    },
  };

  global.WithdrawalService = WithdrawalService;
})(window);
