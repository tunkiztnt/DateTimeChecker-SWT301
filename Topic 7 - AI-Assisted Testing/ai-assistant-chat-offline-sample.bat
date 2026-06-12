@echo off
chcp 65001 > nul
title Date Time Checker - Offline Sample AI Testing Chat
echo ============================================================
echo  TOPIC 7 - AI-ASSISTED TESTING (OFFLINE SAMPLE)
echo ============================================================
echo [MUC TIEU] Tap duot quy trinh AI-assisted khi khong co API key/mang.
echo [LENH DEMO] Nhap /demo-self-heal de xem log AI generation va self-healing.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\ai-assistant-chat.ps1" -OfflineSample
echo.
echo Nhan phim bat ky de dong cua so chat.
pause > nul
