#!/bin/bash
set -e
cd /opt/qopcha-api
mkdir -p secrets
chmod 755 secrets
chmod 644 secrets/firebase-adminsdk.json

# Point API at the mounted service account
if grep -q '^GOOGLE_APPLICATION_CREDENTIALS=' .env; then
  sed -i 's|^GOOGLE_APPLICATION_CREDENTIALS=.*|GOOGLE_APPLICATION_CREDENTIALS=/app/secrets/firebase-adminsdk.json|' .env
else
  echo 'GOOGLE_APPLICATION_CREDENTIALS=/app/secrets/firebase-adminsdk.json' >> .env
fi
if grep -q '^FIREBASE_PROJECT_ID=' .env; then
  sed -i 's|^FIREBASE_PROJECT_ID=.*|FIREBASE_PROJECT_ID=qopchaapp|' .env
else
  echo 'FIREBASE_PROJECT_ID=qopchaapp' >> .env
fi

# Ensure compose mounts ./secrets
if ! grep -q './secrets:/app/secrets' docker-compose.yml; then
  python3 - <<'PY'
from pathlib import Path
p = Path('docker-compose.yml')
text = p.read_text(encoding='utf-8')
needle = '      - ./uploads:/app/uploads\n'
insert = needle + '      - ./secrets:/app/secrets:ro\n'
if needle in text and './secrets:/app/secrets' not in text:
    p.write_text(text.replace(needle, insert, 1), encoding='utf-8')
    print('compose_updated')
else:
    print('compose_ok')
PY
fi

docker compose up -d --force-recreate --no-deps api
sleep 6
docker compose logs api --tail 40 | grep -iE 'fcm|Firebase|listening|Storage' || true
