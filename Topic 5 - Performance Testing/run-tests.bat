@echo off
chcp 65001 > nul
title Topic 5 - Performance Testing

echo ============================================================
echo  TOPIC 5 - PERFORMANCE TESTING
echo ============================================================
echo [MUC TIEU] Do kha nang chiu tai va toc do phan hoi cua API.
echo [CONG CU] Autocannon.
echo [KICH BAN] Smoke: 1 connection; Load: 10; Stress: 50.
echo [DANH GIA] So request, loi, error rate va p99 latency.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-performance-tests.ps1"
if errorlevel 1 (
  echo [ERROR] Performance tests failed!
  goto end
)

echo.
echo ============================================================
echo  PERFORMANCE TESTING COMPLETED SUCCESSFULLY!
echo ============================================================
echo [REPORT] reports\performance-report.txt

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
