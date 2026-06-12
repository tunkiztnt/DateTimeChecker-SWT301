@echo off
chcp 65001 > nul
title Topic 2 - API Testing

echo ============================================================
echo  TOPIC 2 - API TESTING
echo ============================================================
echo [MUC TIEU] Gui HTTP request truc tiep den API, khong thao tac UI.
echo [ENDPOINT] POST /api/check-date va /api/datetime/check
echo [KIEM TRA] HTTP status, JSON response, valid/invalid, response time.
echo.
echo [BUOC 1/3] Bien dich backend Java...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\build.ps1"
if errorlevel 1 (
  echo [ERROR] Biên dịch mã nguồn thất bại!
  goto end
)

echo ============================================================
echo [BUOC 2/3] Playwright gui request va assert response
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
echo [BUOC 3/3] PowerShell gui 10 request va tao report TSV
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
echo [REPORT] reports\api-testing-report.tsv
echo [KET LUAN] API tra ve dung status, JSON va ket qua nghiep vu.

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
