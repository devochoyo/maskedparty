# CHANGELOG — Influencer UI Integration ("Masked Party")

Scope: integrate the new hand-designed influencer UI into the existing Flutter
project, wire every screen to the real backend via the existing `services/`
classes, remove all placeholder/dummy data, and leave architecture, auth,
client-side, and video-call-core-logic untouched.

No new state-management library was introduced (no Provider/Riverpod/Bloc/
GetX/Redux). All screens use `SessionManager.getToken()` for auth and
redirect to `/login` via `Navigator.pushNamedAndRemoveUntil` on a missing
token. All screens use `MaterialPageRoute` for navigation (only `/login`,
`/clientHome`, `/influencerHome` are registered named routes). All errors
surface via `ScaffoldMessenger` SnackBars using the service's returned
`message`, backed by the shared `ApiConfig.handleResponse` / `handleError`.

---

## Screens delivered this session

### `wallet.dart`
- Wired to `WalletService.getBalance` (current/available balance) and
  `WalletService.getHistory` (transaction list).
- New UI's segmented **All / Earnings / Withdrawals** filter is now applied
  client-side to the real transaction list (filtered by transaction `type`
  and amount sign) instead of showing hardcoded rows.
- "Request Withdrawal" and the bar-chart icon route to the real
  `WithdrawalScreen` / `EarningsScreen` via `MaterialPageRoute`.
- Coin purchasing (`wallet/buy-coins.php`) is intentionally NOT exposed here
  — that's a client-only concern per the API.

### `earnings.dart`
- Wired to `InfluencerService.getEarnings` (today/this_week/this_month/
  lifetime aggregate earnings + call counts) for the **Statistics** row, and
  `WalletService.getHistory` for the **Recent Transactions** list.
- **Backend gap:** `influencer/earnings.php` returns aggregates only — no
  per-call breakdown (no client name / call duration per entry). The
  mockup's "Call with John — 15 mins — 25 Coins" style rows have been
  replaced with what `wallet/history.php` actually returns (description,
  coins, amount, date). Nothing here is fabricated.
- "Withdraw" button routes to the real `WithdrawalScreen`.
- Old `earnings.dart` bug fixed: it previously called
  `WalletService.getHistory` under the name "earnings" and never touched
  `InfluencerService.getEarnings` at all, so it had no real aggregate
  figures. Both are now used for what they actually represent.

### `withdrawal.dart`
- Wired to `WithdrawalService.requestWithdrawal(token, amount)` — only
  `amount` is sent, matching the real method signature.
- **Old bug fixed:** the old screen called
  `requestWithdrawal(token, amount, 'bank', bankName: ..., accountNumber: ...)`
  — a 5-argument call against a 2-argument method; it would not have
  compiled against the real service.
- **Backend gap:** `withdrawal/request.php` pays out to the `bank_name` /
  `account_number` captured at **registration** — it does not accept
  per-request bank details. The mockup's editable Bank Name / Account
  Number / Account Name fields have been changed to a **read-only** summary
  (best-effort, populated from `profile/get.php` if the backend includes
  those fields; falls back to "Not available") so the influencer can verify
  their payout destination without being misled into thinking they can
  change it here. A note directs them to contact support to change it.
- Added a real withdrawal history list below the form
  (`WithdrawalService.getWithdrawalHistory`).
- Amount field now validates against the real available balance client-side
  (in addition to the server's own minimum-amount / one-pending-withdrawal
  validation).

### `chat.dart` (conversation list)
- Wired to `ChatService.getConversations`.
- **Backend gap:** `chat/list.php` has no online/"last seen" presence field.
  The mockup's green online dot, "Last seen Xm ago" text, and hardcoded
  Unsplash avatar photos have been removed rather than faked. A neutral
  initial-letter avatar is used when no real `profile_photo` is present.
- The mockup's search field has no backend equivalent, so it filters the
  already-fetched conversation list client-side by `mystery_name`.
- Tapping a conversation opens the shared `ChatDetailScreen` with the real
  `other_user_id` (chat threads are grouped by the other participant's id —
  there is no separate conversation entity on this backend).

### `shared/chat_detail.dart`
- **No changes.** Verified against `ChatService` — already correctly uses
  `other_user_id` (not `conversation_id`), already does not filter/sanitize
  message text client-side (the backend blocks phone numbers, emails, URLs,
  and social handles server-side), already uses the correct primary color
  and error handling. Shared by both client and influencer sides per the
  hard rules, so left untouched.

### `notifications.dart`
- Wired to `NotificationService.getNotifications`,
  `NotificationService.markAsRead`, and the newly-exposed
  `NotificationService.markAllAsRead`.
