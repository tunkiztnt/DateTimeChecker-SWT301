@echo off
chcp 65001 > nul
setlocal
title Topic 7 - AI-Assisted Testing
set NO_PAUSE=0
set TOPIC_STATUS=0
if /I "%~1"=="--no-pause" set NO_PAUSE=1

echo ============================================================
echo  TOPIC 7 - AI-ASSISTED TESTING
echo ============================================================
echo [DEMO GUIDE] Purpose: show how AI helps generate tests, execute them,
echo              compare expected vs actual result, and explain self-healing.
echo [DEMO GUIDE] This runner is stable for video recording and does not require
echo              a Gemini API key. The chat tool is still available separately.
echo.
echo [STEP 1/4] AI analyzes DateTimeChecker rules and proposes test cases.
echo [STEP 2/4] The generated test cases are executed against the real API.
echo [STEP 3/4] CMD prints input, expected result, actual result, HTTP and latency.
echo [STEP 4/4] Self-healing and natural-language-to-test-code concepts are shown.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\ai-self-healing-demo.ps1" -OfflineSample -AutoApprove
if errorlevel 1 (
  echo [ERROR] AI-assisted testing demo failed.
  set TOPIC_STATUS=1
  goto end
)

echo.
echo ============================================================
echo [SUMMARY]
echo  AI-generated tests: PASS
echo  Expected vs actual: DISPLAYED
echo  Report: reports\ai-assisted-generated-tests.tsv
echo  TOPIC 7 AI-ASSISTED TESTING COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
if "%NO_PAUSE%"=="1" exit /b %TOPIC_STATUS%
echo Nhan phim bat ky de dong cua so.
pause > nul
exit /b %TOPIC_STATUS%
