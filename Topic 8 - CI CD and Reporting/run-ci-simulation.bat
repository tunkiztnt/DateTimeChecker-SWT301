@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion
title Local CI/CD Pipeline Simulator

SET PASSED=0
SET FAILED=0
SET SKIPPED=0
SET STAGE1_STATUS=PENDING
SET STAGE2_STATUS=PENDING
SET STAGE3_STATUS=PENDING
SET STAGE4_STATUS=PENDING
SET STAGE5_STATUS=PENDING
SET STAGE6_STATUS=PENDING
SET STAGE7_STATUS=PENDING
SET STAGE8_STATUS=PENDING
if not exist "%~dp0..\reports" mkdir "%~dp0..\reports"

echo ============================================================
echo  LOCAL CI/CD PIPELINE - DateTimeChecker
echo  Started: %DATE% %TIME%
echo ============================================================
echo [MUC TIEU] Mo phong pipeline tu dong kiem tra code truoc khi tich hop.
echo [QUY TAC] Moi stage chi chay khi stage truoc PASS; loi se lam cac stage sau SKIP.
echo [OUTPUT] CMD in log tung stage va tong ket PASS/FAIL/SKIPPED.
echo [REPORT] Ket qua duoc luu vao reports\ci-pipeline-report.txt
echo.

:: STAGE 1: Code Compilation
if !FAILED! GTR 0 (
  echo [STAGE 1/8] Skipped: Build Java Compilation
  SET STAGE1_STATUS=SKIPPED
  SET /A SKIPPED+=1
) else (
  echo ------------------------------------------------------------
  echo [STAGE 1/8] Running: Build Java Compilation...
  echo [WHAT] Compile Java application and test source files.
  echo [PASS IF] javac finishes with exit code 0.
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\build.ps1" 2>&1
  if errorlevel 1 (
    echo [FAIL] Stage 1 failed
    SET STAGE1_STATUS=FAIL
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 1 completed
    SET STAGE1_STATUS=PASS
    SET /A PASSED+=1
  )
)
echo.

:: STAGE 2: Unit Testing (Java and JavaScript)
if !FAILED! GTR 0 (
  echo [STAGE 2/8] Skipped: Unit Testing (Java and JavaScript)
  SET STAGE2_STATUS=SKIPPED
  SET /A SKIPPED+=1
) else (
  echo ------------------------------------------------------------
  echo [STAGE 2/8] Running: Unit Testing (Java and JavaScript)...
  echo [WHAT] Run backend logic tests and frontend helper tests.
  echo [PASS IF] Java test runner and Jest both return exit code 0.
  SET STAGE_FAILED=0
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\test.ps1" 2>&1
  if errorlevel 1 SET STAGE_FAILED=1
  call npm run test:unit 2>&1
  if errorlevel 1 SET STAGE_FAILED=1
  
  if !STAGE_FAILED! EQU 1 (
    echo [FAIL] Stage 2 failed
    SET STAGE2_STATUS=FAIL
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 2 completed
    SET STAGE2_STATUS=PASS
    SET /A PASSED+=1
  )
)
echo.

:: STAGE 3: API Testing
if !FAILED! GTR 0 (
  echo [STAGE 3/8] Skipped: API Validation
  SET STAGE3_STATUS=SKIPPED
  SET /A SKIPPED+=1
) else (
  echo ------------------------------------------------------------
  echo [STAGE 3/8] Running: API Validation...
  echo [WHAT] Send HTTP requests to DateTimeChecker API and assert JSON response.
  echo [PASS IF] Playwright API tests and PowerShell API tests both pass.
  SET STAGE_FAILED=0
  pushd "%~dp0.."
  call npx playwright test --config=playwright.config.js --grep="@api" 2>&1
  if errorlevel 1 SET STAGE_FAILED=1
  popd
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 2 - API Testing\run-api-testing.ps1" 2>&1
  if errorlevel 1 SET STAGE_FAILED=1
  
  if !STAGE_FAILED! EQU 1 (
    echo [FAIL] Stage 3 failed
    SET STAGE3_STATUS=FAIL
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 3 completed
    SET STAGE3_STATUS=PASS
    SET /A PASSED+=1
  )
)
:: Kill server after Stage 3 (API) using the requested netstat loop
FOR /F "tokens=5" %%P IN ('netstat -a -n -o ^| findstr ":4173"') DO taskkill /PID %%P /F 2>nul
echo.

