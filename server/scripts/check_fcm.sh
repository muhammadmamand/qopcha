#!/bin/bash
set -e
cd /opt/qopcha-api
docker compose exec -T api sh -c 'test -f /app/secrets/firebase-adminsdk.json && echo key_ok'
docker compose exec -T api sh -c 'NODE_PATH=/app/node_modules node /tmp/check_fcm.js'
