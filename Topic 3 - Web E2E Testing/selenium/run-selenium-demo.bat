@echo off
chcp 65001 > nul
title Selenium E2E Demo - Date Time Checker
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\scripts\selenium-demo.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] Selenium demo gặp lỗi. Vui lòng xem thông báo ở trên.
)
echo.
echo Nhấn phím bất kỳ để đóng cửa sổ.
pause > nul
