@echo off
chcp 65001 > nul
setlocal
title Topic 3 - Mobile Testing
set NO_PAUSE=0
set TOPIC_STATUS=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1

echo ============================================================
echo  TOPIC 3 - MOBILE E2E TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: run Android E2E tests on the installed app.
echo [DEMO GUIDE] Fast mode: no Flutter build, no reinstall, no mock fallback.
echo.
echo [STEP 1/2] Run Maestro Mobile E2E flows.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-mobile-testing.ps1" -OpenReport
if errorlevel 1 (
  echo [ERROR] Mobile testing failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 2/2] Summary
echo  Mobile E2E flow: PASS
echo  HTML report : topics\03-mobile-testing\reports\mobile-e2e-report\index.html
echo  JSON report : topics\03-mobile-testing\reports\mobile-e2e-report\results.json
echo  MOBILE TESTING COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
