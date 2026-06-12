# Topic 5: Performance Testing - Kiểm thử Hiệu năng

Thư mục này chứa các kịch bản kiểm thử hiệu năng (Load test / Stress test) để xác định độ ổn định, khả năng chịu tải và thời gian phản hồi (Response Latency) của API.

---

## 1. Công cụ sử dụng

Sơ đồ yêu cầu hai công cụ: **JMeter** và **k6**. Ở đây chúng tôi cung cấp 2 giải pháp tự động:
1. **k6 (Khuyên dùng)**: Viết bằng JavaScript, chạy cực kỳ nhanh và nhẹ.
2. **Autocannon (Dự phòng)**: Tích hợp trực tiếp qua Node.js để chạy được ngay trên bất kỳ máy nào mà không cần cài đặt phần mềm ngoài (k6/JMeter).

---

## 2. Các kịch bản kiểm thử

- **k6 Load Test**: [k6/load-test.js](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%205%20-%20Performance%20Testing/k6/load-test.js)
  - Mô phỏng tăng dần từ 0 lên 20 người dùng đồng thời trong 5 giây đầu.
  - Duy trì mức tải 20 người dùng trong 10 giây tiếp theo.
  - Giảm dần về 0 người dùng trong 5 giây cuối.
  - Ngưỡng đánh giá (Threshold): 95% số request phải phản hồi dưới 200ms (`p(95)<200`).
- **Autocannon Benchmark**: [benchmark/autocannon-test.js](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%205%20-%20Performance%20Testing/benchmark/autocannon-test.js)
  - Chạy liên tục trong 10 giây với 50 kết nối đồng thời.
  - Tự động thống kê Số lượng request, Request/giây trung bình, độ trễ tối thiểu/trung bình/tối đa và tỷ lệ lỗi.

---

## 3. Cách chạy Demo

Bạn chỉ cần chạy tệp batch sau:

```powershell
.\Topic 5 - Performance Testing\run-tests.bat
```

*Script sẽ tự động kiểm tra xem `k6` có trong máy của bạn không. Nếu có, nó sẽ chạy k6. Nếu không, nó sẽ tự động chạy Autocannon qua NodeJS để đảm bảo buổi demo của bạn diễn ra suôn sẻ mà không bị gián đoạn.*

## 4. Log cần giải thích khi quay video

CMD sẽ in ba kịch bản:

1. Smoke với 1 connection để kiểm tra server hoạt động.
2. Load với 10 connections để mô phỏng tải bình thường.
3. Stress với 50 connections để đánh giá khi tải cao.

Với mỗi kịch bản, giải thích số request, số lỗi, p99 latency, ngưỡng đánh giá và kết quả `PASS/FAIL`. Báo cáo được lưu tại `reports\performance-report.txt`.

Kịch bản quay tổng hợp nằm tại `HUONG-DAN-QUAY-VIDEO-8-TOPIC.md`.
