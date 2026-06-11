@echo off
chcp 65001 > nul
title Topic 4 - Mobile Testing

echo ============================================================
echo  RUNNING MAESTRO MOBILE TESTING
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-mobile-testing.ps1"
if errorlevel 1 (
  echo [ERROR] Mobile testing failed!
  goto end
)

echo.
echo ============================================================
echo  MOBILE TESTING COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
