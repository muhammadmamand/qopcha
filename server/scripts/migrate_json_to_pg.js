'use strict';

/**
 * One-time migration: server/data/store.json → PostgreSQL
 * Usage: DATABASE_URL=postgres://... node scripts/migrate_json_to_pg.js
 */
const fs = require('fs');
const path = require('path');
const { createPgStore } = require('../src/store_pg');

const ROOT = path.join(__dirname, '..');
const JSON_FILE = path.join(ROOT, 'data', 'store.json');
const DATABASE_URL = process.env.DATABASE_URL;

async function main() {
  if (!DATABASE_URL) {
    console.error('Set DATABASE_URL (e.g. postgres://qopcha:pass@localhost:5432/qopcha)');
    process.exit(1);
  }
  if (!fs.existsSync(JSON_FILE)) {
    console.error('No store.json found at', JSON_FILE);
    process.exit(1);
  }

  const raw = JSON.parse(fs.readFileSync(JSON_FILE, 'utf8'));
  const store = createPgStore(DATABASE_URL);
  await store.init();

  let authCount = 0;
  for (const row of Object.values(raw.auth || {})) {
    const existing = row.email
      ? await store.getAuthByEmail(row.email)
      : await store.getAuthByPhone(row.phone);
    if (!existing) {
      await store.insertAuth(row);
      authCount++;
    }
  }

  for (const [phone, row] of Object.entries(raw.resetCodes || {})) {
    await store.setResetCode(phone, row.code, row.expires_at);
  }

  for (const [key, row] of Object.entries(raw.otpCodes || {})) {
    await store.setOtp(row.phone, row.purpose, row.code, row.expires_at);
  }

  let docCount = 0;
  for (const [col, bag] of Object.entries(raw.documents || {})) {
    for (const [id, data] of Object.entries(bag || {})) {
      await store.write(col, id, data);
      docCount++;
    }
  }

  await store.close();
  console.log(`Migrated ${authCount} auth rows, ${docCount} documents from store.json`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
