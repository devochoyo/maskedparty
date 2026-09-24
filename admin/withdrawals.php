<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'withdrawals';
$pageTitle  = 'Withdrawals';
$pageSub    = 'Approve or reject payout requests';

require __DIR__ . '/_partials/head.php';
?>
<script>
var wdState = { status: 'pending', page: 1 };

function renderWithdrawals() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div class="card">' +
      '<div class="card-head">' +
        '<h3>Withdrawal requests</h3>' +
        '<div class="tabs" id="wdTabs">' +
          tabBtn('pending', wdState.status) + tabBtn('completed', wdState.status) + tabBtn('rejected', wdState.status) + tabBtn('all', wdState.status) +
        '</div>' +
      '</div>' +
      '<div class="card-body" id="wdList"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>';

  document.getElementById('wdTabs').addEventListener('click', function (e) {
    var tab = e.target.closest('.tab');
    if (!tab) return;
    wdState.status = tab.dataset.val;
    wdState.page = 1;
    renderWithdrawals();
  });

  loadWithdrawals();
}

function viewWithdrawalDetails(withdrawalId) {
  api('admin/withdrawals.php', { query: { action: 'details', withdrawal_id: withdrawalId } }).then(function (r) {
    if (!r.success) { toast(r.message || 'Failed to load details', 'error'); return; }
    var d = r.data;
    var html =
      '<div style="margin-bottom:16px;">' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Influencer</span><span class="bank-detail-value">' + esc(d.mystery_name || '—') + '</span></div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Email</span><span class="bank-detail-value" style="font-family:var(--font-body);font-size:13px;">' + esc(d.email || '—') + '</span></div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Amount Requested</span><span class="bank-detail-value">' + money(d.amount) + '</span></div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Fee</span><span class="bank-detail-value" style="color:var(--danger)">' + money(d.fee) + '</span></div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Net Amount</span><span class="bank-detail-value" style="color:var(--ok)">' + money(d.net_amount) + '</span></div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Requested</span><span class="bank-detail-value" style="font-family:var(--font-body);font-size:12px;">' + fmtDate(d.created_at) + '</span></div>' +
      '</div>' +
      '<div style="background:var(--panel-2);border:1px solid var(--line);border-radius:var(--radius-sm);padding:14px;margin-top:12px;">' +
        '<div style="font-size:11px;color:var(--text-faint);text-transform:uppercase;letter-spacing:0.5px;font-weight:700;margin-bottom:12px;">🏦 Bank Account Details</div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Bank Name</span><span class="bank-detail-value">' + esc(d.bank_name || 'Not available') + '</span></div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Account Number</span><span class="bank-detail-value">' + esc(d.account_number || 'Not available') + '</span></div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">Account Name</span><span class="bank-detail-value">' + esc(d.account_name || d.full_name || 'Not available') + '</span></div>' +
        '<div class="bank-detail-row"><span class="bank-detail-label">' + esc(d.bank_code_type || 'Bank Code') + '</span><span class="bank-detail-value">' + esc(d.bank_code_value || 'Not available') + '</span></div>' +
      '</div>';

    openModal({
      title: 'Withdrawal Details #' + withdrawalId,
      html: html,
      hideFooter: true,
      width: '550'
    });
  }).catch(function (e) { toast('Failed to load details', 'error'); });
}

function loadWithdrawals() {
  var wrap = document.getElementById('wdList');
  api('admin/withdrawals.php', { query: { action: 'list', status: wdState.status, page: wdState.page } }).then(function (r) {
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var rows = r.data.withdrawals || [];
    if (!rows.length) { wrap.innerHTML = emptyState('No ' + wdState.status + ' withdrawal requests.'); return; }
    var body = rows.map(function (w) {
      var actions = w.status === 'pending'
        ? '<div class="row-actions">' +
            '<button class="btn btn-info-sm sm" data-view="' + w.id + '">👁 View Details</button>' +
            '<button class="btn btn-ok sm" data-act="approve" data-id="' + w.id + '">Approve</button>' +
            '<button class="btn btn-danger sm" data-act="reject" data-id="' + w.id + '">Reject</button>' +
          '</div>'
        : '<span class="cell-dim">' + fmtDate(w.completed_at) + '</span>';
      return '<tr>' +
        '<td><strong>' + esc(w.mystery_name) + '</strong></td>' +
        '<td>' + money(w.amount) + '</td>' +
        '<td class="cell-dim">' + money(w.fee) + '</td>' +
        '<td><strong>' + money(w.net_amount) + '</strong></td>' +
        '<td class="cell-dim">' + esc(w.bank_code_value || '—') + (w.bank_name ? ' <span class="cell-dim">(' + esc(w.bank_name) + ')</span>' : '') + '</td>' +
        '<td>' + statusBadge(w.status) + '</td>' +
        '<td class="cell-dim">' + fmtDate(w.created_at) + '</td>' +
        '<td>' + actions + '</td>' +
      '</tr>';
    }).join('');
    wrap.innerHTML =
      '<table><thead><tr><th>Influencer</th><th>Amount</th><th>Fee</th><th>Net</th><th>Bank Code</th><th>Status</th><th>Requested</th><th>Actions</th></tr></thead><tbody>' + body + '</tbody></table>' +
      '<div class="pager"><div class="pager-info">Page ' + wdState.page + '</div>' +
      '<div class="pager-btns"><button class="btn sm" id="wdPrev"' + (wdState.page <= 1 ? ' disabled' : '') + '>Previous</button><button class="btn sm" id="wdNext"' + (rows.length < 20 ? ' disabled' : '') + '>Next</button></div></div>';

    var prev = document.getElementById('wdPrev'), next = document.getElementById('wdNext');
    if (prev) prev.onclick = function () { wdState.page--; loadWithdrawals(); };
    if (next) next.onclick = function () { wdState.page++; loadWithdrawals(); };

    wrap.querySelectorAll('[data-view]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        viewWithdrawalDetails(btn.dataset.view);
      });
    });

    wrap.querySelectorAll('[data-act]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.dataset.id, act = btn.dataset.act;
        openModal({
          title: act === 'approve' ? 'Approve withdrawal' : 'Reject withdrawal',
          message: act === 'approve'
            ? 'This will deduct the net amount from the influencer\'s wallet and mark the payout as completed. Make sure you\'ve actually sent the funds first.'
            : 'This will reject the request and refund the held amount back to the influencer\'s wallet.',
          withNote: true,
          confirmLabel: act === 'approve' ? 'Approve' : 'Reject',
          confirmClass: act === 'approve' ? 'btn-ok' : 'btn-danger',
          onConfirm: function (note) {
            return api('admin/withdrawals.php', { method: 'POST', query: { action: act, withdrawal_id: id }, body: { admin_note: note || '' } }).then(function (r) {
              if (r.success) { toast(r.message, 'success'); loadWithdrawals(); refreshBadges(); } else { toast(r.message, 'error'); }
            });
          }
        });
      });
    });
  }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

renderWithdrawals();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
