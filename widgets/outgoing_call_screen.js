// FILE LOCATION: widgets/outgoing_call_screen.js
// Mirrors lib/widgets/outgoing_call_screen.dart. Full-screen outgoing-call
// UI with looping ringtone and a single Cancel action.
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-ocs{position:fixed;inset:0;background:#fff;z-index:9000;display:flex;flex-direction:column;align-items:center;justify-content:flex-start;padding:48px 24px 32px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;text-align:center;}
      .mp-ocs__spacer{flex:1;}
      .mp-ocs__rings{position:relative;width:220px;height:220px;display:flex;align-items:center;justify-content:center;margin-top:24px;}
      .mp-ocs__ring{position:absolute;border-radius:50%;border:2px solid rgba(233,30,99,.2);}
      .mp-ocs__ring.r1{width:200px;height:200px;}
      .mp-ocs__ring.r2{width:220px;height:220px;border-color:rgba(233,30,99,.08);}
      .mp-ocs__avatar{width:140px;height:140px;border-radius:50%;object-fit:cover;background:linear-gradient(135deg,#E91E63,#FF6B8B);display:flex;align-items:center;justify-content:center;color:#fff;font-size:48px;font-weight:700;}
      .mp-ocs__name{margin-top:40px;font-size:26px;font-weight:600;color:#1A1D2E;letter-spacing:.3px;}
      .mp-ocs__status{margin-top:10px;display:flex;align-items:center;justify-content:center;gap:10px;}
      .mp-ocs__dot{width:8px;height:8px;border-radius:50%;background:#E91E63;box-shadow:0 0 8px rgba(233,30,99,.35);}
      .mp-ocs__status span{font-size:14px;color:#757575;}
      .mp-ocs__badge{margin-top:60px;padding:6px 16px;border-radius:20px;background:#FFF5F8;border:1px solid rgba(233,30,99,.15);display:inline-flex;align-items:center;gap:8px;font-size:12px;color:#E91E63;font-weight:500;}
      .mp-ocs__cancel-btn{margin-top:auto;width:64px;height:64px;border-radius:50%;border:none;cursor:pointer;background:#f44336;color:#fff;font-size:26px;box-shadow:0 0 0 4px rgba(244,67,54,.15),0 10px 20px rgba(244,67,54,.25);}
      .mp-ocs__cancel-text{margin-top:16px;background:none;border:none;font-size:13px;color:#9e9e9e;font-weight:500;cursor:pointer;}
    `;
    document.head.appendChild(style);
  }

  const OutgoingCallScreen = {
    // opts: { influencerName, influencerPhoto, statusMessage, onCancel }
    // returns controller: { update(partial), close() }
    show(opts) {
      injectStyles();
      const state = Object.assign({ influencerName: "", influencerPhoto: null, statusMessage: "Calling..." }, opts);

      const audio = document.createElement("audio");
      audio.src = "/assets/outgoing.mp3";
      audio.loop = true;
      audio.play().catch(function () {});

      const el = document.createElement("div");
      el.className = "mp-ocs";
      document.body.appendChild(el);

      function initials(name) {
        return (name || "?").trim().charAt(0).toUpperCase();
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
      function handleCancel() {
        stopRingtone();
        if (state.onCancel) state.onCancel();
      }

      function render() {
        el.innerHTML =
          '<div class="mp-ocs__spacer"></div>' +
          '<div class="mp-ocs__rings">' +
          '<div class="mp-ocs__ring r2"></div>' +
          '<div class="mp-ocs__ring r1"></div>' +
          (state.influencerPhoto
            ? '<img class="mp-ocs__avatar" src="' + state.influencerPhoto + '" alt="">'
            : '<div class="mp-ocs__avatar">' + initials(state.influencerName) + "</div>") +
          "</div>" +
          '<div class="mp-ocs__name">' + escapeHtml(state.influencerName) + "</div>" +
          '<div class="mp-ocs__status"><span class="mp-ocs__dot"></span><span>' + escapeHtml(state.statusMessage) + "</span></div>" +
          '<div class="mp-ocs__badge"><i class="ph ph-video-camera"></i> Video Call</div>' +
          '<button class="mp-ocs__cancel-btn" id="ocsCancelBtn" aria-label="Cancel call"><i class="ph ph-phone"></i></button>' +
          '<button class="mp-ocs__cancel-text" id="ocsCancelText">Cancel</button>';

        el.querySelector("#ocsCancelBtn").addEventListener("click", handleCancel);
        el.querySelector("#ocsCancelText").addEventListener("click", handleCancel);
      }

      render();

      return {
        update(partial) {
          Object.assign(state, partial);
          render();
        },
        close() {
          stopRingtone();
          el.remove();
        },
      };
    },
  };

  global.OutgoingCallScreen = OutgoingCallScreen;
})(window);
