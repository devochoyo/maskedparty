// FILE LOCATION: services/route_guard.js
// Loaded (after session_manager.js) at the very top of every protected
// page's <head>, before any body content, so a logged-out visitor is
// redirected before protected content ever paints.
//
// Usage: <script src="/services/session_manager.js"></script>
//        <script src="/services/route_guard.js"></script>
//        <script>RouteGuard.require();</script>               // any logged-in user
//        <script>RouteGuard.require('client');</script>        // client only
//        <script>RouteGuard.require('influencer');</script>    // influencer only
(function (global) {
  "use strict";

  const RouteGuard = {
    // Redirects to /login (preserving the intended URL) if not logged in.
    // If `role` is given and doesn't match the session's role, redirects to
    // that role's own home instead of granting access to the wrong app half.
    require(role) {
      if (!SessionManager.isLoggedIn()) {
        const next = encodeURIComponent(window.location.pathname + window.location.search);
        window.location.replace("/login?next=" + next);
        return false;
      }
      if (role) {
        const sessionRole = (SessionManager.getRole() || "").toLowerCase();
        if (sessionRole !== role.toLowerCase()) {
          window.location.replace(sessionRole === "influencer" ? "/influencer-home" : "/client-home");
          return false;
        }
      }
      document.documentElement.classList.add("mp-authed");
      return true;
    },
  };

  global.RouteGuard = RouteGuard;
})(window);