- **Old bug fixed:** `notification/list.php` returns
  `{notifications, page, limit, unread_count}` — the old screen read
  `result['data']` directly as if it were the list itself, which would have
  rendered nothing (or crashed) since `data` is an object, not an array.
  Now correctly reads `result['data']['notifications']`.
- "Mark all as read" button (present in the mockup with an empty
  `onPressed`) is now wired to the real endpoint and only shown when
  `unread_count > 0`.
- Per-row icon/color is a purely cosmetic mapping off the notification's
  `type` field (call/verification/withdrawal/review/message/profile) with a
  neutral fallback icon — this does not change what's displayed, only how
  it looks, and never invents a type the backend didn't send.

### `profile.dart`
- Wired to `ProfileService.getProfile` for identity fields (mystery_name,
  biography, country, profile_photo, verification status) and
  `InfluencerService.getEarnings` for the real lifetime call count.
- **Backend gap:** there is no endpoint for an influencer to read their own
  rating or review list (only `review/create.php`, for clients to submit
  one). The mockup's "4.9 ★ (126 Reviews)" and "Reviews" / "Rating" stat
  tiles have been removed entirely — not replaced with zeros or fake
  numbers — leaving only the real "Calls" stat.
- Kept the new UI's wavy gradient header and avatar treatment.
- The mockup's "..." overflow menu (empty `onPressed`) now opens a bottom
  sheet with Gallery / Verification / Settings / Logout, preserving every
  navigation destination the old screen exposed inline.

### `settings.dart`
- Only **Logout** has a real backend action
  (`AuthService.logout` + `SessionManager.clearSession`, then redirect to
  `/login`).
- Privacy Policy / Terms / Community Guidelines / Help Center / Contact
  Support / About App have no corresponding API endpoints in this backend
  (no CMS/content endpoint, no support-ticket endpoint). Rather than wiring
  them to something that doesn't exist, they show a "coming soon" SnackBar
  placeholder — this is called out explicitly in the file's doc comment so
  it's easy to find and wire up later if/when those destinations exist.
  There is also no password-change endpoint (only email-based
  forgot/reset-password), so no such option was added.

### `video_call.dart`
- Wired to `CallService.startCall` (joins the VideoSDK room using
  credentials returned by `call/start.php`), `CallService.getCountdown`
  (polled every 10s for the remaining-time display), and
  `CallService.endCall`.
- Kept the new UI's fullscreen video + picture-in-picture self-view +
  gradient overlay + circular icon control-button layout.
- **Design correction:** the mockup included a second "The client has
  accepted the call — Accept / Decline" sheet inside this screen. That
  decision is already made on the Home screen's incoming-call banner
  (`call/accept.php` / `call/reject.php`) *before* this screen is ever
  pushed, so offering it again here would be a redundant/misleading second
  decision point. Replaced with a one-time dismissible "house rules"
  reminder card, matching the mockup's visual style without duplicating a
  real action that's already complete.
- Added an optional `clientName` parameter (defaults to `'Client'` for
  backward compatibility) so the real caller name — already available as
  `client_mystery_name` on the pending-call payload — can be shown instead
  of a hardcoded "John". `home.dart`'s `_acceptCall` call site was updated
  to pass it through.
