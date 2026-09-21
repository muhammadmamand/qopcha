'use strict';

const bcrypt = require('bcryptjs');
const { Client } = require('pg');

const NEW = '07503727574';
const PASS = process.env.ADMIN_PASSWORD || 'Admin123456';
const EMAIL = (process.env.ADMIN_EMAIL || 'admin@qopcha.com').toLowerCase();
const DATABASE_URL = (process.env.DATABASE_URL || '').trim();

function normalizePhone(raw) {
  let p = String(raw || '').replace(/[\s\-()]/g, '');
  if (p.startsWith('+964')) p = `0${p.slice(4)}`;
  else if (p.startsWith('964')) p = `0${p.slice(3)}`;
  return p;
}

(async () => {
  if (!DATABASE_URL) throw new Error('no DATABASE_URL');
  const hash = await bcrypt.hash(PASS, 12);
  const client = new Client({ connectionString: DATABASE_URL });
  await client.connect();

  const auth = await client.query('SELECT id, phone, email FROM auth ORDER BY id');
  console.log('auth_count', auth.rows.length);

  let admins = [];
  try {
    const q = await client.query(
      `SELECT id, data->>'role' AS role, data->>'phone' AS phone
       FROM docs WHERE collection = 'users' AND (data->>'role') = 'admin'`,
    );
    admins = q.rows;
    console.log('admin_docs', admins.map((a) => ({ id: a.id, phone: a.phone })));
  } catch (e) {
    console.log('docs_fail', e.message);
  }

  let targetId =
    (admins[0] && admins[0].id) ||
    (auth.rows.find((r) => normalizePhone(r.phone) === NEW) || {}).id ||
    (auth.rows.find((r) => String(r.email || '').toLowerCase() === EMAIL) || {}).id ||
    (auth.rows.find((r) => normalizePhone(r.phone) === '07500000000') || {}).id ||
    null;

  if (!targetId) throw new Error('no admin auth target');

  // Free phone if another row already has NEW
  await client.query('UPDATE auth SET phone = NULL WHERE phone = $1 AND id <> $2', [NEW, targetId]);

  // Update phone + password only (avoid email unique collisions)
  await client.query('UPDATE auth SET phone = $1, password_hash = $2 WHERE id = $3', [
    NEW,
    hash,
    targetId,
  ]);

  try {
    const u = await client.query(`SELECT data FROM docs WHERE collection='users' AND id=$1`, [
      targetId,
    ]);
    if (u.rows[0]) {
      const data = { ...(u.rows[0].data || {}) };
      data.phone = NEW;
      data.role = 'admin';
      await client.query(`UPDATE docs SET data=$1::jsonb WHERE collection='users' AND id=$2`, [
        JSON.stringify(data),
        targetId,
      ]);
    }
  } catch (e) {
    console.log('user_update_skip', e.message);
  }

  const check = await client.query('SELECT id, phone, email FROM auth WHERE id=$1', [targetId]);
  console.log('updated', check.rows[0]);
  await client.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
