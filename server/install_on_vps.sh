#!/usr/bin/env bash
# Run ONCE on the Contabo VPS as root (Contabo VNC / console is fine).
# Copies nothing from your PC — clones from GitHub and starts Docker.
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/qopcha-api}"
REPO_URL="${REPO_URL:-https://github.com/muhammadmamand/qopcha.git}"
BRANCH="${BRANCH:-main}"
PUBLIC_URL="${PUBLIC_URL:-https://169-58-230-144.sslip.io}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl git ufw fail2ban rsync

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker

if ! docker compose version >/dev/null 2>&1; then
  apt-get install -y docker-compose-plugin || true
fi

mkdir -p "$APP_DIR"
if [ ! -d "$APP_DIR/.git" ]; then
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" /tmp/qopcha-src
  mkdir -p "$APP_DIR"
  # Prefer nested server/ folder from the Flutter monorepo
  if [ -d /tmp/qopcha-src/server ]; then
    rsync -a --delete /tmp/qopcha-src/server/ "$APP_DIR/"
    # Keep a pointer to the repo for pull-based deploys
    echo "$REPO_URL" > "$APP_DIR/.repo_url"
    echo "$BRANCH" > "$APP_DIR/.repo_branch"
  else
    rsync -a --delete /tmp/qopcha-src/ "$APP_DIR/"
  fi
  rm -rf /tmp/qopcha-src
fi

cd "$APP_DIR"

if [ ! -f .env ]; then
  JWT=$(openssl rand -hex 48)
  cat > .env <<EOF
PORT=8080
PUBLIC_URL=$PUBLIC_URL
JWT_SECRET=$JWT
ADMIN_EMAIL=admin@qopcha.com
ADMIN_PASSWORD=Admin123456
ADMIN_PHONE=07500000000
ALLOWED_ORIGIN=*
POSTGRES_USER=qopcha
POSTGRES_PASSWORD=$(openssl rand -hex 24)
POSTGRES_DB=qopcha
VERIFYWAY_API_URL=https://gateway.standingtech.com/api/v4/sms/send
STANDING_API_URL=https://gateway.standingtech.com/api/v4/sms/send
VERIFYWAY_API_TOKEN=
VERIFYWAY_CHANNEL=whatsapp
VERIFYWAY_FALLBACK_CHANNEL=sms
VERIFYWAY_SENDER=QopchaApp
STANDING_SENDER_ID=QopchaApp
STANDING_LANG=en
EOF
  chmod 600 .env
  echo "Created .env — set VERIFYWAY_API_TOKEN and CHANGE ADMIN_PASSWORD"
else
  # Ensure Standing Tech / OTP keys exist on older installs (does not overwrite values).
  grep -q '^STANDING_API_URL=' .env || echo 'STANDING_API_URL=https://gateway.standingtech.com/api/v4/sms/send' >> .env
  grep -q '^VERIFYWAY_API_URL=' .env || echo 'VERIFYWAY_API_URL=https://gateway.standingtech.com/api/v4/sms/send' >> .env
  grep -q '^VERIFYWAY_API_TOKEN=' .env || echo 'VERIFYWAY_API_TOKEN=' >> .env
  grep -q '^VERIFYWAY_CHANNEL=' .env || echo 'VERIFYWAY_CHANNEL=whatsapp' >> .env
  grep -q '^VERIFYWAY_FALLBACK_CHANNEL=' .env || echo 'VERIFYWAY_FALLBACK_CHANNEL=sms' >> .env
  grep -q '^VERIFYWAY_SENDER=' .env || echo 'VERIFYWAY_SENDER=QopchaApp' >> .env
  grep -q '^STANDING_SENDER_ID=' .env || echo 'STANDING_SENDER_ID=QopchaApp' >> .env
  grep -q '^POSTGRES_USER=' .env || echo 'POSTGRES_USER=qopcha' >> .env
  grep -q '^POSTGRES_PASSWORD=' .env || echo "POSTGRES_PASSWORD=$(openssl rand -hex 24)" >> .env
  grep -q '^POSTGRES_DB=' .env || echo 'POSTGRES_DB=qopcha' >> .env
fi

mkdir -p data uploads
chmod +x update.sh install_on_vps.sh 2>/dev/null || true
docker compose up -d --build

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable || true

echo ""
echo "=== قۆپچە API is up ==="
echo "Health: curl -s $PUBLIC_URL/api/health"
curl -s "$PUBLIC_URL/api/health" || curl -s http://127.0.0.1:8080/api/health || true
echo ""
