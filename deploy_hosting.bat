@echo off
cd /d "c:\xampp\htdocs\Shik Posh"
echo.
echo === Firebase Login + Deploy ===
echo.
echo Step 1: Login (browser will open)...
firebase login
if errorlevel 1 (
  echo Login failed.
  pause
  exit /b 1
)
echo.
echo Step 2: Deploy hosting...
firebase deploy --only hosting --project qopchaapp
echo.
echo When done, open: https://qopchaapp.web.app
pause
