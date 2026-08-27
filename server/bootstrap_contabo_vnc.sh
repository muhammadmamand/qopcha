#!/usr/bin/env bash
# Paste this entire script into Contabo VNC / browser console as root.
# It: authorizes your PC SSH key, installs/starts the API, opens ports.
set -euo pipefail

PUBKEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB84+Ya1VcIwAm2TFdffDduAi5oY/7Bgc/7EvpUqVDMj dell@DESKTOP-GTFEDV0'
APP_DIR=/opt/qopcha-api

mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
grep -qxF "$PUBKEY" /root/.ssh/authorized_keys || echo "$PUBKEY" >> /root/.ssh/authorized_keys
echo "SSH key installed."

if [ ! -f "$APP_DIR/docker-compose.yml" ]; then
  echo "API folder missing — running first install..."
  curl -fsSL https://raw.githubusercontent.com/muhammadmamand/qopcha/main/server/install_on_vps.sh | bash
else
  cd "$APP_DIR"
  mkdir -p admin data uploads
  docker compose up -d --build
fi

ufw allow OpenSSH || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw --force enable || true

echo ""
echo "=== Health ==="
curl -s http://127.0.0.1:8080/api/health || true
echo ""
echo "From your PC run:  scripts\\deploy_admin_to_vps.bat"
echo "Then open: https://169-58-230-144.sslip.io/staff-console/"
