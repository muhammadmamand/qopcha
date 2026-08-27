'use strict';

const fs = require('fs');
const path = require('path');

/**
 * Simple JSON file store (no native deps — works on Windows + Docker).
 * Auth rows: { id, phone, password_hash, email? }
 * resetCodes / otpCodes keyed by phone (+ purpose for otp).
 */
function createStore(dataDir) {
  const file = path.join(dataDir, 'store.json');
  let state = { auth: {}, documents: {}, resetCodes: {}, otpCodes: {} };

  function load() {
    if (!fs.existsSync(file)) return;
    try {
      state = {
        auth: {},
        documents: {},
        resetCodes: {},
        otpCodes: {},
        ...JSON.parse(fs.readFileSync(file, 'utf8')),
      };
      state.auth = state.auth || {};
      state.documents = state.documents || {};
      state.resetCodes = state.resetCodes || {};
      state.otpCodes = state.otpCodes || {};
    } catch (e) {
      console.error('Failed to load store.json, starting empty:', e.message);
    }
  }

  function save() {
    const tmp = `${file}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(state));
    fs.renameSync(tmp, file);
  }

  load();

  return {
    getAuthByPhone(phone) {
      return Object.values(state.auth).find((r) => r.phone === phone) || null;
    },
    getAuthByEmail(email) {
      return Object.values(state.auth).find((r) => r.email === email) || null;
    },
    getAuthById(id) {
      return state.auth[id] || null;
    },
    insertAuth(row) {
      state.auth[row.id] = row;
      save();
    },
    updateAuthPassword(id, password_hash) {
      if (!state.auth[id]) return;
      state.auth[id] = { ...state.auth[id], password_hash };
      save();
    },
    updateAuthPhone(id, phone) {
      if (!state.auth[id]) return;
      state.auth[id] = { ...state.auth[id], phone };
      save();
    },
    setResetCode(phone, code, expires_at) {
      state.resetCodes[phone] = { phone, code, expires_at };
      save();
    },
    getResetCode(phone) {
      return state.resetCodes[phone] || null;
    },
    deleteResetCode(phone) {
      delete state.resetCodes[phone];
      save();
    },
    setOtp(phone, purpose, code, expires_at) {
      const key = `${purpose}:${phone}`;
      state.otpCodes[key] = { phone, purpose, code, expires_at };
      save();
    },
    getOtp(phone, purpose) {
      return state.otpCodes[`${purpose}:${phone}`] || null;
    },
    deleteOtp(phone, purpose) {
      delete state.otpCodes[`${purpose}:${phone}`];
      save();
    },
    read(col, id) {
      const data = state.documents[col]?.[id];
      if (!data) return null;
      return { ...data, id };
    },
    write(col, id, data) {
      if (!state.documents[col]) state.documents[col] = {};
      const payload = { ...data, id };
      state.documents[col][id] = payload;
      save();
      return payload;
    },
    deleteDoc(col, id) {
      if (state.documents[col]) {
        delete state.documents[col][id];
        save();
      }
    },
    all(col) {
      const bag = state.documents[col] || {};
      return Object.entries(bag).map(([id, data]) => ({ ...data, id }));
    },
  };
}

module.exports = { createStore };
