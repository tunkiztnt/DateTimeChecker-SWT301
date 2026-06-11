@echo off
chcp 65001 > nul
title Topic 2 - API Testing

echo ============================================================
echo  COMPILING JAVA CODE
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\build.ps1"
if errorlevel 1 (
  echo [ERROR] Biên dịch mã nguồn thất bại!
  goto end
)

echo ============================================================
echo  RUNNING PLAYWRIGHT API TESTS
echo ============================================================
pushd "%~dp0.."
call npx playwright test --config=playwright.config.js --grep="@api"
popd
if errorlevel 1 (
  echo [ERROR] Playwright API tests failed!
  goto end
)

echo.
echo ============================================================
echo  RUNNING POWERSHELL API TESTS (INTEGRATION)
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-api-testing.ps1"
if errorlevel 1 (
  echo [ERROR] PowerShell API tests failed!
  goto end
)

echo.
echo ============================================================
echo  ALL API TESTS COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
