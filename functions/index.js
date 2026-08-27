/**
 * Cloud Functions for قۆپچە
 * - FCM on new product notifications
 * - Email + FCM when admin approves an account (shop/customer)
 * - Password reset via 6-digit email code (not a link)
 *
 * Deploy:
 *   cd functions && npm install
 *   firebase deploy --only functions,firestore:rules
 *
 * Optional SMTP (otherwise emails are queued to Firestore `mail`
 * for the "Trigger Email" extension):
 *   firebase functions:secrets:set SMTP_USER
 *   firebase functions:secrets:set SMTP_PASS
 *   firebase functions:secrets:set SMTP_HOST   # e.g. smtp.gmail.com
 */
const crypto = require("crypto");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");

initializeApp();

const CODE_TTL_MS = 10 * 60 * 1000;
const MAX_ATTEMPTS = 5;
const RESEND_COOLDOWN_MS = 60 * 1000;

function normalizeEmail(email) {
  return String(email || "")
    .trim()
    .toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function hashCode(code, salt) {
  return crypto
    .createHash("sha256")
    .update(`${salt}:${code}`)
    .digest("hex");
}

function resetDocId(email) {
  return crypto.createHash("sha256").update(email).digest("hex").slice(0, 40);
}

function generateCode() {
  return String(crypto.randomInt(100000, 999999));
}

async function queueMail(db, { to, subject, text, html }) {
  await db.collection("mail").add({
    to: [to],
    message: { subject, text, html },
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function trySendSmtp({ to, subject, text, html }) {
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const host = process.env.SMTP_HOST || "smtp.gmail.com";
  if (!user || !pass) return false;

  // eslint-disable-next-line global-require
  const nodemailer = require("nodemailer");
  const transporter = nodemailer.createTransport({
    host,
    port: Number(process.env.SMTP_PORT || 465),
    secure: String(process.env.SMTP_SECURE || "true") !== "false",
    auth: { user, pass },
  });
  await transporter.sendMail({
    from: `"قۆپچە" <${user}>`,
    to,
    subject,
    text,
    html,
  });
  return true;
}

function buildResetEmail(code) {
  const subject = "کۆدی گۆڕینی وشەی نهێنی — قۆپچە";
  const text =
    `کۆدی پشتڕاستکردنەوەت: ${code}\n\n` +
    `ئەم کۆدە بۆ ١٠ خولەک کارا دەبێت.\n` +
    `ئەگەر تۆ داوات نەکردووە، ئەم ئیمەیڵە پشتگوێ بخە.`;
  const html = `
    <div style="font-family:Tahoma,Arial,sans-serif;direction:rtl;text-align:right;max-width:480px;margin:0 auto;padding:24px;background:#f7fafb;border-radius:16px;">
      <h2 style="color:#146B72;margin:0 0 12px;">قۆپچە</h2>
      <p style="color:#334155;font-size:15px;line-height:1.7;margin:0 0 16px;">
        کۆدی پشتڕاستکردنەوە بۆ گۆڕینی وشەی نهێنی:
      </p>
      <div style="letter-spacing:8px;font-size:32px;font-weight:800;color:#146B72;background:#fff;border:1px solid #d1e4e6;border-radius:14px;padding:16px 12px;text-align:center;">
        ${code}
      </div>
      <p style="color:#64748b;font-size:13px;line-height:1.6;margin:16px 0 0;">
        کۆدەکە بۆ ١٠ خولەک کارایە. ئەگەر تۆ داوات نەکردووە، پشتگوێی بخە.
      </p>
    </div>
  `;
  return { subject, text, html };
}

exports.onNewProductNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    const type = data.type || "";

    if (type === "account_approved") {
      await handleAccountApprovedNotification(event.params.notificationId, data);
      return;
    }

    if (type === "admin_announcement") {
      await handleAdminAnnouncementNotification(event.params.notificationId, data);
      return;
    }

    if (type === "order_ready") {
      await handleOrderReadyNotification(event.params.notificationId, data);
      return;
    }

    if (type === "discount_assigned") {
      await handleDiscountAssignedNotification(event.params.notificationId, data);
      return;
    }

    if (type !== "new_product") {
      logger.info("Skip non-product notification", type);
      return;
    }

    const title = data.title || "بەرهەمی نوێ";
    const body = data.body || "بەرهەمێکی نوێ زیادکرا";
    const productId = data.productId || "";
    const shopOwnerId = data.shopOwnerId || "";

    try {
      const messageId = await getMessaging().send({
        topic: "new_products",
        notification: {
          title: String(title),
          body: String(body),
        },
        data: {
          type: "new_product",
          productId: String(productId),
          shopOwnerId: String(shopOwnerId),
          notificationId: event.params.notificationId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "qopcha_new_products",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });
      logger.info("FCM sent", messageId);
    } catch (err) {
      logger.error("FCM send failed", err);
      throw err;
    }
  }
);

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function buildApprovalEmail({ name, isShop, shopName }) {
  const who = escapeHtml(name || "هاوڕێ");
  const safeShop = escapeHtml(shopName || "");
  const subject = isShop
    ? "دووکانەکەت پەسەند کرا — قۆپچە"
    : "هەژمارەکەت پەسەند کرا — قۆپچە";
  const shopLine =
    isShop && shopName
      ? `<p style="color:#334155;font-size:15px;line-height:1.7;">دووکانی <strong>${safeShop}</strong> قبوڵ کرا.</p>`
      : "";
  const textWho = name || "هاوڕێ";
  const text = isShop
    ? `${textWho}، هەژماری دووکانەکەت لە قۆپچە پەسەند کرا. ئێستا دەتوانیت بەرهەم زیاد بکەیت و فرۆش بکەیت.`
    : `${textWho}، هەژمارەکەت لە قۆپچە پەسەند کرا. ئێستا دەتوانیت داواکاری بکەیت.`;
  const html = `
    <div style="font-family:Tahoma,Arial,sans-serif;direction:rtl;text-align:right;max-width:480px;margin:0 auto;padding:24px;background:#f7fafb;border-radius:16px;">
      <h2 style="color:#146B72;margin:0 0 12px;">قۆپچە</h2>
      <p style="color:#334155;font-size:15px;line-height:1.7;margin:0 0 10px;">سڵاو ${who}،</p>
      ${shopLine}
      <p style="color:#334155;font-size:15px;line-height:1.7;margin:0 0 16px;">
        ${
          isShop
            ? "هەژماری دووکانەکەت لەلایەن ئەدمینەوە <strong>پەسەند کرا</strong>. ئێستا دەتوانیت بەرهەم زیاد بکەیت و فرۆش بکەیت."
            : "هەژمارەکەت لەلایەن ئەدمینەوە <strong>پەسەند کرا</strong>. ئێستا دەتوانیت داواکاری بکەیت."
        }
      </p>
      <div style="background:#146B72;color:#fff;display:inline-block;padding:10px 18px;border-radius:999px;font-weight:700;font-size:14px;">
        قبوڵ کرا ✓
      </div>
    </div>
  `;
  return { subject, text, html };
}

async function handleAccountApprovedNotification(notificationId, data) {
  const db = getFirestore();
  const targetUserId = String(data.targetUserId || "").trim();
  if (!targetUserId) {
    logger.warn("account_approved missing targetUserId", notificationId);
    return;
  }

  const userSnap = await db.collection("users").doc(targetUserId).get();
  if (!userSnap.exists) {
    logger.warn("account_approved user missing", targetUserId);
    return;
  }
  const user = userSnap.data() || {};
  const email = normalizeEmail(user.email);
  const name = user.name || "";
  const isShop = user.role === "shopOwner";
  const shopName = user.shopName || "";
  const title = data.title || (isShop ? "دووکانەکەت پەسەند کرا" : "هەژمارەکەت پەسەند کرا");
  const body =
    data.body ||
    (isShop
      ? "هەژماری دووکانەکەت قبوڵ کرا. ئێستا دەتوانیت بەرهەم زیاد بکەیت."
      : "هەژمارەکەت قبوڵ کرا.");

  // Email
  if (isValidEmail(email)) {
    const mail = buildApprovalEmail({ name, isShop, shopName });
    let sent = false;
    try {
      sent = await trySendSmtp({ to: email, ...mail });
    } catch (err) {
      logger.error("Approval SMTP failed", err);
    }
    if (!sent) {
      await queueMail(db, { to: email, ...mail });
      logger.info("Approval email queued", email);
    } else {
      logger.info("Approval email sent", email);
    }
  }

  // Push to device tokens
  const tokens = new Set();
  if (user.fcmToken) tokens.add(String(user.fcmToken));
  if (Array.isArray(user.fcmTokens)) {
    for (const t of user.fcmTokens) {
      if (t) tokens.add(String(t));
    }
  }
  if (tokens.size === 0) {
    logger.info("No FCM tokens for approved user", targetUserId);
    return;
  }

  const payload = {
    notification: {
      title: String(title),
      body: String(body),
    },
    data: {
      type: "account_approved",
      targetUserId,
      notificationId: String(notificationId),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "qopcha_new_products",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const res = await getMessaging().sendEachForMulticast({
      tokens: [...tokens],
      ...payload,
    });
    logger.info("Approval FCM result", {
      success: res.successCount,
      failure: res.failureCount,
    });
  } catch (err) {
    logger.error("Approval FCM failed", err);
  }
}

async function handleDiscountAssignedNotification(notificationId, data) {
  const title = data.title || "داشکاندنی نوێ";
  const body = data.body || "داشکاندنێکی نوێ زیادکرا";
  const productId = data.productId || "";
  const shopOwnerId = data.shopOwnerId || "";
  const targetUserId = String(data.targetUserId || "").trim();
  const audience = String(data.audience || (targetUserId ? "user" : "all"));

  const payload = {
    notification: {
      title: String(title),
      body: String(body),
    },
    data: {
      type: "discount_assigned",
      productId: String(productId),
      shopOwnerId: String(shopOwnerId),
      notificationId: String(notificationId),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "qopcha_new_products",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    if (audience !== "user" || !targetUserId) {
      const messageId = await getMessaging().send({
        topic: "new_products",
        ...payload,
      });
      logger.info("Discount FCM sent", messageId);
      return;
    }

    const db = getFirestore();
    const userSnap = await db.collection("users").doc(targetUserId).get();
    if (!userSnap.exists) {
      logger.warn("discount target user missing", targetUserId);
      return;
    }
    const user = userSnap.data() || {};
    const tokens = new Set();
    if (user.fcmToken) tokens.add(String(user.fcmToken));
    if (Array.isArray(user.fcmTokens)) {
      for (const token of user.fcmTokens) {
        if (token) tokens.add(String(token));
      }
    }
    if (tokens.size === 0) {
      logger.info("No FCM tokens for discount user", targetUserId);
      return;
    }
    const response = await getMessaging().sendEachForMulticast({
      tokens: [...tokens],
      ...payload,
    });
    logger.info("Discount FCM result", {
      success: response.successCount,
      failure: response.failureCount,
    });
  } catch (err) {
    logger.error("Discount FCM failed", err);
  }
}

async function handleOrderReadyNotification(notificationId, data) {
  const db = getFirestore();
  const targetUserId = String(data.targetUserId || "").trim();
  if (!targetUserId) {
    logger.warn("order_ready missing targetUserId", notificationId);
    return;
  }

  const userSnap = await db.collection("users").doc(targetUserId).get();
  if (!userSnap.exists) {
    logger.warn("order_ready user missing", targetUserId);
    return;
  }
  const user = userSnap.data() || {};
  const tokens = new Set();
  if (user.fcmToken) tokens.add(String(user.fcmToken));
  if (Array.isArray(user.fcmTokens)) {
    for (const token of user.fcmTokens) {
      if (token) tokens.add(String(token));
    }
  }
  if (tokens.size === 0) {
    logger.info("No FCM tokens for order-ready user", targetUserId);
    return;
  }

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens: [...tokens],
      notification: {
        title: String(data.title || "داواکارییەکەت ئامادەیە"),
        body: String(
          data.body || "داواکارییەکەت ئامادەیە و بەمزووانە دەگاتە دەستت.",
        ),
      },
      data: {
        type: "order_ready",
        orderId: String(data.productId || ""),
        targetUserId,
        notificationId: String(notificationId),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "qopcha_new_products",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
    logger.info("Order-ready FCM result", {
      success: response.successCount,
      failure: response.failureCount,
    });
  } catch (err) {
    logger.error("Order-ready FCM failed", err);
  }
}

async function handleAdminAnnouncementNotification(notificationId, data) {
  const title = data.title || "ئاگاداری قۆپچە";
  const body = data.body || "";
  try {
    // Reuse topic customers already subscribe to for product alerts.
    const messageId = await getMessaging().send({
      topic: "new_products",
      notification: {
        title: String(title),
        body: String(body),
      },
      data: {
        type: "admin_announcement",
        notificationId: String(notificationId),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "qopcha_new_products",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
    logger.info("Admin announcement FCM sent", messageId);
  } catch (err) {
    logger.error("Admin announcement FCM failed", err);
    throw err;
  }
}

/**
 * Step 1 — request a 6-digit reset code emailed to the user.
 */
exports.requestPasswordResetCode = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    const email = normalizeEmail(request.data?.email);
    if (!isValidEmail(email)) {
      throw new HttpsError("invalid-argument", "ئیمەیڵێکی دروست بنووسە");
    }

    const db = getFirestore();
    const docId = resetDocId(email);
    const ref = db.collection("passwordResets").doc(docId);
    const existing = await ref.get();
    if (existing.exists) {
      const last = existing.data()?.sentAt?.toMillis?.() || 0;
      if (Date.now() - last < RESEND_COOLDOWN_MS) {
        throw new HttpsError(
          "resource-exhausted",
          "تکایە ١ خولەک چاوەڕوان بە پێش دووبارە ناردن"
        );
      }
    }

    // Always respond ok (don't leak whether the account exists).
    let uid = null;
    try {
      const user = await getAuth().getUserByEmail(email);
      uid = user.uid;
    } catch (_) {
      logger.info("Password reset requested for unknown email");
      return { ok: true };
    }

    const code = generateCode();
    const salt = crypto.randomBytes(16).toString("hex");
    const codeHash = hashCode(code, salt);
    const expiresAt = Date.now() + CODE_TTL_MS;

    await ref.set({
      email,
      uid,
      codeHash,
      salt,
      expiresAt,
      attempts: 0,
      sentAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const mail = buildResetEmail(code);
    let sent = false;
    try {
      sent = await trySendSmtp({ to: email, ...mail });
    } catch (err) {
      logger.error("SMTP send failed", err);
    }
    if (!sent) {
      await queueMail(db, { to: email, ...mail });
      logger.info("Reset code queued to mail collection", email);
    } else {
      logger.info("Reset code emailed via SMTP", email);
    }

    const payload = { ok: true };
    // Emulator-only helper so local testing works without SMTP.
    if (process.env.FUNCTIONS_EMULATOR === "true") {
      payload.debugCode = code;
    }
    return payload;
  }
);

/**
 * Step 2 — verify code + set a new password (Admin SDK).
 */
exports.resetPasswordWithCode = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    const email = normalizeEmail(request.data?.email);
    const code = String(request.data?.code || "").trim();
    const newPassword = String(request.data?.newPassword || "");

    if (!isValidEmail(email)) {
      throw new HttpsError("invalid-argument", "ئیمەیڵێکی دروست بنووسە");
    }
    if (!/^\d{6}$/.test(code)) {
      throw new HttpsError("invalid-argument", "کۆدی ٦ ژمارەیی بنووسە");
    }
    if (newPassword.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "وشەی نهێنی نوێ لانیکەم ٦ کاراکتەر بێت"
      );
    }

    const db = getFirestore();
    const ref = db.collection("passwordResets").doc(resetDocId(email));
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "کۆد نادروستە یان بەسەرچووە");
    }

    const data = snap.data() || {};
    if ((data.attempts || 0) >= MAX_ATTEMPTS) {
      await ref.delete().catch(() => {});
      throw new HttpsError(
        "resource-exhausted",
        "هەوڵی زۆر درا — دووبارە کۆد داوا بکە"
      );
    }
    if (!data.expiresAt || Date.now() > data.expiresAt) {
      await ref.delete().catch(() => {});
      throw new HttpsError("deadline-exceeded", "کۆدەکە بەسەرچوو — دووبارە داوا بکە");
    }

    const expected = hashCode(code, data.salt || "");
    if (expected !== data.codeHash) {
      await ref.update({
        attempts: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      throw new HttpsError("permission-denied", "کۆد هەڵەیە");
    }

    try {
      const user =
        data.uid != null
          ? await getAuth().getUser(data.uid)
          : await getAuth().getUserByEmail(email);
      await getAuth().updateUser(user.uid, { password: newPassword });
    } catch (err) {
      logger.error("Password update failed", err);
      throw new HttpsError("internal", "نەتوانرا وشەی نهێنی بگۆڕدرێت");
    }

    await ref.delete().catch(() => {});
    return { ok: true };
  }
);

const ALLOWED_ADMIN_EMAILS = String(
  process.env.ADMIN_EMAILS || "admin@qopcha.com",
)
  .split(",")
  .map((value) => normalizeEmail(value))
  .filter(Boolean);

const CALL_OPTS = { region: "us-central1" };

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "پێویستە بچیتە ژوورەوە");
  }
  return request.auth;
}

async function requireAdmin(request) {
  const auth = requireAuth(request);
  if (auth.token.admin === true) return auth;
  const profile = await getFirestore().collection("users").doc(auth.uid).get();
  if (profile.exists && profile.data().role === "admin") {
    return auth;
  }
  throw new HttpsError("permission-denied", "مۆڵەتی ئەدمینت نییە");
}

function clientIp(request) {
  const headers = request?.rawRequest?.headers || {};
  const forwarded = headers["x-forwarded-for"] || headers["x-appengine-user-ip"];
  if (typeof forwarded === "string" && forwarded.trim()) {
    return forwarded.split(",")[0].trim();
  }
  return request?.rawRequest?.ip || "";
}

async function writeAudit(auth, action, payload, request) {
  await getFirestore().collection("adminAuditLogs").add({
    uid: auth.uid,
    email: auth.token.email || "",
    action,
    payload: payload || {},
    ip: clientIp(request),
    createdAt: FieldValue.serverTimestamp(),
  });
}

function notificationDoc({
  type,
  title,
  body,
  targetUserId = null,
  shopOwnerId = "",
  shopName = "قۆپچە",
  productId = "",
  productName = "",
  category = "system",
  imageUrl = null,
}) {
  const targeted = Boolean(targetUserId);
  return {
    type,
    title,
    body,
    shopOwnerId,
    shopName,
    productId,
    productName,
    category,
    imageUrl,
    audience: targeted ? "user" : "all",
    createdAt: new Date().toISOString(),
    ...(targeted ? { targetUserId } : {}),
  };
}

exports.bootstrapAdminClaim = onCall(CALL_OPTS, async (request) => {
  const auth = requireAuth(request);
  const email = normalizeEmail(auth.token.email);
  if (!ALLOWED_ADMIN_EMAILS.includes(email)) {
    throw new HttpsError(
      "permission-denied",
      "ئەم ئیمەیڵە ڕێگەپێدراوی ئەدمین نییە",
    );
  }
  const db = getFirestore();
  await db.collection("users").doc(auth.uid).set(
    {
      role: "admin",
      email,
      approvalStatus: "approved",
      approvalNoticeSeen: true,
    },
    { merge: true },
  );
  await getAuth().setCustomUserClaims(auth.uid, { admin: true });
  await writeAudit(auth, "bootstrapAdminClaim", { email }, request);
  return { ok: true };
});

exports.adminAction = onCall(CALL_OPTS, async (request) => {
  const auth = await requireAdmin(request);
  const action = String(request.data?.action || "").trim();
  const data = request.data || {};
  const db = getFirestore();
  const audit = (payload) => writeAudit(auth, action, payload, request);

  switch (action) {
    case "setApproval": {
      const userId = String(data.userId || "").trim();
      const status = String(data.status || "").trim();
      if (!userId || !["approved", "rejected", "pending"].includes(status)) {
        throw new HttpsError("invalid-argument", "داتای پەسەندکردن هەڵەیە");
      }
      const payload = { approvalStatus: status };
      if (status === "rejected") {
        payload.rejectionReason =
          String(data.rejectionReason || "").trim() ||
          "هەژمارەکەت لەلایەن ئەدمینەوە ڕەتکرایەوە";
      } else {
        payload.rejectionReason = null;
      }
      if (status === "approved") payload.approvalNoticeSeen = false;
      await db.collection("users").doc(userId).set(payload, { merge: true });
      if (status === "approved") {
        await db.collection("notifications").add(
          notificationDoc({
            type: "account_approved",
            title: "هەژمارەکەت پەسەندکرا",
            body: "هەژمارەکەت لەلایەن بەڕێوەبەرەوە پەسەندکرا. ئێستا دەتوانیت بەردەوام بیت.",
            category: "account",
            targetUserId: userId,
          }),
        );
      }
      await audit( { userId, status });
      return { ok: true };
    }

    case "setShopTier": {
      const userId = String(data.userId || "").trim();
      const shopTier = String(data.shopTier || "").trim();
      if (!userId || !["silver", "gold", "platinum"].includes(shopTier)) {
        throw new HttpsError("invalid-argument", "پلانی دووکان هەڵەیە");
      }
      await db.collection("users").doc(userId).set({ shopTier }, { merge: true });
      await audit( { userId, shopTier });
      return { ok: true };
    }

    case "setCustomerDiscount": {
      const userId = String(data.userId || "").trim();
      const product = Math.min(70, Math.max(0, Number(data.productDiscountPercent) || 0));
      const delivery = Math.min(100, Math.max(0, Number(data.deliveryDiscountPercent) || 0));
      if (!userId) throw new HttpsError("invalid-argument", "کڕیار دیاری نەکراوە");
      await db.collection("users").doc(userId).set(
        { productDiscountPercent: product, deliveryDiscountPercent: delivery },
        { merge: true },
      );
      if (product > 0 || delivery > 0) {
        await db.collection("notifications").add(
          notificationDoc({
            type: "discount_assigned",
            title: "داشکاندنی تایبەتت بۆ دانرا",
            body: `داشکاندنی بەرهەم ${product}٪، داشکاندنی گەیاندن ${delivery}٪`,
            category: "discount",
            targetUserId: userId,
          }),
        );
      }
      await audit( { userId, product, delivery });
      return { ok: true };
    }

    case "updateOrderStatus": {
      const orderId = String(data.orderId || "").trim();
      const status = String(data.status || "").trim();
      const allowed = ["pending", "confirmed", "ready", "shipped", "completed", "cancelled"];
      if (!orderId || !allowed.includes(status)) {
        throw new HttpsError("invalid-argument", "دۆخی داواکاری هەڵەیە");
      }
      await db.collection("orders").doc(orderId).update({
        status,
        statusUpdatedAt: new Date().toISOString(),
      });
      await audit( { orderId, status });
      return { ok: true };
    }

    case "setOrderDelivery": {
      const orderId = String(data.orderId || "").trim();
      const zoneId = String(data.zoneId || "").trim();
      const fee = Math.max(0, Number(data.fee) || 0);
      if (!orderId || !zoneId) {
        throw new HttpsError("invalid-argument", "ناوچەی گەیاندن هەڵەیە");
      }
      await db.collection("orders").doc(orderId).update({
        deliveryZone: zoneId,
        deliveryFee: fee,
        deliveryUpdatedAt: new Date().toISOString(),
      });
      await audit( { orderId, zoneId, fee });
      return { ok: true };
    }

    case "setProductDiscount": {
      const productId = String(data.productId || "").trim();
      const amount = Math.min(70, Math.max(0, Number(data.discountPercent) || 0));
      const forAll = Boolean(data.discountForAllCustomers) || amount <= 0;
      const customerIds = Array.isArray(data.discountCustomerIds)
        ? data.discountCustomerIds.map((id) => String(id)).filter(Boolean)
        : [];
      if (!productId) throw new HttpsError("invalid-argument", "بەرهەم دیاری نەکراوە");
      await db.collection("products").doc(productId).update({
        discountPercent: amount,
        discountForAllCustomers: forAll,
        discountCustomerIds: forAll ? [] : customerIds,
        discountSetBy: amount > 0 ? "admin" : "",
        updatedAt: new Date().toISOString(),
      });
      if (amount > 0) {
        const productSnap = await db.collection("products").doc(productId).get();
        const product = productSnap.data() || {};
        const targets = forAll ? [null] : customerIds;
        await Promise.all(
          targets.map((targetUserId) =>
            db.collection("notifications").add(
              notificationDoc({
                type: "discount_assigned",
                title: "داشکاندنی نوێ",
                body: `${product.name || "بەرهەم"} بە ${amount}٪ داشکاندن`,
                shopOwnerId: product.shopOwnerId || "",
                shopName: product.shopName || "دووکان",
                productId,
                productName: product.name || "",
                category: "discount",
                imageUrl: Array.isArray(product.imageUrls) ? product.imageUrls[0] : null,
                targetUserId,
              }),
            ),
          ),
        );
      }
      await audit( { productId, amount, forAll });
      return { ok: true };
    }

    case "deleteProduct": {
      const productId = String(data.productId || "").trim();
      if (!productId) throw new HttpsError("invalid-argument", "بەرهەم دیاری نەکراوە");
      await db.collection("products").doc(productId).delete();
      await audit( { productId });
      return { ok: true };
    }

    case "setProductFeatured": {
      const productId = String(data.productId || "").trim();
      if (!productId) throw new HttpsError("invalid-argument", "بەرهەم دیاری نەکراوە");
      await db.collection("products").doc(productId).update({
        isFeatured: Boolean(data.isFeatured),
        updatedAt: new Date().toISOString(),
      });
      await audit( { productId, isFeatured: Boolean(data.isFeatured) });
      return { ok: true };
    }

    case "saveBanner": {
      const values = data.values || {};
      const id = String(data.id || "").trim();
      const ref = id
        ? db.collection("banners").doc(id)
        : db.collection("banners").doc();
      await ref.set(
        { ...values, createdAt: new Date().toISOString() },
        { merge: true },
      );
      await audit( { id: ref.id });
      return { ok: true, id: ref.id };
    }

    case "setBannerActive": {
      const id = String(data.id || "").trim();
      if (!id) throw new HttpsError("invalid-argument", "بانەر دیاری نەکراوە");
      await db.collection("banners").doc(id).update({ active: Boolean(data.active) });
      await audit( { id, active: Boolean(data.active) });
      return { ok: true };
    }

    case "deleteBanner": {
      const id = String(data.id || "").trim();
      if (!id) throw new HttpsError("invalid-argument", "بانەر دیاری نەکراوە");
      await db.collection("banners").doc(id).delete();
      await audit( { id });
      return { ok: true };
    }

    case "saveAppContent": {
      const values = data.values || {};
      await db.collection("appContent").doc("main").set(
        { ...values, updatedAt: new Date().toISOString() },
        { merge: true },
      );
      await audit( { keys: Object.keys(values) });
      return { ok: true };
    }

    case "sendAnnouncement": {
      const title = String(data.title || "").trim();
      const body = String(data.body || "").trim();
      const category = String(data.category || "system").trim() || "system";
      if (!title || !body) {
        throw new HttpsError("invalid-argument", "ناونیشان و دەق پێویستن");
      }
      await db.collection("notifications").add(
        notificationDoc({
          type: "admin_announcement",
          title,
          body,
          category,
        }),
      );
      await audit( { title, category });
      return { ok: true };
    }

    default:
      throw new HttpsError("invalid-argument", "کرداری نەناسراو");
  }
});

