<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'dashboard';
$pageTitle  = 'Overview';
$pageSub    = 'Live snapshot of the platform';

require __DIR__ . '/_partials/head.php';
?>
<script>
function renderDashboard() {
  api('admin/dashboard.php').then(function (r) {
    var c = document.getElementById('content');
    if (!r.success) { c.innerHTML = errorBlock(r.message); return; }
    var s = r.data;
    c.innerHTML =
      '<div class="stat-grid">' +
        statCard('Total users', s.total_users, '') +
        statCard('Clients', s.clients, '') +
        statCard('Influencers', s.influencers, s.verified_influencers + ' verified · ' + s.pending_verification + ' pending') +
        statCard('Online now', s.online_users, '', 'sage') +
        statCard('Revenue today', money(s.today_revenue), 'Total: ' + money(s.total_revenue), 'accent') +
        statCard('Calls today', s.today_calls, 'Total: ' + s.total_calls) +
        statCard('Pending withdrawals', s.pending_withdrawals, s.completed_withdrawals + ' completed', s.pending_withdrawals > 0 ? 'oxblood' : '') +
        statCard('Escrow held', money(s.total_escrow_balance), 'Across all active calls') +
      '</div>' +
      '<div class="card">' +
        '<div class="card-head"><h3>Recent completed payments</h3></div>' +
        '<div class="card-body">' + renderActivityTable(s.recent_activity) + '</div>' +
      '</div>';
  }).catch(function (e) { document.getElementById('content').innerHTML = errorBlock(e.message); });
}

function statCard(label, value, foot, accentClass) {
  return '<div class="stat-card">' +
    '<div class="stat-label">' + esc(label) + '</div>' +
    '<div class="stat-value' + (accentClass ? ' ' + accentClass : '') + '">' + esc(value) + '</div>' +
    (foot ? '<div class="stat-foot">' + esc(foot) + '</div>' : '') +
    '</div>';
}

function renderActivityTable(rows) {
  if (!rows || !rows.length) return emptyState('No recent activity yet.');
  var body = rows.map(function (a) {
    return '<tr><td><span class="badge info">payment</span></td><td>' + money(a.amount) + '</td><td class="cell-dim">' + fmtDate(a.created_at) + '</td></tr>';
  }).join('');
  return '<table><thead><tr><th>Type</th><th>Amount</th><th>Date</th></tr></thead><tbody>' + body + '</tbody></table>';
}

renderDashboard();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
