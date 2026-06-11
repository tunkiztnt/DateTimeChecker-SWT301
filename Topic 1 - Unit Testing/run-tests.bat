@echo off
chcp 65001 > nul
title Topic 1 - Unit Testing

echo ============================================================
echo  RUNNING JAVA UNIT TESTS (BACKEND)
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\test.ps1"
if errorlevel 1 (
  echo [ERROR] Java unit tests failed!
  goto end
)

echo.
echo ============================================================
echo  RUNNING JAVASCRIPT UNIT TESTS (FRONTEND HELPERS)
echo ============================================================
call npm run test:unit
if errorlevel 1 (
  echo [ERROR] JavaScript unit tests failed!
  goto end
)

echo.
echo ============================================================
echo  ALL UNIT TESTS COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
