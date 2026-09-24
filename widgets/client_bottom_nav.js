// FILE LOCATION: widgets/client_bottom_nav.js
// Shared bottom tab bar for all client pages (home, discover, chat, profile).
// Edit this ONE file to restyle, re-link, or re-icon the nav across every
// client page — no need to touch home.html / discover.html / chat.html /
// profile.html individually.
//
// Icons are Phosphor Icons (see widgets/phosphor_icons.js) — outline for
// the inactive tabs, filled for whichever tab is active.
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-cbn{position:fixed;left:0;right:0;bottom:0;background:linear-gradient(to bottom,#fff,rgba(255,228,236,.3));border-top:1px solid rgba(233,30,99,.1);box-shadow:0 -4px 20px rgba(233,30,99,.08);border-radius:24px 24px 0 0;padding:8px 8px calc(8px + env(safe-area-inset-bottom));z-index:50;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;}
      .mp-cbn__row{max-width:600px;margin:0 auto;display:flex;justify-content:space-around;}
      .mp-cbn__item{display:flex;flex-direction:column;align-items:center;gap:3px;padding:6px 14px;border-radius:14px;text-decoration:none;color:#9CA3AF;font-size:10px;font-weight:600;}
      .mp-cbn__item .mp-cbn__ic{font-size:23px;line-height:1;}
      .mp-cbn__item.mp-cbn__active{background:linear-gradient(135deg,rgba(233,30,99,.12),rgba(255,107,139,.06));border:1.5px solid rgba(233,30,99,.2);color:#E91E63;font-weight:700;}
      .mp-cbn__item.mp-cbn__active .mp-cbn__dot{margin-top:2px;width:16px;height:3px;border-radius:2px;background:linear-gradient(90deg,#E91E63,#FF6B8B);}
    `;
    document.head.appendChild(style);
  }

  // `icon` is a Phosphor icon name (without the "ph-" prefix) — swap it
  // here to change what a tab looks like, e.g. "house" -> "house-line".
  const TABS = [
    { key: "home", href: "/client-home", icon: "house", label: "Home" },
    { key: "discover", href: "/discover", icon: "compass", label: "Discover" },
    { key: "chat", href: "/client-chat", icon: "chat-circle", label: "Chat" },
    { key: "profile", href: "/client-profile", icon: "user-circle", label: "Profile" },
  ];

  const ClientBottomNav = {
    // activeTab: "home" | "discover" | "chat" | "profile"
    // Appends itself directly to document.body (it's position:fixed, so it
    // doesn't need a specific container).
    mount(activeTab) {
      injectStyles();
      if (global.PhosphorIcons) global.PhosphorIcons.load();

      const nav = document.createElement("nav");
      nav.className = "mp-cbn";
      nav.innerHTML =
        '<div class="mp-cbn__row">' +
        TABS.map(function (tab) {
          const active = tab.key === activeTab;
          const weightClass = active ? "ph-fill" : "ph";
          return (
            '<a href="' + tab.href + '" class="mp-cbn__item' + (active ? " mp-cbn__active" : "") + '">' +
            '<i class="mp-cbn__ic ' + weightClass + " ph-" + tab.icon + '"></i><span>' + tab.label + "</span>" +
            (active ? '<span class="mp-cbn__dot"></span>' : "") +
            "</a>"
          );
        }).join("") +
        "</div>";
      document.body.appendChild(nav);
      return nav;
    },
  };

  global.ClientBottomNav = ClientBottomNav;
})(window);
