@echo off
chcp 65001 > nul
title Topic 6 - Visual Regression Testing

echo ============================================================
echo  COMPILING JAVA CODE
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\build.ps1"
if errorlevel 1 (
  echo [ERROR] Biên dịch mã nguồn thất bại!
  goto end
)

echo.
echo ============================================================
echo  RUNNING VISUAL REGRESSION CHECKS (PLAYWRIGHT SHOTS)
echo ============================================================

set SNAPSHOT_DIR="%~dp0playwright-visual\visual.spec.js-snapshots"
if not exist %SNAPSHOT_DIR% (
  echo [INFO] Không tìm thấy ảnh giao diện gốc (baselines).
  echo Đang tạo ảnh gốc (baseline screenshots) cho máy của bạn...
  pushd "%~dp0.."
  call npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
  popd
) else (
  echo [INFO] Đang so sánh giao diện với ảnh gốc...
  pushd "%~dp0.."
  call npx playwright test --config=playwright.config.js --grep="@visual"
  popd
)

if errorlevel 1 (
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
