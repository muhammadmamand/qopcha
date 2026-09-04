'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const { createAppStore } = require('./create_store');
const { sendOtpWithFallback, toE164Iraq } = require('./verifyway');
const { pushForNotification } = require('./fcm');

const ROOT = path.join(__dirname, '..');
const DATA_DIR = path.join(ROOT, 'data');
const UPLOAD_DIR = path.join(ROOT, 'uploads');
const PUBLIC_DIR = path.join(ROOT, 'public');
fs.mkdirSync(DATA_DIR, { recursive: true });
fs.mkdirSync(UPLOAD_DIR, { recursive: true });
let store;
let storageBackend = 'json';

async function read(col, id) {
  return store.read(col, id);
}

async function write(col, id, data) {
  return store.write(col, id, data);
}

async function merge(col, id, patch) {
  const current = (await read(col, id)) || { id };
  const next = { ...current };
  for (const [key, value] of Object.entries(patch)) {
    if (key.includes('.')) {
      const [a, b] = key.split('.');
      next[a] = { ...(next[a] || {}), [b]: value };
    } else {
      next[key] = value;
    }
  }
  return write(col, id, next);
}

async function all(col) {
  return store.all(col);
}

function loadEnvFile() {
  const envPath = path.join(ROOT, '.env');
  if (!fs.existsSync(envPath)) return;
  for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const i = t.indexOf('=');
    if (i < 1) continue;
    const key = t.slice(0, i).trim();
    const val = t.slice(i + 1).trim();
    if (!(key in process.env)) process.env[key] = val;
  }
}
loadEnvFile();

const PORT = Number(process.env.PORT || 8080);
const PUBLIC_URL = (process.env.PUBLIC_URL || `http://127.0.0.1:${PORT}`).replace(/\/$/, '');
const ADMIN_EMAIL = (process.env.ADMIN_EMAIL || 'admin@qopcha.com').toLowerCase();
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Admin123456';

function jwtSecret() {
  const fromEnv = process.env.JWT_SECRET;
  if (fromEnv && fromEnv.length >= 24 && fromEnv !== 'change-this-to-a-long-random-string') {
    return fromEnv;
  }
  const secretFile = path.join(DATA_DIR, 'jwt.secret');
  if (fs.existsSync(secretFile)) return fs.readFileSync(secretFile, 'utf8').trim();
  const generated = crypto.randomBytes(48).toString('hex');
  fs.writeFileSync(secretFile, generated, { mode: 0o600 });
  return generated;
}
const JWT_SECRET = jwtSecret();
const ADMIN_PHONE = normalizePhone(process.env.ADMIN_PHONE || '07500000000');

function normalizePhone(raw) {
  let p = String(raw || '').replace(/[\s\-()]/g, '');
  if (p.startsWith('+964')) p = `0${p.slice(4)}`;
  else if (p.startsWith('964')) p = `0${p.slice(3)}`;
  return p;
}

function isValidPhone(phone) {
  return /^07[0-9]{9}$/.test(phone);
}

function publicUser(doc) {
  if (!doc) return null;
  const { passwordHash, password, ...rest } = doc;
  return rest;
}

function signToken(user) {
  return jwt.sign(
    { sub: user.id, phone: user.phone, email: user.email || '', role: user.role },
    JWT_SECRET,
    { expiresIn: '30d' },
  );
}

function authRequired(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'تکایە بچۆ ژوورەوە' });
  try {
    req.auth = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'کاتی چوونەژوورەوە بەسەرچوو' });
  }
}

function adminRequired(req, res, next) {
  if (req.auth?.role !== 'admin') {
    return res.status(403).json({ error: 'تەنها ئەدمین' });
  }
  next();
}

function pickDefined(source, keys) {
  const out = {};
  for (const key of keys) {
    if (source[key] !== undefined) out[key] = source[key];
  }
  return out;
}

const ME_PATCH_KEYS = new Set([
  'name',
  'phone',
  'location',
  'preferredSize',
  'measurements',
  'latitude',
  'longitude',
  'shopName',
  'shopDescription',
  'shopAddress',
  'avatarUrl',
  'shopLogoUrl',
  'shopCoverUrl',
  'approvalNoticeSeen',
  'lastNotificationsSeenAt',
  'lastDeliveredOrdersSeenAt',
  'orderTabsSeenAt',
  'fcmToken',
  'fcmUpdatedAt',
]);

const ORDER_STATUSES = new Set([
  'pending',
  'confirmed',
  'ready',
  'shipped',
  'completed',
  'cancelled',
  'returned',
]);

const SHOP_ORDER_PATCH_KEYS = ['status', 'statusUpdatedAt', 'readyAt'];
const ADMIN_ORDER_PATCH_KEYS = [
  'status',
  'statusUpdatedAt',
  'readyAt',
  'deliveryZone',
  'deliveryFee',
  'driverNote',
  'deliveryUpdatedAt',
  'returnReason',
  'returnNote',
  'returnRequestedAt',
];

