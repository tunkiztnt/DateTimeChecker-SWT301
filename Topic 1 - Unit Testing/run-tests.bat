@echo off
chcp 65001 > nul
setlocal
title Topic 1 - Unit Testing
set NO_PAUSE=0
set TOPIC_STATUS=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1

echo ============================================================
echo  TOPIC 1 - UNIT TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: test small isolated logic before API/UI testing.
echo [DEMO GUIDE] Backend checks: valid date, leap year, month length, range, format.
echo [DEMO GUIDE] Frontend checks: date formatting and input range helper.
echo.
echo [STEP 1/3] Compile Java and run backend unit tests.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\test.ps1"
if errorlevel 1 (
  echo [ERROR] Java unit tests failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 2/3] Run JavaScript helper unit tests with Jest.
echo ============================================================
pushd "%~dp0.."
call npm run test:unit
set JS_TEST_STATUS=%ERRORLEVEL%
popd
if %JS_TEST_STATUS% neq 0 (
  echo [ERROR] JavaScript unit tests failed!
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [STEP 3/3] Summary
echo  Java backend unit tests: PASS
echo  JavaScript Jest tests:   PASS
echo  ALL UNIT TESTS COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
