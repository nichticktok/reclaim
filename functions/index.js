/**
 * Firebase Cloud Functions that back the email one-time-code login flow.
 * Last updated to ensure mailer config loads from env vars.
 */

const { setGlobalOptions } = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');
const crypto = require('node:crypto');
const nodemailer = require('nodemailer');

admin.initializeApp();

setGlobalOptions({
  region: 'us-central1',
  maxInstances: 10,
  memory: '256MiB',
  timeoutSeconds: 30,
});

const db = admin.firestore();
const auth = admin.auth();

const CODE_COLLECTION = 'authMagicCodes';
const CODE_TTL_SECONDS = 10 * 60; // 10 minutes
const MAX_ATTEMPTS = 5;

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// ---------------- MAILER (ENV-ONLY; GEN-2 SAFE) ----------------
let mailTransport = null; // cached per warm instance

function getMailerConfig() {
  const host = process.env.MAILER_HOST;
  const port = Number(process.env.MAILER_PORT || 587);
  const secure = String(process.env.MAILER_SECURE || 'false') === 'true' || port === 465;
  const user = process.env.MAILER_USER;
  const pass = process.env.MAILER_PASS;
  const from = process.env.MAILER_FROM;
  return { host, port, secure, user, pass, from };
}

function isMailerConfigured(cfg) {
  return Boolean(cfg.host && cfg.user && cfg.pass && cfg.from);
}

function getMailTransport(cfg) {
  if (!isMailerConfigured(cfg)) return null;
  if (!mailTransport) {
    mailTransport = nodemailer.createTransport({
      host: cfg.host,
      port: cfg.port,
      secure: cfg.secure, // false for 587 (STARTTLS), true for 465
      auth: { user: cfg.user, pass: cfg.pass },
      // logger: true, debug: true, // uncomment for SMTP wire logs
    });
    mailTransport.verify((err, ok) => {
      if (err) logger.error('SMTP verify failed', { err });
      else logger.info('SMTP verify ok', { ok });
    });
  }
  return mailTransport;
}

async function sendLoginEmail(email, code) {
  const cfg = getMailerConfig();

  // Log a safe summary each request
  logger.info('Mailer config summary', {
    host: !!cfg.host, port: cfg.port, secure: cfg.secure,
    from: !!cfg.from, userSet: !!cfg.user, passSet: !!cfg.pass,
  });

  const transport = getMailTransport(cfg);
  if (!transport) {
    throw new HttpsError('failed-precondition', 'email_transport_unconfigured');
  }

  const subject = 'Your Reclaim login code';
  const textBody = `Here is your Reclaim login code: ${code}\n\nThis code expires in 10 minutes.`;
  const htmlBody = `<p>Here is your <strong>Reclaim</strong> login code:</p>
<p style="font-size:24px;letter-spacing:4px;"><strong>${code}</strong></p>
<p>This code expires in 10 minutes. If you didn't request it, you can ignore this email.</p>`;

  try {
    await transport.sendMail({ to: email, from: cfg.from, subject, text: textBody, html: htmlBody });
    logger.info('Login code emailed', { email });
  } catch (err) {
    logger.error('Failed to send login code email', { email, err });
    throw new HttpsError('internal', 'Failed to send login email. Please try again later.');
  }
}
// -------------- END MAILER ---------------------------------------------------

// -- Utility ------------------------------------------------------------------
function normalizeEmail(email) {
  if (typeof email !== 'string') return '';
  return email.trim().toLowerCase();
}

function docIdForEmail(email) {
  return Buffer.from(email, 'utf8')
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function generateCode() {
  return crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
}

function hashCode(code, salt) {
  return crypto.createHash('sha256').update(`${salt}:${code}`).digest('hex');
}

async function ensureUser(email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      return auth.createUser({ email, emailVerified: true });
    }
    throw err;
  }
}

// -- Callables ----------------------------------------------------------------
exports.auth_requestCode = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  if (!emailRegex.test(email)) {
    throw new HttpsError('invalid-argument', 'Email is required.');
  }

  const code = generateCode();
  const salt = crypto.randomBytes(16).toString('hex');
  const codeHash = hashCode(code, salt);
  const now = Date.now();
  const docRef = db.collection(CODE_COLLECTION).doc(docIdForEmail(email));

  await docRef.set({
    email,
    codeHash,
    salt,
    createdAt: now,
    expiresAt: now + CODE_TTL_SECONDS * 1000,
    attemptCount: 0,
    lastAttemptAt: null,
  });

  await sendLoginEmail(email, code);
  return { success: true };
});

exports.auth_verifyCode = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = (request.data?.code ?? '').toString().trim();

  if (!emailRegex.test(email) || code.length !== 6) {
    throw new HttpsError('invalid-argument', 'Email and 6-digit code are required.');
  }

  const docRef = db.collection(CODE_COLLECTION).doc(docIdForEmail(email));
  const snap = await docRef.get();
  if (!snap.exists) throw new HttpsError('not-found', 'No code found. Request a new one.');

  const data = snap.data();
  const now = Date.now();

  if (data.expiresAt && data.expiresAt < now) {
    await docRef.delete().catch(() => {});
    throw new HttpsError('deadline-exceeded', 'Code expired. Request a new one.');
  }

  if ((data.attemptCount ?? 0) >= MAX_ATTEMPTS) {
    await docRef.delete().catch(() => {});
    throw new HttpsError('resource-exhausted', 'Too many invalid attempts. Request a new code.');
  }

  const expectedHash = hashCode(code, data.salt);
  if (expectedHash !== data.codeHash) {
    await docRef.update({ attemptCount: FieldValue.increment(1), lastAttemptAt: now }).catch(() => {});
    throw new HttpsError('permission-denied', 'Invalid code.');
  }

  await docRef.delete().catch(() => {});

  const userRecord = await ensureUser(email);
  const customToken = await auth.createCustomToken(userRecord.uid);

  logger.info('Auth code verified', { email, uid: userRecord.uid });
  return { customToken };
});
