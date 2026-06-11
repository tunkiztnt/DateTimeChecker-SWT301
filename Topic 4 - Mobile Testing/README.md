# Topic 4: Mobile Testing - Kiểm thử Ứng dụng Di động

Thư mục này chứa mã nguồn ứng dụng di động Flutter và bộ kịch bản kiểm thử giao diện di động sử dụng công cụ **Maestro**.

---

## 1. Thành phần

- **Ứng dụng di động**: [flutter_app/](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%204%20-%20Mobile%20Testing/flutter_app/) (Ứng dụng Flutter di động viết cho Android và iOS).
- **Bộ kịch bản Maestro**: [maestro/](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%204%20-%20Mobile%20Testing/maestro/)
  - Kịch bản test chính: [maestro/date_time_checker_flow.yaml](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%204%20-%20Mobile%20Testing/maestro/date_time_checker_flow.yaml)

---

## 2. Yêu cầu chuẩn bị

Để chạy kiểm thử di động, máy của bạn cần:
1. Đã cài đặt Flutter SDK và cấu hình biến môi trường.
2. Đã khởi động một máy ảo Android (Emulator) hoặc kết nối thiết bị thật qua USB (đã bật USB Debugging).
3. Đã cài đặt Maestro CLI.

### Hướng dẫn cài đặt Maestro CLI (chạy một lần duy nhất):
Mở PowerShell dưới quyền Administrator và chạy script:
```powershell
powershell -ExecutionPolicy Bypass -File ".\Topic 4 - Mobile Testing\install-maestro-free.ps1"
```
Sau khi cài đặt xong, hãy tắt và mở lại terminal/CMD để hệ thống nhận diện lệnh `maestro`.

Xác nhận thiết bị Android đã kết nối thành công:
```powershell
adb devices
```

---

## 3. Cách chạy Demo

Chạy tệp batch sau để tự động biên dịch ứng dụng Flutter, cài đặt lên máy ảo và khởi chạy kiểm thử Maestro:

```powershell
.\Topic 4 - Mobile Testing\run-tests.bat
```

Sau khi chạy xong, báo cáo kết quả sẽ được ghi vào: [reports/mobile-testing-report.txt](file:///d:/DataFPTU/Semester5/SWT301/reports/mobile-testing-report.txt)

---

## 4. Chạy kiểm thử thủ công qua Maestro Studio

Nếu bạn muốn debug trực quan từng bước trên giao diện di động:
1. Mở terminal tại thư mục này.
2. Chạy lệnh:
   ```powershell
   maestro studio
   ```
3. Trình duyệt sẽ tự động mở trang web giúp bạn kéo thả, thao tác trực tiếp trên máy ảo và lưu kịch bản kiểm thử.
