# Topic 8: CI/CD & Reporting - Tích hợp Liên tục và Báo cáo Kết quả (Local Automation)

Thư mục này chứa kịch bản mô phỏng tích hợp liên tục (CI/CD) cục bộ và tài liệu hướng dẫn về báo cáo kết quả kiểm thử tự động trên máy trạm của bạn.

---

## 1. Trình mô phỏng tích hợp liên tục cục bộ (Local CI/CD Pipeline Simulator)

Để giữ cho dự án hoàn toàn cục bộ (không cần đẩy code lên máy chủ đám mây hoặc liên kết với GitHub), chúng tôi đã thiết lập tập tin kịch bản tự động chạy tất cả các tầng kiểm thử nối tiếp nhau nhằm kiểm tra sự ổn định của mã nguồn trước khi tích hợp:

- **Tập tin chạy**: [run-ci-simulation.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%208%20-%20CI%20CD%20and%20Reporting/run-ci-simulation.bat)
- **Các bước chạy trong luồng mô phỏng**:
  1. **STAGE 1 (Build)**: Biên dịch toàn bộ mã nguồn Java của máy chủ ứng dụng.
  2. **STAGE 2 (Unit Testing)**: Thực hiện đồng thời cả các bài kiểm thử đơn vị của mã nguồn Java (JUnit-style backend) và JavaScript helper (Jest UI).
  3. **STAGE 3 (API Testing)**: Khởi động máy chủ tạm thời, chạy các bài kiểm thử API bằng Playwright và PowerShell.
  4. **STAGE 4 (Web E2E)**: Chạy kịch bản kiểm thử hành vi người dùng trên giao diện web bằng trình duyệt tự động của Playwright.
  5. **STAGE 5 (Mobile)**: Chạy kịch bản kiểm thử di động giả lập.
  6. **STAGE 6 (Performance)**: Đo lường và đánh giá hiệu năng chịu tải phản hồi với Autocannon.
  7. **STAGE 7 (Visual)**: Chụp ảnh màn hình giao diện thực tế và so sánh pixel-perfect với ảnh gốc (baseline) nhằm phát hiện lỗi lệch giao diện.
  8. **Summary & Report**: Tổng hợp trạng thái PASS/FAIL của từng giai đoạn và xuất báo cáo hợp nhất.

---

## 2. Báo cáo kết quả kiểm thử (Reporting)

Tất cả các bài kiểm thử đều tự động ghi lại lịch sử và kết quả chi tiết trong thư mục `reports/` để bạn dễ dàng mở ra kiểm tra hoặc đính kèm vào báo cáo môn học:

1. **Báo cáo tích hợp CI/CD (Pipeline Report)**:
   - Tập tin: [reports/ci-pipeline-report.txt](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/reports/ci-pipeline-report.txt)
   - Chứa kết quả tổng quan trạng thái chạy của 7 giai đoạn.
2. **Báo cáo API (PowerShell)**:
   - Tập tin: [reports/api-testing-report.tsv](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/reports/api-testing-report.tsv)
   - Chứa thông tin về các API endpoint, dữ liệu đầu vào, kết quả mong đợi so với thực tế và thời gian phản hồi (ms) định dạng TSV dễ dàng import vào Excel.
3. **Báo cáo Di động (Maestro)**:
   - Tập tin: [reports/mobile-testing-report.txt](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/reports/mobile-testing-report.txt)
   - Chứa log chạy kịch bản Maestro và kết quả pass/fail cuối cùng.
4. **Báo cáo Web E2E / API / Visual (Playwright HTML Report)**:
   - Thư mục: `reports/playwright-report/`
   - Báo cáo HTML trực quan và tương tác. Sau khi chạy thử nghiệm xong, bạn có thể xem lại kết quả dưới dạng trang web động bằng cách chạy lệnh:
     ```powershell
     npx playwright show-report reports/playwright-report
     ```
