@echo off
REM Build Flutter Admin Web Console and upload to Contabo VPS.
REM Result: https://169-58-230-144.sslip.io/staff-console/

setlocal
cd /d "%~dp0.."

set "VPS_HOST=169.58.230.144"
set "VPS_USER=root"
set "SSH_KEY=%USERPROFILE%\.ssh\qopcha_contabo"
set "API_BASE=https://169-58-230-144.sslip.io"
set "REMOTE_DIR=/opt/qopcha-api"

echo.
echo === Building Flutter Admin Web ===
call flutter build web --release --base-href=/staff-console/ --dart-define=ADMIN_WEB=true --dart-define=API_BASE=%API_BASE%
if errorlevel 1 (
  echo Flutter web build failed.
  exit /b 1
)

if not exist "build\web\index.html" (
  echo build\web\index.html missing.
  exit /b 1
)

echo.
echo === Syncing local server\admin mirror ===
if exist "server\admin" rmdir /s /q "server\admin"
mkdir "server\admin"
xcopy /e /i /y "build\web\*" "server\admin\" >nul

echo.
echo === Uploading admin to VPS %VPS_HOST% ===
if not exist "%SSH_KEY%" (
  echo SSH key not found: %SSH_KEY%
  echo Put Contabo online and add your SSH key first. See DEPLOY.md
  exit /b 1
)

ssh -i "%SSH_KEY%" -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new %VPS_USER%@%VPS_HOST% "mkdir -p %REMOTE_DIR%/admin"
if errorlevel 1 (
  echo SSH failed. Is Contabo VPS running?
  exit /b 1
)

scp -i "%SSH_KEY%" -o ConnectTimeout=15 -r build\web\* %VPS_USER%@%VPS_HOST%:%REMOTE_DIR%/admin/
if errorlevel 1 (
  echo Upload failed.
  exit /b 1
)

echo.
echo === Reloading Caddy on VPS ===
ssh -i "%SSH_KEY%" %VPS_USER%@%VPS_HOST% "cd %REMOTE_DIR% && docker compose up -d caddy && docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile 2>nul || docker compose restart caddy"

echo.
echo Done.
echo Open: https://169-58-230-144.sslip.io/staff-console/
echo Login: admin@qopcha.com (password from server ADMIN_PASSWORD / default seed)
echo.
pause