- The mockup's "Speaker" toggle has no backend or VideoSDK-session concept
  behind it (it's a device audio-route setting); kept as local-only UI
  state and documented as such rather than silently pretending it does
  something server-side.
- `callId` continues to mean "the accepted call request's `request_id`"
  exactly as in the original screen — `call/start.php` takes `request_id`
  and returns the real `call_id` in its response, which is what
  `endCall`/`getCountdown` use from that point on.

---

## Screens verified as already correct (no changes needed)

### `edit_profile.dart`
Correctly wired to `ProfileService.getProfile` / `updateProfile` with only
mutable fields (never sends `full_name`, `country_name`, `country_code`,
`email`, or `role`). Profile photo upload goes through
`UploadService.uploadImage` then attaches the returned URL via
`updateProfile`. Correct token/redirect handling throughout.

### `gallery.dart`
Correctly wired to `InfluencerService.getGallery` / `uploadGallery` /
`deleteGalleryImage`. Enforces the real 10-image cap client-side ahead of
the server-side check, and surfaces `upload_errors` from partial-failure
responses. The mockup's "Photos / Videos" tab switcher and video counter
were already correctly dropped in the earlier work, since
`upload-gallery.php` only accepts images.

---

## Screens verified as already correct (from the earlier core-flow session)

- `complete_profile.dart` — fields corrected to match
  `complete-profile.php` exactly.
- `home.dart` — wired to `ProfileService.getProfile` +
  `InfluencerService.getEarnings`; online-status toggle sends a string, not
  a bool; incoming-call banner uses `request_id` / `client_mystery_name`;
  fabricated "Recent Calls" / rating stats removed.
- `verification.dart` — adapted to the real 3-upload
  `submitVerification(governmentIdPath:, selfiePath:, verificationVideoPath:)`
  signature.
- `bottom_navigation.dart` — 4-tab convention (Home, Chat, Wallet, Profile;
  Notifications reached via the bell icon on Home), passes `onWalletTap`
  into Home so the wallet icon switches tabs instead of pushing a duplicate
  screen.

---

## Backend gaps (do not fabricate — flagged, not papered over)

1. **No endpoint for an influencer's own reviews or rating.** Only
   `review/create.php` exists, for clients to submit a review of an
   influencer. `profile.dart` and `earnings.dart` do not show any
   rating/review numbers as a result.
2. **No "recent calls" list for influencers.** `influencer/earnings.php`
   returns aggregate counts only (`today_calls`, lifetime totals, etc.),
   not a per-call history. Anywhere the mockups showed a per-call list
   (`earnings.dart`, `profile.dart`), the real data source used instead is
   `wallet/history.php` (transaction records) where applicable, or the
   feature is simply not shown.
3. **No withdrawal-destination fields per request.** `withdrawal/
   request.php` only accepts `{amount}`; payouts always go to the bank
   details captured at registration. `withdrawal.dart` reflects this
   (read-only summary instead of editable fields).
4. **No dashboard.php.** The dashboard (`home.dart`, from the earlier
   session) is composed client-side from `influencer/earnings.php` +
   `wallet/balance.php` + `notification/list.php`.
5. **No content/support endpoints.** Privacy Policy, Terms, Community
   Guidelines, Help Center, Contact Support, and About App
   (`settings.dart`) have no backend — shown as placeholders, not wired to
   fake data.
6. **No password-change endpoint.** Only email-based forgot/reset-password
   exists; no in-app "change password" form was added.
7. **No "speaker mode" concept.** The video call's speaker toggle
   (`video_call.dart`) is a local device audio-route setting with no
   server-side counterpart.

---

## Bugs fixed in this session (old screens vs. real services)

| File | Bug | Fix |
|---|---|---|
| `withdrawal.dart` | Called `requestWithdrawal(token, amount, 'bank', bankName:, accountNumber:)` — 5 args against a 2-arg method; would not compile | Calls `requestWithdrawal(token, amount)` only |
| `notifications.dart` | Read `result['data']` as the notification list directly | Reads `result['data']['notifications']`, using `unread_count` from the same payload |
| `earnings.dart` | Called `WalletService.getHistory` under the "earnings" name and never called the real `InfluencerService.getEarnings` aggregate endpoint | Uses both, for what they actually represent |

## Bugs already fixed in the prior session (for reference)

| File | Bug | Fix |
|---|---|---|
| `complete_profile.dart` | Sent `full_name`, `mystery_name`, `uses_mask`, `would_remove_mask`, `ambition` — none of which match `complete-profile.php`'s real required fields | Sends `biography`, `age`, `complexion`, `favourite_food`, `hobby`, `aspiration`, `financial_target`, `mask_status`, `willing_to_remove_mask` |
| `home.dart` | Called `updateOnlineStatus(token, boolValue)` | Sends a string status (`"online"` / `"offline"` / `"unavailable"`) |
| `verification.dart` | Called `submitVerification(token, documentPath!)` — 1 positional arg | Calls with the real 3 required named args |

---

## Navigation summary

All influencer-to-influencer navigation uses `MaterialPageRoute` — no new
named routes were added. `InfluencerBottomNavigation` hosts Home, Chat,
Wallet, Profile as an `IndexedStack`; Notifications, Gallery, Verification,
Settings, Earnings, Withdrawal, and the video call screen are all pushed on
top via `MaterialPageRoute` from Home, Profile's overflow menu, or Wallet.

## Files touched this session

- `lib/screens/influencer/wallet.dart` (rewritten)
- `lib/screens/influencer/earnings.dart` (rewritten)
- `lib/screens/influencer/withdrawal.dart` (rewritten)
- `lib/screens/influencer/chat.dart` (rewritten)
- `lib/screens/influencer/notifications.dart` (rewritten)
- `lib/screens/influencer/profile.dart` (rewritten)
- `lib/screens/influencer/settings.dart` (rewritten)
- `lib/screens/influencer/video_call.dart` (rewritten)
- `lib/screens/influencer/home.dart` (small edit: threads real client name
  into `VideoCallScreen`)
- `lib/screens/shared/chat_detail.dart` (verified, unchanged)
- `lib/screens/influencer/edit_profile.dart` (verified, unchanged)
- `lib/screens/influencer/gallery.dart` (verified, unchanged)

All 13 influencer screens plus the shared chat detail screen are now
integrated. No dummy/placeholder data remains anywhere in the delivered
files; every backend gap encountered is documented above and in the
relevant file's doc comment rather than being silently faked.
