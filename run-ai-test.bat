@echo off
chcp 65001 > nul
title DateTimeChecker - AI Assisted Testing Dashboard
echo ============================================================
echo  STARTING AI-ASSISTED TESTING DASHBOARD (SWT301)
echo ============================================================
echo.
npm run ai-test
if errorlevel 1 (
  echo.
  echo [ERROR] Cannot start AI testing dashboard.
)
pause
