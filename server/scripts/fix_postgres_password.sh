#!/usr/bin/env bash
# Sync Postgres user password with POSTGRES_PASSWORD in .env (safe local socket auth).
set -euo pipefail
cd /opt/qopcha-api

POSTGRES_USER=$(grep '^POSTGRES_USER=' .env | cut -d= -f2-)
POSTGRES_PASSWORD=$(grep '^POSTGRES_PASSWORD=' .env | cut -d= -f2-)
POSTGRES_DB=$(grep '^POSTGRES_DB=' .env | cut -d= -f2-)

docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "ALTER USER \"$POSTGRES_USER\" WITH PASSWORD '$POSTGRES_PASSWORD';"

docker compose up -d api
sleep 6
curl -fsS http://127.0.0.1:8080/api/health
echo ""
