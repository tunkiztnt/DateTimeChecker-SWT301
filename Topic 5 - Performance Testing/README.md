# Topic 5: Performance Testing - Kiểm thử hiệu năng

## Dùng để làm gì?

Performance Testing đo tốc độ phản hồi và khả năng chịu tải của API DateTimeChecker khi có nhiều request cùng lúc. Topic này trả lời câu hỏi: hệ thống có phản hồi nhanh và ổn định khi nhiều người dùng kiểm tra ngày tháng không?

## Vai trò và ý nghĩa

- Đánh giá latency, số request xử lý được, lỗi HTTP và độ ổn định khi tăng tải.
- Phát hiện sớm vấn đề nghẽn server hoặc API phản hồi quá chậm.
- Cung cấp số liệu định lượng để đưa vào báo cáo môn SWT301.

## Thành phần chính

- Autocannon benchmark: `Topic 5 - Performance Testing/benchmark/autocannon-test.js`
- k6 script tham khảo: `Topic 5 - Performance Testing/k6/load-test.js`
- Performance runner: `Topic 5 - Performance Testing/run-performance-tests.ps1`
- Script chạy topic: `Topic 5 - Performance Testing/run-tests.bat`

## Cách chạy

Từ thư mục gốc dự án:

```powershell
.\Topic 5 - Performance Testing\run-tests.bat
```

Hoặc chạy benchmark Node.js trực tiếp:

```powershell
npm run test:perf
```

## Luồng hoạt động khi chạy

1. Khởi động server DateTimeChecker tại `http://localhost:4173`.
2. Chạy Autocannon vào endpoint `POST /api/check-date`.
3. Chạy 3 scenario: Smoke, Load và Stress.
4. Tính request count, error count, p99 latency.
5. Ghi báo cáo vào `reports/performance-report.txt`.
6. Tắt server sau khi chạy xong.

## Kết quả mong đợi

- Scenario 1 Smoke: không có lỗi.
- Scenario 2 Load: p99 latency dưới ngưỡng và error rate thấp.
- Scenario 3 Stress: hệ thống vẫn phản hồi trong giới hạn chấp nhận được.
- CMD hiển thị `OVERALL: 3/3 scenarios passed` nếu máy đủ ổn định.

## Gợi ý lời demo

"Topic 5 dùng số liệu để đánh giá chất lượng phi chức năng. Không chỉ đúng về logic, DateTimeChecker còn cần phản hồi nhanh và ổn định khi nhiều request được gửi liên tục."
