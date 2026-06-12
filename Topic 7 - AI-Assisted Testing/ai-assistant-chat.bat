@echo off
chcp 65001 > nul
title Date Time Checker - Gemini AI Testing Assistant Chat
echo ============================================================
echo  TOPIC 7 - AI-ASSISTED TESTING
echo ============================================================
echo [MUC TIEU] Dung Gemini de hoi dap, sinh y tuong test va demo self-healing.
echo [QUY TRINH] Prompt nguoi dung - Gemini phan tich - sinh testcase/de xuat - tester review.
echo [LENH DEMO] Nhap /demo-self-heal de xem quy trinh phat hien va de xuat sua loi.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\ai-assistant-chat.ps1"
if errorlevel 1 (
  echo.
  echo Gemini AI Assistant gap loi. Vui long xem thong bao o tren.
)
echo.
echo Nhan phim bat ky de dong cua so chat.
pause > nul
