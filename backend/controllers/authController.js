const crypto = require('crypto');
const nodemailer = require('nodemailer');
const admin = require('firebase-admin');
const PasswordResetToken = require('../models/PasswordResetToken');

// ─── Email transporter ────────────────────────────────────────────────────────
// Gmail: generate an App Password at
//   Google Account → Security → 2-Step Verification → App Passwords
// Then set GMAIL_USER and GMAIL_APP_PASSWORD in your .env
let _transporter;
function getTransporter() {
  if (!_transporter) {
    _transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_APP_PASSWORD,
      },
    });
  }
  return _transporter;
}

const APP_URL = process.env.APP_URL || 'https://geereel.onrender.com';

// ─── POST /api/auth/forgot-password ──────────────────────────────────────────
exports.forgotPassword = async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: 'Email is required.' });

  const normalizedEmail = email.toLowerCase().trim();

  // Always return the same message to prevent email enumeration
  const okMsg = 'If that email is registered you will receive a reset link shortly.';

  let uid;
  try {
    const record = await admin.auth().getUserByEmail(normalizedEmail);
    uid = record.uid;
  } catch {
    return res.json({ message: okMsg });
  }

  // Invalidate any existing unused tokens for this user
  await PasswordResetToken.deleteMany({ uid });

  const token = crypto.randomBytes(32).toString('hex');
  await PasswordResetToken.create({
    uid,
    email: normalizedEmail,
    token,
    expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
  });

  const resetUrl = `${APP_URL}/reset-password?token=${token}`;

  try {
    await getTransporter().sendMail({
      from: `"Geereel" <${process.env.GMAIL_USER}>`,
      to: normalizedEmail,
      subject: 'Reset your Geereel password',
      html: buildResetEmail(resetUrl),
    });
  } catch (err) {
    console.error('Email send error:', err);
    return res.status(500).json({ message: 'Could not send email. Please try again.' });
  }

  res.json({ message: okMsg });
};

// ─── GET /reset-password?token=xxx ───────────────────────────────────────────
exports.getResetPasswordPage = async (req, res) => {
  const { token } = req.query;

  if (!token) {
    return res.send(buildHtmlPage({ state: 'error', error: 'Invalid or missing reset link.' }));
  }

  const record = await PasswordResetToken.findOne({ token });

  if (!record || record.used || record.expiresAt < new Date()) {
    return res.send(buildHtmlPage({
      state: 'error',
      error: 'This link has expired or already been used. Please request a new one.',
    }));
  }

  res.send(buildHtmlPage({ state: 'form', token }));
};

// ─── POST /reset-password ─────────────────────────────────────────────────────
exports.postResetPassword = async (req, res) => {
  const { token, password, confirmPassword } = req.body;

  if (!token || !password) {
    return res.send(buildHtmlPage({ state: 'error', error: 'Missing required fields.' }));
  }

  if (password !== confirmPassword) {
    return res.send(buildHtmlPage({ state: 'form', token, formError: 'Passwords do not match.' }));
  }

  if (password.length < 8) {
    return res.send(buildHtmlPage({ state: 'form', token, formError: 'Password must be at least 8 characters.' }));
  }

  const record = await PasswordResetToken.findOne({ token });

  if (!record || record.used || record.expiresAt < new Date()) {
    return res.send(buildHtmlPage({
      state: 'error',
      error: 'This link has expired or already been used. Please request a new one.',
    }));
  }

  try {
    await admin.auth().updateUser(record.uid, { password });
    record.used = true;
    await record.save();
    return res.send(buildHtmlPage({ state: 'success' }));
  } catch (err) {
    console.error('Password update error:', err);
    return res.send(buildHtmlPage({ state: 'form', token, formError: 'Could not reset password. Please try again.' }));
  }
};

