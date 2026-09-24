<?php
require_once __DIR__ . '/_bootstrap.php';
admin_require_login();

$admin      = admin_current_user();
$activePage = 'support';
$pageTitle  = 'Support Team';
$pageSub    = 'Manage customer care agents, credentials, and feedback ratings';

require __DIR__ . '/_partials/head.php';
?>
<script>
/* ─────────────────────────────────────────────────────────────────────
 * Support screen — three tabs:
 *   Agents      — list, add, view credentials, suspend / activate
 *   Feedback    — all submitted customer feedback, filterable by agent
 *   Conversations — live / recent support conversations with status
 * ─────────────────────────────────────────────────────────────────────*/

var supportTab = 'agents'; // agents | feedback | conversations

/* ── ENTRY POINT ─────────────────────────────────────────────────────*/
function renderSupport() {
  var c = document.getElementById('content');
  c.innerHTML =
    '<div style="display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:20px;flex-wrap:wrap;">' +
      '<div class="tabs" id="supportTabs">' +
        '<div class="tab active" data-tab="agents">Agents</div>' +
        '<div class="tab" data-tab="feedback">Feedback</div>' +
        '<div class="tab" data-tab="conversations">Conversations</div>' +
      '</div>' +
      '<button class="btn btn-primary-sm" id="addAgentBtn">' +
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:13px;height:13px;"><path d="M12 5v14M5 12h14"/></svg>' +
        'Add Support Agent' +
      '</button>' +
    '</div>' +
    '<div id="supportPanel"></div>';

  document.getElementById('addAgentBtn').onclick = openAddAgentModal;

  document.getElementById('supportTabs').querySelectorAll('.tab').forEach(function (t) {
    t.onclick = function () {
      document.querySelectorAll('#supportTabs .tab').forEach(function (x) { x.classList.remove('active'); });
      t.classList.add('active');
      supportTab = t.dataset.tab;
      loadSupportPanel();
    };
  });

  loadSupportPanel();
}

function loadSupportPanel() {
  if (supportTab === 'agents')        loadAgents();
  else if (supportTab === 'feedback') loadFeedback();
  else                                loadConversations();
}

/* ── TAB 1: AGENTS ───────────────────────────────────────────────────*/
function loadAgents() {
  var panel = document.getElementById('supportPanel');
  panel.innerHTML = '<div class="card"><div class="card-body"><div class="loading-state"><span class="spinner"></span></div></div></div>';

  api('admin/support.php', { query: { action: 'list' } }).then(function (r) {
    if (!r.success) { panel.innerHTML = errorBlock(r.message); return; }
    var agents = r.data.agents || [];

    if (!agents.length) {
      panel.innerHTML =
        '<div class="card">' +
          '<div class="card-head"><h3>Support Agents</h3></div>' +
          '<div class="card-body">' + emptyState('No support agents yet. Add one above.') + '</div>' +
        '</div>';
      return;
    }

    var rows = agents.map(function (a) {
      var rating    = Number(a.rating) || 0;
      var stars     = renderStars(rating);
      var goodBadge = '<span class="badge ok">' + esc(a.good_feedback) + ' good</span>';
      var badBadge  = Number(a.bad_feedback) > 0
        ? '<span class="badge danger">' + esc(a.bad_feedback) + ' bad</span>'
        : '';

      var actions =
        '<button class="btn btn-info-sm sm" onclick="viewCredentials(' + a.id + ')">View Credentials</button> ';
      if (a.status === 'active') {
        actions += '<button class="btn btn-warn sm" onclick="suspendAgent(' + a.id + ', \'' + esc(a.first_name) + ' ' + esc(a.last_name) + '\')">Suspend</button>';
      } else {
        actions += '<button class="btn btn-ok sm" onclick="activateAgent(' + a.id + ', \'' + esc(a.first_name) + ' ' + esc(a.last_name) + '\')">Activate</button>';
      }

      return '<tr>' +
        '<td><strong>' + esc(a.first_name) + ' ' + esc(a.last_name) + '</strong></td>' +
        '<td class="cell-dim">' + esc(a.email) + '</td>' +
        '<td>' + statusBadge(a.status) + '</td>' +
        '<td>' + stars + '</td>' +
        '<td>' + goodBadge + ' ' + badBadge + '</td>' +
        '<td class="cell-dim">' + fmtDate(a.created_at) + '</td>' +
        '<td><div class="row-actions">' + actions + '</div></td>' +
      '</tr>';
    }).join('');

    panel.innerHTML =
      '<div class="card">' +
        '<div class="card-head"><h3>Support Agents <span class="cell-dim" style="font-size:12px;font-weight:400;">' + agents.length + ' total</span></h3></div>' +
        '<div class="card-body">' +
          '<table>' +
            '<thead><tr>' +
              '<th>Name</th><th>Email</th><th>Status</th>' +
              '<th>Rating</th><th>Feedback</th><th>Added</th><th>Actions</th>' +
            '</tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
          '</table>' +
        '</div>' +
      '</div>';
  }).catch(function (e) { document.getElementById('supportPanel').innerHTML = errorBlock(e.message); });
}

