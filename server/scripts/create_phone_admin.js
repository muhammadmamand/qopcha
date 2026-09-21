'use strict';

/**
 * Create a NEW phone-only admin account on Contabo.
 * Does not convert an existing customer — frees the phone if needed, then inserts admin.
 */
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { Client } = require('pg');

const NEW = '07503727574';
const PASS = process.env.ADMIN_PASSWORD || 'Admin123456';
const DATABASE_URL = (process.env.DATABASE_URL || '').trim();

function uuid() {
  return crypto.randomUUID();
}

(async () => {
  if (!DATABASE_URL) throw new Error('DATABASE_URL missing');
  const hash = await bcrypt.hash(PASS, 12);
  const client = new Client({ connectionString: DATABASE_URL });
  await client.connect();

  // Free phone from any existing auth row (do not delete those accounts).
  const existing = await client.query('SELECT id, phone FROM auth WHERE phone = $1', [NEW]);
  for (const row of existing.rows) {
    await client.query('UPDATE auth SET phone = NULL WHERE id = $1', [row.id]);
    console.log('freed_phone_from', row.id);
  }

  // If an admin user doc already exists for this phone, reuse its id; else new id.
  let adminId = null;
  const adminDocs = await client.query(
    `SELECT id, data FROM documents
     WHERE collection = 'users' AND (data->>'role') = 'admin'
     LIMIT 5`,
  );
  for (const row of adminDocs.rows) {
    const phone = String((row.data && row.data.phone) || '');
    if (phone === NEW || !phone) {
      adminId = row.id;
      break;
    }
  }

  if (!adminId) adminId = uuid();

  const authExists = await client.query('SELECT id FROM auth WHERE id = $1', [adminId]);
  if (authExists.rows[0]) {
    await client.query(
      'UPDATE auth SET phone = $1, email = NULL, password_hash = $2 WHERE id = $3',
      [NEW, hash, adminId],
    );
    console.log('updated_auth', adminId);
  } else {
    await client.query(
      'INSERT INTO auth (id, phone, email, password_hash) VALUES ($1, $2, NULL, $3)',
      [adminId, NEW, hash],
    );
    console.log('inserted_auth', adminId);
  }

  const userDoc = {
    id: adminId,
    name: 'ئەدمین',
    phone: NEW,
    role: 'admin',
    approvalStatus: 'approved',
    approvalNoticeSeen: true,
    createdAt: new Date().toISOString(),
  };
  await client.query(
    `INSERT INTO documents (collection, id, data, updated_at)
     VALUES ('users', $1, $2::jsonb, NOW())
     ON CONFLICT (collection, id) DO UPDATE SET data = EXCLUDED.data, updated_at = NOW()`,
    [adminId, JSON.stringify(userDoc)],
  );
  console.log('wrote_admin_user', adminId);

  await client.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
