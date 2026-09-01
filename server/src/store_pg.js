'use strict';

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

function createPgStore(connectionString) {
  const pool = new Pool({
    connectionString,
    max: 20,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
  });

  async function init() {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');
    await pool.query(sql);
  }

  async function close() {
    await pool.end();
  }

  return {
    init,
    close,
    pool,

    async getAuthByPhone(phone) {
      const { rows } = await pool.query(
        'SELECT id, phone, email, password_hash FROM auth WHERE phone = $1 LIMIT 1',
        [phone],
      );
      return rows[0] || null;
    },

    async getAuthByEmail(email) {
      const { rows } = await pool.query(
        'SELECT id, phone, email, password_hash FROM auth WHERE lower(email) = lower($1) LIMIT 1',
        [email],
      );
      return rows[0] || null;
    },

    async getAuthById(id) {
      const { rows } = await pool.query(
        'SELECT id, phone, email, password_hash FROM auth WHERE id = $1 LIMIT 1',
        [id],
      );
      return rows[0] || null;
    },

    async insertAuth(row) {
      await pool.query(
        'INSERT INTO auth (id, phone, email, password_hash) VALUES ($1, $2, $3, $4)',
        [row.id, row.phone || null, row.email || null, row.password_hash],
      );
    },

    async updateAuthPassword(id, password_hash) {
      await pool.query('UPDATE auth SET password_hash = $2 WHERE id = $1', [
        id,
        password_hash,
      ]);
    },

    async updateAuthPhone(id, phone) {
      await pool.query('UPDATE auth SET phone = $2 WHERE id = $1', [id, phone]);
    },

    async setResetCode(phone, code, expires_at) {
      await pool.query(
        `INSERT INTO reset_codes (phone, code, expires_at) VALUES ($1, $2, $3)
         ON CONFLICT (phone) DO UPDATE SET code = EXCLUDED.code, expires_at = EXCLUDED.expires_at`,
        [phone, code, expires_at],
      );
    },

    async getResetCode(phone) {
      const { rows } = await pool.query(
        'SELECT phone, code, expires_at FROM reset_codes WHERE phone = $1',
        [phone],
      );
      return rows[0] || null;
    },

    async deleteResetCode(phone) {
      await pool.query('DELETE FROM reset_codes WHERE phone = $1', [phone]);
    },

    async setOtp(phone, purpose, code, expires_at) {
      await pool.query(
        `INSERT INTO otp_codes (purpose, phone, code, expires_at) VALUES ($1, $2, $3, $4)
         ON CONFLICT (purpose, phone) DO UPDATE SET code = EXCLUDED.code, expires_at = EXCLUDED.expires_at`,
        [purpose, phone, code, expires_at],
      );
    },

    async getOtp(phone, purpose) {
      const { rows } = await pool.query(
        'SELECT phone, purpose, code, expires_at FROM otp_codes WHERE purpose = $1 AND phone = $2',
        [purpose, phone],
      );
      return rows[0] || null;
    },

    async deleteOtp(phone, purpose) {
      await pool.query('DELETE FROM otp_codes WHERE purpose = $1 AND phone = $2', [
        purpose,
        phone,
      ]);
    },

    async read(col, id) {
      const { rows } = await pool.query(
        'SELECT data FROM documents WHERE collection = $1 AND id = $2',
        [col, id],
      );
      if (!rows[0]) return null;
      const data = rows[0].data;
      return { ...data, id: data.id || id };
    },

    async write(col, id, data) {
      const payload = { ...data, id };
      await pool.query(
        `INSERT INTO documents (collection, id, data, updated_at) VALUES ($1, $2, $3::jsonb, NOW())
         ON CONFLICT (collection, id) DO UPDATE SET data = EXCLUDED.data, updated_at = NOW()`,
        [col, id, JSON.stringify(payload)],
      );
      return payload;
    },

    async deleteDoc(col, id) {
      await pool.query('DELETE FROM documents WHERE collection = $1 AND id = $2', [col, id]);
    },

    async all(col) {
      const { rows } = await pool.query(
        'SELECT id, data FROM documents WHERE collection = $1',
        [col],
      );
      return rows.map((r) => ({ ...r.data, id: r.data.id || r.id }));
    },
  };
}

module.exports = { createPgStore };
