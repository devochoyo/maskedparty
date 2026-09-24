// FILE LOCATION: services/api.js
// Mirrors lib/services/api.dart — central fetch wrapper, headers, and
// standardized response/error handling. Every other service file uses
// window.ApiConfig instead of calling fetch() directly.
(function (global) {
  "use strict";

  const ApiConfig = {
    baseUrl: "https://maskedparty.name.ng/api/",
    timeoutMs: 30000,

    headers() {
      return {
        "Content-Type": "application/json",
        Accept: "application/json",
      };
    },

    authHeaders(token) {
      return {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: "Bearer " + token,
      };
    },

    multipartHeaders(token) {
      return {
        Accept: "application/json",
        Authorization: "Bearer " + token,
      };
    },

    // Builds a full request URL for an endpoint path, optionally with query params.
    uri(endpointPath, queryParameters) {
      const full = this.baseUrl + endpointPath;
      if (!queryParameters || Object.keys(queryParameters).length === 0) {
        return full;
      }
      const usp = new URLSearchParams();
      Object.keys(queryParameters).forEach((k) => {
        if (queryParameters[k] !== undefined && queryParameters[k] !== null) {
          usp.append(k, queryParameters[k]);
        }
      });
      return full + "?" + usp.toString();
    },

    // Wraps fetch with a timeout so a stalled request can't hang forever.
    async _fetchWithTimeout(url, options) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), this.timeoutMs);
      try {
        return await fetch(url, { ...options, signal: controller.signal });
      } finally {
        clearTimeout(timer);
      }
    },

    // Parses a Response into the app's standard result shape. Mirrors
    // ApiConfig.handleResponse in api.dart, including the 401 session
    // message and preserving field-level validation errors under `data`.
    async handleResponse(response, isAuthenticatedRequest = false) {
      let decoded;
      try {
        decoded = await response.json();
      } catch (e) {
        return {
          success: false,
          message: "Invalid response received from server.",
          status_code: response.status,
        };
      }

      if (response.status >= 200 && response.status < 300) {
        return decoded;
      }

      if (response.status === 401 && isAuthenticatedRequest) {
        return {
          success: false,
          message: "Session expired. Please login again.",
          status_code: response.status,
        };
      }

      if (decoded && typeof decoded === "object") {
        return {
          ...decoded,
          success: false,
          message: decoded.message || "Something went wrong. Please try again.",
          status_code: response.status,
        };
      }

      return {
        success: false,
        message: "Something went wrong. Please try again.",
        status_code: response.status,
      };
    },

    handleError(error) {
      if (error && error.name === "AbortError") {
        return { success: false, message: "Connection timed out. Please try again." };
      }
      if (!navigator.onLine) {
        return { success: false, message: "No internet connection. Please check your network." };
      }
      return { success: false, message: "Unexpected error occurred. Please try again." };
    },

    // Convenience helpers used by every service file.
    async get(path, token, queryParameters) {
      try {
        const url = this.uri(path, queryParameters);
        const opts = { method: "GET", headers: token ? this.authHeaders(token) : this.headers() };
        const res = await this._fetchWithTimeout(url, opts);
        return await this.handleResponse(res, !!token);
      } catch (e) {
        return this.handleError(e);
      }
    },

    async post(path, token, body) {
      try {
        const url = this.uri(path);
        const opts = {
          method: "POST",
          headers: token ? this.authHeaders(token) : this.headers(),
          body: body !== undefined ? JSON.stringify(body) : undefined,
        };
        const res = await this._fetchWithTimeout(url, opts);
        return await this.handleResponse(res, !!token);
      } catch (e) {
        return this.handleError(e);
      }
    },

    async postMultipart(path, token, formData) {
      try {
        const url = this.uri(path);
        const opts = {
          method: "POST",
          headers: this.multipartHeaders(token),
          body: formData,
        };
        const res = await this._fetchWithTimeout(url, opts);
        return await this.handleResponse(res, true);
      } catch (e) {
        return this.handleError(e);
      }
    },
  };

  global.ApiConfig = ApiConfig;
})(window);
