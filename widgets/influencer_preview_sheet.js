// FILE LOCATION: widgets/influencer_preview_sheet.js
// Mirrors lib/widgets/influencer_preview_sheet.dart. A draggable bottom
// sheet with a quick profile preview, follow/unfollow, "Call Now" (which
// navigates to the full influencer-details page, matching the Dart
// source), and a gallery strip with a fullscreen image viewer.
// Depends on: session_manager.js, api.js, api_endpoints.js,
// client_service.js, follow_service.js.
(function (global) {
  "use strict";

  let stylesInjected = false;
  function injectStyles() {
    if (stylesInjected) return;
    stylesInjected = true;
    const style = document.createElement("style");
    style.textContent = `
      .mp-ips-backdrop{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:9200;display:flex;align-items:flex-end;justify-content:center;}
      .mp-ips{width:100%;max-width:520px;max-height:92vh;background:#fff;border-radius:28px 28px 0 0;overflow-y:auto;padding:12px 20px 32px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
        transform:translateY(100%);transition:transform .3s cubic-bezier(.32,.72,0,1);}
      .mp-ips.mp-open{transform:translateY(0);}
      .mp-ips__handle{width:40px;height:4px;background:#FFE4EC;border-radius:2px;margin:0 auto 24px;}
      .mp-ips__avatar-wrap{display:flex;justify-content:center;}
      .mp-ips__avatar{width:106px;height:106px;border-radius:50%;padding:3px;background:linear-gradient(135deg,#E91E63,#FF6B8B);}
      .mp-ips__avatar img,.mp-ips__avatar .fallback{width:100%;height:100%;border-radius:50%;object-fit:cover;background:#fff;display:flex;align-items:center;justify-content:center;font-size:40px;color:#E91E63;}
      .mp-ips__name{margin-top:16px;text-align:center;font-size:24px;font-weight:700;color:#1A1D2E;}
      .mp-ips__loc{margin-top:6px;text-align:center;font-size:14px;color:#6B7280;}
      .mp-ips__followers{margin-top:6px;text-align:center;font-size:13px;color:#9CA3AF;font-weight:500;}
      .mp-ips__bio{margin-top:16px;text-align:center;font-size:14px;color:#6B7280;line-height:1.5;}
      .mp-ips__offer-title{margin-top:20px;font-size:15px;font-weight:700;color:#1A1D2E;}
      .mp-ips__offer-box{margin-top:8px;padding:14px;background:#F8F9FE;border:1px solid rgba(255,228,236,.8);border-radius:14px;font-size:14px;color:#6B7280;line-height:1.5;}
      .mp-ips__row{display:flex;gap:8px;margin-top:24px;align-items:stretch;}
      .mp-ips__follow-btn{flex:1;height:48px;border-radius:14px;border:none;font-weight:700;font-size:15px;cursor:pointer;}
      .mp-ips__follow-btn.not-following{background:#E91E63;color:#fff;}
      .mp-ips__follow-btn.following{background:#FFE4EC;color:#E91E63;}
      .mp-ips__more-btn{width:48px;height:48px;border-radius:14px;border:none;background:#F8F9FE;color:#9CA3AF;font-size:20px;cursor:pointer;}
      .mp-ips__call-btn{margin-top:12px;width:100%;height:48px;border-radius:14px;border:1.5px solid #E91E63;background:#fff;color:#E91E63;font-weight:700;font-size:15px;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;}
      .mp-ips__gallery-title{margin-top:28px;font-size:17px;font-weight:700;color:#1A1D2E;}
      .mp-ips__gallery{margin-top:12px;display:flex;gap:10px;overflow-x:auto;padding-bottom:4px;}
      .mp-ips__gallery img{width:120px;height:120px;border-radius:14px;object-fit:cover;flex:none;cursor:pointer;background:#FFE4EC;}
      .mp-ips__loading{padding:60px 0;display:flex;justify-content:center;}
      .mp-ips__spin{width:32px;height:32px;border:3px solid rgba(233,30,99,.2);border-top-color:#E91E63;border-radius:50%;animation:mp-ips-spin .8s linear infinite;}
      @keyframes mp-ips-spin{to{transform:rotate(360deg)}}
      .mp-ips__lightbox{position:fixed;inset:0;background:#000;z-index:9700;display:flex;align-items:center;justify-content:center;}
      .mp-ips__lightbox img{max-width:100%;max-height:100%;object-fit:contain;}
      .mp-ips__lightbox-close{position:absolute;top:40px;right:16px;width:40px;height:40px;border-radius:50%;background:rgba(0,0,0,.7);border:none;color:#fff;font-size:20px;cursor:pointer;}
      .mp-ips__menu{position:absolute;background:#fff;border-radius:12px;box-shadow:0 8px 24px rgba(0,0,0,.15);padding:6px;z-index:9300;}
      .mp-ips__menu button{display:block;width:100%;text-align:left;padding:10px 14px;background:none;border:none;font-size:14px;color:#1A1D2E;cursor:pointer;border-radius:8px;}
      .mp-ips__menu button:hover{background:#F8F9FE;}
      .mp-ips__toast{position:fixed;left:16px;right:16px;bottom:24px;background:#D32F2F;color:#fff;padding:14px 16px;border-radius:12px;font-size:14px;text-align:center;max-width:420px;margin:0 auto;z-index:9800;}
    `;
    document.head.appendChild(style);
  }

  function escapeHtml(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  const InfluencerPreviewSheet = {
    // opts: { influencerId, name, photo, country, isLoggedIn, onRequireAuth }
    show(opts) {
      injectStyles();
      const state = Object.assign({ details: null, followerCount: 0, isFollowing: false, followBusy: false, loading: true }, opts);

      const backdrop = document.createElement("div");
      backdrop.className = "mp-ips-backdrop";
      const sheet = document.createElement("div");
      sheet.className = "mp-ips";
      backdrop.appendChild(sheet);
      document.body.appendChild(backdrop);
      requestAnimationFrame(function () { sheet.classList.add("mp-open"); });

      function close() {
        sheet.classList.remove("mp-open");
        setTimeout(function () { backdrop.remove(); }, 250);
      }
      backdrop.addEventListener("click", function (e) { if (e.target === backdrop) close(); });

      function showToast(message) {
        const t = document.createElement("div");
        t.className = "mp-ips__toast";
        t.textContent = message;
        document.body.appendChild(t);
        setTimeout(function () { t.remove(); }, 3200);
      }

      function showFullImage(url) {
        const lb = document.createElement("div");
        lb.className = "mp-ips__lightbox";
        lb.innerHTML = '<img src="' + url + '" alt=""><button class="mp-ips__lightbox-close" aria-label="Close"><i class="ph ph-x"></i></button>';
        lb.querySelector("button").addEventListener("click", function () { lb.remove(); });
        lb.addEventListener("click", function (e) { if (e.target === lb) lb.remove(); });
        document.body.appendChild(lb);
      }

      async function load() {
        try {
          const token = SessionManager.getToken();
          const [detailsResult, statusResult] = await Promise.all([
            ClientService.getInfluencerDetails(token, state.influencerId),
            FollowService.status(state.influencerId),
          ]);
          if (detailsResult && detailsResult.success === true) {
            state.details = detailsResult.data || null;
          }
          if (statusResult && statusResult.success === true && statusResult.data) {
            state.followerCount = statusResult.data.follower_count || 0;
            state.isFollowing = statusResult.data.is_following === true;
          }
        } catch (e) {
          /* fall through to render with whatever we have */
        }
        state.loading = false;
        render();
      }

      async function toggleFollow() {
        if (!state.isLoggedIn) {
          close();
          if (state.onRequireAuth) state.onRequireAuth();
          return;
        }
        if (state.followBusy) return;
        state.followBusy = true;
        render();

        const result = state.isFollowing
          ? await FollowService.unfollow(state.influencerId)
          : await FollowService.follow(state.influencerId);

        state.followBusy = false;

        if (result && result.success === true) {
          const data = result.data;
          state.isFollowing = data ? data.following === true : !state.isFollowing;
          if (data && data.follower_count != null) {
            state.followerCount = data.follower_count;
          } else {
            state.followerCount += state.isFollowing ? 1 : -1;
          }
          render();
        } else if (result && result.requires_auth === true) {
          close();
          if (state.onRequireAuth) state.onRequireAuth();
        } else {
          render();
          showToast((result && result.message) || "Failed");
        }
      }

      function callNow() {
        if (!state.isLoggedIn) {
          close();
          if (state.onRequireAuth) state.onRequireAuth();
          return;
        }
        close();
        window.location.href = "/influencer/" + state.influencerId;
      }

      function render() {
        if (state.loading) {
          sheet.innerHTML = '<div class="mp-ips__handle"></div><div class="mp-ips__loading"><div class="mp-ips__spin" role="status" aria-label="Loading"></div></div>';
          return;
        }

        const d = state.details || {};
        const photo = d.profile_photo || state.photo;
        const name = d.mystery_name || state.name || "";
        const country = d.country_name || state.country || "";
        const bio = d.biography;
        const whatOffer = d.what_offer ? String(d.what_offer).trim() : "";
        const gallery = Array.isArray(d.gallery) ? d.gallery : [];

        sheet.innerHTML =
          '<div class="mp-ips__handle"></div>' +
          '<div class="mp-ips__avatar-wrap"><div class="mp-ips__avatar" id="ipsAvatarWrap">' +
          (photo
            ? '<img src="' + photo + '" alt="">'
            : '<div class="fallback"><i class="ph ph-user"></i></div>') +
          "</div></div>" +
          '<div class="mp-ips__name">' + escapeHtml(name) + "</div>" +
          (country ? '<div class="mp-ips__loc"><i class="ph ph-map-pin"></i> ' + escapeHtml(country) + "</div>" : "") +
          '<div class="mp-ips__followers">' + state.followerCount + " followers</div>" +
          (bio ? '<div class="mp-ips__bio">' + escapeHtml(bio) + "</div>" : "") +
          (whatOffer
            ? '<div class="mp-ips__offer-title">What I will offer on the video call</div><div class="mp-ips__offer-box">' + escapeHtml(whatOffer) + "</div>"
            : "") +
          '<div class="mp-ips__row">' +
          '<button class="mp-ips__follow-btn ' + (state.isFollowing ? "following" : "not-following") + '" id="ipsFollowBtn" ' + (state.followBusy ? "disabled" : "") + ">" +
          (state.followBusy ? "…" : state.isFollowing ? "Following" : "Follow") +
          "</button>" +
          (state.isFollowing ? '<button class="mp-ips__more-btn" id="ipsMoreBtn" aria-label="More options"><i class="ph ph-dots-three"></i></button>' : "") +
          "</div>" +
          '<button class="mp-ips__call-btn" id="ipsCallBtn"><i class="ph ph-video-camera"></i> Call Now</button>' +
          (gallery.length
            ? '<div class="mp-ips__gallery-title">Gallery</div><div class="mp-ips__gallery" id="ipsGallery">' +
              gallery
                .map(function (item) {
                  const url = typeof item === "string" ? item : item && item.url;
                  return url ? '<img src="' + url + '" alt="" data-url="' + url + '">' : "";
                })
                .join("") +
              "</div>"
            : "");

        if (photo) {
          sheet.querySelector("#ipsAvatarWrap").style.cursor = "pointer";
          sheet.querySelector("#ipsAvatarWrap").addEventListener("click", function () { showFullImage(photo); });
        }
        sheet.querySelector("#ipsFollowBtn").addEventListener("click", toggleFollow);
        sheet.querySelector("#ipsCallBtn").addEventListener("click", callNow);
        const moreBtn = sheet.querySelector("#ipsMoreBtn");
        if (moreBtn) {
          moreBtn.addEventListener("click", function (e) {
            e.stopPropagation();
            const menu = document.createElement("div");
            menu.className = "mp-ips__menu";
            const rect = moreBtn.getBoundingClientRect();
            menu.style.top = rect.bottom + 6 + "px";
            menu.style.right = window.innerWidth - rect.right + "px";
            menu.innerHTML = "<button>Unfollow</button>";
            menu.querySelector("button").addEventListener("click", function () {
              menu.remove();
              toggleFollow();
            });
            document.body.appendChild(menu);
            setTimeout(function () {
              document.addEventListener("click", function onDoc() {
                menu.remove();
                document.removeEventListener("click", onDoc);
              }, { once: true });
            });
          });
        }
        const galleryEl = sheet.querySelector("#ipsGallery");
        if (galleryEl) {
          galleryEl.querySelectorAll("img").forEach(function (img) {
            img.addEventListener("click", function () { showFullImage(img.getAttribute("data-url")); });
          });
        }
      }

      render();
      load();

      return { close };
    },
  };

  global.InfluencerPreviewSheet = InfluencerPreviewSheet;
})(window);
