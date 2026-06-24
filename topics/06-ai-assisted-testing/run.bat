@echo off
chcp 65001 > nul
cd /d "%~dp0..\.."
title DateTimeChecker - Topic 6: AI-Assisted Testing

echo ============================================================
echo  RUNNING TOPIC 6: AI-ASSISTED TESTING (Self-Healing)
echo ============================================================
echo.
call node scripts/ai-testing-tool.js
echo.
pause
