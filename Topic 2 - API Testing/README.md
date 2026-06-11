# Topic 2: API Testing - Kiểm thử Giao diện Lập trình Ứng dụng

Thư mục này chứa các thành phần kiểm thử API cho cổng kết nối (endpoint) `POST /api/datetime/check`.

---

## 1. Các thành phần kiểm thử

### A. Playwright API Testing (Khuyên dùng)
- **Mục tiêu**: Tự động gửi các HTTP Request và xác thực dữ liệu phản hồi (Response JSON) cùng thời gian phản hồi (Response Latency < 1s).
- **Công cụ**: Sử dụng **Playwright** API Testing runner.
- **Tập tin liên quan**:
  - Mã nguồn kiểm thử: [api.spec.js](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%202%20-%20API%20Testing/playwright-api/api.spec.js)

### B. Postman Collection
- **Mục tiêu**: Chứa bộ kiểm thử thủ công và tự động hóa qua giao diện Postman.
- **Thư mục liên quan**: [postman/](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%202%20-%20API%20Testing/postman/)
  - Bộ sưu tập: `DateTimeChecker API Testing.postman_collection.json`
  - Môi trường: `DateTimeChecker API Testing.postman_environment.json`

### C. PowerShell API Script (Legacy Integration)
- **Mục tiêu**: Sử dụng script PowerShell tích hợp để gửi request và tự động ghi báo cáo kết quả ra tệp tin TSV.
- **Tập tin liên quan**: [run-api-testing.ps1](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%202%20-%20API%20Testing/run-api-testing.ps1)
- **Báo cáo xuất ra**: [reports/api-testing-report.tsv](file:///d:/DataFPTU/Semester5/SWT301/reports/api-testing-report.tsv)

---

## 2. Cách chạy Demo

Để chạy toàn bộ API tests (bao gồm cả Playwright API test và PowerShell script), hãy chạy tệp batch sau:

```powershell
.\Topic 2 - API Testing\run-tests.bat
```

Hoặc chạy các lệnh riêng lẻ:
- Chạy Playwright API tests: `npm run test:api`
- Chạy PowerShell API tests: `powershell -ExecutionPolicy Bypass -File ".\Topic 2 - API Testing\run-api-testing.ps1"`