function renderStars(rating) {
  // rating is 0–5
  var html = '<span style="display:inline-flex;gap:2px;align-items:center;">';
  for (var i = 1; i <= 5; i++) {
    html += '<svg viewBox="0 0 24 24" fill="' + (i <= rating ? 'var(--warn)' : 'none') + '" stroke="var(--warn)" stroke-width="1.6" style="width:13px;height:13px;">' +
      '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>' +
    '</svg>';
  }
  html += ' <span style="font-size:11px;color:var(--text-faint);font-family:var(--font-mono);">' + rating + '/5</span></span>';
  return html;
}

/* ── ADD AGENT MODAL ─────────────────────────────────────────────────*/
function openAddAgentModal() {
  openModal({
    title: 'Add Support Agent',
    html:
      '<p>Enter the agent\'s details. A unique password will be auto-generated starting with <strong>SUP</strong>.</p>' +
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px;">' +
        '<div><label class="field-label">First Name</label><input class="field-input" id="agentFirstName" placeholder="e.g. Sarah" type="text"></div>' +
        '<div><label class="field-label">Last Name</label><input class="field-input" id="agentLastName" placeholder="e.g. Obi" type="text"></div>' +
      '</div>' +
      '<label class="field-label">Email Address</label>' +
      '<input class="field-input" id="agentEmail" placeholder="support@example.com" type="email">',
    confirmLabel: 'Add Agent',
    confirmClass: 'btn-primary-sm',
    onConfirm: function () {
      var firstName = document.getElementById('agentFirstName').value.trim();
      var lastName  = document.getElementById('agentLastName').value.trim();
      var email     = document.getElementById('agentEmail').value.trim();

      if (!firstName || !lastName || !email) {
        toast('Please fill in all fields.', 'error');
        return Promise.reject();
      }

      return api('admin/support.php', {
        method: 'POST',
        query:  { action: 'add' },
        body:   { first_name: firstName, last_name: lastName, email: email }
      }).then(function (r) {
        if (!r.success) { toast(r.message || 'Failed to add agent.', 'error'); return Promise.reject(); }
        toast('Support agent added successfully!', 'success');
        // Show the view-credentials prompt right after adding
        var agentId = r.data && r.data.support_id;
        loadAgents();
        if (agentId) {
          setTimeout(function () { viewCredentials(agentId); }, 400);
        }
      });
    }
  });
}

/* ── VIEW CREDENTIALS MODAL ──────────────────────────────────────────*/
function viewCredentials(supportId) {
  var root = document.getElementById('modal-root');
  root.innerHTML =
    '<div class="modal-backdrop" id="modalBackdrop">' +
      '<div class="modal" style="max-width:420px;">' +
        '<div class="modal-head"><h4>Agent Credentials</h4><button class="modal-close" id="modalCloseBtn">&times;</button></div>' +
        '<div class="modal-body" id="credBody"><div class="loading-state"><span class="spinner"></span></div></div>' +
      '</div>' +
    '</div>';

  document.getElementById('modalCloseBtn').onclick = function () { root.innerHTML = ''; };
  document.getElementById('modalBackdrop').onclick  = function (e) { if (e.target.id === 'modalBackdrop') root.innerHTML = ''; };

  api('admin/support.php', { query: { action: 'view-credentials', support_id: supportId } })
    .then(function (r) {
      var body = document.getElementById('credBody');
      if (!body) return;
      if (!r.success) { body.innerHTML = errorBlock(r.message); return; }
      var d = r.data;
      body.innerHTML =
        '<p style="margin-bottom:16px;">Share these credentials with the agent so they can log in to the Support App.</p>' +
        '<div class="bank-detail-row">' +
          '<span class="bank-detail-label">Email</span>' +
          '<span class="bank-detail-value" style="font-size:13px;">' + esc(d.email) + '</span>' +
        '</div>' +
        '<div class="bank-detail-row">' +
          '<span class="bank-detail-label">Password</span>' +
          '<span class="bank-detail-value" id="credPassDisplay" style="letter-spacing:2px;">' + esc(d.password) + '</span>' +
        '</div>' +
        '<div style="display:flex;gap:8px;margin-top:16px;">' +
          '<button class="btn w-100" onclick="copyToClipboard(\'' + esc(d.email) + '\', \'Email copied\')">' +
            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" style="width:13px;height:13px;"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>' +
            'Copy Email' +
          '</button>' +
          '<button class="btn w-100" onclick="copyToClipboard(\'' + esc(d.password) + '\', \'Password copied\')">' +
            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" style="width:13px;height:13px;"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>' +
            'Copy Password' +
          '</button>' +
        '</div>';
    }).catch(function (e) {
      var body = document.getElementById('credBody');
      if (body) body.innerHTML = errorBlock(e.message);
    });
}