// ─── HTML helpers ─────────────────────────────────────────────────────────────
function buildHtmlPage({ state, token, formError, error }) {
  let content;

  if (state === 'success') {
    content = `
      <div class="icon">✓</div>
      <h2>Password Updated!</h2>
      <p class="subtitle">Your password has been successfully reset. You can now sign in to Geereel with your new password.</p>
      <p class="hint">Return to the app and sign in.</p>`;
  } else if (state === 'error') {
    content = `
      <div class="icon err">✕</div>
      <h2>Link Invalid</h2>
      <p class="subtitle error">${escHtml(error)}</p>`;
  } else {
    content = `
      <h2>Reset Password</h2>
      <p class="subtitle">Enter a new password for your Geereel account.</p>
      ${formError ? `<p class="error">${escHtml(formError)}</p>` : ''}
      <form method="POST" action="/reset-password">
        <input type="hidden" name="token" value="${escHtml(token)}" />
        <div class="field">
          <label>New password</label>
          <input type="password" name="password" placeholder="At least 8 characters" required minlength="8" />
        </div>
        <div class="field">
          <label>Confirm password</label>
          <input type="password" name="confirmPassword" placeholder="Repeat new password" required minlength="8" />
        </div>
        <button type="submit">Reset Password</button>
      </form>`;
  }

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Reset Password · Geereel</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #0E0E10;
      color: #fff;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      background: #1B1B1F;
      border-radius: 20px;
      padding: 40px 32px;
      width: 100%;
      max-width: 420px;
    }
    .logo { color: #FF3B6F; font-size: 26px; font-weight: 800; margin-bottom: 24px; }
    h2 { font-size: 22px; font-weight: 700; margin-bottom: 8px; }
    .subtitle { color: #A0A0A8; font-size: 14px; line-height: 1.6; margin-bottom: 28px; }
    .hint { color: #A0A0A8; font-size: 13px; margin-top: 12px; }
    .icon {
      font-size: 52px;
      color: #2ED573;
      margin-bottom: 16px;
      width: 72px; height: 72px;
      background: rgba(46,213,115,0.12);
      border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
    }
    .icon.err { color: #FF4757; background: rgba(255,71,87,0.12); }
    .field { margin-bottom: 16px; }
    label { display: block; font-size: 12px; color: #A0A0A8; margin-bottom: 6px; letter-spacing: 0.4px; text-transform: uppercase; }
    input[type="password"] {
      width: 100%;
      background: #26262B;
      border: 1px solid transparent;
      border-radius: 12px;
      color: #fff;
      font-size: 15px;
      padding: 14px 16px;
      outline: none;
      transition: border-color 0.2s;
    }
    input[type="password"]:focus { border-color: #FF3B6F; }
    button {
      width: 100%;
      background: #FF3B6F;
      border: none;
      border-radius: 12px;
      color: #fff;
      font-size: 16px;
      font-weight: 700;
      padding: 16px;
      margin-top: 8px;
      cursor: pointer;
      transition: opacity 0.2s;
    }
    button:hover { opacity: 0.88; }
    button:active { opacity: 0.75; }
    .error { color: #FF4757; font-size: 13px; margin-bottom: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">Geereel</div>
    ${content}
  </div>
</body>
</html>`;
}

function buildResetEmail(resetUrl) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0;padding:0;background:#0E0E10;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#1B1B1F;border-radius:20px;padding:40px 32px;">
          <tr><td>
            <p style="color:#FF3B6F;font-size:26px;font-weight:800;margin:0 0 24px;">Geereel</p>
            <h1 style="color:#fff;font-size:22px;font-weight:700;margin:0 0 12px;">Reset your password</h1>
            <p style="color:#A0A0A8;font-size:14px;line-height:1.6;margin:0 0 32px;">
              We received a request to reset the password for your Geereel account.
              Click the button below — the link expires in <strong style="color:#fff;">1 hour</strong>.
            </p>
            <a href="${resetUrl}"
               style="display:block;text-align:center;background:#FF3B6F;color:#fff;font-size:16px;font-weight:700;text-decoration:none;border-radius:12px;padding:16px 32px;margin-bottom:24px;">
              Reset Password
            </a>
            <p style="color:#5C5C63;font-size:12px;line-height:1.5;margin:0;">
              If you didn't request this, you can safely ignore this email.<br/>
              — The Geereel Team
            </p>
          </td></tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function escHtml(str) {
  return (str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
