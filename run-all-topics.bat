@echo off
chcp 65001 > nul
title DateTimeChecker - Run All SQA Testing Topics

echo ============================================================
echo  DATETIMECHECKER SQA AUTOMATED TEST SUITE RUNNER
echo ============================================================
echo.

echo [INFO] Dang bien dich ma nguon Java...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build.ps1"
if errorlevel 1 (
  echo [ERROR] Bien dich that bai! Khong the chay cac bai kiem thu.
  goto end
)
echo.

echo ============================================================
echo  1. TOPIC 1 - UNIT TESTING (KIEM THU DON VI)
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\test.ps1"
call npm run test:unit
echo.

echo ============================================================
echo  2. TOPIC 2 - API TESTING (KIEM THU API)
echo ============================================================
call npx playwright test --config=playwright.config.js --grep="@api"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Topic 2 - API Testing\run-api-testing.ps1"
echo.

echo ============================================================
echo  3. TOPIC 3 - WEB E2E TESTING (KIEM THU DAU-CUOI WEB)
echo ============================================================
call npx playwright test --config=playwright.config.js --grep="@e2e"
echo.

echo ============================================================
echo  4. TOPIC 4 - MOBILE TESTING (KIEM THU DI DONG)
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Topic 4 - Mobile Testing\run-mobile-testing.ps1"
echo.

echo ============================================================
echo  5. TOPIC 5 - PERFORMANCE TESTING (KIEM THU HIEU NANG)
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Topic 5 - Performance Testing\run-performance-tests.ps1"
echo.

echo ============================================================
echo  6. TOPIC 6 - VISUAL REGRESSION (KIEM THU KHOP ANH GIAO DIEN)
echo ============================================================
call npx playwright test --config=playwright.config.js --grep="@visual"
echo.

echo ============================================================
echo  7. TOPIC 7 - AI-ASSISTED TESTING (KIEM THU HO TRO BOI AI)
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ai-self-healing-demo.ps1" -OfflineSample -AutoApprove
echo.

echo ============================================================
echo  8. TOPIC 8 - CI/CD AND REPORTING (MO PHONG PIPELINE LOCAL)
echo ============================================================
echo [INFO] Chay mo phong tich hop lien tuc (CI/CD Simulation)...
call "%~dp0Topic 8 - CI CD and Reporting\run-ci-simulation.bat"
echo.

echo ============================================================
echo  TAT CA CAC TOPIC DA DUOC CHAY HOAN TAT!
echo ============================================================

:end
echo.
echo Nhan phim bat ky de dong trinh chay.
pause > nul