function copyToClipboard(text, label) {
  navigator.clipboard.writeText(text).then(function () {
    toast(label || 'Copied!', 'success');
  }).catch(function () {
    toast('Could not copy. Please copy manually.', 'error');
  });
}

/* ── SUSPEND / ACTIVATE ──────────────────────────────────────────────*/
function suspendAgent(id, name) {
  openModal({
    title: 'Suspend Agent',
    message: 'Suspend ' + name + '? They will not be able to log in to the support app.',
    confirmLabel: 'Suspend',
    confirmClass: 'btn-danger',
    onConfirm: function () {
      return api('admin/support.php', { method: 'POST', query: { action: 'suspend', support_id: id } })
        .then(function (r) {
          if (!r.success) { toast(r.message, 'error'); return Promise.reject(); }
          toast(name + ' has been suspended.', 'success');
          loadAgents();
        });
    }
  });
}

function activateAgent(id, name) {
  openModal({
    title: 'Activate Agent',
    message: 'Reactivate ' + name + '? They will regain access to the support app.',
    confirmLabel: 'Activate',
    confirmClass: 'btn-ok',
    onConfirm: function () {
      return api('admin/support.php', { method: 'POST', query: { action: 'activate', support_id: id } })
        .then(function (r) {
          if (!r.success) { toast(r.message, 'error'); return Promise.reject(); }
          toast(name + ' has been reactivated.', 'success');
          loadAgents();
        });
    }
  });
}

/* ── TAB 2: FEEDBACK ─────────────────────────────────────────────────*/
var feedbackFilter = '';

function loadFeedback() {
  var panel = document.getElementById('supportPanel');
  panel.innerHTML = '<div class="card"><div class="card-body"><div class="loading-state"><span class="spinner"></span></div></div></div>';

  // First load agents list for the filter dropdown, then load feedback
  api('admin/support.php', { query: { action: 'list' } }).then(function (agentsRes) {
    var agents = (agentsRes.success && agentsRes.data && agentsRes.data.agents) ? agentsRes.data.agents : [];

    var agentOptions = '<option value="">All Agents</option>' +
      agents.map(function (a) {
        return '<option value="' + a.id + '"' + (feedbackFilter == a.id ? ' selected' : '') + '>' +
          esc(a.first_name + ' ' + a.last_name) + '</option>';
      }).join('');

    panel.innerHTML =
      '<div class="card">' +
        '<div class="card-head">' +
          '<h3>Customer Feedback</h3>' +
          '<div class="toolbar">' +
            '<select class="select-input" id="feedbackAgentFilter">' + agentOptions + '</select>' +
          '</div>' +
        '</div>' +
        '<div class="card-body" id="feedbackTableWrap"><div class="loading-state"><span class="spinner"></span></div></div>' +
      '</div>';

    document.getElementById('feedbackAgentFilter').onchange = function (e) {
      feedbackFilter = e.target.value;
      fetchFeedback();
    };

    fetchFeedback();
  }).catch(function (e) { panel.innerHTML = errorBlock(e.message); });
}

function fetchFeedback() {
  var wrap = document.getElementById('feedbackTableWrap');
  if (!wrap) return;
  wrap.innerHTML = '<div class="loading-state"><span class="spinner"></span></div>';

  var query = { action: 'feedback' };
  if (feedbackFilter) query.support_id = feedbackFilter;

  api('admin/support.php', { query: query }).then(function (r) {
    wrap = document.getElementById('feedbackTableWrap');
    if (!wrap) return;
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var rows = r.data.feedback || [];
    if (!rows.length) { wrap.innerHTML = emptyState('No feedback submitted yet.'); return; }

    var body = rows.map(function (f) {
      var isBad = !f.satisfied || !f.issue_resolved || !f.professional;
      var sentiment = isBad
        ? '<span class="badge danger">Negative</span>'
        : '<span class="badge ok">Positive</span>';

      var checks =
        checkIcon(f.satisfied, 'Satisfied') +
        checkIcon(f.issue_resolved, 'Issue resolved') +
        checkIcon(f.professional, 'Professional');

      return '<tr>' +
        '<td>' + esc((f.customer_name || 'Unknown customer')) + '<div class="cell-dim" style="font-size:11px;">' + esc(f.customer_role || '') + '</div></td>' +
        '<td>' + esc(f.agent_name || '—') + '</td>' +
        '<td>' + sentiment + '</td>' +
        '<td>' + checks + '</td>' +
        '<td class="cell-dim" style="max-width:200px;white-space:normal;">' + esc(f.feedback_text || '—') + '</td>' +
        '<td class="cell-dim">' + fmtDate(f.created_at) + '</td>' +
      '</tr>';
    }).join('');

    wrap.innerHTML =
      '<table>' +
        '<thead><tr>' +
          '<th>Customer</th><th>Agent</th><th>Sentiment</th>' +
          '<th>Ratings</th><th>Comment</th><th>Date</th>' +
        '</tr></thead>' +
        '<tbody>' + body + '</tbody>' +
      '</table>';
  }).catch(function (e) {
    var w = document.getElementById('feedbackTableWrap');
    if (w) w.innerHTML = errorBlock(e.message);
  });
}

