// FILE LOCATION: widgets/influencer_bottom_nav.js
// Shared bottom tab bar for all influencer pages (home, chat, create-post
// FAB, followers, profile). Edit this ONE file to restyle, re-link, or
// re-icon the nav across every influencer page — no need to touch
// home.html / chat.html / followers.html / profile.html individually.
//
// Icons are Phosphor Icons (see widgets/phosphor_icons.js) — outline for
// the inactive tabs, filled for whichever tab is active, bold for the
// center Create button's plus sign.
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-ibn{position:fixed;left:0;right:0;bottom:0;background:linear-gradient(to bottom,#fff,rgba(255,228,236,.3));border-top:1px solid rgba(233,30,99,.1);box-shadow:0 -4px 20px rgba(233,30,99,.08);border-radius:24px 24px 0 0;padding:8px 8px calc(8px + env(safe-area-inset-bottom));z-index:50;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;}
      .mp-ibn__row{max-width:600px;margin:0 auto;display:flex;justify-content:space-around;align-items:flex-end;}
      .mp-ibn__item{display:flex;flex-direction:column;align-items:center;gap:3px;padding:6px 10px;border-radius:14px;text-decoration:none;color:#9CA3AF;font-size:9px;font-weight:600;flex:1;}
      .mp-ibn__item .mp-ibn__ic{font-size:21px;line-height:1;}
      .mp-ibn__item.mp-ibn__active{color:#E91E63;font-weight:700;}
      .mp-ibn__create{display:flex;flex-direction:column;align-items:center;gap:3px;flex:none;text-decoration:none;}
      .mp-ibn__create-btn{width:52px;height:52px;border-radius:50%;background:linear-gradient(135deg,#E91E63,#C2185B);border:2px solid #fff;box-shadow:0 6px 16px rgba(233,30,99,.4);display:flex;align-items:center;justify-content:center;color:#fff;font-size:24px;}
      .mp-ibn__create span:last-child{font-size:9px;font-weight:700;color:#E91E63;}
    `;
    document.head.appendChild(style);
  }

  // `icon` is a Phosphor icon name (without the "ph-" prefix) — swap it
  // here to change what a tab looks like.
  const LEFT_TABS = [
    { key: "home", href: "/influencer-home", icon: "house", label: "Home" },
    { key: "chat", href: "/influencer-chat", icon: "chat-circle", label: "Chat" },
  ];
  const RIGHT_TABS = [
    { key: "followers", href: "/followers", icon: "users", label: "Followers" },
    { key: "profile", href: "/influencer-profile", icon: "user-circle", label: "Profile" },
  ];

  function tabHtml(tab, activeTab) {
    const active = tab.key === activeTab;
    const weightClass = active ? "ph-fill" : "ph";
    return (
      '<a href="' + tab.href + '" class="mp-ibn__item' + (active ? " mp-ibn__active" : "") + '">' +
      '<i class="mp-ibn__ic ' + weightClass + " ph-" + tab.icon + '"></i><span>' + tab.label + "</span></a>"
    );
  }

  const InfluencerBottomNav = {
    // activeTab: "home" | "chat" | "followers" | "profile" (omit/pass null
    // when on a page with no matching tab, e.g. create-post itself).
    mount(activeTab) {
      injectStyles();
      if (global.PhosphorIcons) global.PhosphorIcons.load();

      const nav = document.createElement("nav");
      nav.className = "mp-ibn";
      nav.innerHTML =
        '<div class="mp-ibn__row">' +
        LEFT_TABS.map(function (t) { return tabHtml(t, activeTab); }).join("") +
        '<a href="/create-post" class="mp-ibn__create"><span class="mp-ibn__create-btn"><i class="ph-bold ph-plus"></i></span><span>Create</span></a>' +
        RIGHT_TABS.map(function (t) { return tabHtml(t, activeTab); }).join("") +
        "</div>";
      document.body.appendChild(nav);
      return nav;
    },
  };

  global.InfluencerBottomNav = InfluencerBottomNav;
})(window);
