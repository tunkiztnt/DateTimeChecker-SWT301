@echo off
chcp 65001 > nul
title Date Time Checker - Local Server
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] Loi khoi dong may chu.
)
pause
