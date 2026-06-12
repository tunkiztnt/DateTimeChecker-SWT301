# Topic 4: Mobile Testing - Kiểm thử ứng dụng di động

## Dùng để làm gì?

Mobile Testing kiểm tra phiên bản Flutter của DateTimeChecker trên môi trường Android/iOS hoặc chế độ mô phỏng offline. Topic này cho thấy cùng một nghiệp vụ kiểm tra ngày tháng có thể được kiểm thử trên thiết bị di động.

## Vai trò và ý nghĩa

- Xác minh UI mobile, widget Flutter và flow người dùng trên màn hình nhỏ.
- Minh họa kiểm thử tự động bằng Maestro, một công cụ phù hợp cho mobile UI testing.
- Có chế độ fallback simulation để nhóm vẫn demo được khi máy chưa có emulator, Flutter SDK hoặc Maestro.

## Thành phần chính

- Flutter app: `Topic 4 - Mobile Testing/flutter_app/`
- Maestro flow: `Topic 4 - Mobile Testing/maestro/date_time_checker_flow.yaml`
- Mobile runner: `Topic 4 - Mobile Testing/run-mobile-testing.ps1`
- Script chạy topic: `Topic 4 - Mobile Testing/run-tests.bat`
- Hướng dẫn chi tiết: `Topic 4 - Mobile Testing/demo-guide.md`
- Test cases: `Topic 4 - Mobile Testing/mobile-test-cases.md`

## Cách chạy

Từ thư mục gốc dự án:

```powershell
.\Topic 4 - Mobile Testing\run-tests.bat
```

Nếu muốn cài Maestro:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Topic 4 - Mobile Testing\install-maestro-free.ps1"
```

## Luồng hoạt động khi chạy

1. Script kiểm tra Flutter, Android SDK, ADB, thiết bị/emulator và Maestro.
2. Nếu đủ môi trường, chạy Flutter widget tests, build APK, cài app và chạy Maestro flow.
3. Nếu thiếu môi trường, tự chuyển sang Offline Mobile Mock Mode để demo tiến trình.
4. Ghi kết quả vào `reports/mobile-testing-report.txt`.

## Kết quả mong đợi

- Môi trường thật: APK được build/cài, Maestro flow PASS.
- Môi trường thiếu thiết bị: script vẫn in tiến trình giả lập và kết thúc PASS để phục vụ demo.
- Báo cáo mobile nằm trong `reports/mobile-testing-report.txt`.

## Gợi ý lời demo

"Topic 4 chứng minh nhóm đã xem xét kiểm thử đa nền tảng. Ngay cả khi lớp học không có emulator ổn định, script vẫn có chế độ mô phỏng để trình bày quy trình mobile testing rõ ràng."
