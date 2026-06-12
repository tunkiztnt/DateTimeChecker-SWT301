@echo off
chcp 65001 > nul
title Local CI/CD Pipeline Simulator

SET PASSED=0
SET FAILED=0
SET SKIPPED=0

echo ╔══════════════════════════════════════════════════╗
echo ║     LOCAL CI/CD PIPELINE — DateTimeChecker       ║
echo ║     Started: %DATE% %TIME%                         ║
echo ╚══════════════════════════════════════════════════╝
echo.

:: STAGE 1: Code Compilation
if %FAILED% GTR 0 (
  echo [STAGE 1/8] Skipped: Build Java Compilation
  SET /A SKIPPED+=1
) else (
  echo [STAGE 1/8] Running: Build Java Compilation...
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\build.ps1"
  if errorlevel 1 (
    echo [FAIL] Stage 1 failed
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 1 completed
    SET /A PASSED+=1
  )
)
echo.

:: STAGE 2: Unit Testing (Java and JavaScript)
if %FAILED% GTR 0 (
  echo [STAGE 2/8] Skipped: Unit Testing (Java and JavaScript)
  SET /A SKIPPED+=1
) else (
  echo [STAGE 2/8] Running: Unit Testing (Java and JavaScript)...
  SET STAGE_FAILED=0
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\test.ps1"
  if errorlevel 1 SET STAGE_FAILED=1
  call npm run test:unit
  if errorlevel 1 SET STAGE_FAILED=1
  
  if %STAGE_FAILED% EQU 1 (
    echo [FAIL] Stage 2 failed
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 2 completed
    SET /A PASSED+=1
  )
)
echo.

:: STAGE 3: API Testing
if %FAILED% GTR 0 (
  echo [STAGE 3/8] Skipped: API Validation
  SET /A SKIPPED+=1
) else (
  echo [STAGE 3/8] Running: API Validation...
  SET STAGE_FAILED=0
  pushd "%~dp0.."
  call npx playwright test --config=playwright.config.js --grep="@api"
  if errorlevel 1 SET STAGE_FAILED=1
  popd
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 2 - API Testing\run-api-testing.ps1"
  if errorlevel 1 SET STAGE_FAILED=1
  
  if %STAGE_FAILED% EQU 1 (
    echo [FAIL] Stage 3 failed
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 3 completed
    SET /A PASSED+=1
  )
)
:: Kill server after Stage 3 (API) using the requested netstat loop
FOR /F "tokens=5" %%P IN ('netstat -a -n -o ^| findstr ":4173"') DO taskkill /PID %%P /F 2>nul
echo.

:: STAGE 4: Web E2E Browser Testing
if %FAILED% GTR 0 (
  echo [STAGE 4/8] Skipped: Web E2E Browser Testing
  SET /A SKIPPED+=1
) else (
  echo [STAGE 4/8] Running: Web E2E Browser Testing...
  SET STAGE_FAILED=0
  pushd "%~dp0.."
  call npm run test:e2e
  if errorlevel 1 SET STAGE_FAILED=1
  popd
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\selenium-demo.ps1" -AutoClose -Headless
  if errorlevel 1 SET STAGE_FAILED=1
  
  if %STAGE_FAILED% EQU 1 (
    echo [FAIL] Stage 4 failed
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 4 completed
    SET /A PASSED+=1
  )
)
:: Kill server after Stage 4 (E2E) using the requested netstat loop
FOR /F "tokens=5" %%P IN ('netstat -a -n -o ^| findstr ":4173"') DO taskkill /PID %%P /F 2>nul
echo.

:: STAGE 5: Mobile Testing Fallback Simulation
if %FAILED% GTR 0 (
  echo [STAGE 5/8] Skipped: Mobile Testing
  SET /A SKIPPED+=1
) else (
  echo [STAGE 5/8] Running: Mobile Testing...
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 4 - Mobile Testing\run-mobile-testing.ps1"
  if errorlevel 1 (
    echo [FAIL] Stage 5 failed
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 5 completed
    SET /A PASSED+=1
  )
)
echo.

:: STAGE 6: Performance Testing
if %FAILED% GTR 0 (
  echo [STAGE 6/8] Skipped: Performance Testing
  SET /A SKIPPED+=1
) else (
  echo [STAGE 6/8] Running: Performance Testing...
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 5 - Performance Testing\run-performance-tests.ps1"
  if errorlevel 1 (
    echo [FAIL] Stage 6 failed
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 6 completed
    SET /A PASSED+=1
  )
)
echo.

:: STAGE 7: Visual Regression Testing
if %FAILED% GTR 0 (
  echo [STAGE 7/8] Skipped: Visual Regression Testing
  SET /A SKIPPED+=1
) else (
  echo [STAGE 7/8] Running: Visual Regression Testing...
  pushd "%~dp0.."
  call npx playwright test --config=playwright.config.js --grep="@visual"
  if errorlevel 1 (
    echo [FAIL] Stage 7 failed
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 7 completed
    SET /A PASSED+=1
  )
  popd
)
:: Kill server after Stage 7 (Visual) using the requested netstat loop
FOR /F "tokens=5" %%P IN ('netstat -a -n -o ^| findstr ":4173"') DO taskkill /PID %%P /F 2>nul
echo.

:: STAGE 8: AI-Assisted Testing
if %FAILED% GTR 0 (
  echo [STAGE 8/8] Skipped: AI-Assisted Testing
  SET /A SKIPPED+=1
) else (
  echo [STAGE 8/8] Running: AI-Assisted Testing...
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\ai-self-healing-demo.ps1" -OfflineSample -AutoApprove
  if errorlevel 1 (
    echo [FAIL] Stage 8 failed
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 8 completed
    SET /A PASSED+=1
  )
)
echo.

:: Set overall status
if %FAILED% EQU 0 (
  SET OVERALL=SUCCESS
) else (
  SET OVERALL=FAILED
)

echo ══════════════════════════════════════════
echo PIPELINE SUMMARY
echo ══════════════════════════════════════════
echo ✓ PASSED:  %PASSED% stages
echo ✗ FAILED:  %FAILED% stages
echo ○ SKIPPED: %SKIPPED% stages
echo ══════════════════════════════════════════
echo OVERALL: %OVERALL% — Ended: %DATE% %TIME%
echo ══════════════════════════════════════════

if %FAILED% NEQ 0 (
  exit /b 1
) else (
  exit /b 0
)
