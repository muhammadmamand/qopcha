'use strict';

const { createStore } = require('./store');
const { createPgStore } = require('./store_pg');

/** Wrap sync JSON store methods as async for a uniform API. */
function wrapJsonStore(syncStore) {
  const wrap = (fn) => (...args) => Promise.resolve(fn(...args));
  return {
    init: async () => {},
    close: async () => {},
    getAuthByPhone: wrap(syncStore.getAuthByPhone.bind(syncStore)),
    getAuthByEmail: wrap(syncStore.getAuthByEmail.bind(syncStore)),
    getAuthById: wrap(syncStore.getAuthById.bind(syncStore)),
    insertAuth: wrap(syncStore.insertAuth.bind(syncStore)),
    updateAuthPassword: wrap(syncStore.updateAuthPassword.bind(syncStore)),
    updateAuthPhone: wrap(syncStore.updateAuthPhone.bind(syncStore)),
    setResetCode: wrap(syncStore.setResetCode.bind(syncStore)),
    getResetCode: wrap(syncStore.getResetCode.bind(syncStore)),
    deleteResetCode: wrap(syncStore.deleteResetCode.bind(syncStore)),
    setOtp: wrap(syncStore.setOtp.bind(syncStore)),
    getOtp: wrap(syncStore.getOtp.bind(syncStore)),
    deleteOtp: wrap(syncStore.deleteOtp.bind(syncStore)),
    read: wrap(syncStore.read.bind(syncStore)),
    write: wrap(syncStore.write.bind(syncStore)),
    deleteDoc: wrap(syncStore.deleteDoc.bind(syncStore)),
    all: wrap(syncStore.all.bind(syncStore)),
  };
}

/**
 * @param {{ dataDir: string, databaseUrl?: string }} opts
 * @returns {Promise<{ store: object, backend: 'postgres' | 'json' }>}
 */
async function createAppStore({ dataDir, databaseUrl }) {
  const url = (databaseUrl || '').trim();
  if (url) {
    const store = createPgStore(url);
    await store.init();
    console.log('Storage: PostgreSQL');
    return { store, backend: 'postgres' };
  }
  console.log('Storage: JSON file (store.json) — set DATABASE_URL for PostgreSQL');
  return { store: wrapJsonStore(createStore(dataDir)), backend: 'json' };
}

module.exports = { createAppStore };
