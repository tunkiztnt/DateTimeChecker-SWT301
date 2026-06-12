@echo off
chcp 65001 > nul
setlocal
title Topic 2 - API Testing
set NO_PAUSE=0
set TOPIC_STATUS=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1

echo ============================================================
echo  TOPIC 2 - API TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: verify backend JSON API without using the UI.
echo [DEMO GUIDE] Endpoint: POST /api/check-date and /api/datetime/check.
echo [DEMO GUIDE] Pass means HTTP 200, correct JSON result, and fast response.
echo.
echo [STEP 1/4] Compile Java server code.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\build.ps1"
if errorlevel 1 (
  echo [ERROR] Java compilation failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 2/4] Run Playwright API assertions.
echo ============================================================
pushd "%~dp0.."
call npx playwright test --config=playwright.config.js --grep="@api"
set PLAYWRIGHT_API_STATUS=%ERRORLEVEL%
popd
if %PLAYWRIGHT_API_STATUS% neq 0 (
  echo [ERROR] Playwright API tests failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 3/4] Run PowerShell API integration checks and write TSV report.
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-api-testing.ps1"
if errorlevel 1 (
  echo [ERROR] PowerShell API tests failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 4/4] Summary
echo  Playwright API tests: PASS
echo  PowerShell API tests: PASS
echo  Report: reports\api-testing-report.tsv
echo  ALL API TESTS COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
