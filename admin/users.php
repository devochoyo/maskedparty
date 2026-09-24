<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'users';
$pageTitle  = 'Users';
$pageSub    = 'Search, review, and moderate accounts';

require __DIR__ . '/_partials/head.php';
?>
<script>
var usersState = { page: 1, search: '', role: '', status: '' };

function renderUsers() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div class="card">' +
      '<div class="card-head">' +
        '<h3>All users</h3>' +
        '<div class="toolbar">' +
          '<input type="text" class="search-input" id="userSearch" placeholder="Search name or email…" value="' + esc(usersState.search) + '">' +
          '<select class="select-input" id="userRoleFilter">' +
            '<option value="">All roles</option>' +
            '<option value="client">Client</option>' +
            '<option value="influencer">Influencer</option>' +
            '<option value="admin">Admin</option>' +
          '</select>' +
          '<select class="select-input" id="userStatusFilter">' +
            '<option value="">All statuses</option>' +
            '<option value="active">Active</option>' +
            '<option value="pending_verification">Pending verification</option>' +
            '<option value="suspended">Suspended</option>' +
            '<option value="banned">Banned</option>' +
          '</select>' +
        '</div>' +
      '</div>' +
      '<div class="card-body" id="usersTableWrap"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>';

  document.getElementById('userRoleFilter').value = usersState.role;
  document.getElementById('userStatusFilter').value = usersState.status;

  var searchEl = document.getElementById('userSearch');
  var debounce;
  searchEl.addEventListener('input', function () {
    clearTimeout(debounce);
    debounce = setTimeout(function () { usersState.search = searchEl.value; usersState.page = 1; loadUsers(); }, 350);
  });
  document.getElementById('userRoleFilter').addEventListener('change', function (e) { usersState.role = e.target.value; usersState.page = 1; loadUsers(); });
  document.getElementById('userStatusFilter').addEventListener('change', function (e) { usersState.status = e.target.value; usersState.page = 1; loadUsers(); });

  loadUsers();
}

function loadUsers() {
  var wrap = document.getElementById('usersTableWrap');
  wrap.innerHTML = '<div class="loading-state"><span class="spinner"></span></div>';
  api('admin/users.php', { query: { action: 'list', page: usersState.page, search: usersState.search, role: usersState.role, status: usersState.status } })
    .then(function (r) {
      if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
      var rows = r.data.users || [];
      if (!rows.length) { wrap.innerHTML = emptyState('No users match those filters.'); return; }
      var body = rows.map(function (u) {
        var actions = '';
        if (u.status !== 'active') actions += '<button class="btn btn-ok sm" data-act="activate" data-id="' + u.id + '">Activate</button>';
        if (u.status !== 'suspended') actions += '<button class="btn btn-warn sm" data-act="suspend" data-id="' + u.id + '">Suspend</button>';
        if (u.status !== 'banned') actions += '<button class="btn btn-danger sm" data-act="ban" data-id="' + u.id + '">Ban</button>';
        return '<tr>' +
          '<td><strong>' + esc(u.mystery_name) + '</strong><div class="cell-dim">' + esc(u.full_name || '') + '</div></td>' +
          '<td class="cell-dim">' + esc(u.email) + '</td>' +
          '<td><span class="badge info">' + esc(u.role) + '</span></td>' +
          '<td class="cell-dim">' + esc(u.country_name || '—') + '</td>' +
          '<td>' + statusBadge(u.status) + '</td>' +
          '<td class="cell-dim">' + fmtDate(u.created_at) + '</td>' +
          '<td><div class="row-actions">' + actions + '</div></td>' +
        '</tr>';
      }).join('');
      wrap.innerHTML =
        '<table><thead><tr><th>Name</th><th>Email</th><th>Role</th><th>Country</th><th>Status</th><th>Joined</th><th>Actions</th></tr></thead><tbody>' + body + '</tbody></table>' +
        '<div class="pager">' +
          '<div class="pager-info">Page ' + usersState.page + '</div>' +
          '<div class="pager-btns"><button class="btn sm" id="userPrev"' + (usersState.page <= 1 ? ' disabled' : '') + '>Previous</button><button class="btn sm" id="userNext"' + (rows.length < 20 ? ' disabled' : '') + '>Next</button></div>' +
        '</div>';

      var prev = document.getElementById('userPrev'), next = document.getElementById('userNext');
      if (prev) prev.onclick = function () { usersState.page--; loadUsers(); };
      if (next) next.onclick = function () { usersState.page++; loadUsers(); };

      wrap.querySelectorAll('[data-act]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          var id = btn.dataset.id, act = btn.dataset.act;
          var labels = { activate: 'Activate user', suspend: 'Suspend user', ban: 'Ban user' };
          var verbs = { activate: 'reactivate this account', suspend: 'temporarily suspend this account', ban: 'permanently ban this account' };
          openModal({
            title: labels[act],
            message: 'This will ' + verbs[act] + '. Continue?',
            confirmLabel: labels[act],
            confirmClass: act === 'activate' ? 'btn-ok' : (act === 'ban' ? 'btn-danger' : 'btn-warn'),
            onConfirm: function () {
              return api('admin/users.php', { method: 'POST', query: { action: act, user_id: id } }).then(function (r) {
                if (r.success) { toast(r.message, 'success'); loadUsers(); } else { toast(r.message, 'error'); }
              });
            }
          });
        });
      });
    }).catch(function (e) { wrap.innerHTML = errorBlock(e.message); });
}

renderUsers();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
