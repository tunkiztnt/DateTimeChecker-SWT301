@echo off
chcp 65001 > nul
title Topic 3 - Web E2E Testing

echo ============================================================
echo  STARTING APPLICATION SERVER
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\start-server.ps1"
if errorlevel 1 (
  echo [ERROR] Không thể khởi động server!
  goto end
)

echo.
echo ============================================================
echo  RUNNING SELENIUM WEB E2E TESTS (EDGE BROWSER)
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\selenium-demo.ps1" -AutoClose
set TEST_STATUS=%ERRORLEVEL%

echo.
echo ============================================================
echo  STOPPING APPLICATION SERVER
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\stop-server.ps1"

if %TEST_STATUS% neq 0 (
  echo [ERROR] Selenium E2E tests failed!
  goto end
)

echo.
echo ============================================================
echo  ALL WEB E2E TESTS COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
