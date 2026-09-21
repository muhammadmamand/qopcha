#!/bin/bash
set -e
cd /opt/qopcha-api

# Keep ADMIN_PHONE in sync
if grep -q '^ADMIN_PHONE=' .env; then
  sed -i 's/^ADMIN_PHONE=.*/ADMIN_PHONE=07503727574/' .env
else
  echo 'ADMIN_PHONE=07503727574' >> .env
fi

docker compose cp /tmp/create_phone_admin.js api:/tmp/create_phone_admin.js
docker compose exec -T api sh -c 'NODE_PATH=/app/node_modules node /tmp/create_phone_admin.js'

# Reload env so finalizeAuthUser promotes by ADMIN_PHONE
docker compose up -d --force-recreate --no-deps api
sleep 8

python3 <<'PY'
import json, urllib.request
req = urllib.request.Request(
    'http://127.0.0.1:8080/api/auth/login',
    data=json.dumps({'phone': '07503727574', 'password': 'Admin123456'}).encode(),
    headers={'Content-Type': 'application/json'},
    method='POST',
)
try:
    with urllib.request.urlopen(req, timeout=20) as resp:
        body = json.loads(resp.read().decode())
        u = body.get('user') or {}
        print('login_ok', 'role=' + str(u.get('role')), 'phone=' + str(u.get('phone')))
except Exception as e:
    print('login_fail', e)
PY
