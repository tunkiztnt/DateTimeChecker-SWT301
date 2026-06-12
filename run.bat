@echo off
chcp 65001 > nul
title Date Time Checker - Local Server
echo ============================================================
echo  DATETIMECHECKER LOCAL SERVER
echo ============================================================
echo [STEP 1/3] Compile Java source.
echo [STEP 2/3] Start local server at http://localhost:4173.
echo [STEP 3/3] Browser will open automatically if the script can launch it.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] Cannot start local server.
)
pause
