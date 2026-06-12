# Hướng dẫn quay video demo 8 topic kiểm thử

Tài liệu này là kịch bản chung để nhóm quay video. Khi chạy mỗi topic, cửa sổ CMD sẽ tự in mục tiêu, công cụ, quy trình, dữ liệu kiểm thử và kết quả `PASS/FAIL`.

## Chuẩn bị trước khi quay

1. Mở thư mục gốc `C:\Github-Jel-ui\AllDateTimeChecker`.
2. Đóng các cửa sổ CMD và server cũ đang dùng cổng `4173`.
3. Kiểm tra đã cài Java, Node.js và Microsoft Edge.
4. Với Topic 4, mở Android Emulator nếu muốn quay kiểm thử mobile thật.
5. Với Topic 7, chuẩn bị Gemini API key hoặc dùng chế độ offline sample.
6. Phóng to cửa sổ CMD để người xem đọc được log.

## Cấu trúc trình bày chung

Với mỗi topic, người trình bày nên nói theo thứ tự:

1. Topic này kiểm tra vấn đề gì?
2. Công cụ nào được sử dụng?
3. Test gửi dữ liệu hoặc thao tác như thế nào?
4. Điều kiện nào quyết định `PASS/FAIL`?
5. Log CMD và báo cáo chứng minh điều gì?

## Topic 1 - Unit Testing

**Chạy:**

```powershell
.\Topic 1 - Unit Testing\run-tests.bat
```

**Cần quay:** CMD biên dịch source, chạy Java unit test, in input và kết quả, sau đó chạy Jest.

**Câu trình bày:** Unit testing kiểm tra từng hàm logic độc lập, không cần mở web hoặc gửi HTTP request.

**Kết quả mong đợi:** Java tests và JavaScript tests đều `PASS`.

## Topic 2 - API Testing

**Chạy:**

```powershell
.\Topic 2 - API Testing\run-tests.bat
```

**Cần quay:** Log Playwright và PowerShell hiển thị endpoint, JSON request, kết quả mong đợi, HTTP status, JSON thực tế và response time.

**Câu trình bày:** API testing bỏ qua giao diện, gửi request trực tiếp đến backend và xác minh response.

**Báo cáo:** `reports\api-testing-report.tsv`.

## Topic 3 - Web E2E Testing

**Chạy tự động và giữ CMD:**

```powershell
.\Topic 3 - Web E2E Testing\run-tests.bat
```

**Chạy demo trình duyệt và giữ Edge mở:**

```powershell
.\Topic 3 - Web E2E Testing\selenium\run-selenium-demo.bat
```

**Cần quay:** Selenium mở Edge, nhập Day/Month/Year, bấm Check, đọc kết quả UI và in `PASS/FAIL` trong CMD.

**Câu trình bày:** E2E kiểm tra toàn bộ luồng từ thao tác người dùng, giao diện, API đến backend.

## Topic 4 - Mobile Testing

**Chạy:**

```powershell
.\Topic 4 - Mobile Testing\run-tests.bat
```

**Cần quay:** Kiểm tra thiết bị, Flutter widget test, build APK, cài APK và Maestro thao tác giao diện. CMD sẽ ghi rõ nếu đang chạy chế độ thật hoặc mô phỏng.

**Câu trình bày:** Mobile testing kiểm tra ứng dụng Flutter trên thiết bị Android từ góc nhìn người dùng.

**Báo cáo:** `reports\mobile-testing-report.txt`.

## Topic 5 - Performance Testing

**Chạy:**

```powershell
.\Topic 5 - Performance Testing\run-tests.bat
```

**Cần quay:** Ba kịch bản Smoke, Load và Stress; số connection, request, lỗi và p99 latency.

**Câu trình bày:** Performance testing đánh giá hệ thống có phản hồi đủ nhanh và ổn định khi tải tăng hay không.

**Báo cáo:** `reports\performance-report.txt`.

## Topic 6 - Visual Regression

**Chạy:**

```powershell
.\Topic 6 - Visual Regression\run-tests.bat
```

**Cần quay:** Playwright chụp năm trạng thái giao diện và so sánh với baseline. Nếu khác, chỉ vào ảnh actual, expected và diff trong report.

**Câu trình bày:** Visual regression phát hiện thay đổi giao diện ngoài ý muốn bằng so sánh ảnh.

**Xem report khi có lỗi:**

```powershell
npx playwright show-report reports\playwright-report
```

## Topic 7 - AI-Assisted Testing

**Chạy Gemini thật:**

```powershell
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat.bat
```

**Chạy tập dượt không cần API key:**

```powershell
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat-offline-sample.bat
```

Trong cửa sổ chat, nhập:

```text
/demo-self-heal
```

**Cần quay:** Prompt người dùng, AI phân tích, sinh testcase/đề xuất, phát hiện locator lỗi và đề xuất locator thay thế.

**Câu trình bày:** AI hỗ trợ tester sinh dữ liệu, phân tích lỗi và đề xuất sửa; tester vẫn là người review và quyết định.

## Topic 8 - CI/CD and Reporting

**Chạy:**

```powershell
.\Topic 8 - CI CD and Reporting\run-ci-simulation.bat
```

**Cần quay:** Pipeline chạy tuần tự từng stage và in `PASS`, `FAIL`, `SKIPPED`, sau đó hiển thị pipeline summary.

**Câu trình bày:** CI/CD tự động chạy các tầng kiểm thử để chặn lỗi trước khi tích hợp hoặc phát hành.

**Lưu ý khi quay:** Ở mỗi stage, chỉ vào hai dòng `WHAT` và `PASS IF` để người chấm hiểu stage đó kiểm tra gì và điều kiện đạt là gì. Cuối video mở `reports\ci-pipeline-report.txt` để chứng minh pipeline có báo cáo tổng hợp.

## Checklist kết thúc video

- CMD hiển thị rõ từng bước và kết quả.
- Giải thích được sự khác nhau giữa các topic.
- Chỉ ra ít nhất một input, expected và actual.
- Chỉ ra file báo cáo của topic có report.
- Không để lộ Gemini API key trong video.
