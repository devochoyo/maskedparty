// FILE LOCATION: widgets/phosphor_icons.js
// Loads the Phosphor Icons web font (regular + fill + bold weights) from
// jsDelivr, the same way widgets/incoming_call_screen.js etc. rely on
// VideoSDK's CDN — a small, versioned, well-known dependency rather than
// hand-copying dozens of raw SVG paths (one typo there silently breaks an
// icon). Only icons actually used on the page render; unused glyphs cost
// nothing extra.
//
// Usage once loaded: <i class="ph ph-house"></i> (regular),
// <i class="ph-fill ph-house"></i> (fill, used for the active nav tab),
// <i class="ph-bold ph-plus"></i> (bold, used for the influencer Create FAB).
//
// NOTE: requires style-src/font-src https://cdn.jsdelivr.net in your CSP —
// already added to .htaccess and deploy/nginx.conf.example.
(function (global) {
  "use strict";

  const VERSION = "2.1.2";
  const WEIGHTS = ["regular", "fill", "bold"];
  let loaded = false;

  function load() {
    if (loaded) return;
    loaded = true;
    WEIGHTS.forEach(function (weight) {
      const link = document.createElement("link");
      link.rel = "stylesheet";
      link.type = "text/css";
      link.href = "https://cdn.jsdelivr.net/npm/@phosphor-icons/web@" + VERSION + "/src/" + weight + "/style.css";
      document.head.appendChild(link);
    });
  }

  global.PhosphorIcons = { load: load };
})(window);
