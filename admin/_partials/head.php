<?php
/**
 * Shared page shell: <head>, sidebar nav, topbar, and the opening of
 * #content. Every admin/*.php page does:
 *
 *   $admin      = admin_current_user();
 *   $activePage = 'users';               // matches one nav-item below
 *   $pageTitle  = 'Users';
 *   $pageSub    = 'Search, review, and moderate accounts';
 *   require __DIR__ . '/_partials/head.php';
 *   ... page markup + its own <script> ...
 *   require __DIR__ . '/_partials/foot.php';
 */
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= htmlspecialchars($pageTitle) ?> — Masked Party Admin</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

:root {
  --bg: #fdfbfc; --panel: #ffffff; --panel-2: #fff5fa;
  --line: #f0dce8; --line-soft: #f6e9f1;
  --text: #221a20; --text-dim: #6b5c65; --text-faint: #9c8a94;
  --pink: #ff1e7d; --pink-hi: #ff4d97; --pink-dark: #d90d63;
  --pink-tint: #ffe4f0; --pink-tint-2: #fff0f7;
  --ok: #1f9d63; --ok-bg: #e6f7ee;
  --warn: #c9822b; --warn-bg: #fbf0dd;
  --danger: #e0335a; --danger-bg: #fde8ee;
  --info: #4d7ec9; --info-bg: #eaf1fc;
  --radius: 12px; --radius-sm: 8px;
  --shadow: 0 10px 30px rgba(216, 30, 110, 0.08), 0 2px 8px rgba(0,0,0,0.04);
  --font-display: 'Fraunces', Georgia, serif;
  --font-body: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;
}
* { box-sizing: border-box; }
html, body { height: 100%; margin: 0; }
body {
  background: var(--bg);
  background-image:
    radial-gradient(900px 480px at 90% -8%, rgba(255,30,125,0.06), transparent 60%),
    radial-gradient(700px 420px at -5% 105%, rgba(255,30,125,0.04), transparent 55%);
  background-attachment: fixed;
  color: var(--text); font-family: var(--font-body); font-size: 14px; line-height: 1.5;
  -webkit-font-smoothing: antialiased;
}
::selection { background: var(--pink); color: #fff; }
a { color: inherit; text-decoration: none; }
::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--line); border-radius: 8px; }
::-webkit-scrollbar-thumb:hover { background: var(--pink-hi); }

