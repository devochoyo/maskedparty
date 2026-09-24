<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'call-minute-costs';
$pageTitle  = 'Call Minute Costs';
$pageSub    = 'Set how many coins a call costs per minute';

require __DIR__ . '/_partials/head.php';
?>
<script>
function renderMinuteCosts() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div class="card">' +
      '<div class="card-head"><h3>Call minute costs</h3><button class="btn btn-primary-sm sm" id="newCostBtn">+ New cost</button></div>' +
      '<div class="card-body" id="costList"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>';

  document.getElementById('newCostBtn').addEventListener('click', function () { openCostForm(null); });
  loadMinuteCosts();
  loadPaygPricing();
}

function loadPaygPricing() {
  var wrap = document.getElementById('paygPricing');
  api('admin/payg-pricing.php', { query: { action: 'list' } }).then(function (r) {
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var p = r.data.pricing;
    wrap.innerHTML =
      '<div class="toolbar" style="justify-content:space-between; width:100%;">' +
        '<div style="display:grid;grid-template-columns:repeat(2,minmax(180px,1fr));gap:14px;flex:1;">' +
          '<div><label class="field-label">Pay per minute (coins/minute)</label><input class="field-input" id="paygPerMinute" type="number" min="0.0001" step="0.0001" value="' + esc(p.per_minute) + '"></div>' +
          '<div><label class="field-label">Pay per second (coins/second)</label><input class="field-input" id="paygPerSecond" type="number" min="0.0001" step="0.0001" value="' + esc(p.per_second) + '"></div>' +
        '</div>' +
        '<button class="btn btn-primary-sm" id="savePaygBtn">Save pricing</button>' +
      '</div>' +
      '<div class="dim" style="margin-top:10px;font-size:12px;">Rates are snapshotted when a Pay As You Go call starts and are used for that call.</div>';
    document.getElementById('savePaygBtn').onclick = function () {
      var btn = this;
      var body = {
        per_minute: parseFloat(document.getElementById('paygPerMinute').value),
        per_second: parseFloat(document.getElementById('paygPerSecond').value)
      };
      if (!(body.per_minute > 0) || !(body.per_second > 0)) {
        toast('Both Pay As You Go rates must be greater than zero.', 'error');
        return;
      }
      btn.disabled = true; btn.textContent = 'Saving…';
      api('admin/payg-pricing.php', { method: 'POST', query: { action: 'update' }, body: body }).then(function (save) {
        if (save.success) toast(save.message, 'success');
        else toast(save.message, 'error');
        btn.disabled = false; btn.textContent = 'Save pricing';
      }).catch(function (e) {
        toast(e.message, 'error');
        btn.disabled = false; btn.textContent = 'Save pricing';
      });
    };
  }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

function loadMinuteCosts() {
  var wrap = document.getElementById('costList');
  api('admin/call-minute-costs.php', { query: { action: 'list' } }).then(function (r) {
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var rows = r.data.costs || [];
    if (!rows.length) { wrap.innerHTML = emptyState('No call minute costs yet. Add one, e.g. 1 minute = 10 coins.'); return; }
    var body = rows.map(function (row) {
      var rate = (Number(row.coin_cost) / Number(row.minutes)).toFixed(2);
      return '<tr>' +
        '<td><strong>' + esc(row.minutes) + '</strong> min</td>' +
        '<td>' + esc(row.coin_cost) + ' coins</td>' +
        '<td>' + rate + ' coins/min</td>' +
        '<td>' + (Number(row.is_active) ? '<span class="badge ok">Active</span>' : '<span class="badge neutral">Disabled</span>') + '</td>' +
        '<td><div class="row-actions">' +
          '<button class="btn sm" data-edit="' + row.id + '">Edit</button>' +
          (Number(row.is_active)
            ? '<button class="btn btn-warn sm" data-toggle="disable" data-id="' + row.id + '">Disable</button>'
            : '<button class="btn btn-ok sm" data-toggle="enable" data-id="' + row.id + '">Enable</button>') +
          '<button class="btn btn-warn sm" data-delete="' + row.id + '">Delete</button>' +
        '</div></td>' +
      '</tr>';
    }).join('');
    wrap.innerHTML = '<table><thead><tr><th>Minutes</th><th>Coin cost</th><th>Rate</th><th>Status</th><th>Actions</th></tr></thead><tbody>' + body + '</tbody></table>';

    wrap.querySelectorAll('[data-edit]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var row = rows.find(function (r) { return String(r.id) === btn.dataset.edit; });
        openCostForm(row);
      });
    });
    wrap.querySelectorAll('[data-toggle]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        api('admin/call-minute-costs.php', { method: 'POST', query: { action: btn.dataset.toggle, cost_id: btn.dataset.id } }).then(function (r) {
          if (r.success) { toast(r.message, 'success'); loadMinuteCosts(); } else { toast(r.message, 'error'); }
        });
      });
    });
    wrap.querySelectorAll('[data-delete]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        if (!confirm('Delete this cost tier? This cannot be undone.')) return;
        api('admin/call-minute-costs.php', { method: 'POST', query: { action: 'delete', cost_id: btn.dataset.id } }).then(function (r) {
          if (r.success) { toast(r.message, 'success'); loadMinuteCosts(); } else { toast(r.message, 'error'); }
        });
      });
    });
  }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

