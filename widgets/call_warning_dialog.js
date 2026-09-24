// FILE LOCATION: widgets/call_warning_dialog.js
// Mirrors lib/widgets/call_warning_dialog.dart. Shown before a call starts
// (financial/rating notice). Resolves true ("I Agree") or false (dismissed).
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-cwd-backdrop{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:9500;display:flex;align-items:center;justify-content:center;padding:16px;}
      .mp-cwd{width:100%;max-width:480px;max-height:75vh;background:#fff;border-radius:20px;box-shadow:0 10px 30px rgba(0,0,0,.15);display:flex;flex-direction:column;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;}
      .mp-cwd__head{background:linear-gradient(135deg,#E91E63,#FF6B8B);padding:16px;display:flex;align-items:center;gap:12px;}
      .mp-cwd__head-icon{width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.2);display:flex;align-items:center;justify-content:center;font-size:22px;flex:none;}
      .mp-cwd__head-title{color:#fff;font-size:17px;font-weight:700;}
      .mp-cwd__head-sub{color:rgba(255,255,255,.8);font-size:11px;margin-top:2px;}
      .mp-cwd__body{padding:16px;overflow-y:auto;}
      .mp-cwd__item{display:flex;align-items:flex-start;gap:12px;margin-bottom:12px;}
      .mp-cwd__item-icon{width:36px;height:36px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:18px;flex:none;}
      .mp-cwd__item-title{font-size:13px;font-weight:700;color:#1A1D2E;}
      .mp-cwd__item-desc{font-size:11px;color:#757575;line-height:1.4;margin-top:4px;}
      .mp-cwd__actions{display:flex;gap:8px;margin-top:8px;}
      .mp-cwd__btn{flex:1;height:42px;border-radius:10px;font-size:12px;font-weight:700;cursor:pointer;}
      .mp-cwd__btn.dismiss{background:#fff;border:1px solid #e0e0e0;color:#616161;}
      .mp-cwd__btn.agree{background:#00C853;border:none;color:#fff;}
    `;
    document.head.appendChild(style);
  }

  const ITEMS = [
    { icon: "<i class='ph ph-wifi-high'></i>", color: "#2196F3", title: "Stable Internet Connection", desc: "Ensure a stable internet connection before starting the call. Ending the call before the minute elapses leads to loss of coins, so ensure your connection is stable." },
    { icon: "<i class='ph-bold ph-plus'></i>", color: "#9C27B0", title: "Call Extensions", desc: "You can extend the call for more minutes while on video call if you need additional time." },
    { icon: "<i class='ph-fill ph-star'></i>", color: "#FFC107", title: "Rating Impact", desc: "3 bad ratings from influencers will lead to suspension of your account and loss of funds." },
  ];

  const CallWarningDialog = {
    // Returns a Promise<boolean> — true = "I Agree", false = dismissed/backdrop.
    show() {
      injectStyles();
      return new Promise(function (resolve) {
        const backdrop = document.createElement("div");
        backdrop.className = "mp-cwd-backdrop";

        const itemsHtml = ITEMS.map(function (it) {
          return (
            '<div class="mp-cwd__item">' +
            '<div class="mp-cwd__item-icon" style="background:' + it.color + '1A;color:' + it.color + '">' + it.icon + "</div>" +
            '<div><div class="mp-cwd__item-title">' + it.title + '</div><div class="mp-cwd__item-desc">' + it.desc + "</div></div>" +
            "</div>"
          );
        }).join("");

        backdrop.innerHTML =
          '<div class="mp-cwd" role="dialog" aria-modal="true" aria-label="Important Notice">' +
          '<div class="mp-cwd__head">' +
          '<div class="mp-cwd__head-icon"><i class="ph ph-warning"></i></div>' +
          '<div><div class="mp-cwd__head-title">Important Notice</div><div class="mp-cwd__head-sub">Please read carefully before proceeding</div></div>' +
          "</div>" +
          '<div class="mp-cwd__body">' +
          itemsHtml +
          '<div class="mp-cwd__actions">' +
          '<button class="mp-cwd__btn dismiss" id="cwdDismiss">Dismiss</button>' +
          '<button class="mp-cwd__btn agree" id="cwdAgree"><i class="ph ph-check"></i> I Agree</button>' +
          "</div>" +
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
        backdrop.querySelector("#cwdDismiss").addEventListener("click", function () { close(false); });
        backdrop.querySelector("#cwdAgree").addEventListener("click", function () { close(true); });
      });
    },
  };

  global.CallWarningDialog = CallWarningDialog;
})(window);
