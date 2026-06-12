@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion
title Local CI/CD Pipeline Simulator

set ROOT=%~dp0..
set REPORT_DIR=%ROOT%\reports
set REPORT_FILE=%REPORT_DIR%\ci-pipeline-report.txt
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"

set PASSED=0
set FAILED=0
set SKIPPED=0

echo ============================================================
echo  LOCAL CI/CD PIPELINE - DateTimeChecker
echo  Started: %DATE% %TIME%
echo ============================================================
echo [DEMO GUIDE] Purpose: simulate a local CI/CD quality gate.
echo [DEMO GUIDE] Each stage represents one testing layer. If one fails, later stages can be skipped.
echo [DEMO GUIDE] Final output shows PASSED / FAILED / SKIPPED and writes a report file.
echo.

> "%REPORT_FILE%" echo Local CI/CD Pipeline Report
>> "%REPORT_FILE%" echo ==========================
>> "%REPORT_FILE%" echo Started: %DATE% %TIME%
>> "%REPORT_FILE%" echo.

echo [STAGE 1/8] Build Java Compilation
echo [MEANING] Confirm source code is compilable before any test runs.
if !FAILED! GTR 0 (
  echo [SKIP] Stage 1 skipped because a previous stage failed.
  >> "%REPORT_FILE%" echo Stage 1 Build: SKIPPED
  set /A SKIPPED+=1
) else (
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\build.ps1"
  if errorlevel 1 (
    echo [FAIL] Stage 1 Build failed.
    >> "%REPORT_FILE%" echo Stage 1 Build: FAIL
    set /A FAILED+=1
  ) else (
    echo [PASS] Stage 1 Build completed.
    >> "%REPORT_FILE%" echo Stage 1 Build: PASS
    set /A PASSED+=1
  )
)
echo.

echo [STAGE 2/8] Unit Testing - Java and JavaScript
echo [MEANING] Verify isolated backend logic and frontend helper functions.
if !FAILED! GTR 0 (
  echo [SKIP] Stage 2 skipped because a previous stage failed.
  >> "%REPORT_FILE%" echo Stage 2 Unit Testing: SKIPPED
  set /A SKIPPED+=1
) else (
  set STAGE_FAILED=0
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\test.ps1"
  if errorlevel 1 set STAGE_FAILED=1
  pushd "%ROOT%"
  call npm run test:unit
  if errorlevel 1 set STAGE_FAILED=1
  popd
  if !STAGE_FAILED! EQU 1 (
    echo [FAIL] Stage 2 Unit Testing failed.
    >> "%REPORT_FILE%" echo Stage 2 Unit Testing: FAIL
    set /A FAILED+=1
  ) else (
    echo [PASS] Stage 2 Unit Testing completed.
    >> "%REPORT_FILE%" echo Stage 2 Unit Testing: PASS
    set /A PASSED+=1
  )
)
echo.

echo [STAGE 3/8] API Testing
echo [MEANING] Send HTTP requests and validate JSON responses from the backend.
if !FAILED! GTR 0 (
  echo [SKIP] Stage 3 skipped because a previous stage failed.
  >> "%REPORT_FILE%" echo Stage 3 API Testing: SKIPPED
  set /A SKIPPED+=1
) else (
  set STAGE_FAILED=0
  pushd "%ROOT%"
  call npx playwright test --config=playwright.config.js --grep="@api"
  if errorlevel 1 set STAGE_FAILED=1
  popd
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\Topic 2 - API Testing\run-api-testing.ps1"
  if errorlevel 1 set STAGE_FAILED=1
  if !STAGE_FAILED! EQU 1 (
    echo [FAIL] Stage 3 API Testing failed.
    >> "%REPORT_FILE%" echo Stage 3 API Testing: FAIL
    set /A FAILED+=1
  ) else (
    echo [PASS] Stage 3 API Testing completed.
    >> "%REPORT_FILE%" echo Stage 3 API Testing: PASS
    set /A PASSED+=1
  )
)
call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\stop-server.ps1"
echo.

echo [STAGE 4/8] Web E2E Browser Testing
echo [MEANING] Simulate real user behavior in a browser.
if !FAILED! GTR 0 (
  echo [SKIP] Stage 4 skipped because a previous stage failed.
  >> "%REPORT_FILE%" echo Stage 4 Web E2E: SKIPPED
  set /A SKIPPED+=1
) else (
  call "%ROOT%\Topic 3 - Web E2E Testing\run-tests.bat" --no-pause
  if errorlevel 1 (
    echo [FAIL] Stage 4 Web E2E failed.
    >> "%REPORT_FILE%" echo Stage 4 Web E2E: FAIL
    set /A FAILED+=1
  ) else (
    echo [PASS] Stage 4 Web E2E completed. Selenium warning is accepted when EdgeDriver is unavailable.
    >> "%REPORT_FILE%" echo Stage 4 Web E2E: PASS
    set /A PASSED+=1
  )
)
call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\stop-server.ps1"
echo.

