@echo off
chcp 65001 > nul
title Date Time Checker - Reset Gemini API Key
echo ============================================================
echo  RESET GEMINI API KEY
echo ============================================================
echo [DEMO GUIDE] Purpose: delete old key so you can enter a new Gemini API key.
echo [DEMO GUIDE] Use this if the key is wrong, quota is expired, or model access changes.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\reset-gemini-key.ps1"
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
