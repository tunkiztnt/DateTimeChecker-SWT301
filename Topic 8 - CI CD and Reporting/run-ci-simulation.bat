@echo off
chcp 65001 > nul
title Local CI/CD Pipeline Simulator

echo ============================================================
echo  LOCAL CI/CD PIPELINE SIMULATION RUNNER
echo ============================================================
echo [INFO] Pipeline started at: %DATE% %TIME%
echo.

set REPORT_FILE="%~dp0..\reports\ci-pipeline-report.txt"

if not exist "%~dp0..\reports" (
  mkdir "%~dp0..\reports"
)

echo CI/CD Pipeline Execution Report > %REPORT_FILE%
echo =============================== >> %REPORT_FILE%
echo Executed: %DATE% %TIME% >> %REPORT_FILE%
echo. >> %REPORT_FILE%

set STAGE_1=PASS
set STAGE_2=PASS
set STAGE_3=PASS
set STAGE_4=PASS
set STAGE_5=PASS
set STAGE_6=PASS
set STAGE_7=PASS

:: STAGE 1: Compilation
echo ------------------------------------------------------------
echo  STAGE 1: CODE COMPILATION (BUILD STAGE)
echo ------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\build.ps1"
if errorlevel 1 (
  set STAGE_1=FAIL
  echo [STAGE 1] Build failed! >> %REPORT_FILE%
  goto summary
)
echo [STAGE 1] Build: SUCCESS >> %REPORT_FILE%
echo.

:: STAGE 2: Unit Testing
echo ------------------------------------------------------------
echo  STAGE 2: UNIT TESTING (JAVA & JAVASCRIPT)
echo ------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\test.ps1"
if errorlevel 1 (
  set STAGE_2=FAIL
)
call npm run test:unit
if errorlevel 1 (
  set STAGE_2=FAIL
)
if "%STAGE_2%"=="FAIL" (
  echo [STAGE 2] Unit tests failed! >> %REPORT_FILE%
) else (
  echo [STAGE 2] Unit tests: SUCCESS >> %REPORT_FILE%
)
echo.

:: STAGE 3: API Testing
echo ------------------------------------------------------------
echo  STAGE 3: API VALIDATION (PLAYWRIGHT & POWERSHELL)
echo ------------------------------------------------------------
call npx playwright test --config=playwright.config.js --grep="@api"
if errorlevel 1 (
  set STAGE_3=FAIL
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 2 - API Testing\run-api-testing.ps1"
if errorlevel 1 (
  set STAGE_3=FAIL
)
if "%STAGE_3%"=="FAIL" (
  echo [STAGE 3] API tests failed! >> %REPORT_FILE%
) else (
  echo [STAGE 3] API tests: SUCCESS >> %REPORT_FILE%
)
echo.

:: STAGE 4: Web E2E Testing
echo ------------------------------------------------------------
echo  STAGE 4: WEB E2E AUTOMATION (PLAYWRIGHT BROWSER)
echo ------------------------------------------------------------
call npx playwright test --config=playwright.config.js --grep="@e2e"
if errorlevel 1 (
  set STAGE_4=FAIL
)
if "%STAGE_4%"=="FAIL" (
  echo [STAGE 4] Web E2E tests failed! >> %REPORT_FILE%
) else (
  echo [STAGE 4] Web E2E tests: SUCCESS >> %REPORT_FILE%
)
echo.

:: STAGE 5: Mobile Testing Fallback Simulation
echo ------------------------------------------------------------
echo  STAGE 5: MOBILE AUTOMATION (SIMULATOR/EMULATOR RUN)
echo ------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 4 - Mobile Testing\run-mobile-testing.ps1"
if errorlevel 1 (
  set STAGE_5=FAIL
)
if "%STAGE_5%"=="FAIL" (
  echo [STAGE 5] Mobile tests failed! >> %REPORT_FILE%
) else (
  echo [STAGE 5] Mobile tests: SUCCESS >> %REPORT_FILE%
)
echo.

:: STAGE 6: Performance Testing
echo ------------------------------------------------------------
echo  STAGE 6: PERFORMANCE & LATENCY LOAD TESTING
echo ------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 5 - Performance Testing\run-performance-tests.ps1"
if errorlevel 1 (
  set STAGE_6=FAIL
)
if "%STAGE_6%"=="FAIL" (
  echo [STAGE 6] Performance tests failed! >> %REPORT_FILE%
) else (
  echo [STAGE 6] Performance tests: SUCCESS >> %REPORT_FILE%
)
echo.

:: STAGE 7: Visual Regression Testing
echo ------------------------------------------------------------
echo  STAGE 7: VISUAL PIXEL-PERFECT CHECK (PLAYWRIGHT SHOTS)
echo ------------------------------------------------------------
call npx playwright test --config=playwright.config.js --grep="@visual"
if errorlevel 1 (
  set STAGE_7=FAIL
)
if "%STAGE_7%"=="FAIL" (
  echo [STAGE 7] Visual regression tests failed! >> %REPORT_FILE%
) else (
  echo [STAGE 7] Visual regression tests: SUCCESS >> %REPORT_FILE%
)
echo.

:summary
echo ============================================================
echo  CI/CD PIPELINE INTEGRATION RUN SUMMARY
echo ============================================================
echo Stage 1: Build Java Compilation        - %STAGE_1%
echo Stage 2: Unit Testing (Backend & UI)   - %STAGE_2%
echo Stage 3: API Validation                - %STAGE_3%
echo Stage 4: Web E2E Browser Testing       - %STAGE_4%
echo Stage 5: Mobile Testing (Maestro/Mock) - %STAGE_5%
echo Stage 6: Performance Latency Bench     - %STAGE_6%
echo Stage 7: Visual Regression Screenshots  - %STAGE_7%
echo ============================================================

echo Summary: >> %REPORT_FILE%
echo ----------------------- >> %REPORT_FILE%
echo Stage 1: Build Java Compilation        - %STAGE_1% >> %REPORT_FILE%
echo Stage 2: Unit Testing (Backend & UI)   - %STAGE_2% >> %REPORT_FILE%
echo Stage 3: API Validation                - %STAGE_3% >> %REPORT_FILE%
echo Stage 4: Web E2E Browser Testing       - %STAGE_4% >> %REPORT_FILE%
echo Stage 5: Mobile Testing (Maestro/Mock) - %STAGE_5% >> %REPORT_FILE%
echo Stage 6: Performance Latency Bench     - %STAGE_6% >> %REPORT_FILE%
echo Stage 7: Visual Regression Screenshots  - %STAGE_7% >> %REPORT_FILE%
echo ----------------------- >> %REPORT_FILE%

if "%STAGE_1%"=="FAIL" goto fail
if "%STAGE_2%"=="FAIL" goto fail
if "%STAGE_3%"=="FAIL" goto fail
if "%STAGE_4%"=="FAIL" goto fail
if "%STAGE_5%"=="FAIL" goto fail
if "%STAGE_6%"=="FAIL" goto fail
if "%STAGE_7%"=="FAIL" goto fail

echo [SUCCESS] PIPELINE PASSED SUCCESSFULLY!
echo Final Verdict: PASS >> %REPORT_FILE%
goto end

:fail
echo [ERROR] PIPELINE COMPLETED WITH FAILURES. Check logs above.
echo Final Verdict: FAIL >> %REPORT_FILE%

:end
echo Integration report compiled: reports/ci-pipeline-report.txt
echo.
