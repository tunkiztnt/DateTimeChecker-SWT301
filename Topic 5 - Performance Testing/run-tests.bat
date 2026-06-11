@echo off
chcp 65001 > nul
title Topic 5 - Performance Testing

echo ============================================================
echo  RUNNING PERFORMANCE TESTS
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-performance-tests.ps1"
if errorlevel 1 (
  echo [ERROR] Performance tests failed!
  goto end
)

echo.
echo ============================================================
echo  PERFORMANCE TESTING COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
