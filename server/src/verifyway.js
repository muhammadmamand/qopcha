'use strict';

/**
 * Standing Tech SMS / WhatsApp gateway
 * POST https://gateway.standingtech.com/api/v4/sms/send
 *
 * Body example:
 * {
 *   "recipient": "9647502171212",
 *   "sender_id": "QopchaApp",
 *   "type": "whatsapp",   // or "sms"
 *   "message": "362514",
 *   "lang": "en"
 * }
 */
async function sendViaStandingTech({ recipientDigits, message, type }) {
  const token = (process.env.VERIFYWAY_API_TOKEN || process.env.STANDING_API_TOKEN || '').trim();
  if (!token) {
    throw new Error('VERIFYWAY_API_TOKEN is not configured');
  }

  const url = (
    process.env.STANDING_API_URL ||
    process.env.VERIFYWAY_API_URL ||
    'https://gateway.standingtech.com/api/v4/sms/send'
  ).trim();

  const senderId = (
    process.env.STANDING_SENDER_ID ||
    process.env.VERIFYWAY_SENDER ||
    'QopchaApp'
  ).trim();

  const lang = (process.env.STANDING_LANG || 'en').trim();
  const channel = String(type || 'whatsapp').toLowerCase();

  const body = {
    recipient: String(recipientDigits).replace(/\D/g, ''),
    sender_id: senderId,
    type: channel,
    message: String(message),
    lang,
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify(body),
  });

  const text = await res.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { raw: text };
  }

  if (!res.ok) {
    const msg =
      data.error ||
      data.message ||
      data.msg ||
      (typeof data.raw === 'string' ? data.raw : null) ||
      `StandingTech HTTP ${res.status}`;
    const err = new Error(String(msg));
    err.status = res.status;
    err.payload = data;
    err.channel = channel;
    throw err;
  }

  // Some gateways return 200 with status/success flags.
  const status = String(data.status || data.result || '').toLowerCase();
  if (
    status &&
    status !== 'success' &&
    status !== 'ok' &&
    status !== 'queued' &&
    status !== '1' &&
    data.success === false
  ) {
    const err = new Error(data.error || data.message || 'StandingTech send failed');
    err.channel = channel;
    err.payload = data;
    throw err;
  }

  return { ...data, channel };
}

/**
 * WhatsApp first, then SMS if WhatsApp delivery fails.
 * Skips fallback for auth / config errors.
 */
async function sendOtpWithFallback({ recipientE164, code }) {
  const primary = (process.env.VERIFYWAY_CHANNEL || 'whatsapp').trim().toLowerCase();
  const fallback = (process.env.VERIFYWAY_FALLBACK_CHANNEL || 'sms').trim().toLowerCase();
  const recipientDigits = String(recipientE164 || '').replace(/\D/g, '');

  try {
    return await sendViaStandingTech({
      recipientDigits,
      message: String(code),
      type: primary,
    });
  } catch (err) {
    const msg = String(err.message || '').toLowerCase();
    const noFallback =
      msg.includes('invalid api key') ||
      msg.includes('unauthorized') ||
      msg.includes('unauthenticated') ||
      msg.includes('not configured') ||
      err.status === 401 ||
      err.status === 403 ||
      !fallback ||
      fallback === primary;

    if (noFallback) throw err;

    console.warn(
      `StandingTech ${primary} failed (${err.message}); falling back to ${fallback}`,
    );
    return await sendViaStandingTech({
      recipientDigits,
      message: String(code),
      type: fallback,
    });
  }
}

/** @deprecated alias */
async function sendWhatsAppOtp(args) {
  return sendOtpWithFallback(args);
}

async function sendOtpViaChannel({ recipientE164, code, channel }) {
  return sendViaStandingTech({
    recipientDigits: String(recipientE164 || '').replace(/\D/g, ''),
    message: String(code),
    type: channel,
  });
}

/** 07xxxxxxxxx → +9647xxxxxxxxx (store still uses + form; gateway gets digits only) */
function toE164Iraq(localPhone) {
  const p = String(localPhone || '').replace(/\D/g, '');
  if (p.startsWith('964')) return `+${p}`;
  if (p.startsWith('0')) return `+964${p.slice(1)}`;
  return `+964${p}`;
}

module.exports = {
  sendViaStandingTech,
  sendOtpViaChannel,
  sendOtpWithFallback,
  sendWhatsAppOtp,
  toE164Iraq,
};
