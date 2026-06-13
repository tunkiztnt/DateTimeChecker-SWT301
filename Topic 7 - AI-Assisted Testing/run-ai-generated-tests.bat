@echo off
chcp 65001 > nul
setlocal
title Topic 7 - AI Generated Test Execution
set NO_PAUSE=0
set OFFLINE_SAMPLE=1
set TOPIC_STATUS=0

if /I "%~1"=="--no-pause" set NO_PAUSE=1
if /I "%~1"=="--real" set OFFLINE_SAMPLE=0
if /I "%~2"=="--real" set OFFLINE_SAMPLE=0

echo ============================================================
echo  TOPIC 7 - AI GENERATED TEST EXECUTION
echo ============================================================
echo [DEMO GUIDE] Purpose: generate testcase JSON, save it to file,
echo [DEMO GUIDE] then run visible Playwright E2E tests based on that file.
if "%OFFLINE_SAMPLE%"=="1" (
  echo [DEMO GUIDE] Mode: Offline sample for stable classroom demo.
) else (
  echo [DEMO GUIDE] Mode: Real Gemini generation.
)
echo [DEMO GUIDE] Browser mode: headed (visible UI demo).
echo.

if "%OFFLINE_SAMPLE%"=="1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\run-ai-generated-tests.ps1" -OfflineSample
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\run-ai-generated-tests.ps1"
)

if errorlevel 1 (
  set TOPIC_STATUS=1
  echo.
  echo [ERROR] Topic 7 AI-generated test execution failed.
) else (
  echo.
  echo [SUCCESS] Topic 7 AI-generated test execution completed successfully.
)

echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
