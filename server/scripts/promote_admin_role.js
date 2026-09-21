'use strict';

const { Client } = require('pg');

const NEW = '07503727574';
const ID = 'df359fd9-c5b7-412a-8e47-58ea0b124a6b';
const DATABASE_URL = (process.env.DATABASE_URL || '').trim();

(async () => {
  const client = new Client({ connectionString: DATABASE_URL });
  await client.connect();

  const { rows } = await client.query(
    `SELECT id, data FROM documents WHERE collection = 'users' AND id = $1`,
    [ID],
  );
  if (!rows[0]) {
    // fallback by phone
    const all = await client.query(
      `SELECT id, data FROM documents WHERE collection = 'users' AND data->>'phone' = $1`,
      [NEW],
    );
    if (!all.rows[0]) throw new Error('user document not found');
    rows[0] = all.rows[0];
  }

  const data = { ...(rows[0].data || {}) };
  data.phone = NEW;
  data.role = 'admin';
  data.approvalStatus = 'approved';
  data.approvalNoticeSeen = true;

  await client.query(
    `UPDATE documents SET data = $1::jsonb, updated_at = NOW()
     WHERE collection = 'users' AND id = $2`,
    [JSON.stringify(data), rows[0].id],
  );
  console.log('promoted', rows[0].id, 'role=admin');
  await client.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
