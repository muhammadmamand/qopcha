#!/usr/bin/env bash
# Pull latest server/ from GitHub and rebuild containers.
# Used by GitHub Actions and manual `ssh ... 'bash /opt/qopcha-api/update.sh'`
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/qopcha-api}"
REPO_URL="${REPO_URL:-$(cat "$APP_DIR/.repo_url" 2>/dev/null || echo https://github.com/muhammadmamand/qopcha.git)}"
BRANCH="${BRANCH:-$(cat "$APP_DIR/.repo_branch" 2>/dev/null || echo main)}"

cd "$APP_DIR"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP/src"
if [ -d "$TMP/src/server" ]; then
  SRC="$TMP/src/server"
else
  SRC="$TMP/src"
fi

# Preserve runtime data + secrets
rsync -a \
  --exclude '.env' \
  --exclude 'data/' \
  --exclude 'uploads/' \
  --exclude 'node_modules/' \
  "$SRC/" "$APP_DIR/"

docker compose up -d --build
docker image prune -f >/dev/null 2>&1 || true
curl -fsS http://127.0.0.1:8080/api/health
echo ""
echo "Updated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
