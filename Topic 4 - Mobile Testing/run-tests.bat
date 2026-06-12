@echo off
chcp 65001 > nul
setlocal
title Topic 4 - Mobile Testing
set NO_PAUSE=0
set TOPIC_STATUS=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1

echo ============================================================
echo  TOPIC 4 - MOBILE TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: show how DateTimeChecker can be tested on mobile.
echo [DEMO GUIDE] Real mode uses Flutter, ADB, Android device/emulator and Maestro.
echo [DEMO GUIDE] If the environment is missing, fallback simulation keeps the demo stable.
echo.
echo [STEP 1/3] Check Flutter, Android SDK, ADB, device and Maestro.
echo [STEP 2/3] Run real mobile flow or offline fallback simulation.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-mobile-testing.ps1"
if errorlevel 1 (
  echo [ERROR] Mobile testing failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 3/3] Summary
echo  Mobile test flow: PASS
echo  Report: reports\mobile-testing-report.txt
echo  MOBILE TESTING COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
