// FILE LOCATION: widgets/incoming_call_screen.js
// Mirrors lib/widgets/incoming_call_screen.dart. Full-screen incoming-call
// UI with looping ringtone, accept/reject, and a terminal (non-actionable)
// state for auto-timeout / already-ended calls.
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-ics{position:fixed;inset:0;background:#fff;z-index:9000;display:flex;flex-direction:column;align-items:center;justify-content:flex-start;padding:48px 24px 32px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;text-align:center;}
      .mp-ics__spacer{flex:1;}
      .mp-ics__rings{position:relative;width:220px;height:220px;display:flex;align-items:center;justify-content:center;margin-top:24px;}
      .mp-ics__ring{position:absolute;border-radius:50%;border:2px solid rgba(233,30,99,.2);}
      .mp-ics__ring.r1{width:200px;height:200px;}
      .mp-ics__ring.r2{position:absolute;width:220px;height:220px;border-color:rgba(233,30,99,.08);}
      .mp-ics__avatar{width:140px;height:140px;border-radius:50%;object-fit:cover;background:linear-gradient(135deg,#E91E63,#FF6B8B);display:flex;align-items:center;justify-content:center;color:#fff;font-size:48px;font-weight:700;}
      .mp-ics__name{margin-top:40px;font-size:26px;font-weight:600;color:#1A1D2E;letter-spacing:.3px;}
      .mp-ics__status{margin-top:10px;display:flex;align-items:center;justify-content:center;gap:10px;}
      .mp-ics__dot{width:8px;height:8px;border-radius:50%;background:#E91E63;box-shadow:0 0 8px rgba(233,30,99,.35);}
      .mp-ics__dot.terminal{background:#bdbdbd;box-shadow:none;}
      .mp-ics__status span{font-size:14px;color:#757575;}
      .mp-ics__badge{margin-top:60px;padding:6px 16px;border-radius:20px;background:#FFF5F8;border:1px solid rgba(233,30,99,.15);display:inline-flex;align-items:center;gap:8px;font-size:12px;color:#E91E63;font-weight:500;}
      .mp-ics__actions{display:flex;align-items:center;justify-content:center;gap:60px;margin-top:auto;transition:opacity .25s ease;}
      .mp-ics__btn{width:64px;height:64px;border-radius:50%;border:none;cursor:pointer;display:flex;align-items:center;justify-content:center;color:#fff;font-size:26px;}
      .mp-ics__btn.reject{background:#f44336;box-shadow:0 0 0 4px rgba(244,67,54,.15),0 10px 20px rgba(244,67,54,.25);}
      .mp-ics__btn.accept{background:#00C853;box-shadow:0 0 0 4px rgba(0,200,83,.15),0 10px 20px rgba(0,200,83,.25);}
      .mp-ics__btn:disabled{opacity:.5;cursor:not-allowed;}
      .mp-ics__spin{width:22px;height:22px;border:2.5px solid rgba(255,255,255,.5);border-top-color:#fff;border-radius:50%;animation:mp-ics-spin .8s linear infinite;}
      @keyframes mp-ics-spin{to{transform:rotate(360deg)}}
      .mp-ics__cancel{margin-top:16px;background:none;border:none;font-size:13px;color:#9e9e9e;font-weight:500;cursor:pointer;}
    `;
    document.head.appendChild(style);
  }

  const IncomingCallScreen = {
    // opts: { callerName, callerPhoto, isResponding, statusOverride, onAccept, onReject }
    // returns controller: { update(partial), close() }
    show(opts) {
      injectStyles();
      const state = Object.assign(
        { callerName: "Unknown", callerPhoto: null, isResponding: false, statusOverride: null },
        opts
      );

      const audio = document.createElement("audio");
      audio.src = "/assets/incoming.mp3";
      audio.loop = true;
      audio.play().catch(function () {
        /* autoplay may be blocked until a user gesture; silently ignore */
      });

      const el = document.createElement("div");
      el.className = "mp-ics";
      document.body.appendChild(el);

      function initials(name) {
        return (name || "?").trim().charAt(0).toUpperCase();
      }

      function render() {
        const isTerminal = !!state.statusOverride;
        const controlsDisabled = isTerminal || state.isResponding;
        el.innerHTML =
          '<div class="mp-ics__spacer"></div>' +
          '<div class="mp-ics__rings">' +
          '<div class="mp-ics__ring r2"></div>' +
          '<div class="mp-ics__ring r1"></div>' +
          (state.callerPhoto
            ? '<img class="mp-ics__avatar" src="' + state.callerPhoto + '" alt="">'
            : '<div class="mp-ics__avatar">' + initials(state.callerName) + "</div>") +
          "</div>" +
          '<div class="mp-ics__name">' + escapeHtml(state.callerName) + "</div>" +
          '<div class="mp-ics__status"><span class="mp-ics__dot' + (isTerminal ? " terminal" : "") + '"></span><span>' +
          escapeHtml(state.statusOverride || "Incoming Call...") +
          "</span></div>" +
          '<div class="mp-ics__badge"><i class="ph ph-video-camera"></i> Video Call</div>' +
          '<div class="mp-ics__actions" style="opacity:' + (isTerminal ? "0.4" : "1") + '">' +
          '<button class="mp-ics__btn reject" id="icsRejectBtn" aria-label="Decline call" ' + (controlsDisabled ? "disabled" : "") + "><i class='ph ph-phone'></i></button>" +
          '<button class="mp-ics__btn accept" id="icsAcceptBtn" aria-label="Accept call" ' + (controlsDisabled ? "disabled" : "") + ">" +
          (state.isResponding ? '<span class="mp-ics__spin"></span>' : "<i class='ph ph-video-camera'></i>") +
          "</button>" +
          "</div>" +
          '<button class="mp-ics__cancel" id="icsCancelText" ' + (controlsDisabled ? "disabled" : "") + ">Cancel</button>";

        el.querySelector("#icsAcceptBtn").addEventListener("click", handleAccept);
        el.querySelector("#icsRejectBtn").addEventListener("click", handleReject);
        el.querySelector("#icsCancelText").addEventListener("click", handleReject);
      }

      function escapeHtml(s) {
        return String(s).replace(/[&<>"']/g, function (c) {
          return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
        });
      }

      function stopRingtone() {
        try {
          audio.pause();
          audio.currentTime = 0;
        } catch (e) {}
      }

      function handleAccept() {
        stopRingtone();
        if (state.onAccept) state.onAccept();
      }
      function handleReject() {
        stopRingtone();
        if (state.onReject) state.onReject();
      }

      render();

      return {
        update(partial) {
          Object.assign(state, partial);
          if (state.statusOverride) stopRingtone();
          render();
        },
        close() {
          stopRingtone();
          el.remove();
        },
      };
    },
  };

  global.IncomingCallScreen = IncomingCallScreen;
})(window);
