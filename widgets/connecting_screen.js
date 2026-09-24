// FILE LOCATION: widgets/connecting_screen.js
// Mirrors lib/widgets/connecting_screen.dart. A full-screen "Connecting..."
// state used while a call is being set up.
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-conn{position:fixed;inset:0;background:#F8F9FE;display:flex;align-items:center;justify-content:center;z-index:9000;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;}
      .mp-conn__icon{width:100px;height:100px;border-radius:50%;background:rgba(233,30,99,.1);display:flex;align-items:center;justify-content:center;}
      .mp-conn__spinner{width:60px;height:60px;border:3px solid rgba(233,30,99,.25);border-top-color:#E91E63;border-radius:50%;animation:mp-conn-spin .9s linear infinite;}
      @keyframes mp-conn-spin{to{transform:rotate(360deg)}}
      .mp-conn__title{margin-top:32px;font-size:24px;font-weight:700;color:#1A1D2E;text-align:center;}
      .mp-conn__sub{margin-top:8px;font-size:14px;color:#6B7280;text-align:center;}
    `;
    document.head.appendChild(style);
  }

  const ConnectingScreen = {
    // Mounts into `container` (defaults to document.body as an overlay).
    // Returns a controller with unmount().
    mount(container) {
      injectStyles();
      const el = document.createElement("div");
      el.className = "mp-conn";
      el.innerHTML =
        '<div style="display:flex;flex-direction:column;align-items:center;">' +
        '<div class="mp-conn__icon"><div class="mp-conn__spinner" role="status" aria-label="Connecting"></div></div>' +
        '<div class="mp-conn__title">Connecting...</div>' +
        '<div class="mp-conn__sub">Please wait while we connect your call</div>' +
        "</div>";
      (container || document.body).appendChild(el);
      return {
        unmount() {
          el.remove();
        },
      };
    },
  };

  global.ConnectingScreen = ConnectingScreen;
})(window);
