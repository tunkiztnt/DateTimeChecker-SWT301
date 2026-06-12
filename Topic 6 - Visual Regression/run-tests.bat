@echo off
chcp 65001 > nul
title Topic 6 - Visual Regression Testing

echo ============================================================
echo  TOPIC 6 - VISUAL REGRESSION TESTING
echo ============================================================
echo [MUC TIEU] Phat hien giao dien bi lech sau khi thay doi code.
echo [CONG CU] Playwright screenshot comparison.
echo [QUY TRINH] Chup giao dien hien tai - so voi baseline - tao diff neu khac.
echo [TRANG THAI] Empty, valid input, valid result, invalid result, error.
echo.
echo [BUOC 1/3] Khoi dong application server...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\start-server.ps1"
if errorlevel 1 (
  echo [ERROR] Không thể khởi động server!
  goto end
)

echo.
echo ============================================================
echo [BUOC 2/3] Playwright chup va so sanh 5 trang thai giao dien
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
echo [BUOC 3/3] Dung application server
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
echo [KET LUAN] Tat ca anh hien tai khop baseline trong nguong cho phep.

:end
echo.
echo Nhan phim bat ky de dong cua so.
pause > nul
