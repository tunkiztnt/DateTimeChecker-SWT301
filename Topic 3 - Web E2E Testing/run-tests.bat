@echo off
chcp 65001 > nul
title Topic 3 - Web E2E Testing

echo ============================================================
echo  TOPIC 3 - WEB E2E TESTING
echo ============================================================
echo [MUC TIEU] Mo Edge va mo phong thao tac nguoi dung tu dau den cuoi.
echo [CONG CU] Selenium WebDriver.
echo [QUY TRINH] Mo web - nhap Day/Month/Year - bam Check - doc UI - PASS/FAIL.
echo.
echo [BUOC 1/3] Khoi dong application server...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\start-server.ps1"
if errorlevel 1 (
  echo [ERROR] Không thể khởi động server!
  goto end
)

echo.
echo ============================================================
echo [BUOC 2/3] Selenium dieu khien Edge va chay 10 test case
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\selenium-demo.ps1" -AutoClose
set TEST_STATUS=%ERRORLEVEL%

echo.
echo ============================================================
echo [BUOC 3/3] Dung application server
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
echo [KET LUAN] Luong nguoi dung tren giao dien web hoat dong dung.

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
