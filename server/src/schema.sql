-- قۆپچە (Qopcha) PostgreSQL schema

CREATE TABLE IF NOT EXISTS auth (
  id TEXT PRIMARY KEY,
  phone TEXT,
  email TEXT,
  password_hash TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS auth_phone_uidx ON auth (phone) WHERE phone IS NOT NULL AND phone <> '';
CREATE UNIQUE INDEX IF NOT EXISTS auth_email_uidx ON auth (lower(email)) WHERE email IS NOT NULL AND email <> '';

CREATE TABLE IF NOT EXISTS reset_codes (
  phone TEXT PRIMARY KEY,
  code TEXT NOT NULL,
  expires_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS otp_codes (
  purpose TEXT NOT NULL,
  phone TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at BIGINT NOT NULL,
  PRIMARY KEY (purpose, phone)
);

CREATE TABLE IF NOT EXISTS documents (
  collection TEXT NOT NULL,
  id TEXT NOT NULL,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (collection, id)
);

CREATE INDEX IF NOT EXISTS documents_collection_idx ON documents (collection);