function openCostForm(row) {
  var isEdit = !!row;
  var root = document.getElementById('modal-root');
  root.innerHTML =
    '<div class="modal-backdrop" id="costBackdrop">' +
      '<div class="modal">' +
        '<div class="modal-head"><h4>' + (isEdit ? 'Edit cost' : 'New cost') + '</h4><button class="modal-close" id="costCloseBtn">&times;</button></div>' +
        '<div class="modal-body">' +
          field('Minutes', 'costMinutes', 'number', isEdit ? row.minutes : '') +
          field('Coin cost', 'costCoins', 'number', isEdit ? row.coin_cost : '') +
          field('Display order', 'costOrder', 'number', isEdit ? row.display_order : '0') +
        '</div>' +
        '<div class="modal-foot"><button class="btn" id="costCancelBtn">Cancel</button><button class="btn btn-primary-sm" id="costSaveBtn">' + (isEdit ? 'Save changes' : 'Create cost') + '</button></div>' +
      '</div>' +
    '</div>';

  function close() { root.innerHTML = ''; }
  document.getElementById('costCloseBtn').onclick = close;
  document.getElementById('costCancelBtn').onclick = close;
  document.getElementById('costBackdrop').onclick = function (e) { if (e.target.id === 'costBackdrop') close(); };
  document.getElementById('costSaveBtn').onclick = function () {
    var body = {
      minutes: parseInt(document.getElementById('costMinutes').value, 10),
      coin_cost: parseFloat(document.getElementById('costCoins').value),
      display_order: parseInt(document.getElementById('costOrder').value || '0', 10)
    };
    if (!(body.minutes > 0) || !(body.coin_cost > 0)) {
      toast('Fill in minutes and coin cost.', 'error');
      return;
    }
    var btn = document.getElementById('costSaveBtn');
    btn.disabled = true; btn.textContent = 'Saving…';
    var query = isEdit ? { action: 'update', cost_id: row.id } : { action: 'create' };
    api('admin/call-minute-costs.php', { method: 'POST', query: query, body: body }).then(function (r) {
      if (r.success) { toast(r.message, 'success'); close(); loadMinuteCosts(); }
      else { toast(r.message, 'error'); btn.disabled = false; btn.textContent = isEdit ? 'Save changes' : 'Create cost'; }
    });
  };
}

function field(label, id, type, value) {
  return '<label class="field-label">' + esc(label) + '</label><input class="field-input" type="' + type + '" id="' + id + '" value="' + esc(value) + '" style="margin-bottom:12px;">';
}

renderMinuteCosts();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
