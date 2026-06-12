# Hướng dẫn quay demo API Testing

## Mục tiêu

Chứng minh backend `POST /api/datetime/check` hoạt động đúng bằng cách gửi HTTP request trực tiếp, không thao tác giao diện.

## Các bước quay

1. Mở `api-test-cases.md` và giới thiệu các nhóm dữ liệu hợp lệ, không hợp lệ, giá trị biên và sai định dạng.
2. Mở `playwright-api/api.spec.js` để chỉ ra phần gửi request và assert response.
3. Chạy:

```powershell
.\Topic 2 - API Testing\run-tests.bat
```

4. Trong CMD, chỉ vào endpoint, JSON request, expected, actual, response time và kết quả `PASS/FAIL`.
5. Mở `reports/api-testing-report.tsv` để xem báo cáo tổng hợp.

## Câu kết luận gợi ý

> API Testing đã gửi request trực tiếp đến backend và xác minh HTTP status, JSON response, kết quả nghiệp vụ cùng thời gian phản hồi. Vì vậy bài test không phụ thuộc giao diện web.
