<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'verification';
$pageTitle  = 'Verification';
$pageSub    = 'Review influencer ID and video submissions';

require __DIR__ . '/_partials/head.php';
?>
<script>
var verifState = { status: 'pending' };

function renderVerification() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div class="card">' +
      '<div class="card-head">' +
        '<h3>Influencer verification</h3>' +
        '<div class="tabs" id="verifTabs">' +
          tabBtn('pending', verifState.status) + tabBtn('approved', verifState.status) + tabBtn('rejected', verifState.status) +
        '</div>' +
      '</div>' +
      '<div class="card-body pad" id="verifList"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>';

  document.getElementById('verifTabs').addEventListener('click', function (e) {
    var tab = e.target.closest('.tab');
    if (!tab) return;
    verifState.status = tab.dataset.val;
    renderVerification();
  });

  loadVerifications();
}

function loadVerifications() {
  var wrap = document.getElementById('verifList');
  api('admin/verification.php', { query: { action: 'list', status: verifState.status, page: 1 } }).then(function (r) {
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var rows = r.data.verifications || [];
    if (!rows.length) { wrap.innerHTML = emptyState('No ' + verifState.status + ' verification requests.'); return; }
    wrap.innerHTML = rows.map(function (v) {
      var docs = ['government_id_url', 'selfie_url', 'verification_video_url'].map(function (f) {
        if (!v[f]) return '';
        var isVideo = f === 'verification_video_url';
        return '<div class="doc-thumb">' + (isVideo
          ? '<video src="' + esc(v[f]) + '" muted></video>'
          : '<img src="' + esc(v[f]) + '" loading="lazy">') + '</div>';
      }).join('');
      var actions = verifState.status === 'pending'
        ? '<div class="row-actions">' +
            '<button class="btn btn-ok sm" data-act="approve" data-id="' + v.id + '">Approve</button>' +
            '<button class="btn btn-warn sm" data-act="request_resubmission" data-id="' + v.id + '">Request resubmission</button>' +
            '<button class="btn btn-danger sm" data-act="reject" data-id="' + v.id + '">Reject</button>' +
          '</div>'
        : '';
      return '<div class="card" style="margin-bottom:14px;">' +
        '<div class="card-head"><h3>' + esc(v.mystery_name) + '</h3><span class="cell-dim">' + esc(v.email) + '</span></div>' +
        '<div class="card-body pad">' +
          (v.biography ? '<p class="dim" style="margin:0 0 12px;font-size:13px;">' + esc(v.biography) + '</p>' : '') +
          '<div class="doc-grid">' + (docs || '<span class="dim">No documents submitted.</span>') + '</div>' +
          actions +
        '</div>' +
      '</div>';
    }).join('');

    wrap.querySelectorAll('[data-act]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.dataset.id, act = btn.dataset.act;
        var labels = { approve: 'Approve influencer', reject: 'Reject verification', request_resubmission: 'Request resubmission' };
        openModal({
          title: labels[act],
          message: 'Add an optional note for the influencer, then confirm.',
          withNote: true,
          confirmLabel: labels[act],
          confirmClass: act === 'approve' ? 'btn-ok' : (act === 'reject' ? 'btn-danger' : 'btn-warn'),
          onConfirm: function (note) {
            return api('admin/verification.php', { method: 'POST', query: { action: act, influencer_id: id }, body: { admin_note: note || '' } }).then(function (r) {
              if (r.success) { toast(r.message, 'success'); loadVerifications(); refreshBadges(); } else { toast(r.message, 'error'); }
            });
          }
        });
      });
    });
  }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

renderVerification();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
