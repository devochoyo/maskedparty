<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'reports';
$pageTitle  = 'Reports';
$pageSub    = 'User-submitted reports awaiting review';

require __DIR__ . '/_partials/head.php';
?>
<script>
var repState = { status: 'pending' };

function renderReports() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div class="card">' +
      '<div class="card-head">' +
        '<h3>User reports</h3>' +
        '<div class="tabs" id="repTabs">' +
          tabBtn('pending', repState.status) + tabBtn('resolved', repState.status) + tabBtn('dismissed', repState.status) + tabBtn('all', repState.status) +
        '</div>' +
      '</div>' +
      '<div class="card-body" id="repList"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>';

  document.getElementById('repTabs').addEventListener('click', function (e) {
    var tab = e.target.closest('.tab');
    if (!tab) return;
    repState.status = tab.dataset.val;
    renderReports();
  });

  loadReports();
}

function loadReports() {
  var wrap = document.getElementById('repList');
  api('admin/reports.php', { query: { action: 'list', status: repState.status, page: 1 } }).then(function (r) {
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var rows = r.data.reports || [];
    if (!rows.length) { wrap.innerHTML = emptyState('No ' + repState.status + ' reports.'); return; }
    var body = rows.map(function (rep) {
      var actions = rep.status === 'pending'
        ? '<div class="row-actions">' +
            '<button class="btn btn-warn sm" data-act="suspend_user" data-id="' + rep.id + '">Suspend reported</button>' +
            '<button class="btn btn-danger sm" data-act="ban_user" data-id="' + rep.id + '">Ban reported</button>' +
            '<button class="btn btn-ghost sm" data-act="dismiss" data-id="' + rep.id + '">Dismiss</button>' +
          '</div>'
        : '';
      return '<tr>' +
        '<td><strong>' + esc(rep.reported_name) + '</strong><div class="cell-dim">reported by ' + esc(rep.reporter_name) + '</div></td>' +
        '<td>' + esc(rep.reason) + '</td>' +
        '<td>' + statusBadge(rep.status) + '</td>' +
        '<td class="cell-dim">' + fmtDate(rep.created_at) + '</td>' +
        '<td>' + actions + '</td>' +
      '</tr>';
    }).join('');
    wrap.innerHTML = '<table><thead><tr><th>Reported user</th><th>Reason</th><th>Status</th><th>Filed</th><th>Actions</th></tr></thead><tbody>' + body + '</tbody></table>';

    wrap.querySelectorAll('[data-act]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.dataset.id, act = btn.dataset.act;
        var labels = { suspend_user: 'Suspend reported user', ban_user: 'Ban reported user', dismiss: 'Dismiss report' };
        openModal({
          title: labels[act],
          message: 'Add an optional admin note, then confirm.',
          withNote: true,
          confirmLabel: labels[act],
          confirmClass: act === 'ban_user' ? 'btn-danger' : (act === 'suspend_user' ? 'btn-warn' : 'btn-primary-sm'),
          onConfirm: function (note) {
            return api('admin/reports.php', { method: 'POST', query: { action: act, report_id: id }, body: { admin_note: note || '' } }).then(function (r) {
              if (r.success) { toast(r.message, 'success'); loadReports(); refreshBadges(); } else { toast(r.message, 'error'); }
            });
          }
        });
      });
    });
  }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

renderReports();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
