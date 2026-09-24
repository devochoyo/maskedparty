// FILE LOCATION: services/auth_service.js
// Mirrors lib/services/auth_service.dart.
(function (global) {
  "use strict";

  const AuthService = {
    async register({
      role,
      email,
      password,
      confirmPassword,
      mysteryName,
      countryName,
      countryCode,
      fullName,
      bankName,
      accountNumber,
      bankCodeType,
      bankCodeValue,
      referralCode,
      maskStatus,
    }) {
      const body = {
        role,
        email,
        password,
        confirm_password: confirmPassword,
        mystery_name: mysteryName,
        country_name: countryName,
      };
      if (countryCode) body.country_code = countryCode;
      if (referralCode) body.referral_code = referralCode;
      if (role === "influencer") {
        if (fullName) body.full_name = fullName;
        if (bankName) body.bank_name = bankName;
        if (accountNumber) body.account_number = accountNumber;
        if (bankCodeType) body.bank_code_type = bankCodeType;
        if (bankCodeValue) body.bank_code_value = bankCodeValue;
        if (maskStatus) body.mask_status = maskStatus;
      }

      const result = await ApiConfig.post(ApiEndpoints.registerUser, null, body);

      if (result && result.success === true) {
        const token = SessionManager.extractToken(result);
        const extractedRole = SessionManager.extractRole(result, role);
        const user = SessionManager.extractUser(result);
        if (token) SessionManager.saveSession({ token, role: extractedRole, user });
      }
      return result;
    },

    async login(email, password) {
      const result = await ApiConfig.post(ApiEndpoints.login, null, { email, password });

      if (result && result.success === true) {
        const token = SessionManager.extractToken(result);
        const role = SessionManager.extractRole(result, "client");
        const user = SessionManager.extractUser(result);
        const data = result.data;

        let profileCompleted = true;
        if (data && Object.prototype.hasOwnProperty.call(data, "profile_completed")) {
          const value = data.profile_completed;
          if (typeof value === "boolean") profileCompleted = value;
          else if (typeof value === "number") profileCompleted = value === 1;
          else if (typeof value === "string") profileCompleted = value === "1" || value.toLowerCase() === "true";
        }

        if (token) SessionManager.saveSession({ token, role, user });

        return {
          success: true,
          data,
          message: result.message,
          profile_completed: profileCompleted,
          role,
          token,
        };
      }

      return result && typeof result === "object" ? result : { success: false, message: "Login failed" };
    },

    async logout(token) {
      let result;
      try {
        result = await ApiConfig.post(ApiEndpoints.logout, token);
      } finally {
        SessionManager.clearSession();
      }
      return result;
    },

    async forgotPassword(email) {
      return ApiConfig.post(ApiEndpoints.forgotPassword, null, { email });
    },

    async resetPassword({ code, newPassword, confirmPassword }) {
      return ApiConfig.post(ApiEndpoints.resetPassword, null, {
        otp: code,
        new_password: newPassword,
        confirm_password: confirmPassword,
      });
    },

    async verifyOtp({ email, code }) {
      return ApiConfig.post(ApiEndpoints.verifyOtp, null, { email, code });
    },

    async checkProfileCompletion(token) {
      const result = await ApiConfig.get(ApiEndpoints.profileGet, token);

      if (result && result.success === true) {
        const data = result.data;
        const role = data ? data.role : null;

        if (role !== "influencer") {
          return { success: true, role, profile_completed: true, data };
        }

        let profileCompleted = false;
        if (data && Object.prototype.hasOwnProperty.call(data, "profile_completed")) {
          const value = data.profile_completed;
          if (typeof value === "boolean") profileCompleted = value;
          else if (typeof value === "number") profileCompleted = value === 1;
          else if (typeof value === "string") profileCompleted = value === "1" || value.toLowerCase() === "true";
        }

        if (!profileCompleted && data) {
          const hasBiography = data.biography != null && String(data.biography) !== "" && String(data.biography) !== "null";
          const hasAge = data.age != null && data.age !== 0 && String(data.age) !== "0";
          profileCompleted = hasBiography && hasAge;
        }

        return { success: true, role, profile_completed: profileCompleted, data };
      }

      return { success: false, profile_completed: true };
    },

    // Routes a logged-in user to the right home page after login/splash,
    // mirroring AuthService.checkAndNavigateProfile in the Dart app.
    // Uses clean URLs (see ROUTES in router.js).
    async routeAfterLogin(token, role) {
      if (role !== "influencer") {
        window.location.replace("/client-home");
        return;
      }
      try {
        const result = await this.checkProfileCompletion(token);
        if (result.profile_completed === true) {
          window.location.replace("/influencer-home");
        } else {
          window.location.replace("/complete-profile");
        }
      } catch (e) {
        window.location.replace("/influencer-home");
      }
    },
  };

  global.AuthService = AuthService;
})(window);
