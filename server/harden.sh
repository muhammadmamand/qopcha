#!/usr/bin/env bash
set -euo pipefail

# Run on the Contabo VPS as root AFTER you change the leaked root password.
# Usage: bash harden.sh

apt-get update
apt-get install -y ufw fail2ban unattended-upgrades ca-certificates curl docker.io docker-compose-plugin

ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

systemctl enable --now docker fail2ban unattended-upgrades

cat >/etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
maxretry = 4
bantime = 1h
findtime = 10m
EOF
systemctl restart fail2ban

echo "Firewall, fail2ban, and Docker are ready."
echo "Next: copy the server/ folder here, create .env, then: docker compose up -d --build"
