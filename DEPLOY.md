# Deploy قۆپچە API to Contabo + auto-update on Git push

The **Flutter app** runs on phones. The **API** (`server/`) runs on your Contabo VPS.
When you push changes under `server/` to GitHub `main`, GitHub Actions rebuilds the API on the VPS.

Mobile UI changes still need a new APK/AAB build for users (Play Store / sideload).

## 0) Security first

1. In Contabo panel, **change the root password** (never paste it in chat).
2. Prefer SSH keys (steps below).

## 1) First install on the VPS (one time)

Open **Contabo VNC / browser console**, log in as `root`, then paste:

```bash
curl -fsSL https://raw.githubusercontent.com/muhammadmamand/qopcha/main/server/install_on_vps.sh | bash
```

Or, if that file is not on GitHub yet, upload `server/install_on_vps.sh` and run:

```bash
bash install_on_vps.sh
```

Check:

```bash
curl -s http://169.58.230.144/api/health
```

Seed demo products (optional):

```bash
cd /opt/qopcha-api
docker compose exec api node -e "console.log('ok')" 
# from your PC:
node server/scripts/seed_demo.js http://169.58.230.144
```

Copy update script into place (install script already puts files under `/opt/qopcha-api`):

```bash
chmod +x /opt/qopcha-api/update.sh /opt/qopcha-api/install_on_vps.sh
```

## 2) SSH key from your PC (for you + GitHub Actions)

On Windows PowerShell:

```powershell
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\qopcha_contabo -N '""'
Get-Content $env:USERPROFILE\.ssh\qopcha_contabo.pub
```

On the VPS (as root):

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'PASTE_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Test from PC:

```powershell
ssh -i $env:USERPROFILE\.ssh\qopcha_contabo root@169.58.230.144 "curl -s http://127.0.0.1:8080/api/health"
```

## 3) Auto-deploy on every push (GitHub)

Repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|--------|--------|
| `VPS_HOST` | `169.58.230.144` |
| `VPS_USER` | `root` |
| `VPS_SSH_KEY` | full private key from `qopcha_contabo` (including `BEGIN` / `END` lines) |
| `VPS_PORT` | `22` (optional) |

Workflow file: `.github/workflows/deploy-api.yml`

Then:

```powershell
git add server .github/workflows/deploy-api.yml
git commit -m "Deploy Contabo API with auto-update"
git push origin main
```

GitHub → **Actions** tab → watch **Deploy API to Contabo**.

## 4) Admin console on Contabo

Build + upload Flutter admin web:

```powershell
scripts\deploy_admin_to_vps.bat
```

Then open: `http://169.58.230.144/staff-console`

OTP-verified signups are **auto-approved** (customers and shops) — no admin accept step.

## 5) Point the mobile app at the public API

Release builds use `http://169.58.230.144` (see `lib/core/config/api_config.dart`).
Rebuild APK after the API is healthy:

```powershell
flutter build apk --release
```

## 6) Day-to-day workflow

1. Change code locally  
2. Commit + `git push origin main`  
3. If you changed `server/**` → VPS updates automatically  
4. If you changed Flutter UI → rebuild APK and distribute  
5. If you changed admin → run `scripts\deploy_admin_to_vps.bat`  

Manual update without GitHub Actions:

```powershell
ssh -i $env:USERPROFILE\.ssh\qopcha_contabo root@169.58.230.144 "bash /opt/qopcha-api/update.sh"
```

## Notes

- Data lives in `/opt/qopcha-api/data` (survives deploys).
- Uploads live in `/opt/qopcha-api/uploads`.
- `.env` is never overwritten by `update.sh`.
- For WhatsApp OTP, set on the VPS `.env`:
  `VERIFYWAY_API_TOKEN=...` then `docker compose up -d --build`.
- Flutter always calls `http://169.58.230.144` unless you pass `--dart-define=API_BASE=...`.
- For HTTPS, point a domain DNS A-record to the VPS and update `Caddyfile` + `PUBLIC_URL`.
