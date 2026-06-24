@echo off
chcp 65001 > nul
setlocal
cd /d "%~dp0..\.."
title DateTimeChecker - Topic 4: Performance Testing
set "NO_PAUSE=0"
if /I "%~1"=="--no-pause" set "NO_PAUSE=1"

echo ============================================================
echo  RUNNING TOPIC 4: PERFORMANCE TESTING ^(Stress ^& Load Tests^)
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File ".\topics\04-performance-testing\run.ps1"
set "EXIT_CODE=%ERRORLEVEL%"
echo.
if "%NO_PAUSE%"=="1" exit /b %EXIT_CODE%
pause
exit /b %EXIT_CODE%