const RETURN_REASON_PRESETS = new Set([
  'قەبارە / سایز گونجاو نییە',
  'کوالیتی خراپە یان زیانی هەیە',
  'کاڵا وەک وەسف نییە',
  'گۆڕینی بڕیار',
  'هەڵەی داواکاری',
  'هۆکاری تر',
]);

const NOTIFICATION_FIELDS = [
  'type',
  'title',
  'body',
  'shopOwnerId',
  'shopName',
  'productId',
  'productName',
  'category',
  'imageUrl',
  'targetUserId',
];

const ADMIN_ONLY_NOTIFICATION_TYPES = new Set([
  'admin_announcement',
  'account_approved',
  'order_delivered',
]);

const ALLOWED_NOTIFICATION_TYPES = new Set([
  'admin_announcement',
  'account_approved',
  'order_delivered',
  'new_product',
  'order_ready',
  'discount_assigned',
]);

function shopMayTransitionOrder(from, to) {
  if (from === 'pending' && (to === 'confirmed' || to === 'cancelled')) return true;
  if (from === 'confirmed' && to === 'ready') return true;
  return false;
}

async function seedAdmin() {
  if ((await store.getAuthByEmail(ADMIN_EMAIL)) || (await store.getAuthByPhone(ADMIN_PHONE))) return;
  const id = uuidv4();
  const password_hash = await bcrypt.hash(ADMIN_PASSWORD, 12);
  await store.insertAuth({ id, email: ADMIN_EMAIL, phone: ADMIN_PHONE, password_hash });
  await write('users', id, {
    id,
    name: 'ئەدمین',
    email: ADMIN_EMAIL,
    phone: ADMIN_PHONE,
    role: 'admin',
    approvalStatus: 'approved',
    approvalNoticeSeen: true,
    createdAt: new Date().toISOString(),
  });
  console.log(`Seeded admin ${ADMIN_EMAIL} / ${ADMIN_PHONE}`);
}

