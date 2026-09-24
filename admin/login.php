<?php
require_once __DIR__ . '/_bootstrap.php';

if (admin_is_logged_in()) {
    header('Location: /admin/index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($email === '' || $password === '') {
        $error = 'Enter your email and password.';
    } else {
        $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        $loginUrl = $scheme . '://' . $_SERVER['HTTP_HOST'] . '/api/auth/login.php';

        $ch = curl_init($loginUrl);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            CURLOPT_POSTFIELDS => json_encode(['email' => $email, 'password' => $password]),
            CURLOPT_TIMEOUT => 15,
        ]);
        $raw = curl_exec($ch);
        $curlErr = curl_error($ch);
        curl_close($ch);

        $result = $raw ? json_decode($raw, true) : null;

        if ($curlErr) {
            $error = 'Could not reach the API. ' . $curlErr;
        } elseif (!$result || !$result['success']) {
            $error = $result['message'] ?? 'Invalid credentials.';
        } elseif ($result['data']['role'] !== 'admin') {
            $error = 'This account does not have admin access.';
        } else {
            $_SESSION['admin_token'] = $result['data']['token'];
            $_SESSION['admin_user'] = $result['data']['user'];
            header('Location: /admin/index.php');
            exit;
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sign in — Masked Party Admin</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600&family=Inter:wght@400;500;600;700&display=swap');

:root {
  --bg: #fdfbfc;
  --panel: #ffffff;
  --panel-2: #fff5fa;
  --line: #f0dce8;
  --text: #221a20;
  --text-dim: #6b5c65;
  --text-faint: #9c8a94;
  --pink: #ff1e7d;
  --pink-hi: #ff4d97;
  --danger: #e0335a;
  --danger-bg: #fde8ee;
  --radius: 12px;
  --radius-sm: 8px;
  --shadow: 0 10px 30px rgba(216, 30, 110, 0.08), 0 2px 8px rgba(0,0,0,0.04);
  --font-display: 'Fraunces', Georgia, serif;
  --font-body: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
}
* { box-sizing: border-box; }
html, body { height: 100%; margin: 0; }
body {
  background: var(--bg);
  background-image:
    radial-gradient(900px 480px at 90% -8%, rgba(255,30,125,0.06), transparent 60%),
    radial-gradient(700px 420px at -5% 105%, rgba(255,30,125,0.04), transparent 55%);
  background-attachment: fixed;
  color: var(--text);
  font-family: var(--font-body);
  font-size: 14px;
  -webkit-font-smoothing: antialiased;
}
.login-shell {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;
  position: relative;
  overflow: hidden;
}
.login-shell::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image: radial-gradient(circle at 1px 1px, rgba(255,30,125,0.08) 1px, transparent 0);
  background-size: 28px 28px;
  pointer-events: none;
}
.login-card {
  position: relative;
  width: 100%;
  max-width: 380px;
  background: var(--panel);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  padding: 40px 36px 32px;
  box-shadow: var(--shadow);
}
.login-mark {
  width: 46px; height: 46px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--pink-hi), var(--pink));
  display: grid; place-items: center;
  margin: 0 auto 20px;
  color: #fff;
  box-shadow: 0 6px 16px rgba(255,30,125,0.35);
}
.login-mark svg { width: 20px; height: 20px; }
.login-title {
  font-family: var(--font-display);
  font-weight: 600;
  font-size: 22px;
  text-align: center;
  margin: 0 0 4px;
}
.login-sub {
  text-align: center;
  color: var(--text-faint);
  font-size: 12.5px;
  margin: 0 0 28px;
  letter-spacing: 0.3px;
  text-transform: uppercase;
}
.field { margin-bottom: 16px; }
.field label {
  display: block;
  font-size: 12px;
  color: var(--text-dim);
  margin-bottom: 6px;
  font-weight: 600;
}
.field input {
  width: 100%;
  background: var(--panel-2);
  border: 1.5px solid var(--line);
  color: var(--text);
  padding: 11px 13px;
  border-radius: var(--radius-sm);
  font-size: 14px;
  font-family: var(--font-body);
  transition: border-color .15s ease, background .15s ease;
}
.field input:focus { outline: none; border-color: var(--pink); background: #fff; }
.btn-primary {
  width: 100%;
  background: linear-gradient(180deg, var(--pink-hi), var(--pink));
  color: #fff;
  border: none;
  padding: 12px;
  border-radius: var(--radius-sm);
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  margin-top: 6px;
  box-shadow: 0 6px 16px rgba(255,30,125,0.3);
  transition: filter .15s ease, transform .05s ease;
}
.btn-primary:hover { filter: brightness(1.06); }
.btn-primary:active { transform: translateY(1px); }
.btn-primary:disabled { opacity: 0.5; cursor: not-allowed; box-shadow: none; }
.login-error {
  background: var(--danger-bg);
  border: 1px solid #f5c1cf;
  color: var(--danger);
  font-size: 13px;
  padding: 10px 12px;
  border-radius: var(--radius-sm);
  margin-bottom: 16px;
  font-weight: 500;
}
</style>
</head>
<body>
<div class="login-shell">
  <div class="login-card">
    <div class="login-mark">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3c-4 0-7 2.5-7 6.5 0 2 .8 3.3 1.6 4.3.5.6.9 1.1.9 2.2v1c0 1.1.9 2 2 2h.5c.3 0 .5.2.5.5v.5c0 .5.4 1 1 1h1.5c.3 0 .5-.2.5-.5v-1c0-.3.2-.5.5-.5s.5.2.5.5v1c0 .3.2.5.5.5H16c.6 0 1-.5 1-1v-.5c0-.3.2-.5.5-.5h.5c1.1 0 2-.9 2-2v-1c0-1.1.4-1.6.9-2.2.8-1 1.6-2.3 1.6-4.3C21.5 5.5 18.5 3 14.5 3"/><circle cx="9" cy="10.5" r="1"/><circle cx="15" cy="10.5" r="1"/></svg>
    </div>
    <h1 class="login-title">Masked Party</h1>
    <p class="login-sub">Admin Control Panel</p>

    <?php if ($error): ?>
      <div class="login-error"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <form method="POST" autocomplete="off" id="loginForm">
      <div class="field">
        <label for="email">Admin email</label>
        <input type="email" id="email" name="email" placeholder="you@company.com" required value="<?= htmlspecialchars($_POST['email'] ?? '') ?>">
      </div>
      <div class="field">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" placeholder="••••••••" required>
      </div>
      <button type="submit" class="btn-primary" id="submitBtn">Sign in</button>
    </form>
  </div>
</div>
<script>
document.getElementById('loginForm').addEventListener('submit', function () {
  var btn = document.getElementById('submitBtn');
  btn.disabled = true;
  btn.textContent = 'Signing in…';
});
</script>
</body>
</html>
