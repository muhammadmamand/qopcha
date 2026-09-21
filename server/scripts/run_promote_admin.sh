#!/bin/bash
set -e
cd /opt/qopcha-api

# Ensure env has the phone
grep -q 'ADMIN_PHONE=07503727574' .env || sed -i 's/^ADMIN_PHONE=.*/ADMIN_PHONE=07503727574/' .env
grep -q 'ADMIN_PHONE=' .env || echo 'ADMIN_PHONE=07503727574' >> .env

docker compose cp /tmp/promote_admin_role.js api:/tmp/promote_admin_role.js
docker compose exec -T api sh -c 'NODE_PATH=/app/node_modules node /tmp/promote_admin_role.js'

# Recreate so ADMIN_PHONE env is loaded
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
        u = json.loads(resp.read().decode()).get('user') or {}
        print('login_ok', u.get('role'), u.get('phone'))
except Exception as e:
    print('login_fail', e)
PY