function checkIcon(val, label) {
  var ok = val == 1 || val === true || val === '1';
  var color = ok ? 'var(--ok)' : 'var(--danger)';
  var icon  = ok
    ? '<path d="M20 6L9 17l-5-5"/>'
    : '<path d="M18 6L6 18M6 6l12 12"/>';
  return '<span title="' + esc(label) + '" style="display:inline-flex;align-items:center;gap:3px;margin-right:6px;font-size:11px;color:' + color + ';">' +
    '<svg viewBox="0 0 24 24" fill="none" stroke="' + color + '" stroke-width="2.2" style="width:12px;height:12px;">' + icon + '</svg>' +
    esc(label) +
  '</span>';
}

/* ── TAB 3: CONVERSATIONS ────────────────────────────────────────────*/
var convPage = 1;

function loadConversations() {
  var panel = document.getElementById('supportPanel');
  panel.innerHTML =
    '<div class="card">' +
      '<div class="card-head">' +
        '<h3>Support Conversations</h3>' +
        '<div class="toolbar">' +
          '<select class="select-input" id="convStatusFilter">' +
            '<option value="">All statuses</option>' +
            '<option value="pending">Pending</option>' +
            '<option value="active">Active</option>' +
            '<option value="resolved">Resolved</option>' +
          '</select>' +
        '</div>' +
      '</div>' +
      '<div class="card-body" id="convTableWrap"><div class="loading-state"><span class="spinner"></span></div></div>' +
    '</div>';

  document.getElementById('convStatusFilter').onchange = function (e) {
    convPage = 1;
    fetchConversations(e.target.value);
  };

  fetchConversations('');
}

function fetchConversations(statusFilter) {
  var wrap = document.getElementById('convTableWrap');
  if (!wrap) return;
  wrap.innerHTML = '<div class="loading-state"><span class="spinner"></span></div>';

  var query = { action: 'conversations', page: convPage };
  if (statusFilter) query.status = statusFilter;

  api('admin/support.php', { query: query }).then(function (r) {
    wrap = document.getElementById('convTableWrap');
    if (!wrap) return;
    if (!r.success) { wrap.innerHTML = errorBlock(r.message); return; }
    var convs = r.data.conversations || [];
    if (!convs.length) { wrap.innerHTML = emptyState('No conversations found.'); return; }

    var body = convs.map(function (c) {
      var agentCell = c.agent_name
        ? esc(c.agent_name)
        : '<span class="cell-dim">Unassigned</span>';

      var statusLabel = c.status === 'pending'
        ? '<span class="badge warn">Pending</span>'
        : c.status === 'active'
          ? '<span class="badge ok">Active</span>'
          : '<span class="badge neutral">Resolved</span>';

      return '<tr>' +
        '<td>' + esc(c.customer_name || 'Unknown') + '<div class="cell-dim" style="font-size:11px;">' + esc(c.customer_role || '') + '</div></td>' +
        '<td>' + agentCell + '</td>' +
        '<td>' + statusLabel + '</td>' +
        '<td class="cell-dim">' + esc(c.message_count || 0) + ' msgs</td>' +
        '<td class="cell-dim">' + fmtDate(c.created_at) + '</td>' +
        '<td class="cell-dim">' + (c.resolved_at ? fmtDate(c.resolved_at) : '—') + '</td>' +
      '</tr>';
    }).join('');

    wrap.innerHTML =
      '<table>' +
        '<thead><tr>' +
          '<th>Customer</th><th>Assigned Agent</th><th>Status</th>' +
          '<th>Messages</th><th>Opened</th><th>Resolved</th>' +
        '</tr></thead>' +
        '<tbody>' + body + '</tbody>' +
      '</table>';
  }).catch(function (e) {
    var w = document.getElementById('convTableWrap');
    if (w) w.innerHTML = errorBlock(e.message);
  });
}

/* ── INIT ─────────────────────────────────────────────────────────────*/
renderSupport();
</script>
<?php require __DIR__ . '/_partials/foot.php'; ?>
