<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'packages';
$pageTitle  = 'Coin Packages';
$pageSub    = 'Manage pricing shown in the app';

require __DIR__ . '/_partials/head.php';
?>
<script>
function renderPackages() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div class="card">' +
      '<div class="card-head"><h3>Coin packages</h3><button class="btn btn-primary-sm sm" id="newPkgBtn">+ New package</button></div>' +
      '<div class="card-body" id="pkgList"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>';

  document.getElementById('newPkgBtn').addEventListener('click', function () { openPackageForm(null); });
  loadPackages();
}

function loadPackages() {
  var wrap = document.getElementById('pkgList');
  api('admin/coin-packages.php', { query: { action: 'list' } }).then(function (r) {
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var rows = r.data.packages || [];
    if (!rows.length) { wrap.innerHTML = emptyState('No coin packages yet.'); return; }
    var body = rows.map(function (p) {
      var flags = [];
      if (Number(p.is_popular)) flags.push('<span class="badge info">Popular</span>');
      if (Number(p.is_best_value)) flags.push('<span class="badge ok">Best value</span>');
      return '<tr>' +
        '<td><strong>' + esc(p.name) + '</strong></td>' +
        '<td>' + p.currency + ' ' + Number(p.price).toFixed(2) + '</td>' +
        '<td>' + esc(p.coins) + ' coins</td>' +
        '<td>' + esc(p.minutes) + ' min</td>' +
        '<td>' + (flags.join(' ') || '<span class="dim">—</span>') + '</td>' +
        '<td>' + (Number(p.is_active) ? '<span class="badge ok">Active</span>' : '<span class="badge neutral">Disabled</span>') + '</td>' +
        '<td><div class="row-actions">' +
          '<button class="btn sm" data-edit="' + p.id + '">Edit</button>' +
          (Number(p.is_active)
            ? '<button class="btn btn-warn sm" data-toggle="disable" data-id="' + p.id + '">Disable</button>'
            : '<button class="btn btn-ok sm" data-toggle="enable" data-id="' + p.id + '">Enable</button>') +
        '</div></td>' +
      '</tr>';
    }).join('');
    wrap.innerHTML = '<table><thead><tr><th>Name</th><th>Price</th><th>Coins</th><th>Minutes</th><th>Flags</th><th>Status</th><th>Actions</th></tr></thead><tbody>' + body + '</tbody></table>';

    wrap.querySelectorAll('[data-edit]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var pkg = rows.find(function (p) { return String(p.id) === btn.dataset.edit; });
        openPackageForm(pkg);
      });
    });
    wrap.querySelectorAll('[data-toggle]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        api('admin/coin-packages.php', { method: 'POST', query: { action: btn.dataset.toggle, package_id: btn.dataset.id } }).then(function (r) {
          if (r.success) { toast(r.message, 'success'); loadPackages(); } else { toast(r.message, 'error'); }
        });
      });
    });
  }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

function openPackageForm(pkg) {
  var isEdit = !!pkg;
  var root = document.getElementById('modal-root');
  root.innerHTML =
    '<div class="modal-backdrop" id="pkgBackdrop">' +
      '<div class="modal">' +
        '<div class="modal-head"><h4>' + (isEdit ? 'Edit package' : 'New package') + '</h4><button class="modal-close" id="pkgCloseBtn">&times;</button></div>' +
        '<div class="modal-body">' +
          field('Name', 'pkgName', 'text', isEdit ? pkg.name : '') +
          field('Price (GBP)', 'pkgPrice', 'number', isEdit ? pkg.price : '') +
          field('Coins', 'pkgCoins', 'number', isEdit ? pkg.coins : '') +
          field('Minutes', 'pkgMinutes', 'number', isEdit ? pkg.minutes : '') +
          field('Display order', 'pkgOrder', 'number', isEdit ? pkg.display_order : '0') +
          '<label class="field-label" style="margin-top:10px;"><input type="checkbox" id="pkgPopular"' + (isEdit && Number(pkg.is_popular) ? ' checked' : '') + '> Mark as popular</label><br>' +
          '<label class="field-label"><input type="checkbox" id="pkgBestValue"' + (isEdit && Number(pkg.is_best_value) ? ' checked' : '') + '> Mark as best value</label>' +
        '</div>' +
        '<div class="modal-foot"><button class="btn" id="pkgCancelBtn">Cancel</button><button class="btn btn-primary-sm" id="pkgSaveBtn">' + (isEdit ? 'Save changes' : 'Create package') + '</button></div>' +
      '</div>' +
    '</div>';

  function close() { root.innerHTML = ''; }
  document.getElementById('pkgCloseBtn').onclick = close;
  document.getElementById('pkgCancelBtn').onclick = close;
  document.getElementById('pkgBackdrop').onclick = function (e) { if (e.target.id === 'pkgBackdrop') close(); };
  document.getElementById('pkgSaveBtn').onclick = function () {
    var body = {
      name: document.getElementById('pkgName').value.trim(),
      price: parseFloat(document.getElementById('pkgPrice').value),
      coins: parseInt(document.getElementById('pkgCoins').value, 10),
      minutes: parseInt(document.getElementById('pkgMinutes').value, 10),
      display_order: parseInt(document.getElementById('pkgOrder').value || '0', 10),
      is_popular: document.getElementById('pkgPopular').checked,
      is_best_value: document.getElementById('pkgBestValue').checked
    };
    if (!body.name || !(body.price > 0) || !(body.coins > 0) || !(body.minutes > 0)) {
      toast('Fill in name, price, coins, and minutes.', 'error');
      return;
    }
    var btn = document.getElementById('pkgSaveBtn');
    btn.disabled = true; btn.textContent = 'Saving…';
    var query = isEdit ? { action: 'update', package_id: pkg.id } : { action: 'create' };
    api('admin/coin-packages.php', { method: 'POST', query: query, body: body }).then(function (r) {
      if (r.success) { toast(r.message, 'success'); close(); loadPackages(); }
      else { toast(r.message, 'error'); btn.disabled = false; btn.textContent = isEdit ? 'Save changes' : 'Create package'; }
    });
  };
}

function field(label, id, type, value) {
  return '<label class="field-label">' + esc(label) + '</label><input class="field-input" type="' + type + '" id="' + id + '" value="' + esc(value) + '" style="margin-bottom:12px;">';
}

renderPackages();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
