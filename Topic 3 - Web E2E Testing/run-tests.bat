@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion
title Topic 3 - Web E2E Testing
set NO_PAUSE=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1
set TOPIC_STATUS=0

echo ============================================================
echo  TOPIC 3 - WEB E2E TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: simulate a real user on the web application.
echo [DEMO GUIDE] Main test: Playwright opens browser pages and checks UI/API result.
echo [DEMO GUIDE] Optional visual demo: Selenium opens Microsoft Edge if EdgeDriver is available.
echo.
echo [TEST CASE PLAN]
echo  ID     INPUT / ACTION                            EXPECTED        MEANING
echo  E2E01  day=15, month=6, year=2023               VALID           Happy path
echo  E2E02  day=29, month=2, year=2023               INVALID         Non-leap February
echo  E2E03  day=32, month=1, year=2023               ERROR           Day range validation
echo  E2E04  day=abc, month=1, year=2023              ERROR           Format validation
echo  E2E05  Close App: No, then Yes                  CLOSED          Modal behavior
echo  E2E06  day=1, month=1, year=1000                VALID           Minimum boundary
echo  E2E07  day=31, month=12, year=3000              VALID           Maximum boundary
echo  E2E08  day=29, month=2, year=2000               VALID           Leap year rule
echo  E2E09  day=29, month=2, year=1900               INVALID         Century leap rule
echo.

echo ============================================================
echo [STEP 1/4] Run Playwright Web E2E tests.
echo          Flow: open app, type date, click Check, verify modal/result.
echo ============================================================
pushd "%~dp0.."
call npm run test:e2e
set PLAYWRIGHT_E2E_STATUS=%ERRORLEVEL%
popd
if %PLAYWRIGHT_E2E_STATUS% neq 0 (
  echo [ERROR] Playwright Web E2E tests failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 2/4] Run optional Selenium visible browser demo.
echo          If EdgeDriver cannot be downloaded, this step is skipped with explanation.
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\selenium-demo.ps1" -AutoClose
set SELENIUM_STATUS=%ERRORLEVEL%
if %SELENIUM_STATUS% neq 0 (
  echo [WARN] Selenium visible demo could not run in this environment.
  echo [WARN] Common reason: Microsoft Edge WebDriver is not installed and network download is blocked.
  echo [WARN] Playwright E2E already passed, so Topic 3 automated verification is still complete.
) else (
  echo [PASS] Selenium visible demo completed.
)

echo.
echo ============================================================
echo [STEP 3/4] Report meaning
echo  Playwright E2E proves the end-to-end web workflow works.
echo  Selenium, when available, is useful for recording a visible browser demo.
echo ============================================================

echo.
echo ============================================================
echo [STEP 4/4] Summary
echo  Playwright Web E2E tests: PASS
if %SELENIUM_STATUS% neq 0 (
  echo  Selenium visible demo:   SKIPPED/WARN
) else (
  echo  Selenium visible demo:   PASS
)
echo  WEB E2E TESTING COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
