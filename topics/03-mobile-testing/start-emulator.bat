@echo off
chcp 65001 > nul
setlocal
title Topic 3 - Start Emulator

set "REFRESH_ARG="
if /I "%~1"=="--refresh" set "REFRESH_ARG=-RefreshApp"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0open-demo-app.ps1" %REFRESH_ARG%
set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% neq 0 (
    echo.
    echo [ERROR] Topic 3 demo launcher failed.
    echo If this is the first setup, try:
    echo   powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_android_tools.ps1"
)

echo.
pause
exit /b %EXIT_CODE%
