<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'pay-as-you-go';
$pageTitle  = 'Pay as you go';
$pageSub    = 'Set the coin rate clients are charged for Pay As You Go calls';

require __DIR__ . '/_partials/head.php';
?>
<script>
function renderPayg() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div class="card">' +
      '<div class="card-head"><div><h3>Pay As You Go pricing</h3><div class="dim" style="margin-top:4px;font-size:12px;">These rates are separate from the normal call minute-cost tiers.</div></div></div>' +
      '<div class="card-body pad" id="paygBody"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>' +
    '<div class="card">' +
      '<div class="card-head"><h3>How it works</h3></div>' +
      '<div class="card-body pad">' +
        '<div class="dim" style="font-size:13px;line-height:1.7;">' +
          '<p style="margin:0 0 8px;"><strong>Pay per minute:</strong> the client is billed using the configured coins-per-minute rate for the actual minutes used.</p>' +
          '<p style="margin:0 0 8px;"><strong>Pay per second:</strong> the client is billed using the configured coins-per-second rate for the actual seconds used.</p>' +
          '<p style="margin:0;">Rates are snapshotted when a Pay As You Go call starts, so changing the settings will not change an active call.</p>' +
        '</div>' +
      '</div>' +
    '</div>';
  loadPricing();
}

function loadPricing() {
  var wrap = document.getElementById('paygBody');
  api('admin/payg-pricing.php', { query: { action: 'list' } }).then(function (r) {
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var p = r.data.pricing || {};
    wrap.innerHTML =
      '<div class="toolbar" style="width:100%;align-items:flex-end;">' +
        '<div style="flex:1;min-width:220px;">' +
          '<label class="field-label">Pay per minute — coins per minute</label>' +
          '<input class="field-input" id="paygPerMinute" type="number" min="0.0001" step="0.0001" value="' + esc(p.per_minute) + '">' +
          '<div class="dim" style="font-size:11px;margin-top:5px;">Example: 5 means 5 coins for each minute.</div>' +
        '</div>' +
        '<div style="flex:1;min-width:220px;">' +
          '<label class="field-label">Pay per second — coins per second</label>' +
          '<input class="field-input" id="paygPerSecond" type="number" min="0.0001" step="0.0001" value="' + esc(p.per_second) + '">' +
          '<div class="dim" style="font-size:11px;margin-top:5px;">Decimal values such as 0.25 or 0.5 are supported.</div>' +
        '</div>' +
        '<button class="btn btn-primary-sm" id="savePaygBtn">Save pricing</button>' +
      '</div>';

    document.getElementById('savePaygBtn').onclick = savePricing;
  }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

function savePricing() {
  var btn = document.getElementById('savePaygBtn');
  var minute = parseFloat(document.getElementById('paygPerMinute').value);
  var second = parseFloat(document.getElementById('paygPerSecond').value);
  if (!Number.isFinite(minute) || minute <= 0 || !Number.isFinite(second) || second <= 0) {
    toast('Enter valid Pay As You Go rates greater than zero.', 'error');
    return;
  }
  btn.disabled = true;
  btn.textContent = 'Saving…';
  api('admin/payg-pricing.php', {
    method: 'POST',
    query: { action: 'update' },
    body: { per_minute: minute, per_second: second }
  }).then(function (r) {
    if (r.success) toast(r.message || 'Pay As You Go pricing updated.', 'success');
    else toast(r.message || 'Unable to save pricing.', 'error');
    btn.disabled = false;
    btn.textContent = 'Save pricing';
  }).catch(function (e) {
    toast(e.message, 'error');
    btn.disabled = false;
    btn.textContent = 'Save pricing';
  });
}

renderPayg();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