.app { display: grid; grid-template-columns: 232px 1fr; min-height: 100vh; }
.sidebar {
  background: var(--panel); border-right: 1px solid var(--line); padding: 22px 14px;
  display: flex; flex-direction: column; position: sticky; top: 0; height: 100vh;
}
.brand { display: flex; align-items: center; gap: 10px; padding: 0 8px 22px; margin-bottom: 10px; border-bottom: 1px solid var(--line-soft); }
.brand-mark {
  width: 32px; height: 32px; border-radius: 50%;
  background: linear-gradient(135deg, var(--pink-hi), var(--pink));
  display: grid; place-items: center; color: #fff; flex-shrink: 0;
  box-shadow: 0 4px 10px rgba(255,30,125,0.3);
}
.brand-mark svg { width: 15px; height: 15px; }
.brand-text { font-family: var(--font-display); font-weight: 600; font-size: 15px; line-height: 1.2; }
.brand-text small { display: block; font-family: var(--font-body); font-size: 10px; color: var(--text-faint); text-transform: uppercase; letter-spacing: 0.6px; font-weight: 600; margin-top: 2px; }
.nav { display: flex; flex-direction: column; gap: 2px; margin-top: 6px; }
.nav-item {
  display: flex; align-items: center; gap: 10px; padding: 9px 10px; border-radius: var(--radius-sm);
  color: var(--text-dim); font-size: 13.5px; font-weight: 600; cursor: pointer; border: 1px solid transparent;
  transition: background .12s ease, color .12s ease; position: relative;
}
.nav-item svg { width: 16px; height: 16px; opacity: 0.75; flex-shrink: 0; }
.nav-item:hover { background: var(--pink-tint-2); color: var(--text); }
.nav-item.active { background: var(--pink-tint); border-color: #ffc7e0; color: var(--pink-dark); }
.nav-item.active svg { color: var(--pink); opacity: 1; }
.nav-badge {
  margin-left: auto; background: var(--pink); color: #fff; font-size: 10.5px; font-weight: 700;
  padding: 1px 6px; border-radius: 20px; min-width: 18px; text-align: center; font-family: var(--font-mono);
}
.sidebar-foot { margin-top: auto; padding-top: 14px; border-top: 1px solid var(--line-soft); }
.admin-chip { display: flex; align-items: center; gap: 9px; padding: 8px; border-radius: var(--radius-sm); }
.admin-avatar {
  width: 28px; height: 28px; border-radius: 50%; background: linear-gradient(135deg, var(--pink-hi), var(--pink));
  display: grid; place-items: center; font-family: var(--font-display); font-weight: 600; font-size: 12px; color: #fff; flex-shrink: 0;
}
.admin-name { font-size: 12.5px; font-weight: 700; line-height: 1.3; }
.admin-role { font-size: 10.5px; color: var(--text-faint); text-transform: uppercase; letter-spacing: 0.4px; }
.logout-link { display: block; font-size: 12px; color: var(--text-faint); margin-top: 10px; padding: 6px 8px; border-radius: var(--radius-sm); font-weight: 600; }
.logout-link:hover { color: var(--danger); background: var(--danger-bg); }

.main { min-width: 0; }
.topbar {
  position: sticky; top: 0; z-index: 5; display: flex; align-items: center; justify-content: space-between;
  padding: 16px 28px; background: rgba(253,251,252,0.85); backdrop-filter: blur(10px); border-bottom: 1px solid var(--line-soft);
}
.page-title { font-family: var(--font-display); font-size: 19px; font-weight: 600; }
.page-sub { color: var(--text-faint); font-size: 12.5px; margin-top: 2px; }
.content { padding: 26px 28px 60px; }

.stat-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 14px; margin-bottom: 28px; }
.stat-card { background: var(--panel); border: 1px solid var(--line); border-radius: var(--radius); padding: 18px 18px 16px; position: relative; overflow: hidden; }
.stat-card::after { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px; background: linear-gradient(90deg, var(--pink), var(--pink-hi)); opacity: 0.85; }
.stat-label { font-size: 11px; color: var(--text-faint); text-transform: uppercase; letter-spacing: 0.5px; font-weight: 700; margin-bottom: 10px; }
.stat-value { font-family: var(--font-display); font-size: 26px; font-weight: 600; }
.stat-value.accent { color: var(--pink); }
.stat-value.oxblood { color: var(--pink-dark); }
.stat-value.sage { color: var(--ok); }
.stat-foot { font-size: 11.5px; color: var(--text-faint); margin-top: 6px; }

