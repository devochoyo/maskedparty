// FILE LOCATION: widgets/client_release.js
// Mirrors lib/widgets/client_release.dart. Shown to the CLIENT after a call
// ends: a 30-minute escrow countdown with a "Release Now" button, or the
// credited celebration state once released (auto or manual).
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-crel{margin:12px 20px;background:#fff;border-radius:16px;box-shadow:0 8px 20px rgba(233,30,99,.15);overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
        transform:translateY(0);transition:transform .4s ease, opacity .4s ease;}
      .mp-crel.mp-enter{transform:translateY(20px);opacity:0;}
      .mp-crel__head{background:#E91E63;padding:16px 20px 16px 20px;display:flex;align-items:center;gap:12px;}
      .mp-crel__head-icon{width:36px;height:36px;border-radius:50%;background:rgba(255,255,255,.2);display:flex;align-items:center;justify-content:center;font-size:18px;flex:none;}
      .mp-crel__head-title{color:#fff;font-size:16px;font-weight:700;flex:1;}
      .mp-crel__close{width:28px;height:28px;border-radius:8px;background:rgba(255,255,255,.2);border:none;color:#fff;font-size:14px;cursor:pointer;flex:none;}
      .mp-crel__body{padding:24px;text-align:center;}
      .mp-crel__msg{font-size:15px;color:#1A1D2E;font-weight:500;}
      .mp-crel__countdown{margin-top:16px;padding:16px 24px;background:#FFF5F8;border:1px solid rgba(233,30,99,.2);border-radius:16px;}
      .mp-crel__time{font-size:36px;font-weight:700;color:#E91E63;letter-spacing:2px;font-variant-numeric:tabular-nums;}
      .mp-crel__mins{margin-top:4px;font-size:11px;color:#9e9e9e;}
      .mp-crel__note{margin-top:12px;font-size:12px;color:#9e9e9e;line-height:1.4;}
      .mp-crel__btn{margin-top:24px;width:100%;height:56px;border:none;border-radius:16px;background:#00C853;color:#fff;font-size:16px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;}
      .mp-crel__btn:disabled{opacity:.5;cursor:not-allowed;}
      .mp-crel__spin{width:20px;height:20px;border:2.5px solid rgba(255,255,255,.5);border-top-color:#fff;border-radius:50%;animation:mp-crel-spin .8s linear infinite;}
      @keyframes mp-crel-spin{to{transform:rotate(360deg)}}
      .mp-crel__check{width:80px;height:80px;margin:0 auto;border-radius:50%;background:#E91E63;display:flex;align-items:center;justify-content:center;font-size:40px;color:#fff;box-shadow:0 10px 20px rgba(233,30,99,.25);animation:mp-crel-pop .5s cubic-bezier(.34,1.56,.64,1);}
      @keyframes mp-crel-pop{from{transform:scale(0)}to{transform:scale(1)}}
      .mp-crel__released-title{margin-top:20px;font-size:22px;font-weight:700;color:#1A1D2E;}
      .mp-crel__released-sub{margin-top:8px;font-size:14px;color:#757575;line-height:1.4;}
      .mp-crel__timer-pill{margin-top:12px;display:inline-flex;align-items:center;gap:6px;padding:8px 16px;background:#FFF5F8;border-radius:12px;font-size:12px;color:#E91E63;font-weight:500;}
      .mp-crel__toast{position:fixed;left:16px;right:16px;bottom:24px;background:#D32F2F;color:#fff;padding:14px 16px;border-radius:12px;font-size:14px;text-align:center;max-width:420px;margin:0 auto;z-index:9600;}
    `;
    document.head.appendChild(style);
  }

  const ClientReleaseWidget = {
    // opts: { callId, influencerName, initialRemainingSeconds, onClose }
    // Always uses a 1800s (30 min) escrow window, matching the Dart source.
    // Returns controller: { destroy() }
    mount(container, opts) {
      injectStyles();
      const state = Object.assign({ influencerName: "" }, opts);
      let remaining = 1800;
      let isReleasing = false;
      let released = false;
      let timer = null;

      const wrap = document.createElement("div");
      wrap.className = "mp-crel mp-enter";
      (container || document.body).appendChild(wrap);
      requestAnimationFrame(function () { wrap.classList.remove("mp-enter"); });

      function fmt(sec) {
        if (sec <= 0) return "00:00";
        const m = String(Math.floor(sec / 60)).padStart(2, "0");
        const s = String(sec % 60).padStart(2, "0");
        return m + ":" + s;
      }

      async function getToken() {
        return SessionManager.getToken();
      }

      function showError(message) {
        const toast = document.createElement("div");
        toast.className = "mp-crel__toast";
        toast.textContent = message;
        document.body.appendChild(toast);
        setTimeout(function () { toast.remove(); }, 3500);
      }

      async function releaseNow() {
        if (isReleasing || released) return;
        isReleasing = true;
        render();
        const token = await getToken();
        if (!token) { isReleasing = false; render(); return; }
        try {
          const result = await CallService.releaseCoins(token, state.callId);
          if (result && result.success === true) {
            clearInterval(timer);
            released = true;
            isReleasing = false;
            showReleasedAnimation();
          } else {
            isReleasing = false;
            render();
            showError((result && result.message) || "Failed to release coins");
          }
        } catch (e) {
          isReleasing = false;
          render();
          showError("Something went wrong. Please try again.");
        }
      }

      async function autoRelease() {
        if (released) return;
        const token = await getToken();
        if (!token) return;
        try {
          const result = await CallService.releaseCoins(token, state.callId);
          if (result && result.success === true) {
            released = true;
            showReleasedAnimation();
          } else {
            setTimeout(function () { if (!released) autoRelease(); }, 3000);
          }
        } catch (e) {
          setTimeout(function () { if (!released) autoRelease(); }, 3000);
        }
      }

      function close() {
        clearInterval(timer);
        wrap.classList.add("mp-enter");
        setTimeout(function () {
          wrap.remove();
          if (state.onClose) state.onClose();
        }, 300);
      }

      function showReleasedAnimation() {
        wrap.innerHTML =
          '<div class="mp-crel__head"><div class="mp-crel__head-icon"><i class="ph ph-check"></i></div><div class="mp-crel__head-title">Call Ended</div></div>' +
          '<div class="mp-crel__body">' +
          '<div class="mp-crel__check"><i class="ph ph-check"></i></div>' +
          '<div class="mp-crel__released-title">Payment Released! <i class="ph-fill ph-confetti"></i></div>' +
          '<div class="mp-crel__released-sub">' + escapeHtml(state.influencerName) + " has been credited.</div>" +
          '<div class="mp-crel__timer-pill"><i class="ph ph-timer"></i> Auto-closing in 5 seconds...</div>' +
          "</div>";
        setTimeout(close, 5000);
      }

      function escapeHtml(s) {
        return String(s).replace(/[&<>"']/g, function (c) {
          return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
        });
      }

      function render() {
        if (released) return;
        const totalMinutes = Math.ceil(remaining / 60);
        wrap.innerHTML =
          '<div class="mp-crel__head">' +
          '<div class="mp-crel__head-icon"><i class="ph ph-coins"></i></div>' +
          '<div class="mp-crel__head-title">Call Ended</div>' +
          '<button class="mp-crel__close" id="crelCloseBtn" aria-label="Close"><i class="ph ph-x"></i></button>' +
          "</div>" +
          '<div class="mp-crel__body">' +
          '<div class="mp-crel__msg">Payment will be released to ' + escapeHtml(state.influencerName) + " in</div>" +
          '<div class="mp-crel__countdown"><div class="mp-crel__time">' + fmt(remaining) + '</div><div class="mp-crel__mins">~' + totalMinutes + " minutes remaining</div></div>" +
          '<div class="mp-crel__note">Coins are held in escrow and auto-release when the timer ends.</div>' +
          '<button class="mp-crel__btn" id="crelReleaseBtn" ' + (isReleasing ? "disabled" : "") + ">" +
          (isReleasing ? '<span class="mp-crel__spin"></span><span>Releasing...</span>' : "<span><i class='ph ph-rocket-launch'></i></span><span>Release Now</span>") +
          "</button>" +
          "</div>";

        const closeBtn = wrap.querySelector("#crelCloseBtn");
        if (closeBtn) closeBtn.addEventListener("click", close);
        wrap.querySelector("#crelReleaseBtn").addEventListener("click", releaseNow);
      }

      render();
      timer = setInterval(function () {
        if (released) return;
        remaining--;
        if (remaining <= 0) {
          clearInterval(timer);
          autoRelease();
          return;
        }
        render();
      }, 1000);

      return {
        destroy() {
          clearInterval(timer);
          wrap.remove();
        },
      };
    },
  };

  global.ClientReleaseWidget = ClientReleaseWidget;
})(window);
