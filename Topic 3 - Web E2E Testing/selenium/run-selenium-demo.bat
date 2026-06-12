@echo off
chcp 65001 > nul
title Selenium E2E Demo - Date Time Checker

echo ============================================================
echo  SELENIUM VISIBLE DEMO - DateTimeChecker
echo ============================================================
echo [DEMO GUIDE] This optional demo opens Microsoft Edge and shows user-like actions.
echo [DEMO GUIDE] If msedgedriver is missing, install Edge WebDriver or use Topic 3 run-tests.bat.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\scripts\selenium-demo.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] Selenium demo gap loi. Vui long xem thong bao o tren.
)
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