:: STAGE 4: Web E2E Browser Testing
if !FAILED! GTR 0 (
  echo [STAGE 4/8] Skipped: Web E2E Browser Testing
  SET STAGE4_STATUS=SKIPPED
  SET /A SKIPPED+=1
) else (
  echo ------------------------------------------------------------
  echo [STAGE 4/8] Running: Web E2E Browser Testing...
  echo [WHAT] Open browser automation, enter dates, click buttons, verify UI result.
  echo [PASS IF] Playwright E2E and Selenium WebDriver both pass.
  SET STAGE_FAILED=0
  pushd "%~dp0.."
  call npm run test:e2e 2>&1
  if errorlevel 1 SET STAGE_FAILED=1
  popd
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\selenium-demo.ps1" -AutoClose -Headless 2>&1
  if errorlevel 1 SET STAGE_FAILED=1
  
  if !STAGE_FAILED! EQU 1 (
    echo [FAIL] Stage 4 failed
    SET STAGE4_STATUS=FAIL
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 4 completed
    SET STAGE4_STATUS=PASS
    SET /A PASSED+=1
  )
)
:: Kill server after Stage 4 (E2E) using the requested netstat loop
FOR /F "tokens=5" %%P IN ('netstat -a -n -o ^| findstr ":4173"') DO taskkill /PID %%P /F 2>nul
echo.

:: STAGE 5: Mobile Testing Fallback Simulation
if !FAILED! GTR 0 (
  echo [STAGE 5/8] Skipped: Mobile Testing
  SET STAGE5_STATUS=SKIPPED
  SET /A SKIPPED+=1
) else (
  echo ------------------------------------------------------------
  echo [STAGE 5/8] Running: Mobile Testing...
  echo [WHAT] Run Flutter/mobile flow or clearly fall back to offline mobile mock mode.
  echo [PASS IF] Mobile script exits successfully and writes mobile report.
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 4 - Mobile Testing\run-mobile-testing.ps1" 2>&1
  if errorlevel 1 (
    echo [FAIL] Stage 5 failed
    SET STAGE5_STATUS=FAIL
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 5 completed
    SET STAGE5_STATUS=PASS
    SET /A PASSED+=1
  )
)
echo.

:: STAGE 6: Performance Testing
if !FAILED! GTR 0 (
  echo [STAGE 6/8] Skipped: Performance Testing
  SET STAGE6_STATUS=SKIPPED
  SET /A SKIPPED+=1
) else (
  echo ------------------------------------------------------------
  echo [STAGE 6/8] Running: Performance Testing...
  echo [WHAT] Run Smoke, Load, and Stress scenarios against the API.
  echo [PASS IF] All performance thresholds pass.
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Topic 5 - Performance Testing\run-performance-tests.ps1" 2>&1
  if errorlevel 1 (
    echo [FAIL] Stage 6 failed
    SET STAGE6_STATUS=FAIL
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 6 completed
    SET STAGE6_STATUS=PASS
    SET /A PASSED+=1
  )
)
echo.

