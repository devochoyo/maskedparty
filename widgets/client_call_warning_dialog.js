// FILE LOCATION: widgets/client_call_warning_dialog.js
// Mirrors lib/widgets/client_call_warning_dialog.dart. Community-conduct
// agreement shown to a client before a call. Resolves true/false.
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-ccwd-backdrop{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:9500;display:flex;align-items:center;justify-content:center;padding:24px;}
      .mp-ccwd{width:100%;max-width:500px;background:#fff;border-radius:24px;box-shadow:0 10px 30px rgba(0,0,0,.12);padding:24px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;max-height:85vh;overflow-y:auto;text-align:center;}
      .mp-ccwd__icon{width:72px;height:72px;margin:0 auto;border-radius:50%;background:rgba(233,30,99,.1);display:flex;align-items:center;justify-content:center;font-size:34px;}
      .mp-ccwd__title{margin-top:16px;font-size:20px;font-weight:700;color:#1A1D2E;}
      .mp-ccwd__desc{margin-top:8px;font-size:13px;color:#757575;line-height:1.5;}
      .mp-ccwd__rules{margin-top:16px;background:#F8F9FE;border:1px solid rgba(233,30,99,.1);border-radius:16px;padding:16px;text-align:left;}
      .mp-ccwd__rule{display:flex;align-items:flex-start;gap:10px;padding:8px 0;border-bottom:1px solid #eee;}
      .mp-ccwd__rule:last-child{border-bottom:none;}
      .mp-ccwd__rule-icon{width:28px;height:28px;border-radius:50%;background:rgba(233,30,99,.1);display:flex;align-items:center;justify-content:center;font-size:14px;flex:none;}
      .mp-ccwd__rule-text{font-size:13px;color:#1A1D2E;font-weight:500;line-height:1.3;}
      .mp-ccwd__actions{display:flex;gap:12px;margin-top:20px;}
      .mp-ccwd__btn{flex:1;padding:12px 8px;border-radius:16px;font-size:14px;font-weight:700;cursor:pointer;}
      .mp-ccwd__btn.cancel{background:none;border:none;color:#757575;}
      .mp-ccwd__btn.accept{background:#E91E63;border:none;color:#fff;}
    `;
    document.head.appendChild(style);
  }

  const RULES = [
    { icon: "<i class='ph ph-video-camera-slash'></i>", text: "No screenshots or screen recording" },
    { icon: "<i class='ph ph-phone-slash'></i>", text: "No contact sharing or personal information" },
    { icon: "<i class='ph ph-megaphone'></i>", text: "Be respectful and professional" },
  ];

  const ClientCallWarningDialog = {
    // Returns a Promise<boolean> — true = "Accept & Continue", false = cancel/backdrop.
    show() {
      injectStyles();
      return new Promise(function (resolve) {
        const backdrop = document.createElement("div");
        backdrop.className = "mp-ccwd-backdrop";

        const rulesHtml = RULES.map(function (r) {
          return (
            '<div class="mp-ccwd__rule">' +
            '<div class="mp-ccwd__rule-icon">' + r.icon + "</div>" +
            '<div class="mp-ccwd__rule-text">' + r.text + "</div>" +
            "</div>"
          );
        }).join("");

        backdrop.innerHTML =
          '<div class="mp-ccwd" role="dialog" aria-modal="true" aria-label="Privacy Agreement">' +
          '<div class="mp-ccwd__icon"><i class="ph ph-warning"></i></div>' +
          '<div class="mp-ccwd__title">Privacy Agreement</div>' +
          '<div class="mp-ccwd__desc">To ensure a safe and respectful environment for everyone, please agree to the following:</div>' +
          '<div class="mp-ccwd__rules">' + rulesHtml + "</div>" +
          '<div class="mp-ccwd__actions">' +
          '<button class="mp-ccwd__btn cancel" id="ccwdCancel">Cancel</button>' +
          '<button class="mp-ccwd__btn accept" id="ccwdAccept">Accept &amp; Continue</button>' +
          "</div>" +
          "</div>";

        document.body.appendChild(backdrop);

        function close(result) {
          backdrop.remove();
          resolve(result);
        }

        backdrop.addEventListener("click", function (e) {
          if (e.target === backdrop) close(false);
        });
        backdrop.querySelector("#ccwdCancel").addEventListener("click", function () { close(false); });
        backdrop.querySelector("#ccwdAccept").addEventListener("click", function () { close(true); });
      });
    },
  };

  global.ClientCallWarningDialog = ClientCallWarningDialog;
})(window);