echo [STAGE 5/8] Mobile Testing
echo [MEANING] Validate mobile workflow or show fallback simulation when mobile tools are missing.
if !FAILED! GTR 0 (
  echo [SKIP] Stage 5 skipped because a previous stage failed.
  >> "%REPORT_FILE%" echo Stage 5 Mobile Testing: SKIPPED
  set /A SKIPPED+=1
) else (
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\Topic 4 - Mobile Testing\run-mobile-testing.ps1"
  if errorlevel 1 (
    echo [FAIL] Stage 5 Mobile Testing failed.
    >> "%REPORT_FILE%" echo Stage 5 Mobile Testing: FAIL
    set /A FAILED+=1
  ) else (
    echo [PASS] Stage 5 Mobile Testing completed.
    >> "%REPORT_FILE%" echo Stage 5 Mobile Testing: PASS
    set /A PASSED+=1
  )
)
echo.

echo [STAGE 6/8] Performance Testing
echo [MEANING] Measure latency, error rate and stability under concurrent load.
if !FAILED! GTR 0 (
  echo [SKIP] Stage 6 skipped because a previous stage failed.
  >> "%REPORT_FILE%" echo Stage 6 Performance Testing: SKIPPED
  set /A SKIPPED+=1
) else (
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\Topic 5 - Performance Testing\run-performance-tests.ps1"
  if errorlevel 1 (
    echo [FAIL] Stage 6 Performance Testing failed.
    >> "%REPORT_FILE%" echo Stage 6 Performance Testing: FAIL
    set /A FAILED+=1
  ) else (
    echo [PASS] Stage 6 Performance Testing completed.
    >> "%REPORT_FILE%" echo Stage 6 Performance Testing: PASS
    set /A PASSED+=1
  )
)
echo.

echo [STAGE 7/8] Visual Regression Testing
echo [MEANING] Compare current UI screenshots with baseline images.
if !FAILED! GTR 0 (
  echo [SKIP] Stage 7 skipped because a previous stage failed.
  >> "%REPORT_FILE%" echo Stage 7 Visual Regression: SKIPPED
  set /A SKIPPED+=1
) else (
  pushd "%ROOT%"
  call npx playwright test --config=playwright.config.js --grep="@visual"
  if errorlevel 1 (
    echo [FAIL] Stage 7 Visual Regression failed.
    >> "%REPORT_FILE%" echo Stage 7 Visual Regression: FAIL
    set /A FAILED+=1
  ) else (
    echo [PASS] Stage 7 Visual Regression completed.
    >> "%REPORT_FILE%" echo Stage 7 Visual Regression: PASS
    set /A PASSED+=1
  )
  popd
)
call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\stop-server.ps1"
echo.

echo [STAGE 8/8] AI-Assisted Testing
echo [MEANING] Demonstrate AI-supported testcase generation and self-healing concept.
if !FAILED! GTR 0 (
  echo [SKIP] Stage 8 skipped because a previous stage failed.
  >> "%REPORT_FILE%" echo Stage 8 AI-Assisted Testing: SKIPPED
  set /A SKIPPED+=1
) else (
  call powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\ai-self-healing-demo.ps1" -OfflineSample -AutoApprove
  if errorlevel 1 (
    echo [FAIL] Stage 8 AI-Assisted Testing failed.
    >> "%REPORT_FILE%" echo Stage 8 AI-Assisted Testing: FAIL
    set /A FAILED+=1
  ) else (
    echo [PASS] Stage 8 AI-Assisted Testing completed.
    >> "%REPORT_FILE%" echo Stage 8 AI-Assisted Testing: PASS
    set /A PASSED+=1
  )
)
echo.

if !FAILED! EQU 0 (
  set OVERALL=SUCCESS
) else (
  set OVERALL=FAILED
)

echo ============================================================
echo  PIPELINE SUMMARY
echo ============================================================
echo  PASSED:  !PASSED! stages
echo  FAILED:  !FAILED! stages
echo  SKIPPED: !SKIPPED! stages
echo  OVERALL: !OVERALL!
echo  Report:  %REPORT_FILE%
echo  Ended:   %DATE% %TIME%
echo ============================================================

>> "%REPORT_FILE%" echo.
>> "%REPORT_FILE%" echo Summary
>> "%REPORT_FILE%" echo -------
>> "%REPORT_FILE%" echo Passed: !PASSED!
>> "%REPORT_FILE%" echo Failed: !FAILED!
>> "%REPORT_FILE%" echo Skipped: !SKIPPED!
>> "%REPORT_FILE%" echo Overall: !OVERALL!
>> "%REPORT_FILE%" echo Ended: %DATE% %TIME%

if !FAILED! NEQ 0 (
  exit /b 1
) else (
  exit /b 0
)
