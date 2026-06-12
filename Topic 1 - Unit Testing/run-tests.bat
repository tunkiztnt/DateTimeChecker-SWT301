@echo off
chcp 65001 > nul
title Topic 1 - Unit Testing

echo ============================================================
echo  TOPIC 1 - UNIT TESTING
echo ============================================================
echo [MUC TIEU] Kiem tra tung ham/logic rieng le, khong can mo web.
echo [CONG CU] Java test runner + Jest.
echo [QUY TRINH] Build source - chay Java tests - chay JavaScript tests.
echo.
echo [BUOC 1/3] Bien dich ma nguon Java va test code...
echo [BUOC 2/3] Chay Java unit tests cho DateTimeValidationService...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\test.ps1"
if errorlevel 1 (
  echo [ERROR] Java unit tests failed!
  goto end
)

echo.
echo ============================================================
echo [BUOC 3/3] Chay JavaScript unit tests cho frontend helpers
echo ============================================================
echo [KIEM TRA] Format ngay thang, gia tri bien va du lieu khong hop le.
call npm run test:unit
if errorlevel 1 (
  echo [ERROR] JavaScript unit tests failed!
  goto end
)

echo.
echo ============================================================
echo  ALL UNIT TESTS COMPLETED SUCCESSFULLY!
echo ============================================================
echo [KET LUAN] Cac don vi logic backend va frontend deu PASS.

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
