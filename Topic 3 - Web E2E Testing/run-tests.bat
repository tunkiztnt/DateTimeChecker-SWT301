@echo off
chcp 65001 > nul
title Topic 3 - Web E2E Testing

echo ============================================================
echo  COMPILING JAVA CODE
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\build.ps1"
if errorlevel 1 (
  echo [ERROR] Biên dịch mã nguồn thất bại!
  goto end
)

echo.
echo ============================================================
echo  RUNNING PLAYWRIGHT WEB E2E TESTS
echo ============================================================
call npx playwright test --config=playwright.config.js --grep="@e2e"
if errorlevel 1 (
  echo [ERROR] Playwright E2E tests failed!
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
