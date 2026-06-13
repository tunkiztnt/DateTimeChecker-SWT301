@echo off
chcp 65001 > nul
title Date Time Checker - Gemini AI Testing Assistant Chat
echo ============================================================
echo  TOPIC 7 - AI-ASSISTED TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: use Gemini to suggest test cases and explain testing strategy.
echo [DEMO GUIDE] Try prompt: Hay tao testcase cho ngay nhuan, bien thang va du lieu sai dinh dang.
echo [DEMO GUIDE] Command: /demo-self-heal
echo [DEMO GUIDE] Command: /export-testcases
echo [DEMO GUIDE] Command: /run-generated-tests
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\ai-assistant-chat.ps1"
if errorlevel 1 (
  echo.
  echo Gemini AI Assistant gap loi. Vui long xem thong bao o tren.
)
echo.
echo Nhan phim bat ky de dong cua so chat.
pause > nul
