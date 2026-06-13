@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion
title DateTimeChecker - Run All SWT301 Testing Topics

set ROOT=%~dp0
set TOTAL=8
set PASSED=0
set FAILED=0
set NO_PAUSE=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1

echo ============================================================
echo  DATETIMECHECKER - RUN ALL 8 SWT301 TESTING TOPICS
echo ============================================================
echo [DEMO GUIDE] This is the final rehearsal runner for the whole group.
echo [DEMO GUIDE] Each topic uses its own detailed runner so the CMD output
echo              still shows purpose, steps, test cases, and report paths.
echo [DEMO GUIDE] The runner continues after a failed topic so you can see
echo              the full demo status at the end.
echo.

echo ============================================================
echo [TOPIC 1/8] UNIT TESTING
echo ============================================================
call "%ROOT%Topic 1 - Unit Testing\run-tests.bat" --no-pause
if errorlevel 1 (
  echo [RUN-ALL RESULT] Topic 1: FAILED
  set /A FAILED+=1
) else (
  echo [RUN-ALL RESULT] Topic 1: PASSED
  set /A PASSED+=1
)
echo.

echo ============================================================
echo [TOPIC 2/8] API TESTING
echo ============================================================
call "%ROOT%Topic 2 - API Testing\run-tests.bat" --no-pause
if errorlevel 1 (
  echo [RUN-ALL RESULT] Topic 2: FAILED
  set /A FAILED+=1
) else (
  echo [RUN-ALL RESULT] Topic 2: PASSED
  set /A PASSED+=1
)
echo.

echo ============================================================
echo [TOPIC 3/8] WEB E2E TESTING
echo ============================================================
call "%ROOT%Topic 3 - Web E2E Testing\run-tests.bat" --no-pause
if errorlevel 1 (
  echo [RUN-ALL RESULT] Topic 3: FAILED
  set /A FAILED+=1
) else (
  echo [RUN-ALL RESULT] Topic 3: PASSED
  set /A PASSED+=1
)
echo.

echo ============================================================
echo [TOPIC 4/8] MOBILE TESTING
echo ============================================================
call "%ROOT%Topic 4 - Mobile Testing\run-tests.bat" --no-pause
if errorlevel 1 (
  echo [RUN-ALL RESULT] Topic 4: FAILED
  set /A FAILED+=1
) else (
  echo [RUN-ALL RESULT] Topic 4: PASSED
  set /A PASSED+=1
)
echo.

echo ============================================================
echo [TOPIC 5/8] PERFORMANCE TESTING
echo ============================================================
call "%ROOT%Topic 5 - Performance Testing\run-tests.bat" --no-pause
if errorlevel 1 (
  echo [RUN-ALL RESULT] Topic 5: FAILED
  set /A FAILED+=1
) else (
  echo [RUN-ALL RESULT] Topic 5: PASSED
  set /A PASSED+=1
)
echo.

echo ============================================================
echo [TOPIC 6/8] VISUAL REGRESSION
echo ============================================================
call "%ROOT%Topic 6 - Visual Regression\run-tests.bat" --no-pause
if errorlevel 1 (
  echo [RUN-ALL RESULT] Topic 6: FAILED
  set /A FAILED+=1
) else (
  echo [RUN-ALL RESULT] Topic 6: PASSED
  set /A PASSED+=1
)
echo.

echo ============================================================
echo [TOPIC 7/8] AI-ASSISTED TESTING
echo ============================================================
call "%ROOT%Topic 7 - AI-Assisted Testing\run-tests.bat" --no-pause
if errorlevel 1 (
  echo [RUN-ALL RESULT] Topic 7: FAILED
  set /A FAILED+=1
) else (
  echo [RUN-ALL RESULT] Topic 7: PASSED
  set /A PASSED+=1
)
echo.

echo ============================================================
echo [TOPIC 8/8] CI/CD AND REPORTING
echo ============================================================
call "%ROOT%Topic 8 - CI CD and Reporting\run-ci-simulation.bat"
if errorlevel 1 (
  echo [RUN-ALL RESULT] Topic 8: FAILED
  set /A FAILED+=1
) else (
  echo [RUN-ALL RESULT] Topic 8: PASSED
  set /A PASSED+=1
)
echo.

echo ============================================================
echo  RUN ALL TOPICS SUMMARY
echo ============================================================
echo  Total topics: %TOTAL%
echo  Passed:       !PASSED!
echo  Failed:       !FAILED!
echo  Reports:      %ROOT%reports
if !FAILED! EQU 0 (
  echo  Overall:      SUCCESS
) else (
  echo  Overall:      REVIEW FAILED TOPICS ABOVE
)
echo ============================================================
echo.
if "%NO_PAUSE%"=="1" goto finish
echo Press any key to close this runner.
pause > nul

:finish
if !FAILED! NEQ 0 (
  exit /b 1
) else (
  exit /b 0
)
