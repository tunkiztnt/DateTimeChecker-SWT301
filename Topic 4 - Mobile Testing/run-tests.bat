@echo off
chcp 65001 > nul
title Topic 4 - Mobile Testing

echo ============================================================
echo  TOPIC 4 - MOBILE TESTING
echo ============================================================
echo [MUC TIEU] Kiem tra ung dung Flutter tren Android nhu nguoi dung that.
echo [CONG CU] Flutter test + ADB + Maestro.
echo [QUY TRINH] Kiem tra device - widget test - build APK - cai app - Maestro thao tac UI.
echo [LUU Y] Neu khong co emulator/device, script se in ro che do mo phong.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-mobile-testing.ps1"
if errorlevel 1 (
  echo [ERROR] Mobile testing failed!
  goto end
)

echo.
echo ============================================================
echo  MOBILE TESTING COMPLETED SUCCESSFULLY!
echo ============================================================
echo [REPORT] reports\mobile-testing-report.txt

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