.card { background: var(--panel); border: 1px solid var(--line); border-radius: var(--radius); margin-bottom: 20px; overflow: hidden; }
.card-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 16px 18px; border-bottom: 1px solid var(--line-soft); flex-wrap: wrap; }
.card-head h3 { font-family: var(--font-display); font-size: 15.5px; font-weight: 600; margin: 0; }
.card-body { padding: 4px; }
.card-body.pad { padding: 18px; }
@media (max-width: 880px) {
  .card-body { overflow-x: auto; -webkit-overflow-scrolling: touch; }
}
.toolbar { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.search-input, .select-input {
  background: var(--panel-2); border: 1.5px solid var(--line); color: var(--text); padding: 8px 11px;
  border-radius: var(--radius-sm); font-size: 13px; font-family: var(--font-body);
}
.search-input:focus, .select-input:focus { outline: none; border-color: var(--pink); background: #fff; }
.search-input { min-width: 200px; }

table { width: 100%; border-collapse: collapse; font-size: 13px; }
thead th {
  text-align: left; font-size: 10.5px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-faint);
  font-weight: 700; padding: 11px 16px; border-bottom: 1px solid var(--line-soft); white-space: nowrap; background: var(--panel-2);
}
tbody td { padding: 12px 16px; border-bottom: 1px solid var(--line-soft); vertical-align: middle; }
tbody tr:last-child td { border-bottom: none; }
tbody tr { transition: background .1s ease; }
tbody tr:hover { background: var(--pink-tint-2); }
.cell-dim { color: var(--text-faint); }
.cell-mono { font-family: var(--font-mono); font-size: 12px; color: var(--text-dim); }

.badge { display: inline-flex; align-items: center; gap: 5px; font-size: 11px; font-weight: 700; padding: 3px 9px; border-radius: 20px; text-transform: capitalize; white-space: nowrap; }
.badge::before { content: ''; width: 5px; height: 5px; border-radius: 50%; background: currentColor; }
.badge.ok { background: var(--ok-bg); color: var(--ok); }
.badge.warn { background: var(--warn-bg); color: var(--warn); }
.badge.danger { background: var(--danger-bg); color: var(--danger); }
.badge.info { background: var(--info-bg); color: var(--info); }
.badge.neutral { background: #f1eaee; color: var(--text-dim); }

.btn {
  display: inline-flex; align-items: center; gap: 6px; font-size: 12.5px; font-weight: 700; padding: 7px 12px;
  border-radius: var(--radius-sm); border: 1.5px solid var(--line); background: #fff; color: var(--text);
  cursor: pointer; transition: all .12s ease; font-family: var(--font-body); white-space: nowrap;
}
.btn:hover { border-color: var(--pink); color: var(--pink-dark); }
.btn:disabled { opacity: 0.45; cursor: not-allowed; }
.btn.sm { padding: 5px 9px; font-size: 11.5px; }
.btn-ok { background: var(--ok-bg); border-color: #bfe6cf; color: var(--ok); }
.btn-ok:hover { background: #d8f2e3; border-color: var(--ok); color: var(--ok); }
.btn-danger { background: var(--danger-bg); border-color: #f6c4d0; color: var(--danger); }
.btn-danger:hover { background: #fbd2dd; border-color: var(--danger); color: var(--danger); }
.btn-warn { background: var(--warn-bg); border-color: #f0dbb2; color: var(--warn); }
.btn-warn:hover { background: #f7e7c4; border-color: var(--warn); color: var(--warn); }
.btn-ghost { background: transparent; border-color: transparent; color: var(--text-faint); }
.btn-ghost:hover { color: var(--pink-dark); background: var(--pink-tint-2); border-color: transparent; }
.btn-primary-sm { background: linear-gradient(180deg, var(--pink-hi), var(--pink)); border-color: transparent; color: #fff; }
.btn-primary-sm:hover { filter: brightness(1.06); color: #fff; }
.btn-info-sm { background: var(--info-bg); border-color: #c5d5f0; color: var(--info); }
.btn-info-sm:hover { background: #d4e0f7; border-color: var(--info); color: var(--info); }
.row-actions { display: flex; gap: 6px; flex-wrap: wrap; }

.pager { display: flex; align-items: center; justify-content: space-between; padding: 12px 16px; border-top: 1px solid var(--line-soft); }
.pager-info { font-size: 12px; color: var(--text-faint); }
.pager-btns { display: flex; gap: 6px; }

.tabs { display: flex; gap: 4px; padding: 4px; background: var(--panel-2); border-radius: var(--radius-sm); border: 1px solid var(--line); width: fit-content; }
.tab { padding: 7px 13px; font-size: 12.5px; font-weight: 700; border-radius: 6px; cursor: pointer; color: var(--text-faint); }
.tab.active { background: var(--pink); color: #fff; }
.tab:hover:not(.active) { color: var(--pink-dark); }

.empty-state, .loading-state { padding: 48px 20px; text-align: center; color: var(--text-faint); font-size: 13px; }
.empty-state svg { width: 30px; height: 30px; margin-bottom: 10px; opacity: 0.4; }
.spinner { width: 18px; height: 18px; border: 2px solid var(--line); border-top-color: var(--pink); border-radius: 50%; animation: spin .7s linear infinite; display: inline-block; }
@keyframes spin { to { transform: rotate(360deg); } }

#toast-stack { position: fixed; bottom: 20px; right: 20px; display: flex; flex-direction: column; gap: 8px; z-index: 200; }
.toast {
  background: #fff; border: 1px solid var(--line); border-left: 3px solid var(--pink); color: var(--text);
  padding: 12px 16px; border-radius: var(--radius-sm); font-size: 13px; box-shadow: var(--shadow); min-width: 240px;
  animation: toast-in .18s ease;
}
.toast.success { border-left-color: var(--ok); }
.toast.error { border-left-color: var(--danger); }
@keyframes toast-in { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }

.modal-backdrop { position: fixed; inset: 0; background: rgba(34,26,32,0.45); backdrop-filter: blur(2px); display: grid; place-items: center; z-index: 100; padding: 20px; }
.modal { background: #fff; border: 1px solid var(--line); border-radius: var(--radius); width: 100%; max-width: 500px; box-shadow: var(--shadow); }
.modal-head { padding: 16px 20px; border-bottom: 1px solid var(--line-soft); display: flex; align-items: center; justify-content: space-between; }
.modal-head h4 { margin: 0; font-family: var(--font-display); font-size: 16px; font-weight: 600; }
.modal-close { cursor: pointer; color: var(--text-faint); font-size: 18px; line-height: 1; padding: 4px; background: none; border: none; }
.modal-close:hover { color: var(--pink-dark); }
.modal-body { padding: 18px 20px; }
.modal-body p { color: var(--text-dim); font-size: 13.5px; margin: 0 0 14px; }
.modal-foot { padding: 14px 20px; border-top: 1px solid var(--line-soft); display: flex; justify-content: flex-end; gap: 8px; }
.field-label { display: block; font-size: 12px; color: var(--text-dim); margin-bottom: 6px; font-weight: 600; }
input.field-input, textarea.field-textarea {
  width: 100%; background: var(--panel-2); border: 1.5px solid var(--line); color: var(--text); padding: 10px 12px;
  border-radius: var(--radius-sm); font-size: 13px; font-family: var(--font-body);
}
textarea.field-textarea { resize: vertical; min-height: 74px; }
input.field-input:focus, textarea.field-textarea:focus { outline: none; border-color: var(--pink); background: #fff; }

/* Bank details display */
.bank-detail-row {
  display: flex; justify-content: space-between; align-items: center;
  padding: 10px 0; border-bottom: 1px solid var(--line-soft);
}
.bank-detail-row:last-child { border-bottom: none; }
.bank-detail-label { font-size: 12px; color: var(--text-faint); font-weight: 600; text-transform: uppercase; letter-spacing: 0.4px; }
.bank-detail-value { font-size: 14px; font-weight: 600; color: var(--text); font-family: var(--font-mono); }

.doc-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 10px; margin: 12px 0; }
.doc-thumb {
  aspect-ratio: 1; border-radius: var(--radius-sm); border: 1px solid var(--line); background: var(--panel-2) center/cover no-repeat;
  display: grid; place-items: center; color: var(--text-faint); font-size: 11px; overflow: hidden;
}
.doc-thumb img, .doc-thumb video { width: 100%; height: 100%; object-fit: cover; }

.mono { font-family: var(--font-mono); }
.dim { color: var(--text-faint); }
.flex-between { display: flex; align-items: center; justify-content: space-between; }
.gap-8 { gap: 8px; }
.w-100 { width: 100%; }

.hamburger-btn {
  display: none; align-items: center; justify-content: center;
  width: 36px; height: 36px; border-radius: var(--radius-sm);
  border: 1.5px solid var(--line); background: #fff; color: var(--text);
  cursor: pointer; flex-shrink: 0;
}
.hamburger-btn svg { width: 18px; height: 18px; }
.hamburger-btn:hover { border-color: var(--pink); color: var(--pink-dark); }

.sidebar-overlay {
  display: none; position: fixed; inset: 0; background: rgba(34,26,32,0.45);
  z-index: 39; opacity: 0; transition: opacity .2s ease;
}
.sidebar-overlay.open { display: block; opacity: 1; }

@media (max-width: 880px) {
  .app { grid-template-columns: 1fr; }
  .hamburger-btn { display: inline-flex; }
  .sidebar {
    position: fixed; top: 0; left: 0; z-index: 40; width: 260px; max-width: 84vw;
    height: 100vh; transform: translateX(-100%); transition: transform .22s ease;
    box-shadow: var(--shadow); display: flex;
  }
  .sidebar.open { transform: translateX(0); }
  .topbar { padding: 14px 16px; gap: 10px; }
  .content { padding: 16px; }
  .card-head { padding: 14px; }
  table { font-size: 12.5px; }
  thead th, tbody td { padding: 9px 10px; }
}

@media (max-width: 480px) {
  .page-title { font-size: 16.5px; }
  .stat-grid { grid-template-columns: 1fr 1fr; gap: 10px; }
  .stat-value { font-size: 21px; }
  .toolbar { width: 100%; }
  .search-input { min-width: 0; flex: 1; }
  .modal { max-width: 100% !important; margin: 0 8px; }
}
</style>
</head>
<body>
<div class="app">

  <div class="sidebar-overlay" id="sidebarOverlay"></div>
  <aside class="sidebar" id="sidebar">
    <div class="brand">
      <div class="brand-mark">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3c-4 0-7 2.5-7 6.5 0 2 .8 3.3 1.6 4.3.5.6.9 1.1.9 2.2v1c0 1.1.9 2 2 2h.5c.3 0 .5.2.5.5v.5c0 .5.4 1 1 1h1.5c.3 0 .5-.2.5-.5v-1c0-.3.2-.5.5-.5s.5.2.5.5v1c0 .3.2.5.5.5H16c.6 0 1-.5 1-1v-.5c0-.3.2-.5.5-.5h.5c1.1 0 2-.9 2-2v-1c0-1.1.4-1.6.9-2.2.8-1 1.6-2.3 1.6-4.3C21.5 5.5 18.5 3 14.5 3"/><circle cx="9" cy="10.5" r="1"/><circle cx="15" cy="10.5" r="1"/></svg>
      </div>
      <div class="brand-text">Masked Party<small>Admin Panel</small></div>
    </div>

    <nav class="nav" id="nav">
      <a href="dashboard.php" class="nav-item<?= $activePage === 'dashboard' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/></svg>
        Overview
      </a>
      <a href="users.php" class="nav-item<?= $activePage === 'users' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="8" r="3.5"/><path d="M5 20c0-3.5 3-6 7-6s7 2.5 7 6"/></svg>
        Users
      </a>
      <a href="verification.php" class="nav-item<?= $activePage === 'verification' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 12l2 2 4-4"/><circle cx="12" cy="12" r="9"/></svg>
        Verification
        <span class="nav-badge" id="badge-verification" style="display:none">0</span>
      </a>
      <a href="withdrawals.php" class="nav-item<?= $activePage === 'withdrawals' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="6" width="20" height="14" rx="2"/><path d="M2 10h20"/><path d="M6 15h4"/></svg>
        Withdrawals
        <span class="nav-badge" id="badge-withdrawals" style="display:none">0</span>
      </a>
      <a href="calls.php" class="nav-item<?= $activePage === 'calls' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M15.05 5A5 5 0 0119 8.95M15.05 1A9 9 0 0123 8.94M4.6 9.3a13.5 13.5 0 006 6.1l1.9-1.9a1.7 1.7 0 011.7-.4c1 .3 2 .5 3.1.5a1.7 1.7 0 011.7 1.7v2.8a1.7 1.7 0 01-1.7 1.7C10.6 19.8 4.2 13.4 3.2 4.7A1.7 1.7 0 014.9 3h2.8a1.7 1.7 0 011.7 1.7c0 1.1.2 2.1.5 3.1a1.7 1.7 0 01-.4 1.7L4.6 9.3z"/></svg>
        Calls
      </a>
      <a href="reports.php" class="nav-item<?= $activePage === 'reports' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 9v4"/><path d="M12 16.5v.01"/><path d="M10.3 3.9L2.7 17.3A1.8 1.8 0 004.3 20h15.4a1.8 1.8 0 001.6-2.7L13.7 3.9a1.8 1.8 0 00-3.4 0z"/></svg>
        Reports
        <span class="nav-badge" id="badge-reports" style="display:none">0</span>
      </a>
      <a href="packages.php" class="nav-item<?= $activePage === 'packages' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M12 7v10M8.5 9.5c0-1.4 1.5-2.5 3.5-2.5s3.5 1 3.5 2.2c0 2.8-7 1.4-7 4.2 0 1.3 1.6 2.3 3.5 2.3s3.5-1 3.5-2.3"/></svg>
        Coin Packages
      </a>
      <a href="call-minute-costs.php" class="nav-item<?= $activePage === 'call-minute-costs' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/></svg>
        Call Minute Costs
      </a>
      <a href="pay-as-you-go.php" class="nav-item<?= $activePage === 'pay-as-you-go' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 3v18M17 7.5c0-1.7-2.2-3-5-3s-5 1.3-5 3 2.2 3 5 3 5 1.3 5 3-2.2 3-5 3-5-1.3-5-3"/></svg>
        Pay as you go
      </a>
      <a href="support.php" class="nav-item<?= $activePage === 'support' ? ' active' : '' ?>">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/><path d="M12 8v4M12 14.5v.01"/></svg>
        Support
        <span class="nav-badge" id="badge-support" style="display:none">0</span>
      </a>
    </nav>

    <div class="sidebar-foot">
      <div class="admin-chip">
        <div class="admin-avatar"><?= htmlspecialchars(strtoupper(substr($admin['mystery_name'] ?? 'A', 0, 1))) ?></div>
        <div>
          <div class="admin-name"><?= htmlspecialchars($admin['mystery_name'] ?? 'Admin') ?></div>
          <div class="admin-role">Administrator</div>
        </div>
      </div>
      <a href="/admin/logout.php" class="logout-link">Sign out</a>
    </div>
  </aside>

  <div class="main">
    <div class="topbar">
      <div style="display:flex;align-items:center;gap:12px;">
        <button class="hamburger-btn" id="hamburgerBtn" aria-label="Toggle menu">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 6h18M3 12h18M3 18h18"/></svg>
        </button>
        <div>
          <div class="page-title"><?= htmlspecialchars($pageTitle) ?></div>
          <div class="page-sub"><?= htmlspecialchars($pageSub) ?></div>
        </div>
      </div>
    </div>
    <div class="content" id="content">
      <div class="loading-state"><span class="spinner"></span></div>
    </div>
  </div>

</div>

<div id="toast-stack"></div>
<div id="modal-root"></div>

<script>
/* ---------------------------------------------------------------------
 * Shared helpers used by every page's own <script> block below.
 * Declared as plain top-level functions (no IIFE) so the page-specific
 * <script> tag that comes after can call them directly.
 * ------------------------------------------------------------------- */

  function api(path, opts) {
    opts = opts || {};
    var qs = new URLSearchParams(opts.query || {});
    qs.set('path', path);
    var url = '/admin/proxy.php?' + qs.toString();
    var fetchOpts = { method: opts.method || 'GET', headers: {} };
    if (opts.body) {
      fetchOpts.headers['Content-Type'] = 'application/json';
      fetchOpts.body = JSON.stringify(opts.body);
    }
    return fetch(url, fetchOpts).then(function (res) {
      return res.json().then(function (data) {
        if (res.status === 401) {
          window.location.href = '/admin/login.php';
          throw new Error('Session expired');
        }
        return data;
      });
    });
  }

  function esc(str) {
    var d = document.createElement('div');
    d.textContent = (str === null || str === undefined) ? '' : String(str);
    return d.innerHTML;
  }
  function money(n) { return '£' + (Number(n) || 0).toFixed(2); }
  function fmtDuration(totalSeconds) {
    var s = Math.max(0, Number(totalSeconds) || 0);
    var h = Math.floor(s / 3600);
    var m = Math.floor((s % 3600) / 60);
    var sec = Math.floor(s % 60);
    var pad = function (n) { return n < 10 ? '0' + n : String(n); };
    return h > 0 ? (h + ':' + pad(m) + ':' + pad(sec)) : (m + ':' + pad(sec));
  }
  function endedByBadge(role) {
    var map = { client: 'info', influencer: 'ok', system: 'neutral' };
    var cls = map[role] || 'neutral';
    return '<span class="badge ' + cls + '">' + esc(role || 'unknown') + '</span>';
  }
  function fmtDate(s) {
    if (!s) return '—';
    var d = new Date(s.replace(' ', 'T'));
    if (isNaN(d)) return s;
    return d.toLocaleDateString(undefined, { day: '2-digit', month: 'short', year: 'numeric' }) +
      ' · ' + d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
  }

  function toast(msg, type) {
    var stack = document.getElementById('toast-stack');
    var el = document.createElement('div');
    el.className = 'toast ' + (type || '');
    el.textContent = msg;
    stack.appendChild(el);
    setTimeout(function () {
      el.style.opacity = '0';
      el.style.transition = 'opacity .2s ease';
      setTimeout(function () { el.remove(); }, 200);
    }, 3200);
  }

  function statusBadge(status) {
    var map = {
      active: 'ok', completed: 'ok', approved: 'ok', online: 'ok', resolved: 'ok',
      pending: 'warn', pending_verification: 'warn', busy: 'warn',
      suspended: 'warn', dismissed: 'neutral',
      banned: 'danger', rejected: 'danger', expired: 'danger',
      offline: 'neutral', unavailable: 'neutral'
    };
    var cls = map[status] || 'neutral';
    return '<span class="badge ' + cls + '">' + esc((status || '').replace(/_/g, ' ')) + '</span>';
  }

  function openModal(opts) {
    var root = document.getElementById('modal-root');
    var needsNote = !!opts.withNote;
    root.innerHTML =
      '<div class="modal-backdrop" id="modalBackdrop">' +
        '<div class="modal" style="max-width:' + (opts.width || '500') + 'px;">' +
          '<div class="modal-head"><h4>' + esc(opts.title) + '</h4><button class="modal-close" id="modalCloseBtn">&times;</button></div>' +
          '<div class="modal-body">' +
            (opts.html ? opts.html : '<p>' + esc(opts.message) + '</p>') +
            (needsNote ? '<label class="field-label">Admin note (optional)</label><textarea class="field-textarea" id="modalNote" placeholder="Reason, context, etc."></textarea>' : '') +
          '</div>' +
          (opts.hideFooter ? '' :
          '<div class="modal-foot">' +
            '<button class="btn" id="modalCancelBtn">Cancel</button>' +
            '<button class="btn ' + (opts.confirmClass || 'btn-primary-sm') + '" id="modalConfirmBtn">' + esc(opts.confirmLabel || 'Confirm') + '</button>' +
          '</div>') +
        '</div>' +
      '</div>';

    function close() { root.innerHTML = ''; }
    var closeBtn = document.getElementById('modalCloseBtn');
    var cancelBtn = document.getElementById('modalCancelBtn');
    var backdrop = document.getElementById('modalBackdrop');
    if (closeBtn) closeBtn.onclick = close;
    if (cancelBtn) cancelBtn.onclick = close;
    if (backdrop) backdrop.onclick = function (e) { if (e.target.id === 'modalBackdrop') close(); };

    var confirmBtn = document.getElementById('modalConfirmBtn');
    if (confirmBtn && opts.onConfirm) {
      confirmBtn.onclick = function () {
        var note = needsNote ? document.getElementById('modalNote').value.trim() : undefined;
        confirmBtn.disabled = true;
        confirmBtn.textContent = 'Working…';
        opts.onConfirm(note).then(close).catch(function () {
          confirmBtn.disabled = false;
          confirmBtn.textContent = opts.confirmLabel || 'Confirm';
        });
      };
    }
  }
  function emptyState(msg) {
    return '<div class="empty-state"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="12" r="9"/><path d="M9 10h.01M15 10h.01M8 15c1.2 1 2.6 1.5 4 1.5s2.8-.5 4-1.5"/></svg><div>' + esc(msg) + '</div></div>';
  }
  function errorBlock(msg) {
    return '<div class="card"><div class="card-body pad"><div class="login-error" style="background:var(--danger-bg);border:1px solid #f5c1cf;color:var(--danger);padding:12px;border-radius:8px;">' + esc(msg || 'Something went wrong.') + '</div></div></div>';
  }
  function tabBtn(val, current) {
    return '<div class="tab' + (val === current ? ' active' : '') + '" data-val="' + val + '">' + val.charAt(0).toUpperCase() + val.slice(1) + '</div>';
  }
  function refreshBadges() {
    api('admin/withdrawals.php', { query: { action: 'list', status: 'pending', page: 1 } }).then(function (r) {
      var n = (r.success && r.data) ? (r.data.withdrawals || []).length : 0;
      var b = document.getElementById('badge-withdrawals');
      if (n > 0) { b.style.display = ''; b.textContent = n === 20 ? '20+' : n; } else { b.style.display = 'none'; }
    }).catch(function () {});
    api('admin/verification.php', { query: { action: 'list', status: 'pending', page: 1 } }).then(function (r) {
      var n = (r.success && r.data) ? (r.data.verifications || []).length : 0;
      var b = document.getElementById('badge-verification');
      if (n > 0) { b.style.display = ''; b.textContent = n === 20 ? '20+' : n; } else { b.style.display = 'none'; }
    }).catch(function () {});
    api('admin/reports.php', { query: { action: 'list', status: 'pending', page: 1 } }).then(function (r) {
      var n = (r.success && r.data) ? (r.data.reports || []).length : 0;
      var b = document.getElementById('badge-reports');
      if (n > 0) { b.style.display = ''; b.textContent = n === 20 ? '20+' : n; } else { b.style.display = 'none'; }
    }).catch(function () {});
    api('admin/support.php', { query: { action: 'list' } }).then(function (r) {
      var agents = (r.success && r.data && r.data.agents) ? r.data.agents : [];
      var suspended = agents.filter(function (a) { return a.status === 'suspended'; }).length;
      var b = document.getElementById('badge-support');
      if (suspended > 0) { b.style.display = ''; b.textContent = suspended; } else { b.style.display = 'none'; }
    }).catch(function () {});
  }

refreshBadges();

/* ---------------------------------------------------------------------
 * Mobile sidebar: hamburger toggle + tap-outside-to-close.
 * ------------------------------------------------------------------- */
(function () {
  var sidebar   = document.getElementById('sidebar');
  var overlay   = document.getElementById('sidebarOverlay');
  var hamburger = document.getElementById('hamburgerBtn');
  if (!sidebar || !overlay || !hamburger) return;

  function openSidebar() {
    sidebar.classList.add('open');
    overlay.classList.add('open');
  }
  function closeSidebar() {
    sidebar.classList.remove('open');
    overlay.classList.remove('open');
  }

  hamburger.addEventListener('click', function () {
    if (sidebar.classList.contains('open')) closeSidebar(); else openSidebar();
  });
  overlay.addEventListener('click', closeSidebar);

  // Close after navigating (links are normal <a> page loads, but this
  // avoids a flash of the open sidebar on slower connections/back-nav).
  sidebar.querySelectorAll('.nav-item, .logout-link').forEach(function (el) {
    el.addEventListener('click', closeSidebar);
  });

  // If the viewport grows back to desktop width, make sure the sidebar
  // isn't left in a "forced open" transform state.
  window.addEventListener('resize', function () {
    if (window.innerWidth > 880) closeSidebar();
  });
})();
</script>
