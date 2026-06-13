@echo off
chcp 65001 > nul
title Date Time Checker - Offline Sample AI Testing Chat
echo ============================================================
echo  TOPIC 7 - AI-ASSISTED TESTING OFFLINE SAMPLE
echo ============================================================
echo [DEMO GUIDE] Purpose: run the same AI demo flow without Gemini API key.
echo [DEMO GUIDE] Use this when internet, quota or API key is not ready.
echo [DEMO GUIDE] Command: /demo-self-heal
echo [DEMO GUIDE] Command: /export-testcases
echo [DEMO GUIDE] Command: /run-generated-tests
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\ai-assistant-chat.ps1" -OfflineSample
echo.
echo Nhan phim bat ky de dong cua so chat.
pause > nul
