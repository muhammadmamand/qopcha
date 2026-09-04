'use strict';

/**
 * Optional Firebase Cloud Messaging from the Contabo API.
 * Without credentials, notifications still save in the API inbox —
 * phones only see them after opening the app.
 *
 * Set one of:
 *   FIREBASE_SERVICE_ACCOUNT_JSON='{...service account json...}'
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 */

let messaging = null;
let initAttempted = false;

function tryInit() {
  if (initAttempted) return messaging;
  initAttempted = true;
  try {
    // eslint-disable-next-line global-require
    const admin = require('firebase-admin');
    if (admin.apps.length) {
      messaging = admin.messaging();
      return messaging;
    }
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (raw && raw.trim()) {
      const cred = JSON.parse(raw);
      admin.initializeApp({
        credential: admin.credential.cert(cred),
        projectId: cred.project_id || 'qopchaapp',
      });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID || 'qopchaapp',
      });
    } else {
      console.warn(
        '[fcm] No FIREBASE_SERVICE_ACCOUNT_JSON / GOOGLE_APPLICATION_CREDENTIALS — push disabled',
      );
      return null;
    }
    messaging = admin.messaging();
    console.log('[fcm] Firebase Admin messaging ready');
  } catch (err) {
    console.warn('[fcm] init skipped:', err.message || err);
    messaging = null;
  }
  return messaging;
}

function basePayload(notification) {
  const title = String(notification.title || 'قۆپچە').slice(0, 200);
  const body = String(notification.body || '').slice(0, 500);
  const data = {
    type: String(notification.type || ''),
    productId: String(notification.productId || ''),
    shopOwnerId: String(notification.shopOwnerId || ''),
    notificationId: String(notification.id || ''),
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };
  return {
    notification: { title, body },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'qopcha_new_products',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: { sound: 'default', badge: 1 },
      },
    },
  };
}

async function sendToTopic(topic, notification) {
  const msg = tryInit();
  if (!msg) return;
  try {
    const id = await msg.send({
      topic,
      ...basePayload(notification),
    });
    console.log('[fcm] topic', topic, id);
  } catch (err) {
    console.warn('[fcm] topic send failed:', err.message || err);
  }
}

async function sendToTokens(tokens, notification) {
  const msg = tryInit();
  if (!msg || !tokens.length) return;
  const unique = [...new Set(tokens.map((t) => String(t || '').trim()).filter(Boolean))];
  if (!unique.length) return;
  try {
    const result = await msg.sendEachForMulticast({
      tokens: unique,
      ...basePayload(notification),
    });
    console.log(
      '[fcm] multicast',
      unique.length,
      'ok=',
      result.successCount,
      'fail=',
      result.failureCount,
    );
  } catch (err) {
    console.warn('[fcm] multicast failed:', err.message || err);
  }
}

/**
 * @param {object} notification saved notification row
 * @param {{ read: Function, all: Function }} store helpers
 */
async function pushForNotification(notification, store) {
  if (!notification || !notification.type) return;
  const type = String(notification.type);
  const target = String(notification.targetUserId || '').trim();

  // Targeted: send only to that user's saved FCM token(s).
  if (target) {
    const user = await store.read('users', target);
    if (!user) return;
    const tokens = [];
    if (user.fcmToken) tokens.push(user.fcmToken);
    if (Array.isArray(user.fcmTokens)) tokens.push(...user.fcmTokens);
    await sendToTokens(tokens, notification);
    return;
  }

  // Broadcast new products → topic customers subscribe to.
  if (type === 'new_product') {
    await sendToTopic('new_products', notification);
    return;
  }

  // Admin announcements / global discounts → all customers with tokens.
  if (type === 'admin_announcement' || type === 'discount_assigned') {
    const users = await store.all('users');
    const tokens = [];
    for (const u of users) {
      if (u.role === 'shopOwner' || u.role === 'admin') continue;
      if (u.fcmToken) tokens.push(u.fcmToken);
      if (Array.isArray(u.fcmTokens)) tokens.push(...u.fcmTokens);
    }
    await sendToTokens(tokens, notification);
  }
}

module.exports = { pushForNotification, tryInit };
