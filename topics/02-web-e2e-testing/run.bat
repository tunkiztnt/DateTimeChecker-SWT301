@echo off
chcp 65001 > nul
cd /d "%~dp0..\.."
title DateTimeChecker - Topic 2: Web E2E Testing

echo ============================================================
echo  RUNNING TOPIC 2: WEB E2E TESTING (Playwright CSS/ID Selectors)
echo ============================================================
echo.

echo [1/3] Compiling Java backend...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\build.ps1" > nul 2>&1

echo [2/3] Starting backend server in the background...
start /b java -cp out/classes com.datetimechecker.App > nul 2>&1
timeout /t 2 /nobreak > nul

echo [3/3] Running Web E2E tests...
call npx playwright test topics/02-web-e2e-testing/

echo.
echo [INFO] Stopping backend server...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\stop-server.ps1" > nul 2>&1
echo.
pause
