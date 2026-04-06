@echo off
title Discover Jakarta API
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is not installed or not in PATH.
  echo Install from https://nodejs.org/ then reopen this window.
  pause
  exit /b 1
)

where npm >nul 2>nul
if errorlevel 1 (
  echo npm not found. Reinstall Node.js from https://nodejs.org/
  pause
  exit /b 1
)

if not exist "node_modules\" (
  echo Installing dependencies...
  call npm install
  if errorlevel 1 (
    echo npm install failed.
    pause
    exit /b 1
  )
)

if not exist ".env" (
  echo Creating .env from .env.example ^(edit DB_PASS if needed^)...
  copy /Y ".env.example" ".env" >nul
)

echo Starting API (default port 3001 — see server\.env) ...
echo Test in browser: http://127.0.0.1:3001/health
echo Keep this window open while using the Flutter app.
call npm start
pause
