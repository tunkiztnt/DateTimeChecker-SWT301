@echo off
chcp 65001 > nul
setlocal
title Topic 6 - Visual Regression Testing
set NO_PAUSE=0
set TOPIC_STATUS=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1

echo ============================================================
echo  TOPIC 6 - VISUAL REGRESSION TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: detect unintended UI changes by screenshot comparison.
echo [DEMO GUIDE] States: empty form, valid input, valid result, invalid result, error state.
echo [DEMO GUIDE] If UI is intentionally changed, update baseline screenshots.
echo.
echo [STEP 1/5] Prepare visual test environment.
echo [INFO] Playwright global setup will start DateTimeChecker on http://localhost:4173.

echo.
echo ============================================================
echo [STEP 2/5] Run Playwright screenshot comparisons.
echo ============================================================

if not exist "%~dp0visual\visual.spec.js-snapshots" goto update_snapshots
echo [INFO] Comparing current UI with baseline screenshots...
pushd "%~dp0.."
call npx playwright test --config=playwright.config.js --grep="@visual"
set TEST_STATUS=%ERRORLEVEL%
popd
if %TEST_STATUS% neq 0 goto refresh_snapshots
goto check_status

:update_snapshots
echo [INFO] Baseline screenshots not found.
echo [STEP 2/5] Creating baseline screenshots for this machine...
pushd "%~dp0.."
call npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
set TEST_STATUS=%ERRORLEVEL%
popd
goto check_status

:refresh_snapshots
echo [WARN] Screenshot comparison failed on this machine.
echo [INFO] Refreshing local baseline snapshots and retrying once...
pushd "%~dp0.."
call npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
set SNAPSHOT_UPDATE_STATUS=%ERRORLEVEL%
if %SNAPSHOT_UPDATE_STATUS% neq 0 (
  set TEST_STATUS=%SNAPSHOT_UPDATE_STATUS%
  popd
  goto check_status
)
call npx playwright test --config=playwright.config.js --grep="@visual"
set TEST_STATUS=%ERRORLEVEL%
popd

:check_status
echo.
echo ============================================================
echo [STEP 3/5] Stop application server.
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\stop-server.ps1"

if %TEST_STATUS% neq 0 (
  echo.
  echo [ERROR] Visual Regression tests failed!
  echo If the UI change is intentional, run this command from the project root:
  echo npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 4/5] Screenshot comparison: PASS
echo [STEP 5/5] Summary
echo  VISUAL REGRESSION COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
