@echo off
chcp 65001 > nul
setlocal
title Topic 5 - Performance Testing
set NO_PAUSE=0
set TOPIC_STATUS=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1

echo ============================================================
echo  TOPIC 5 - PERFORMANCE TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: measure speed and stability under concurrent requests.
echo [DEMO GUIDE] Scenarios: Smoke, Load and Stress.
echo [DEMO GUIDE] Key metrics: total requests, errors, p99 latency and pass threshold.
echo.
echo [STEP 1/4] Start local DateTimeChecker server.
echo [STEP 2/4] Run Autocannon Smoke, Load and Stress scenarios.
echo [STEP 3/4] Write performance report.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-performance-tests.ps1"
if errorlevel 1 (
  echo [ERROR] Performance tests failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 4/4] Summary
echo  Performance scenarios: PASS
echo  Report: reports\performance-report.txt
echo  PERFORMANCE TESTING COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
