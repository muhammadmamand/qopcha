#!/bin/bash
set -e
cd /opt/qopcha-api
echo "=== host key ==="
ls -la secrets/firebase-adminsdk.json
echo "=== env lines ==="
grep GOOGLE_APPLICATION_CREDENTIALS .env || echo missing_gac
grep FIREBASE_PROJECT_ID .env || echo missing_project
echo "=== compose secrets mount ==="
grep secrets docker-compose.yml || echo no_secrets_mount
echo "=== in container ==="
docker compose exec -T api ls -la /app/secrets/firebase-adminsdk.json
echo "=== fcm init ==="
docker compose exec -T api sh -c 'NODE_PATH=/app/node_modules node /tmp/check_fcm.js'