:: STAGE 7: Visual Regression Testing
if !FAILED! GTR 0 (
  echo [STAGE 7/8] Skipped: Visual Regression Testing
  SET STAGE7_STATUS=SKIPPED
  SET /A SKIPPED+=1
) else (
  echo ------------------------------------------------------------
  echo [STAGE 7/8] Running: Visual Regression Testing...
  echo [WHAT] Capture UI screenshots and compare them with baseline images.
  echo [PASS IF] All current screenshots match baselines within tolerance.
  pushd "%~dp0.."
  call npx playwright test --config=playwright.config.js --grep="@visual" 2>&1
  if errorlevel 1 (
    echo [FAIL] Stage 7 failed
    SET STAGE7_STATUS=FAIL
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 7 completed
    SET STAGE7_STATUS=PASS
    SET /A PASSED+=1
  )
  popd
)
:: Kill server after Stage 7 (Visual) using the requested netstat loop
FOR /F "tokens=5" %%P IN ('netstat -a -n -o ^| findstr ":4173"') DO taskkill /PID %%P /F 2>nul
echo.

:: STAGE 8: AI-Assisted Testing
if !FAILED! GTR 0 (
  echo [STAGE 8/8] Skipped: AI-Assisted Testing
  SET STAGE8_STATUS=SKIPPED
  SET /A SKIPPED+=1
) else (
  echo ------------------------------------------------------------
  echo [STAGE 8/8] Running: AI-Assisted Testing...
  echo [WHAT] Demonstrate AI test generation, self-healing locator, and natural language to test code.
  echo [PASS IF] Offline AI-assisted demo completes successfully.
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\ai-self-healing-demo.ps1" -OfflineSample -AutoApprove 2>&1
  if errorlevel 1 (
    echo [FAIL] Stage 8 failed
    SET STAGE8_STATUS=FAIL
    SET /A FAILED+=1
  ) else (
    echo [PASS] Stage 8 completed
    SET STAGE8_STATUS=PASS
    SET /A PASSED+=1
  )
)
echo.

:: Set overall status
if !FAILED! EQU 0 (
  SET OVERALL=SUCCESS
) else (
  SET OVERALL=FAILED
)

SET /A SKIPPED=8-PASSED-FAILED

echo ==========================================
echo PIPELINE SUMMARY
echo ==========================================
echo Stage 1 Build:              !STAGE1_STATUS!
echo Stage 2 Unit Testing:       !STAGE2_STATUS!
echo Stage 3 API Testing:        !STAGE3_STATUS!
echo Stage 4 Web E2E Testing:    !STAGE4_STATUS!
echo Stage 5 Mobile Testing:     !STAGE5_STATUS!
echo Stage 6 Performance:        !STAGE6_STATUS!
echo Stage 7 Visual Regression:  !STAGE7_STATUS!
echo Stage 8 AI-Assisted:        !STAGE8_STATUS!
echo ------------------------------------------
echo [PASS]    !PASSED! stages
echo [FAIL]    !FAILED! stages
echo [SKIPPED] !SKIPPED! stages
echo ==========================================
echo OVERALL: !OVERALL! - Ended: %DATE% %TIME%
echo ==========================================

(
  echo CI/CD PIPELINE SUMMARY
  echo ======================
  echo Ended: %DATE% %TIME%
  echo.
  echo Stage results:
  echo 1. Build Java Compilation: !STAGE1_STATUS!
  echo 2. Unit Testing: !STAGE2_STATUS!
  echo 3. API Testing: !STAGE3_STATUS!
  echo 4. Web E2E Browser Testing: !STAGE4_STATUS!
  echo 5. Mobile Testing: !STAGE5_STATUS!
  echo 6. Performance Testing: !STAGE6_STATUS!
  echo 7. Visual Regression Testing: !STAGE7_STATUS!
  echo 8. AI-Assisted Testing: !STAGE8_STATUS!
  echo.
  echo Passed: !PASSED!
  echo Failed: !FAILED!
  echo Skipped: !SKIPPED!
  echo Overall: !OVERALL!
) > "%~dp0..\reports\ci-pipeline-report.txt"
echo [REPORT] reports\ci-pipeline-report.txt
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul

if !FAILED! NEQ 0 (
  exit /b 1
) else (
  exit /b 0
)
