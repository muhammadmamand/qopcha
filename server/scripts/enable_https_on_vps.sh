#!/bin/bash
set -euo pipefail
cd /opt/qopcha-api

PUBLIC='https://169-58-230-144.sslip.io'
DOMAIN='169-58-230-144.sslip.io'
EMAIL='admin@qopcha.com'

touch .env
grep -q '^PUBLIC_URL=' .env && sed -i "s|^PUBLIC_URL=.*|PUBLIC_URL=${PUBLIC}|" .env || echo "PUBLIC_URL=${PUBLIC}" >> .env
grep -q '^DOMAIN=' .env && sed -i "s|^DOMAIN=.*|DOMAIN=${DOMAIN}|" .env || echo "DOMAIN=${DOMAIN}" >> .env
grep -q '^ACME_EMAIL=' .env && sed -i "s|^ACME_EMAIL=.*|ACME_EMAIL=${EMAIL}|" .env || echo "ACME_EMAIL=${EMAIL}" >> .env

export DOMAIN ACME_EMAIL="$EMAIL"
docker compose up -d --force-recreate caddy
sleep 15
echo '=== caddy logs ==='
docker compose logs --tail=60 caddy
echo '=== local checks ==='
curl -sS -o /dev/null -w "http80=%{http_code}\n" http://127.0.0.1/api/health || true
curl -sS -o /dev/null -w "https_host=%{http_code}\n" --resolve "${DOMAIN}:443:127.0.0.1" "https://${DOMAIN}/api/health" || true
curl -sS --resolve "${DOMAIN}:443:127.0.0.1" "https://${DOMAIN}/api/health" || true
echo
