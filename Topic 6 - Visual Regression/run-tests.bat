@echo off
chcp 65001 > nul
title Topic 6 - Visual Regression Testing

echo ============================================================
echo  STARTING APPLICATION SERVER
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\start-server.ps1"
if errorlevel 1 (
  echo [ERROR] Không thể khởi động server!
  goto end
)

echo.
echo ============================================================
echo  RUNNING VISUAL REGRESSION CHECKS (PLAYWRIGHT SHOTS)
echo ============================================================

if not exist "%~dp0visual\visual.spec.js-snapshots" goto update_snapshots
echo [INFO] Đang so sánh giao diện với ảnh gốc...
pushd "%~dp0.."
call npx playwright test --config=playwright.config.js --grep="@visual"
popd
goto check_status

:update_snapshots
echo [INFO] Không tìm thấy ảnh giao diện gốc (baselines).
echo Đang tạo ảnh gốc (baseline screenshots) cho máy của bạn...
pushd "%~dp0.."
call npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
popd

:check_status
set TEST_STATUS=%ERRORLEVEL%

echo.
echo ============================================================
echo  STOPPING APPLICATION SERVER
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\stop-server.ps1"

if %TEST_STATUS% neq 0 (
  echo.
  echo [ERROR] Visual Regression tests failed!
  echo Nếu bạn có thay đổi giao diện cố ý, hãy chạy lệnh sau từ thư mục gốc để cập nhật ảnh gốc:
  echo npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
  goto end
)

echo.
echo ============================================================
echo  VISUAL REGRESSION COMPLETED SUCCESSFULLY!
echo ============================================================

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
