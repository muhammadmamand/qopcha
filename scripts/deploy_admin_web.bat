@echo off
REM Build + deploy the React + Tailwind Admin Console to Firebase Hosting.
REM Result URL example: https://qopchaapp.web.app

cd /d "%~dp0.."

echo.
echo Tip: for local development use scripts\run_admin_web.bat
echo.
echo === Building Admin Web Console ===
cd /d "%~dp0..\admin-web"
call npm install
if errorlevel 1 (
  echo Dependency install failed.
  exit /b 1
)
call npm run build
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

echo.
echo === Deploying to Firebase Hosting ===
cd /d "%~dp0.."
call firebase deploy --only hosting:qopchaapp
if errorlevel 1 (
  echo Deploy failed. Is Firebase CLI logged in?  firebase login
  exit /b 1
)

echo.
echo Done. Open your Hosting URL and sign in at /staff-console
echo PIN default: 7291  (change in admin-web\src\contexts\AuthContext.tsx)
echo.
pause
