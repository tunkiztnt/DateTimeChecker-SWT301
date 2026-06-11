# Topic 6: Visual Regression - Kiểm thử Hồi quy Giao diện

Thư mục này chứa kịch bản kiểm thử giao diện trực quan (**Visual Regression Testing** / **PW shots**) nhằm đảm bảo bố cục, màu sắc và các thành phần giao diện không bị lệch hoặc biến đổi ngoài ý muốn sau khi cập nhật mã nguồn.

---

## 1. Thành phần

- **Bộ kịch bản so khớp giao diện**: [visual.spec.js](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%206%20-%20Visual%20Regression/playwright-visual/visual.spec.js)
- **Thư mục chứa ảnh giao diện gốc (Baselines)**: [playwright-visual/visual.spec.js-snapshots/](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%206%20-%20Visual%20Regression/playwright-visual/visual.spec.js-snapshots/)

---

## 2. Kịch bản kiểm thử

- **VIS01: Homepage visual screenshot in light theme**
  - Mở trang chủ ứng dụng ở chế độ sáng (Default light theme).
  - Tự động thay đổi đồng hồ thời gian thực thành một ngày cố định (`Thursday, 11 June 2026`) để tránh lỗi lệch ảnh do thời gian thay đổi liên tục.
  - Chụp màn hình trình duyệt và so sánh với ảnh gốc `homepage-light.png`.
- **VIS02: Homepage visual screenshot in dark theme**
  - Mở ứng dụng, nhấn nút chuyển giao diện sang chế độ tối (Dark theme).
  - Đóng băng thời gian thực hiển thị.
  - Chụp màn hình trình duyệt và so sánh với ảnh gốc `homepage-dark.png`.

---

## 3. Cách chạy Demo

Để chạy kiểm tra hồi quy giao diện, hãy chạy tệp batch sau:

```powershell
.\Topic 6 - Visual Regression\run-tests.bat
```

*Nếu bạn cố ý thay đổi CSS/HTML giao diện và muốn lưu lại giao diện mới làm ảnh mẫu gốc, hãy chạy lệnh sau trong terminal:*
```powershell
npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
```
