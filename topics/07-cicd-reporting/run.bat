@echo off
chcp 65001 > nul
setlocal
cd /d "%~dp0..\.."
title DateTimeChecker - Topic 7: CI/CD Reporting

set "OPEN_REPORT="
if /I "%~1"=="--open-report" set "OPEN_REPORT=-OpenReport"

echo ============================================================
echo  RUNNING TOPIC 7: CI/CD PIPELINE DEMO
echo ============================================================
echo  Flow is controlled by StageStatus inside topics\07-cicd-reporting\run.ps1
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File ".\topics\07-cicd-reporting\run.ps1" %OPEN_REPORT%
set "PIPELINE_EXIT=%ERRORLEVEL%"

echo.
if "%PIPELINE_EXIT%"=="0" (
  echo [PASS] Topic 7 pipeline completed successfully.
) else (
  echo [FAIL] Topic 7 pipeline failed.
)
echo.
pause
exit /b %PIPELINE_EXIT%
