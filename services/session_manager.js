// FILE LOCATION: services/session_manager.js
// Mirrors lib/services/session_manager.dart. Persists the logged-in user's
// auth token, role, and basic profile info across page loads.
//
// SECURITY NOTE: the backend issues bearer tokens (not cookies), so the
// token must live somewhere JS can read it to set the Authorization header.
// We use sessionStorage (cleared when the tab closes) rather than
// localStorage, to shrink the window a stolen/left-open device exposes the
// token, and every page ships a strict CSP (see each page's <meta> tag and
// the server security headers) specifically to make token-stealing XSS
// unreachable in the first place. See SECURITY.md for the full model.
(function (global) {
  "use strict";

  const TOKEN_KEY = "mp_auth_token";
  const ROLE_KEY = "mp_auth_role";
  const USER_KEY = "mp_auth_user";

  const SessionManager = {
    saveSession({ token, role, user }) {
      sessionStorage.setItem(TOKEN_KEY, token);
      sessionStorage.setItem(ROLE_KEY, role);
      if (user) sessionStorage.setItem(USER_KEY, JSON.stringify(user));
    },

    getToken() {
      return sessionStorage.getItem(TOKEN_KEY);
    },

    getRole() {
      return sessionStorage.getItem(ROLE_KEY);
    },

    getUser() {
      const raw = sessionStorage.getItem(USER_KEY);
      if (!raw) return null;
      try {
        return JSON.parse(raw);
      } catch (e) {
        return null;
      }
    },

    isLoggedIn() {
      const token = this.getToken();
      return !!token;
    },

    clearSession() {
      sessionStorage.removeItem(TOKEN_KEY);
      sessionStorage.removeItem(ROLE_KEY);
      sessionStorage.removeItem(USER_KEY);
    },

    // Best-effort extraction of a token from common API response shapes.
    extractToken(result) {
      if (!result || typeof result !== "object") return null;
      if (typeof result.token === "string") return result.token;
      if (typeof result.access_token === "string") return result.access_token;
      const data = result.data;
      if (data && typeof data === "object") {
        if (typeof data.token === "string") return data.token;
        if (typeof data.access_token === "string") return data.access_token;
      }
      return null;
    },

    extractRole(result, fallback = "client") {
      if (!result || typeof result !== "object") return fallback;
      if (typeof result.role === "string") return result.role;
      if (result.user && typeof result.user.role === "string") return result.user.role;
      const data = result.data;
      if (data && typeof data === "object") {
        if (typeof data.role === "string") return data.role;
        if (data.user && typeof data.user.role === "string") return data.user.role;
      }
      return fallback;
    },

    extractUser(result) {
      if (!result || typeof result !== "object") return null;
      if (result.user && typeof result.user === "object") return result.user;
      const data = result.data;
      if (data && data.user && typeof data.user === "object") return data.user;
      return null;
    },
  };

  global.SessionManager = SessionManager;
})(window);
