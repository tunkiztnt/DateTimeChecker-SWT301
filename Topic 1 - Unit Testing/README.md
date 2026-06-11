# Topic 1: Unit Testing - Kiểm thử Độc lập

Thư mục này chứa cấu hình và các tài liệu liên quan đến Unit Testing (Kiểm thử Độc lập) cho ứng dụng DateTimeChecker ở cả phía Backend (Java) và Frontend (JavaScript).

---

## 1. Thành phần kiểm thử

### A. Java Unit Testing (Backend)
- **Mục tiêu**: Kiểm thử trực tiếp lớp xử lý nghiệp vụ chính `DateTimeValidationService`.
- **Tập tin liên quan**:
  - Mã nguồn logic: [DateTimeValidationService.java](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/src/main/java/com/datetimechecker/DateTimeValidationService.java)
  - Mã nguồn kiểm thử: [DateTimeValidationServiceTest.java](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/src/test/java/com/datetimechecker/DateTimeValidationServiceTest.java)

### B. JavaScript Unit Testing (Frontend Helpers)
- **Mục tiêu**: Kiểm thử các hàm bổ trợ xử lý ngày tháng ở phía giao diện (UI).
- **Công cụ**: Sử dụng **Jest** làm framework kiểm thử chính.
- **Tập tin liên quan**:
  - Mã nguồn hàm hỗ trợ: [date-helpers.js](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%201%20-%20Unit%20Testing/javascript-unit-testing/date-helpers.js)
  - Tập tin kiểm thử: [date-helpers.test.js](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%201%20-%20Unit%20Testing/javascript-unit-testing/date-helpers.test.js)

---

## 2. Cách chạy Demo

Để chạy toàn bộ Unit Tests (cả Java và JavaScript), bạn chỉ cần mở Command Prompt / PowerShell và chạy tệp batch sau:

```powershell
.\Topic 1 - Unit Testing\run-tests.bat
```

Hoặc chạy các lệnh riêng biệt:
- Chạy Java Unit Test: `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
- Chạy JavaScript Unit Test: `npm run test:unit`
