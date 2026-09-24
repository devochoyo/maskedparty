<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'calls';
$pageTitle  = 'Calls';
$pageSub    = 'Track how every call ended and who ended it';

require __DIR__ . '/_partials/head.php';
?>
<script>
var callsState = { page: 1, search: '', endedBy: '' };

function renderCalls() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div class="card">' +
      '<div class="card-head">' +
        '<h3>Call history</h3>' +
        '<div class="toolbar">' +
          '<input type="text" class="search-input" id="callSearch" placeholder="Search influencer, client, or ended by…" value="' + esc(callsState.search) + '">' +
          '<select class="select-input" id="callEndedByFilter">' +
            '<option value="">Ended by: anyone</option>' +
            '<option value="client">Client</option>' +
            '<option value="influencer">Influencer</option>' +
            '<option value="system">System (timeout)</option>' +
          '</select>' +
        '</div>' +
      '</div>' +
      '<div class="card-body" id="callsTableWrap"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>';

  document.getElementById('callEndedByFilter').value = callsState.endedBy;

  var searchEl = document.getElementById('callSearch');
  var debounce;
  searchEl.addEventListener('input', function () {
    clearTimeout(debounce);
    debounce = setTimeout(function () { callsState.search = searchEl.value; callsState.page = 1; loadCalls(); }, 350);
  });
  document.getElementById('callEndedByFilter').addEventListener('change', function (e) {
    callsState.endedBy = e.target.value; callsState.page = 1; loadCalls();
  });

  loadCalls();
}

function loadCalls() {
  var wrap = document.getElementById('callsTableWrap');
  wrap.innerHTML = '<div class="loading-state"><span class="spinner"></span></div>';
  api('admin/call-tracking.php', { query: { action: 'list', page: callsState.page, search: callsState.search, ended_by: callsState.endedBy } })
    .then(function (r) {
      if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
      var rows = r.data.calls || [];
      if (!rows.length) { wrap.innerHTML = emptyState('No ended calls match those filters.'); return; }
      var body = rows.map(function (call) {
        return '<tr>' +
          '<td class="cell-mono">#' + esc(call.call_id) + '</td>' +
          '<td><strong>' + esc(call.influencer_name) + '</strong></td>' +
          '<td>' + esc(call.client_name) + '</td>' +
          '<td>' + endedByBadge(call.ended_by_role) + ' <span class="cell-dim">' + esc(call.ended_by_name) + '</span></td>' +
          '<td class="cell-mono">' + fmtDuration(call.duration_seconds) + '</td>' +
          '<td class="cell-dim">' + fmtDate(call.created_at) + '</td>' +
        '</tr>';
      }).join('');
      wrap.innerHTML =
        '<table><thead><tr><th>Call</th><th>Influencer</th><th>Client</th><th>Ended by</th><th>Duration</th><th>Ended at</th></tr></thead><tbody>' + body + '</tbody></table>' +
        '<div class="pager">' +
          '<div class="pager-info">Page ' + callsState.page + '</div>' +
          '<div class="pager-btns"><button class="btn sm" id="callPrev"' + (callsState.page <= 1 ? ' disabled' : '') + '>Previous</button><button class="btn sm" id="callNext"' + (rows.length < 20 ? ' disabled' : '') + '>Next</button></div>' +
        '</div>';

      var prev = document.getElementById('callPrev'), next = document.getElementById('callNext');
      if (prev) prev.onclick = function () { callsState.page--; loadCalls(); };
      if (next) next.onclick = function () { callsState.page++; loadCalls(); };
    }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

renderCalls();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