async function seedStarterProducts() {
  if ((await all('products')).length > 0) return;
  const adminAuth = await store.getAuthByEmail(ADMIN_EMAIL);
  if (!adminAuth) return;
  const adminUser = await read('users', adminAuth.id);
  if (!adminUser) return;

  const shopName = 'قۆپچە';
  const now = new Date().toISOString();
  const demos = [
    {
      name: 'کاتی شەرت کلاسیک',
      description: 'شەرتی نەرم و ڕۆژانە',
      category: 'پۆشاک',
      price: 35000,
      colors: ['سپی', 'ڕەش'],
      material: 'کاتن',
      brand: 'قۆپچە',
      imageUrls: ['https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800'],
      sizeStocks: [{ size: 'M', quantity: 8 }, { size: 'L', quantity: 10 }],
      isFeatured: true,
      productType: 'clothing',
    },
    {
      name: 'جلکی هاوینەی ئافرەتان',
      description: 'جلکی سووک و مۆدێرن',
      category: 'کراس',
      price: 55000,
      colors: ['پەمەیی', 'سپی'],
      material: 'لینن',
      brand: 'قۆپچە',
      imageUrls: ['https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=800'],
      sizeStocks: [{ size: 'S', quantity: 5 }, { size: 'M', quantity: 7 }],
      isFeatured: true,
      discountPercent: 15,
      discountType: 'percent',
      discountForAllCustomers: true,
      discountSetBy: 'shop',
      productType: 'clothing',
    },
    {
      name: 'پانتۆڵی جین',
      description: 'جینی نەرم بۆ ڕۆژانە',
      category: 'پانتۆڵ',
      price: 48000,
      colors: ['شینی جین'],
      material: 'دینم',
      brand: 'قۆپچە',
      imageUrls: ['https://images.unsplash.com/photo-1542272604-787c3835535d?w=800'],
      sizeStocks: [{ size: '32', quantity: 6 }, { size: '34', quantity: 5 }],
      isFeatured: false,
      productType: 'clothing',
    },
    {
      name: 'کۆتی زستانە',
      description: 'کۆتی گەرم و مۆدێرن',
      category: 'کۆت',
      price: 89000,
      colors: ['ڕەش', 'قاوەیی'],
      material: 'وۆڵ',
      brand: 'قۆپچە',
      imageUrls: ['https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=800'],
      sizeStocks: [{ size: 'L', quantity: 4 }, { size: 'XL', quantity: 3 }],
      isFeatured: true,
      productType: 'clothing',
    },
  ];

  for (const demo of demos) {
    const id = uuidv4();
    await write('products', id, {
      ...demo,
      id,
      shopOwnerId: adminUser.id,
      shopName,
      createdAt: now,
      updatedAt: now,
    });
  }
  console.log(`Seeded ${demos.length} starter products`);
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOAD_DIR),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase() || '.jpg';
    const safe = ['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(ext) ? ext : '.jpg';
    cb(null, `${Date.now()}_${uuidv4()}${safe}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (!/^image\//.test(file.mimetype || '')) {
      return cb(new Error('تەنها وێنە ڕێگەپێدراوە'));
    }
    cb(null, true);
  },
});

const app = express();
app.set('trust proxy', 1);
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors({ origin: process.env.ALLOWED_ORIGIN || true }));
app.use(express.json({ limit: '2mb' }));
app.use(
  '/uploads',
  express.static(UPLOAD_DIR, { maxAge: '7d', fallthrough: false }),
);
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5000,
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) =>
      req.method === 'GET' &&
      (req.path === '/api/health' ||
        req.path === '/api/products' ||
        req.path.startsWith('/api/products/') ||
        req.path === '/api/banners' ||
        req.path === '/api/content' ||
        req.path === '/privacy' ||
        req.path === '/support' ||
        req.path === '/qopcha_logo.png' ||
        req.path === '/Rabar_038.ttf' ||
        req.path.startsWith('/public') ||
        req.path.startsWith('/uploads')),
  }),
);
const authLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 40,
  message: { error: 'هەوڵی زۆر درا — دواتر هەوڵبدەرەوە' },
});

app.get('/api/health', async (_req, res) => {
  const products = await all('products');
  res.json({
    ok: true,
    service: 'qopcha',
    storage: storageBackend,
    time: new Date().toISOString(),
    products: products.length,
  });
});

app.post('/api/setup/seed-starter', async (_req, res) => {
  try {
    const before = (await all('products')).length;
    if (before > 0) {
      return res.json({ ok: true, skipped: true, products: before });
    }
    await seedStarterProducts();
    const after = (await all('products')).length;
    res.json({ ok: true, seeded: after > before, products: after });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'هەڵەیەک ڕوویدا' });
  }
});

app.get('/', (_req, res) => {
  res.type('html').send(`<!DOCTYPE html>
<html lang="ku" dir="rtl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>قۆپچە — Qopcha API</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 520px; margin: 48px auto; padding: 0 20px; color: #152426; line-height: 1.6; }
    h1 { color: #116c71; margin-bottom: 0.25rem; }
    p { color: #5a6a6c; }
    a { color: #116c71; font-weight: 600; }
    .ok { display: inline-block; background: #e8f5f0; color: #1b7a4e; padding: 6px 12px; border-radius: 8px; font-size: 14px; margin-top: 12px; }
  </style>
</head>
<body>
  <h1>قۆپچە · Qopcha</h1>
  <p>API سێرڤەرەکە کار دەکات — ئەم بەستەرە بۆ ئەپەکەی مۆبایلە، نەک ماڵپەڕی تەواو.</p>
  <p class="ok">✓ Server online</p>
  <p><a href="/support">Help & Support / یارمەتی و پشتگیری</a></p>
  <p><a href="/privacy">Privacy Policy / سیاسەتی تایبەتمەندی</a></p>
  <p><a href="/api/health">API health check</a></p>
</body>
</html>`);
});

app.use(
  '/public',
  express.static(PUBLIC_DIR, { maxAge: '7d', fallthrough: false }),
);

app.get('/privacy', (_req, res) => {
  res.type('html').sendFile(path.join(PUBLIC_DIR, 'privacy.html'));
});

app.get('/support', (_req, res) => {
  res.type('html').sendFile(path.join(PUBLIC_DIR, 'support.html'));
});
app.get('/qopcha_logo.png', (_req, res) => {
  res.sendFile(path.join(PUBLIC_DIR, 'qopcha_logo.png'));
});

app.get('/Rabar_038.ttf', (_req, res) => {
  res.type('font/ttf').sendFile(path.join(PUBLIC_DIR, 'Rabar_038.ttf'));
});

app.post('/api/auth/register', authLimit, async (req, res) => {
  try {
    const body = req.body || {};
    const phone = normalizePhone(body.phone);
    const password = String(body.password || '');
    const name = String(body.name || '').trim();
    const code = String(body.code || body.otp || '').trim();
    const role = body.role === 'shopOwner' ? 'shopOwner' : 'customer';
    if (!phone || !password || !name) {
      return res.status(400).json({ error: 'ناو، ژمارەی مۆبایل و وشەی نهێنی پێویستن' });
    }
    if (!isValidPhone(phone)) {
      return res.status(400).json({ error: 'ژمارەی مۆبایل دروست نییە (07xxxxxxxxx)' });
    }
    if (!/^\d{6}$/.test(code)) {
      return res.status(400).json({ error: 'کۆدی پشتڕاستکردنەوەی واتساپ پێویستە' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'وشەی نهێنی لاوازە (لانیکەم ٦ پیت)' });
    }
    if (await store.getAuthByPhone(phone)) {
      return res.status(400).json({ error: 'ئەم ژمارەیە پێشتر تۆمارکراوە' });
    }
    const otp = await store.getOtp(phone, 'signup');
    if (!otp || otp.code !== code || otp.expires_at < Date.now()) {
      return res.status(400).json({ error: 'کۆد نادروستە یان بەسەرچووە' });
    }
    await store.deleteOtp(phone, 'signup');
    const id = uuidv4();
    const password_hash = await bcrypt.hash(password, 12);
    await store.insertAuth({ id, phone, password_hash });
    // OTP-verified accounts are auto-accepted — no admin approval queue.
    const user = await write('users', id, {
      id,
      name,
      email: '',
      phone,
      role,
      phoneVerified: true,
      approvalStatus: 'approved',
      approvalNoticeSeen: true,
      location: body.location || null,
      shopName: body.shopName || null,
      shopDescription: body.shopDescription || null,
      shopAddress: body.shopAddress || null,
      shopLogoUrl: body.shopLogoUrl || null,
      shopCoverUrl: body.shopCoverUrl || null,
      shopTier: role === 'shopOwner' ? (body.shopTier || 'gold') : null,
      createdAt: new Date().toISOString(),
    });
    res.json({ token: signToken(user), user: publicUser(user) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'هەڵەیەک ڕوویدا' });
  }
});

async function finalizeAuthUser(row) {
  let user = await read('users', row.id);
  if (!user) return null;
  if ((row.email || user.email || '').toLowerCase() === ADMIN_EMAIL && user.role !== 'admin') {
    user = await merge('users', user.id, {
      role: 'admin',
      approvalStatus: 'approved',
      approvalNoticeSeen: true,
    });
  }
  if (user.role === 'admin') return user;
  // OTP / phone-verified accounts stay approved without admin review.
  if (user.phoneVerified === true && user.approvalStatus === 'pending') {
    user = await merge('users', user.id, {
      approvalStatus: 'approved',
      approvalNoticeSeen: true,
    });
  }
  if (user.role === 'customer' && user.approvalStatus === 'pending') {
    user = await merge('users', user.id, {
      approvalStatus: 'approved',
      approvalNoticeSeen: true,
    });
  }
  return user;
}

async function sendPhoneOtp(phone, purpose) {
  const code = String(crypto.randomInt(100000, 999999));
  const expiresAt = Date.now() + 10 * 60 * 1000;
  await store.setOtp(phone, purpose, code, expiresAt);
  if (purpose === 'reset') {
    await store.setResetCode(phone, code, expiresAt);
  }
  const result = await sendOtpWithFallback({
    recipientE164: toE164Iraq(phone),
    code,
  });
  const channel = result?.channel || 'whatsapp';
  if (process.env.NODE_ENV !== 'production') {
    console.log(`OTP (${purpose}/${channel}) for ${phone}: ${code}`);
  }
  return { code, channel };
}

app.post('/api/auth/login', authLimit, async (req, res) => {
  const phone = normalizePhone(req.body?.phone || req.body?.email);
  const email = String(req.body?.email || '').trim().toLowerCase();
  const password = String(req.body?.password || '');

  // Staff console may still log in with admin email.
  let row = null;
  if (email && email.includes('@')) {
    row = await store.getAuthByEmail(email);
  }
  if (!row && phone) {
    row = await store.getAuthByPhone(phone);
  }

  if (!row || !(await bcrypt.compare(password, row.password_hash))) {
    return res.status(401).json({ error: 'ژمارەی مۆبایل یان وشەی نهێنی هەڵەیە' });
  }
  const user = await finalizeAuthUser(row);
  if (!user) return res.status(401).json({ error: 'هەژمارەکە نەدۆزرایەوە' });
  res.json({ token: signToken(user), user: publicUser(user) });
});

/** Send WhatsApp OTP for login, signup, or password reset. */
app.post('/api/auth/otp/send', authLimit, async (req, res) => {
  try {
    const phone = normalizePhone(req.body?.phone);
    const rawPurpose = String(req.body?.purpose || 'login').toLowerCase();
    const purpose =
      rawPurpose === 'reset' || rawPurpose === 'signup' ? rawPurpose : 'login';
    if (!isValidPhone(phone)) {
      return res.status(400).json({ error: 'ژمارەی مۆبایل دروست نییە (07xxxxxxxxx)' });
    }
    const row = await store.getAuthByPhone(phone);
    if (purpose === 'signup') {
      if (row) {
        return res.status(400).json({ error: 'ئەم ژمارەیە پێشتر تۆمارکراوە' });
      }
      const sent = await sendPhoneOtp(phone, 'signup');
      return res.json({ ok: true, channel: sent.channel });
    }
    if (!row) {
      // Avoid account enumeration for reset; login needs a clear error.
      if (purpose === 'login') {
        return res.status(404).json({ error: 'ئەم ژمارەیە تۆمار نەکراوە' });
      }
      return res.json({ ok: true });
    }
    const sent = await sendPhoneOtp(phone, purpose);
    res.json({ ok: true, channel: sent.channel });
  } catch (err) {
    console.error('OTP send failed:', err.message || err);
    const raw = String(err.message || '').toLowerCase();
    let error = 'نەتوانرا کۆدی واتساپ بنێردرێت — دواتر هەوڵ بدەرەوە';
    if (raw.includes('invalid api key') || raw.includes('unauthorized')) {
      error =
        'کلیلی VerifyWay نادروستە — لە پۆرتاڵ کلیلی نوێ وەربگرە و لە server/.env دایبنێ';
    } else if (raw.includes('balance') || raw.includes('credit') || raw.includes('payment')) {
      error = 'باڵانسی VerifyWay بەسەند نییە — هەژمارەکەت تۆپ ئەپ بکە';
    } else if (raw.includes('not configured')) {
      error = 'VERIFYWAY_API_TOKEN لە سێرڤەر دانەنراوە';
    }
    res.status(502).json({ error });
  }
});

/** Verify WhatsApp OTP and issue session (login). */
app.post('/api/auth/otp/login', authLimit, async (req, res) => {
  const phone = normalizePhone(req.body?.phone);
  const code = String(req.body?.code || '').trim();
  if (!isValidPhone(phone) || !/^\d{6}$/.test(code)) {
    return res.status(400).json({ error: 'ژمارە یان کۆد هەڵەیە' });
  }
  const otp = await store.getOtp(phone, 'login');
  if (!otp || otp.code !== code || otp.expires_at < Date.now()) {
    return res.status(401).json({ error: 'کۆد نادروستە یان بەسەرچووە' });
  }
  const row = await store.getAuthByPhone(phone);
  if (!row) return res.status(401).json({ error: 'هەژمارەکە نەدۆزرایەوە' });
  await store.deleteOtp(phone, 'login');
  const user = await finalizeAuthUser(row);
  if (!user) return res.status(401).json({ error: 'هەژمارەکە نەدۆزرایەوە' });
  res.json({ token: signToken(user), user: publicUser(user) });
});

app.get('/api/auth/me', authRequired, async (req, res) => {
  const user = publicUser(await read('users', req.auth.sub));
  if (!user) return res.status(401).json({ error: 'تکایە دووبارە بچۆ ژوورەوە' });
  res.json({ user });
});

app.patch('/api/auth/me', authRequired, async (req, res) => {
  const body = req.body || {};
  const patch = {};
  for (const [key, value] of Object.entries(body)) {
    if (key.startsWith('orderTabsSeenAt.')) {
      patch[key] = value;
      continue;
    }
    if (ME_PATCH_KEYS.has(key)) patch[key] = value;
  }
  if (patch.phone != null) {
    const phone = normalizePhone(patch.phone);
    if (!isValidPhone(phone)) {
      return res.status(400).json({ error: 'ژمارەی مۆبایل دروست نییە (07xxxxxxxxx)' });
    }
    const existing = await store.getAuthByPhone(phone);
    if (existing && existing.id !== req.auth.sub) {
      return res.status(400).json({ error: 'ئەم ژمارەیە پێشتر تۆمارکراوە' });
    }
    await store.updateAuthPhone(req.auth.sub, phone);
    patch.phone = phone;
  }
  const user = await merge('users', req.auth.sub, patch);
  res.json({ user: publicUser(user) });
});

app.post('/api/auth/change-password', authRequired, async (req, res) => {
  const currentPassword = String(req.body?.currentPassword || '');
  const newPassword = String(req.body?.newPassword || '');
  if (newPassword.length < 6) {
    return res.status(400).json({ error: 'وشەی نهێنی نوێ لانیکەم ٦ پیت بێت' });
  }
  const row = await store.getAuthById(req.auth.sub);
  if (!row || !(await bcrypt.compare(currentPassword, row.password_hash))) {
    return res.status(400).json({ error: 'وشەی نهێنی ئێستات هەڵەیە' });
  }
  const password_hash = await bcrypt.hash(newPassword, 12);
  await store.updateAuthPassword(req.auth.sub, password_hash);
  res.json({ ok: true });
});

app.post('/api/auth/forgot', authLimit, async (req, res) => {
  try {
    const phone = normalizePhone(req.body?.phone || req.body?.email);
    if (!isValidPhone(phone)) {
      return res.status(400).json({ error: 'ژمارەی مۆبایل دروست نییە (07xxxxxxxxx)' });
    }
    const row = await store.getAuthByPhone(phone);
    if (row) {
      const sent = await sendPhoneOtp(phone, 'reset');
      return res.json({ ok: true, channel: sent.channel });
    }
    // Always OK so callers cannot probe which phones exist.
    res.json({ ok: true });
  } catch (err) {
    console.error('Forgot OTP send failed:', err.message || err);
    const raw = String(err.message || '').toLowerCase();
    let error = 'نەتوانرا کۆدی واتساپ بنێردرێت — دواتر هەوڵ بدەرەوە';
    if (raw.includes('invalid api key') || raw.includes('unauthorized')) {
      error =
        'کلیلی VerifyWay نادروستە — لە پۆرتاڵ کلیلی نوێ وەربگرە و لە server/.env دایبنێ';
    } else if (raw.includes('balance') || raw.includes('credit') || raw.includes('payment')) {
      error = 'باڵانسی VerifyWay بەسەند نییە — هەژمارەکەت تۆپ ئەپ بکە';
    }
    res.status(502).json({ error });
  }
});

app.post('/api/auth/reset', authLimit, async (req, res) => {
  const phone = normalizePhone(req.body?.phone || req.body?.email);
  const code = String(req.body?.code || '').trim();
  const newPassword = String(req.body?.newPassword || '');
  if (!/^\d{6}$/.test(code) || newPassword.length < 6) {
    return res.status(400).json({ error: 'کۆد یان وشەی نهێنی هەڵەیە' });
  }
  const otp = await store.getOtp(phone, 'reset');
  const legacy = await store.getResetCode(phone);
  const match =
    (otp && otp.code === code && otp.expires_at >= Date.now()) ||
    (legacy && legacy.code === code && legacy.expires_at >= Date.now());
  if (!match) {
    return res.status(400).json({ error: 'کۆد نادروستە یان بەسەرچووە' });
  }
  const auth = await store.getAuthByPhone(phone);
  if (!auth) return res.status(400).json({ error: 'هەژمار نەدۆزرایەوە' });
  const password_hash = await bcrypt.hash(newPassword, 12);
  await store.updateAuthPassword(auth.id, password_hash);
  await store.deleteOtp(phone, 'reset');
  await store.deleteResetCode(phone);
  res.json({ ok: true });
});

app.post('/api/upload', authRequired, (req, res) => {
  upload.single('file')(req, res, (err) => {
    if (err) return res.status(400).json({ error: err.message || 'نەتوانرا وێنە هەڵبژێردرێت' });
    if (!req.file) return res.status(400).json({ error: 'وێنە پێویستە' });
    res.json({ url: `${PUBLIC_URL}/uploads/${req.file.filename}` });
  });
});

app.get('/api/products', async (_req, res) => {
  const shopOwnerId = String(_req.query.shopOwnerId || '');
  const featured = String(_req.query.featured || '') === '1';
  const category = String(_req.query.category || '');
  let list = await all('products');
  if (shopOwnerId) list = list.filter((p) => p.shopOwnerId === shopOwnerId);
  if (featured) list = list.filter((p) => p.isFeatured === true);
  if (category && category !== 'هەموو') list = list.filter((p) => p.category === category);
  list.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
  res.json({ products: list });
});

app.get('/api/products/:id', async (req, res) => {
  const product = await read('products', req.params.id);
  if (!product) return res.status(404).json({ error: 'بەرهەم نەدۆزرایەوە' });
  res.json({ product });
});

app.post('/api/products', authRequired, async (req, res) => {
  if (!['shopOwner', 'admin'].includes(req.auth.role)) {
    return res.status(403).json({ error: 'ناتوانیت بەرهەم زیاد بکەیت' });
  }
  const id = uuidv4();
  const now = new Date().toISOString();
  const product = await write('products', id, {
    ...(req.body || {}),
    id,
    shopOwnerId: req.auth.role === 'admin' ? (req.body?.shopOwnerId || req.auth.sub) : req.auth.sub,
    createdAt: now,
    updatedAt: now,
  });
  res.json({ product });
});

app.patch('/api/products/:id', authRequired, async (req, res) => {
  const current = await read('products', req.params.id);
  if (!current) return res.status(404).json({ error: 'بەرهەم نەدۆزرایەوە' });
  if (req.auth.role !== 'admin' && current.shopOwnerId !== req.auth.sub) {
    return res.status(403).json({ error: 'ناتوانیت ئەم بەرهەمە بگۆڕیت' });
  }
  const product = await merge('products', current.id, {
    ...(req.body || {}),
    updatedAt: new Date().toISOString(),
  });
  res.json({ product });
});

app.delete('/api/products/:id', authRequired, async (req, res) => {
  const current = await read('products', req.params.id);
  if (!current) return res.status(404).json({ error: 'بەرهەم نەدۆزرایەوە' });
  if (req.auth.role !== 'admin' && current.shopOwnerId !== req.auth.sub) {
    return res.status(403).json({ error: 'ناتوانیت ئەم بەرهەمە بسڕیتەوە' });
  }
  await store.deleteDoc('products', current.id);
  res.json({ ok: true });
});

app.get('/api/orders', authRequired, async (req, res) => {
  let list = await all('orders');
  if (req.auth.role === 'admin') {
    // all
  } else if (req.auth.role === 'shopOwner') {
    list = list.filter((o) => o.shopOwnerId === req.auth.sub);
  } else {
    list = list.filter((o) => o.userId === req.auth.sub);
  }
  list.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
  res.json({ orders: list });
});

app.post('/api/orders', authRequired, async (req, res) => {
  const items = Array.isArray(req.body?.orders) ? req.body.orders : [req.body];
  const created = [];
  for (const raw of items) {
    if (!raw) continue;
    const id = uuidv4();
    const order = await write('orders', id, {
      ...raw,
      id,
      userId: req.auth.sub,
      createdAt: new Date().toISOString(),
      status: raw.status || 'pending',
    });
    created.push(order);
  }
  res.json({ orders: created });
});

app.patch('/api/orders/:id', authRequired, async (req, res) => {
  const current = await read('orders', req.params.id);
  if (!current) return res.status(404).json({ error: 'داواکاری نەدۆزرایەوە' });
  const shop = current.shopOwnerId === req.auth.sub;
  const admin = req.auth.role === 'admin';
  if (!shop && !admin) return res.status(403).json({ error: 'ڕێگەپێنەدراو' });

  const body = req.body || {};
  const allowedKeys = admin ? ADMIN_ORDER_PATCH_KEYS : SHOP_ORDER_PATCH_KEYS;
  const patch = pickDefined(body, allowedKeys);
  if (patch.status != null) {
    const nextStatus = String(patch.status);
    if (!ORDER_STATUSES.has(nextStatus)) {
      return res.status(400).json({ error: 'دۆخی داواکاری نادروستە' });
    }
    if (!admin && !shopMayTransitionOrder(String(current.status || ''), nextStatus)) {
      return res.status(403).json({ error: 'ناتوانیت ئەم دۆخە دابنێیت' });
    }
    patch.status = nextStatus;
  }
  if (patch.deliveryFee != null) {
    const fee = Number(patch.deliveryFee);
    if (!Number.isFinite(fee) || fee < 0) {
      return res.status(400).json({ error: 'کرێی گەیاندن نادروستە' });
    }
    patch.deliveryFee = fee;
  }
  patch.statusUpdatedAt = new Date().toISOString();
  const order = await merge('orders', current.id, patch);
  res.json({ order });
});

/** Customer requests a return on a delivered (completed) order. */
app.post('/api/orders/:id/return', authRequired, async (req, res) => {
  const current = await read('orders', req.params.id);
  if (!current) return res.status(404).json({ error: 'داواکاری نەدۆزرایەوە' });
  if (current.userId !== req.auth.sub && req.auth.role !== 'admin') {
    return res.status(403).json({ error: 'ڕێگەپێنەدراو' });
  }
  if (String(current.status || '') !== 'completed') {
    return res.status(400).json({ error: 'تەنها داواکاری گەیشتوو دەتوانرێت بگەڕێنرێتەوە' });
  }
  const reason = String(req.body?.reason || '').trim();
  const note = String(req.body?.note || '').trim();
  if (!reason) {
    return res.status(400).json({ error: 'تکایە هۆکاری گەڕاندنەوە هەڵبژێرە' });
  }
  if (reason.length > 200 || note.length > 500) {
    return res.status(400).json({ error: 'هۆکار زۆر درێژە' });
  }
  const now = new Date().toISOString();
  const order = await merge('orders', current.id, {
    status: 'returned',
    returnReason: reason,
    returnNote: note || null,
    returnRequestedAt: now,
    statusUpdatedAt: now,
  });
  res.json({ order });
});

app.get('/api/notifications', authRequired, async (req, res) => {
  const uid = req.auth.sub;
  const list = (await all('notifications')).filter((n) => {
    const target = (n.targetUserId || '').trim();
    if (target) return target === uid;
    return n.audience === 'all' || !target;
  });
  list.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
  res.json({ notifications: list.slice(0, 60) });
});

app.post('/api/notifications', authRequired, async (req, res) => {
  const body = req.body || {};
  const type = String(body.type || '').trim();
  if (!ALLOWED_NOTIFICATION_TYPES.has(type)) {
    return res.status(400).json({ error: 'جۆری ئاگاداری نادروستە' });
  }

  const isAdmin = req.auth.role === 'admin';
  const isShop = req.auth.role === 'shopOwner';
  if (ADMIN_ONLY_NOTIFICATION_TYPES.has(type) && !isAdmin) {
    return res.status(403).json({ error: 'تەنها ئەدمین' });
  }
  if (
    (type === 'new_product' || type === 'order_ready' || type === 'discount_assigned') &&
    !isAdmin &&
    !isShop
  ) {
    return res.status(403).json({ error: 'ڕێگەپێنەدراو' });
  }

  const targetUserId = String(body.targetUserId || '').trim();
  if ((type === 'order_ready' || type === 'account_approved' || type === 'order_delivered') && !targetUserId) {
    return res.status(400).json({ error: 'targetUserId پێویستە' });
  }

  // Personal platform discounts (empty shopOwnerId) are admin-only.
  if (type === 'discount_assigned' && !isAdmin) {
    const claimedShop = String(body.shopOwnerId || '').trim();
    if (!claimedShop || claimedShop !== req.auth.sub) {
      return res.status(403).json({ error: 'ڕێگەپێنەدراو' });
    }
  }

  const fields = pickDefined(body, NOTIFICATION_FIELDS);
  fields.type = type;
  fields.title = String(fields.title || '').slice(0, 200);
  fields.body = String(fields.body || '').slice(0, 2000);
  if (targetUserId) fields.targetUserId = targetUserId;
  else delete fields.targetUserId;

  if (isShop && !isAdmin) {
    fields.shopOwnerId = req.auth.sub;
  } else if (fields.shopOwnerId != null) {
    fields.shopOwnerId = String(fields.shopOwnerId);
  }

  const id = String(body.id || uuidv4()).slice(0, 120);
  const notification = await write('notifications', id, {
    ...fields,
    id,
    audience: targetUserId ? 'user' : 'all',
    createdAt: new Date().toISOString(),
  });
  // Fire-and-forget FCM so phones get a system alert without opening the app.
  pushForNotification(notification, { read, all }).catch((err) => {
    console.warn('[fcm] push failed:', err.message || err);
  });
  res.json({ notification });
});

app.get('/api/users', authRequired, adminRequired, async (_req, res) => {
  const users = (await all('users'))
    .map(publicUser)
    .filter((u) => u.role !== 'admin');
  users.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
  res.json({ users });
});

app.patch('/api/users/:id', authRequired, adminRequired, async (req, res) => {
  const current = await read('users', req.params.id);
  if (!current) return res.status(404).json({ error: 'بەکارهێنەر نەدۆزرایەوە' });
  const body = { ...(req.body || {}) };
  delete body.id;
  delete body.password;
  delete body.passwordHash;
  delete body.password_hash;
  // Never promote/demote admin via this endpoint.
  if (body.role === 'admin' || current.role === 'admin') {
    delete body.role;
  }
  const user = await merge('users', current.id, body);
  res.json({ user: publicUser(user) });
});

app.get('/api/banners', async (_req, res) => {
  const activeOnly = String(_req.query.active || '') === '1';
  let list = await all('banners');
  if (activeOnly) list = list.filter((b) => b.active !== false);
  list.sort((a, b) => (a.order || 0) - (b.order || 0));
  res.json({ banners: list });
});

app.post('/api/banners', authRequired, adminRequired, async (req, res) => {
  const id = req.body?.id || uuidv4();
  const banner = await write('banners', id, {
    ...(req.body || {}),
    id,
    createdAt: req.body?.createdAt || new Date().toISOString(),
  });
  res.json({ banner });
});

app.delete('/api/banners/:id', authRequired, adminRequired, async (req, res) => {
  await store.deleteDoc('banners', req.params.id);
  res.json({ ok: true });
});

app.get('/api/content', async (_req, res) => {
  res.json({ content: (await read('appContent', 'main')) || {} });
});

app.put('/api/content', authRequired, adminRequired, async (req, res) => {
  const content = await write('appContent', 'main', {
    ...(req.body || {}),
    updatedAt: new Date().toISOString(),
  });
  res.json({ content });
});

app.get('/api/addresses', authRequired, async (req, res) => {
  const list = await all(`addresses:${req.auth.sub}`);
  list.sort((a, b) => Number(b.isDefault) - Number(a.isDefault));
  res.json({ addresses: list });
});

app.post('/api/addresses', authRequired, async (req, res) => {
  const col = `addresses:${req.auth.sub}`;
  const id = req.body?.id || uuidv4();
  if (req.body?.isDefault) {
    for (const item of await all(col)) {
      if (item.id !== id && item.isDefault) await merge(col, item.id, { isDefault: false });
    }
  }
  const address = await write(col, id, {
    ...(req.body || {}),
    id,
    updatedAt: new Date().toISOString(),
  });
  if (address.location) {
    await merge('users', req.auth.sub, { location: address.location });
  }
  res.json({ address });
});

app.delete('/api/addresses/:id', authRequired, async (req, res) => {
  await store.deleteDoc(`addresses:${req.auth.sub}`, req.params.id);
  res.json({ ok: true });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'هەڵەیەک ڕوویدا' });
});

async function boot() {
  const created = await createAppStore({
    dataDir: DATA_DIR,
    databaseUrl: process.env.DATABASE_URL,
  });
  store = created.store;
  storageBackend = created.backend;
  await seedAdmin();
  await seedStarterProducts();
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`قۆپچە API listening on ${PORT} (${PUBLIC_URL}) [${storageBackend}]`);
  });
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
