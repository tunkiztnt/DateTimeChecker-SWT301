@echo off
chcp 65001 > nul
setlocal
cd /d "%~dp0..\.."
title DateTimeChecker - Topic 5: Visual Regression
set "NO_PAUSE=0"
set "TOPIC_STATUS=0"
if /I "%~1"=="--no-pause" set "NO_PAUSE=1"

echo ============================================================
echo  RUNNING TOPIC 5: VISUAL REGRESSION (Screenshot Comparisons)
echo ============================================================
echo  Engine: Visual Compare v4 ^(deterministic local-font render, exact pixel compare, always export current + diff^)
echo.

echo [1/3] Compiling Java backend...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\build.ps1" > nul 2>&1

echo [2/3] Starting backend server in the background...
start /b java -cp out/classes com.datetimechecker.App > nul 2>&1
timeout /t 2 /nobreak > nul

echo [3/3] Running Visual Regression tests...
if exist "topics\05-visual-regression\current-run-images" del /q "topics\05-visual-regression\current-run-images\*" > nul 2>&1
if exist "topics\05-visual-regression\diff-images" del /q "topics\05-visual-regression\diff-images\*" > nul 2>&1
set "HEADLESS=true"
call npx playwright test topics/05-visual-regression/
set "HEADLESS="
if errorlevel 1 (
  set "TOPIC_STATUS=1"
)

echo.
echo [VISUAL REVIEW] Baseline images:
echo   topics\05-visual-regression\baseline-images
echo [VISUAL REVIEW] Current run images:
echo   topics\05-visual-regression\current-run-images
echo [VISUAL REVIEW] Diff images:
echo   topics\05-visual-regression\diff-images

echo.
echo [INFO] Stopping backend server...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\stop-server.ps1" > nul 2>&1
echo.
if "%TOPIC_STATUS%"=="0" (
  echo [PASS] Topic 5 visual regression passed.
) else (
  echo [FAIL] Topic 5 visual regression failed.
)
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
pause
exit /b %TOPIC_STATUS%
