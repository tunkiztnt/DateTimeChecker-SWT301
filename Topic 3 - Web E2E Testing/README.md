# Topic 3: Web E2E Testing - Kiểm thử Trực diện từ Đầu đến Cuối

Thư mục này chứa các kịch bản kiểm thử tự động hóa trên trình duyệt thực tế, mô phỏng các thao tác của người dùng trên giao diện Web.

---

## 1. Các công cụ kiểm thử E2E

### A. Playwright Web E2E (Khuyên dùng và được gắn sao trong sơ đồ)
- **Mục tiêu**: Tự động mở trình duyệt Chromium, điền các giá trị kiểm thử vào Form, nhấn Kiểm tra và xác nhận các phần tử hiển thị (kết quả hợp lệ/không hợp lệ, lỗi cụ thể, đổi giao diện tối/sáng).
- **Tập tin liên quan**:
  - Mã nguồn kiểm thử: [web-e2e.spec.js](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker/Topic%203%20-%20Web%20E2E%20Testing/e2e/web-e2e.spec.js)

### B. Selenium WebDriver (Java)
- **Mục tiêu**: Demo kiểm thử trực quan bằng Selenium WebDriver trên Microsoft Edge, hiển thị các hộp thoại kết quả giữa màn hình và dừng lại sau khi hoàn thành.
- **Tập tin liên quan**:
  - Mã nguồn Java: [SeleniumVisibleDemo.java](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/src/selenium/java/com/datetimechecker/SeleniumVisibleDemo.java)
  - Tập lệnh chạy demo: [run-selenium-demo.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%203%20-%20Web%20E2E%20Testing/selenium/run-selenium-demo.bat)

---

## 2. Cách chạy Demo

### Chạy Playwright E2E Test:
```powershell
.\Topic 3 - Web E2E Testing\run-tests.bat
```

### Chạy Selenium UI Demo (yêu cầu Microsoft Edge):
```powershell
.\Topic 3 - Web E2E Testing\selenium\run-selenium-demo.bat
```
*(Nếu là lần đầu chạy Selenium, chương trình sẽ tự động tải trình duyệt và WebDriver phù hợp về máy)*
