# Topic 2: API Testing - Kiểm thử API

## Dùng để làm gì?

API Testing kiểm tra endpoint `POST /api/datetime/check` và `POST /api/check-date` của DateTimeChecker mà không cần thao tác trực tiếp trên giao diện web. Đây là tầng xác nhận dữ liệu request/response giữa frontend và backend.

## Vai trò và ý nghĩa

- Đảm bảo API trả về đúng JSON cho ngày hợp lệ, ngày không hợp lệ và lỗi dữ liệu đầu vào.
- Kiểm tra thời gian phản hồi, mã trạng thái HTTP và cấu trúc dữ liệu trả về.
- Giúp phát hiện lỗi backend nhanh hơn Web E2E vì không phụ thuộc trình duyệt.

## Thành phần chính

- Playwright API tests: `Topic 2 - API Testing/playwright-api/api.spec.js`
- PowerShell integration script: `Topic 2 - API Testing/run-api-testing.ps1`
- Postman collection: `Topic 2 - API Testing/postman/DateTimeChecker API Testing.postman_collection.json`
- Postman environment: `Topic 2 - API Testing/postman/DateTimeChecker API Testing.postman_environment.json`
- Script chạy demo: `Topic 2 - API Testing/run-tests.bat`

## Cách chạy

Từ thư mục gốc dự án:

```powershell
.\Topic 2 - API Testing\run-tests.bat
```

Hoặc chạy riêng:

```powershell
npm run test:api
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Topic 2 - API Testing\run-api-testing.ps1"
```

## Luồng hoạt động khi chạy

1. Biên dịch Java server.
2. Playwright tự khởi động server test tại `http://localhost:4173`.
3. Gửi request JSON với nhiều bộ dữ liệu ngày tháng.
4. Xác minh `status=200`, `result=VALID/INVALID/ERROR`, `valid=true/false`, `errors`, `details`.
5. PowerShell script ghi báo cáo TSV vào `reports/api-testing-report.tsv`.

## Kết quả mong đợi

- Playwright API tests pass.
- PowerShell API tests pass 10 testcase.
- File `reports/api-testing-report.tsv` có các cột: `id`, `name`, `input`, `expected_valid`, `actual_valid`, `status_code`, `elapsed_ms`, `result`.

## Gợi ý lời demo

"Topic 2 kiểm thử trực tiếp API nên có thể chứng minh backend DateTimeChecker trả JSON đúng trước khi giao diện web sử dụng dữ liệu đó."
