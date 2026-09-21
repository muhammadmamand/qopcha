#!/bin/bash
set -e
cd /opt/qopcha-api
docker compose cp /tmp/fix_admin_phone.js api:/tmp/fix_admin_phone.js
docker compose exec -T api sh -c 'NODE_PATH=/app/node_modules node /tmp/fix_admin_phone.js'
# soft restart without hanging forever
docker compose kill -s HUP api 2>/dev/null || true
docker restart qopcha-api-api-1
sleep 5
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
