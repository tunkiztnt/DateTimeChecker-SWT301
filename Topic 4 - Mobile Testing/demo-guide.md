# Hướng dẫn quay demo Mobile Testing

## Mục tiêu

Chứng minh ứng dụng Flutter hoạt động đúng trên Android thông qua kiểm thử logic, build/cài APK và thao tác giao diện bằng Maestro.

## Chuẩn bị

1. Mở Android Emulator hoặc kết nối điện thoại đã bật USB Debugging.
2. Kiểm tra thiết bị bằng `adb devices`.
3. Đảm bảo Flutter và Maestro đã được cài đặt.

## Các bước quay

1. Mở `maestro/date_time_checker_flow.yaml` và giải thích flow.
2. Chạy:

```powershell
.\Topic 4 - Mobile Testing\run-tests.bat
```

3. Quay đồng thời emulator và CMD.
4. Chỉ vào các bước chọn thiết bị, Flutter widget tests, build APK, cài app và Maestro xác minh UI.
5. Mở `reports/mobile-testing-report.txt`.

## Lưu ý

Nếu thiếu thiết bị hoặc công cụ, script sẽ chạy chế độ mô phỏng và ghi rõ trong CMD. Khi quay bài chính thức nên dùng emulator thật.

## Câu kết luận gợi ý

> Mobile Testing đã kiểm tra ứng dụng Flutter từ góc nhìn người dùng trên Android, bao gồm nhập dữ liệu, bấm nút và xác minh kết quả hiển thị.
