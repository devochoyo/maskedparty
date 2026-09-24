// FILE LOCATION: widgets/influencer_release.js
// Mirrors lib/widgets/influencer_release.dart. Shown to the INFLUENCER after
// a call ends: a passive escrow countdown (only the client or the 30-minute
// timer actually triggers release — this side just watches and reacts).
// The parent screen (video_call.html, Phase 3) is expected to call
// markCredited() when it learns via polling/webhook that release happened.
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-irel{margin:12px 20px;background:#fff;border-radius:16px;box-shadow:0 8px 20px rgba(233,30,99,.15);overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
        transform:translateY(0);transition:transform .4s ease, opacity .4s ease;}
      .mp-irel.mp-enter{transform:translateY(20px);opacity:0;}
      .mp-irel__head{background:#E91E63;padding:16px 20px;display:flex;align-items:center;gap:12px;}
      .mp-irel__head-icon{width:36px;height:36px;border-radius:50%;background:rgba(255,255,255,.2);display:flex;align-items:center;justify-content:center;font-size:16px;flex:none;}
      .mp-irel__head-title{color:#fff;font-size:15px;font-weight:700;flex:1;}
      .mp-irel__close{width:26px;height:26px;border-radius:8px;background:rgba(255,255,255,.2);border:none;color:#fff;font-size:13px;cursor:pointer;flex:none;}
      .mp-irel__body{padding:24px;text-align:center;}
      .mp-irel__msg{font-size:15px;color:#1A1D2E;font-weight:500;}
      .mp-irel__submsg{margin-top:6px;font-size:13px;color:#9e9e9e;}
      .mp-irel__countdown{margin-top:16px;padding:16px 24px;background:#FFF5F8;border:1px solid rgba(233,30,99,.2);border-radius:16px;}
      .mp-irel__time{font-size:36px;font-weight:700;color:#E91E63;letter-spacing:2px;font-variant-numeric:tabular-nums;}
      .mp-irel__mins{margin-top:4px;font-size:11px;color:#9e9e9e;}
      .mp-irel__note{margin-top:12px;font-size:12px;color:#9e9e9e;line-height:1.4;}
      .mp-irel__warning{margin-top:24px;display:flex;align-items:flex-start;gap:12px;text-align:left;background:#FFF5F8;border:1px solid rgba(229,57,53,.3);border-radius:16px;padding:16px;}
      .mp-irel__warning span{font-size:12px;color:#E53935;line-height:1.5;font-weight:500;}
      .mp-irel__btn{margin-top:24px;width:100%;height:52px;border:none;border-radius:16px;background:#E91E63;color:#fff;font-size:15px;font-weight:700;cursor:pointer;}
      .mp-irel__check{width:80px;height:80px;margin:0 auto;border-radius:50%;background:#E91E63;display:flex;align-items:center;justify-content:center;font-size:36px;color:#FFD54F;box-shadow:0 10px 20px rgba(233,30,99,.25);animation:mp-irel-pop .5s cubic-bezier(.34,1.56,.64,1);}
      @keyframes mp-irel-pop{from{transform:scale(0)}to{transform:scale(1)}}
      .mp-irel__released-title{margin-top:20px;font-size:22px;font-weight:700;color:#1A1D2E;}
      .mp-irel__released-sub{margin-top:8px;font-size:14px;color:#1A1D2E;line-height:1.4;}
      .mp-irel__timer-pill{margin-top:12px;display:inline-flex;align-items:center;gap:6px;padding:8px 16px;background:#FFF5F8;border-radius:12px;font-size:12px;color:#E91E63;font-weight:500;}
      .mp-irel__btn2{margin-top:24px;width:100%;height:56px;border:none;border-radius:16px;background:#E91E63;color:#fff;font-size:16px;font-weight:700;cursor:pointer;}
    `;
    document.head.appendChild(style);
  }

  const InfluencerReleaseWidget = {
    // opts: { clientName, initialRemainingSeconds, onClose }
    // Returns controller: { markCredited(), destroy() }
    mount(container, opts) {
      injectStyles();
      const state = Object.assign({ clientName: "" }, opts);
      let remaining = typeof state.initialRemainingSeconds === "number" ? state.initialRemainingSeconds : 1800;
      let credited = false;
      let timer = null;

      const wrap = document.createElement("div");
      wrap.className = "mp-irel mp-enter";
      (container || document.body).appendChild(wrap);
      requestAnimationFrame(function () { wrap.classList.remove("mp-enter"); });

      function fmt(sec) {
        if (sec <= 0) return "00:00";
        const m = String(Math.floor(sec / 60)).padStart(2, "0");
        const s = String(sec % 60).padStart(2, "0");
        return m + ":" + s;
      }
      function escapeHtml(s) {
        return String(s).replace(/[&<>"']/g, function (c) {
          return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
        });
      }

      function close() {
        clearInterval(timer);
        wrap.classList.add("mp-enter");
        setTimeout(function () {
          wrap.remove();
          if (state.onClose) state.onClose();
        }, 300);
      }

      function renderCredited() {
        clearInterval(timer);
        wrap.innerHTML =
          '<div class="mp-irel__head"><div class="mp-irel__head-icon"><i class="ph ph-check"></i></div><div class="mp-irel__head-title">Payment Released! <i class="ph-fill ph-confetti"></i></div></div>' +
          '<div class="mp-irel__body">' +
          '<div class="mp-irel__check"><i class="ph ph-coins"></i></div>' +
          '<div class="mp-irel__released-title">Payment Credited! <i class="ph-fill ph-confetti"></i></div>' +
          '<div class="mp-irel__released-sub">The payment has been added to your balance.</div>' +
          '<div class="mp-irel__timer-pill"><i class="ph ph-timer"></i> Auto-closing in 5 seconds...</div>' +
          '<button class="mp-irel__btn2" id="irelRateBtn">Rate your experience</button>' +
          "</div>";
        wrap.querySelector("#irelRateBtn").addEventListener("click", function () {
          clearInterval(timer);
          window.location.href = "/rate-client?client_name=" + encodeURIComponent(state.clientName || "");
        });
        setTimeout(close, 5000);
      }

      function render() {
        if (credited) return;
        const totalMinutes = Math.ceil(remaining / 60);
        wrap.innerHTML =
          '<div class="mp-irel__head">' +
          '<div class="mp-irel__head-icon"><i class="ph ph-hourglass"></i></div>' +
          '<div class="mp-irel__head-title">Pending Release</div>' +
          '<button class="mp-irel__close" id="irelCloseBtn" aria-label="Close"><i class="ph ph-x"></i></button>' +
          "</div>" +
          '<div class="mp-irel__body">' +
          '<div class="mp-irel__msg">Payment will be released if ' + escapeHtml(state.clientName) + " does not release early</div>" +
          '<div class="mp-irel__submsg">Auto-releases in</div>' +
          '<div class="mp-irel__countdown"><div class="mp-irel__time">' + fmt(remaining) + '</div><div class="mp-irel__mins">~' + totalMinutes + " minutes remaining</div></div>" +
          '<div class="mp-irel__note">Coins are held in escrow until the client releases or the timer ends.</div>' +
          '<div class="mp-irel__warning"><i class="ph ph-info"></i>️<span>3 bad reviews from clients will lead to suspension of your account and loss of all earnings.</span></div>' +
          '<button class="mp-irel__btn" id="irelCloseBtn2">Close &amp; Rate Client</button>' +
          "</div>";

        wrap.querySelector("#irelCloseBtn").addEventListener("click", close);
        wrap.querySelector("#irelCloseBtn2").addEventListener("click", function () {
          clearInterval(timer);
          window.location.href = "/rate-client?client_name=" + encodeURIComponent(state.clientName || "");
        });
      }

      render();
      timer = setInterval(function () {
        if (credited) return;
        remaining--;
        if (remaining <= 0) {
          clearInterval(timer);
          remaining = 0;
          render();
          return;
        }
        render();
      }, 1000);

      return {
        // Call this when the parent screen learns (via polling) that the
        // client — or the timer, server-side — actually released the escrow.
        markCredited() {
          credited = true;
          renderCredited();
        },
        destroy() {
          clearInterval(timer);
          wrap.remove();
        },
      };
    },
  };

  global.InfluencerReleaseWidget = InfluencerReleaseWidget;
})(window);
