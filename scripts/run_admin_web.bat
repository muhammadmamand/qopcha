@echo off
REM Run the React + Tailwind Admin Console locally.

cd /d "%~dp0..\admin-web"
call npm install
if errorlevel 1 exit /b 1
call npm run dev
pause
