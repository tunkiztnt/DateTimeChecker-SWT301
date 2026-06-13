# Script Lời Thoại Quay Video Demo - DateTimeChecker SWT301

> **Cách dùng:** Mỗi topic gồm phần mở đầu, phần nói trong lúc chạy test, và phần kết. Khi quay video, bạn không cần đọc y nguyên từng chữ; hãy dùng nội dung này như kịch bản để nói tự nhiên.

> **Lưu ý quan trọng:** File này bám theo implementation thực tế trong repo local. URD gốc mô tả ứng dụng DateTimeChecker chạy Windows/.NET, nhưng project demo của nhóm đang triển khai bằng Java HTTP server, HTML/CSS/JavaScript frontend, Flutter mobile app và các script test tự động. Vì vậy khi thuyết trình nên nói theo hướng: "Nhóm mô phỏng và kiểm thử nghiệp vụ DateTimeChecker theo yêu cầu URD bằng bộ công cụ hiện tại."

---

## TOPIC 1 - Unit Testing (Java + Jest)

### Mở đầu
> *[Mở terminal tại thư mục project, chuẩn bị chạy `Topic 1 - Unit Testing\run-tests.bat`]*

"Xin chào thầy và các bạn. Topic đầu tiên là **Unit Testing**, nghĩa là kiểm thử những đơn vị nhỏ nhất của ứng dụng DateTimeChecker.

Ở project này, nhóm em kiểm thử hai phần chính:
- Logic backend Java trong `DateTimeValidationService`.
- Các helper JavaScript dùng cho frontend bằng Jest.

Mục tiêu của Unit Testing là kiểm tra rule ngày, tháng, năm trước khi ghép với API, giao diện web, mobile hoặc pipeline CI/CD. Nếu logic lõi sai, các tầng test phía sau dù có chạy được cũng không còn đáng tin cậy."

### Trong khi chạy test
> *[Chạy `.\Topic 1 - Unit Testing\run-tests.bat`]*

"Script đang biên dịch source Java vào thư mục `out/classes`, sau đó chạy test cho backend Java và Jest test cho phần helper JavaScript.

Các test case tập trung vào yêu cầu trong URD:
- Day phải nằm trong khoảng 1 đến 31.
- Month phải nằm trong khoảng 1 đến 12.
- Year phải nằm trong khoảng 1000 đến 3000.
- Dữ liệu rỗng hoặc nhập chữ phải bị báo lỗi.
- Các ngày đặc biệt như 29/02 năm nhuận, 29/02 năm không nhuận, 31/04 phải trả kết quả đúng.

Ví dụ, 29/02/2024 hợp lệ vì 2024 là năm nhuận; 29/02/2025 không hợp lệ vì 2025 không phải năm nhuận. Đây là những lỗi logic rất dễ xảy ra nếu chỉ test thủ công bằng vài trường hợp đơn giản."

### Kết luận
"Unit Testing là lớp kiểm thử nhanh và gần code nhất. Nó giúp nhóm phát hiện lỗi sớm ở phần xử lý ngày tháng trước khi chạy các test lớn hơn như API Testing hay Web E2E."

---

## TOPIC 2 - API Testing (Playwright API + PowerShell)

### Mở đầu
> *[Mở terminal, chuẩn bị chạy `Topic 2 - API Testing\run-tests.bat`]*

"Topic 2 là **API Testing**. Ở tầng này, nhóm em không thao tác qua giao diện web mà gửi request trực tiếp đến backend DateTimeChecker.

Endpoint chính đang được test là `POST /api/check-date`. Request gửi lên gồm `day`, `month`, `year`, và server trả về JSON với các trường như `valid`, `result`, `message`, `errors`, `parts`, `details`.

API Testing cần thiết vì nó kiểm tra backend độc lập với UI. Nếu API trả sai JSON, frontend có đẹp hay đúng locator thì kết quả cuối cùng vẫn sai."

### Trong khi chạy test
> *[Chạy `.\Topic 2 - API Testing\run-tests.bat`]*

"Trong topic này có hai lớp kiểm tra:
- Playwright API test gửi request và assert response.
- PowerShell integration script chạy thêm nhiều testcase và ghi báo cáo TSV vào thư mục `reports`.

Các trường hợp chính gồm:
- `30/05/2026` phải trả về `VALID`.
- `31/04/2026` phải trả về `INVALID` vì tháng 4 chỉ có 30 ngày.
- `29/02/2024` hợp lệ vì là năm nhuận.
- `29/02/2025` không hợp lệ.
- Day bằng 0, month bằng 13 hoặc input rỗng phải trả về `ERROR`.
- Có testcase kiểm tra response time dưới 1000 mili giây theo yêu cầu performance trong URD.
- Có testcase gửi 5 request đồng thời để xem API phản hồi ổn định hay không.

Khi các assert đều pass, điều đó chứng minh backend xử lý đúng dữ liệu đầu vào và trả cấu trúc JSON đúng cho frontend sử dụng."

### Kết luận
"API Testing giúp nhóm xác nhận phần server hoạt động đúng mà không phụ thuộc vào trình duyệt. Đây là cầu nối giữa Unit Testing và Web E2E Testing."

---

## TOPIC 3 - Web E2E Testing (Playwright + Selenium Demo)

### Mở đầu
> *[Mở terminal, chuẩn bị chạy `Topic 3 - Web E2E Testing\run-tests.bat`]*

"Topic 3 là **Web End-to-End Testing**, tức là kiểm thử luồng người dùng từ đầu đến cuối trên trình duyệt.

Ở repo này, nhóm em dùng Playwright để chạy test tự động và có thêm Selenium demo để mở trình duyệt Edge trực quan hơn khi quay video. Playwright là phần kiểm tra chính; Selenium giúp người xem thấy rõ các thao tác trên UI.

Khác với Topic 2, topic này không chỉ gọi API. Test sẽ mở web app, tìm các ô Day, Month, Year, nhập dữ liệu, bấm Check, chờ API phản hồi và kiểm tra modal kết quả hiển thị đúng."

### Trong khi chạy test
> *[Chạy topic và quay phần browser/terminal]*

"Script khởi động server DateTimeChecker tại `http://localhost:4173`, sau đó Playwright bắt đầu chạy các case E2E.

Các case tiêu biểu gồm:
- `15/06/2023` là happy path, kết quả phải là `VALID`.
- `29/02/2023` phải là `INVALID` vì 2023 không phải năm nhuận.
- `32/01/2023` phải báo lỗi vì day vượt quá range 1 đến 31.
- `abc/1/2023` phải báo lỗi sai định dạng vì Day không phải số nguyên.
- `1/1/1000` và `31/12/3000` kiểm tra biên dưới và biên trên của Year.
- `29/02/2000` hợp lệ vì năm 2000 chia hết cho 400.
- `29/02/1900` không hợp lệ vì năm 1900 là năm thế kỷ nhưng không chia hết cho 400.

Ngoài ra còn có case kiểm tra chức năng đóng app. Trên bản web demo, nhóm dùng nút `Close App` để mô phỏng yêu cầu Close trong URD: khi chọn No thì app vẫn mở, khi chọn Yes thì app chuyển sang trạng thái đã đóng."

### Kết luận
"Web E2E Testing kiểm tra hệ thống từ góc nhìn người dùng cuối. Khi test pass, nhóm có bằng chứng rằng UI, JavaScript, API backend và thông báo kết quả đang phối hợp đúng với nhau."

---

## TOPIC 4 - Mobile Testing (Flutter + Maestro / Offline Mock)

### Mở đầu
> *[Mở terminal, chuẩn bị chạy `Topic 4 - Mobile Testing\run-tests.bat`]*

"Topic 4 là **Mobile Testing**. Nhóm em xây dựng thêm một phiên bản mobile của DateTimeChecker bằng Flutter để minh họa việc kiểm thử trên nền tảng di động.

Mobile Testing cần thiết vì cùng một nghiệp vụ kiểm tra ngày tháng, khi đưa lên màn hình nhỏ và môi trường mobile, có thể phát sinh lỗi khác với web: layout, widget, thao tác nhập liệu, hoặc flow người dùng."

### Trong khi chạy test
> *[Chạy `.\Topic 4 - Mobile Testing\run-tests.bat`]*

"Script sẽ kiểm tra môi trường trước: Flutter SDK, Android SDK, ADB, thiết bị hoặc emulator, và Maestro.

Nếu môi trường đầy đủ, script sẽ chạy Flutter widget tests, build APK, cài app lên thiết bị Android và chạy Maestro flow để tự động thao tác trên app.

Nếu máy chưa có emulator hoặc thiếu tool mobile, script tự chuyển sang **Offline Mobile Mock Mode**. Chế độ này không giả vờ là test thiết bị thật; nó dùng để demo rõ quy trình mobile testing, test case và cách báo cáo kết quả trong điều kiện lớp học hoặc máy cá nhân chưa có môi trường Android ổn định.

Các test case vẫn xoay quanh nghiệp vụ chính: nhập ngày hợp lệ, nhập ngày không hợp lệ, nhập sai range hoặc sai định dạng, rồi xác nhận app hiển thị kết quả đúng."

### Kết luận
"Mobile Testing chứng minh nhóm đã xem xét chất lượng trên nền tảng di động, không chỉ trên web. Điểm quan trọng là hiểu quy trình: chuẩn bị môi trường, chạy test tự động, có fallback demo, và ghi report."

---

## TOPIC 5 - Performance Testing (Autocannon, k6 tham khảo)

### Mở đầu
> *[Mở terminal, chuẩn bị chạy `Topic 5 - Performance Testing\run-tests.bat`]*

"Topic 5 là **Performance Testing**, tức là kiểm thử hiệu năng. Theo URD, kết quả kiểm tra phải xuất hiện trong vòng 1 giây sau khi người dùng bấm Check.

Trong repo hiện tại, công cụ chạy chính là **Autocannon**. Ngoài ra có một script k6 trong thư mục topic để tham khảo, nhưng khi chạy demo bằng batch file thì phần chính được dùng là Autocannon."

### Trong khi chạy test
> *[Chạy `.\Topic 5 - Performance Testing\run-tests.bat`]*

"Script khởi động server DateTimeChecker rồi bắn request vào endpoint `POST /api/check-date`.

Performance test có 3 scenario:
- **Smoke Test:** 1 connection trong 5 giây, mục tiêu là xác nhận server và API còn sống, không có lỗi.
- **Load Test:** 10 connection trong 15 giây, mô phỏng nhiều người dùng bình thường kiểm tra ngày cùng lúc. Điều kiện pass là p99 latency dưới 500 mili giây và error rate dưới 1%.
- **Stress Test:** 50 connection trong 10 giây, đẩy tải cao hơn để xem API còn ổn định không. Điều kiện pass là p99 latency dưới 2000 mili giây và error rate dưới 5%.

Sau khi chạy xong, script ghi `performance-report.txt` vào thư mục `reports`, gồm số request, số lỗi và p99 latency của từng scenario."

### Kết luận
"Performance Testing giúp nhóm không chỉ chứng minh phần mềm đúng về logic, mà còn phản hồi đủ nhanh và ổn định khi có nhiều request liên tục."

---

## TOPIC 6 - Visual Regression Testing (Playwright Screenshots)

### Mở đầu
> *[Mở terminal, chuẩn bị chạy `Topic 6 - Visual Regression\run-tests.bat`]*

"Topic 6 là **Visual Regression Testing**, kiểm thử hồi quy giao diện bằng cách so sánh screenshot.

Functional test có thể biết nút Check hoạt động, nhưng khó phát hiện các lỗi như logo bị lệch, modal bị sai layout, màu chữ bị đổi, hoặc giao diện bị vỡ sau khi sửa CSS. Vì vậy nhóm dùng Playwright screenshot comparison để bảo vệ giao diện."

### Trong khi chạy test
> *[Chạy `.\Topic 6 - Visual Regression\run-tests.bat`]*

"Playwright mở trang web, cố định phần ngày hiển thị thành `Thursday, 11 June 2026` để tránh ảnh bị thay đổi do thời gian thật, rồi chụp 5 trạng thái:
- Empty form: màn hình vừa mở, input còn trống.
- Valid input entered: đã nhập `15/06/2023` nhưng chưa bấm Check.
- Valid result: bấm Check với ngày hợp lệ.
- Invalid result: bấm Check với `29/02/2023`.
- Error state: nhập `abc` ở Day.

Các ảnh mới được so sánh với baseline trong thư mục snapshot. Repo có cấu hình tolerance nhỏ để tránh fail vì khác biệt render rất nhỏ giữa môi trường, nhưng nếu UI thay đổi đáng kể thì test sẽ fail và Playwright report sẽ chỉ ra ảnh khác."

### Kết luận
"Visual Regression Testing là lớp kiểm tra bằng hình ảnh. Nó giúp nhóm giữ giao diện ổn định sau các lần sửa code và tạo bằng chứng trực quan cho video demo."

---

## TOPIC 7 - AI-Assisted Testing (Gemini + Offline Self-Healing Demo)

### Mở đầu
> *[Mở terminal, chuẩn bị chạy phần Topic 7 hoặc `run-all-topics.bat`]*

"Topic 7 là **AI-Assisted Testing**, tức là kiểm thử có hỗ trợ bởi AI.

Theo sơ đồ topic, AI-assisted testing có thể dùng nhiều công cụ như Playwright MCP, Copilot hoặc các nền tảng AI khác. Trong repo của nhóm em, phần demo được triển khai bằng Google Gemini và offline sample để minh họa ba ý tưởng chính: AI gợi ý testcase, AI giải thích chiến lược test, và mô phỏng self-healing khi locator bị thay đổi."

### Trong khi chạy demo
> *[Chạy offline sample hoặc self-healing demo]*

"Nếu có Gemini API key, nhóm có thể chạy `ai-assistant-chat.bat`, nhập prompt bằng tiếng Việt như: 'Hãy tạo testcase kiểm thử DateTimeChecker cho ngày nhuận, biên tháng, biên năm và dữ liệu sai định dạng.'

AI sẽ đề xuất testcase gồm input, expected result và lý do cần test.

Để quay video ổn định, repo còn có offline sample và self-healing demo. Trong luồng self-healing:
- AI phân tích yêu cầu và sinh testcase.
- Detector mô phỏng trường hợp test fail vì locator cũ không còn đúng.
- AI Heal đề xuất locator mới bền hơn, ví dụ dựa trên label thay vì id dễ thay đổi.
- Regression được mô phỏng chạy lại và pass.

Điểm cần nhấn mạnh là đây là demo hỗ trợ tester. AI không thay thế người kiểm thử; tester vẫn phải review testcase, kiểm chứng kết quả và quyết định có đưa vào bộ automation thật hay không."

### Kết luận
"AI-Assisted Testing giúp tăng tốc phân tích yêu cầu và sinh ý tưởng testcase, đặc biệt với các trường hợp biên như năm nhuận, biên tháng, biên năm và sai định dạng. Giá trị chính là hỗ trợ tư duy kiểm thử, không phải tự động tin mọi câu trả lời của AI."

---

## TOPIC 8 - CI/CD & Reporting (Local Pipeline Simulation)

### Mở đầu
> *[Mở terminal, chuẩn bị chạy `Topic 8 - CI CD and Reporting\run-ci-simulation.bat`]*

"Topic 8 là **CI/CD và Reporting**. Đây là topic tổng hợp, mô phỏng một pipeline kiểm thử tự động cục bộ cho DateTimeChecker.

Thay vì chỉ chạy từng topic rời rạc, pipeline giúp nhóm chứng minh quy trình kiểm soát chất lượng: build trước, test từng tầng, nếu lỗi thì dừng hoặc skip các stage sau, cuối cùng tổng hợp PASS/FAIL/SKIPPED."

### Trong khi chạy pipeline
> *[Chạy `.\Topic 8 - CI CD and Reporting\run-ci-simulation.bat`]*

"Pipeline local có 8 stage:
- **Stage 1 - Build Java Compilation:** kiểm tra source Java có biên dịch được không.
- **Stage 2 - Unit Testing:** chạy test backend Java và Jest cho JavaScript helper.
- **Stage 3 - API Testing:** gửi HTTP request và xác minh JSON response.
- **Stage 4 - Web E2E Browser Testing:** mô phỏng hành vi người dùng trên trình duyệt.
- **Stage 5 - Mobile Testing:** chạy mobile test hoặc fallback simulation.
- **Stage 6 - Performance Testing:** đo latency, error rate và độ ổn định dưới tải.
- **Stage 7 - Visual Regression Testing:** so sánh screenshot hiện tại với baseline.
- **Stage 8 - AI-Assisted Testing:** demo AI hỗ trợ sinh testcase và self-healing concept.

Nếu một stage fail, pipeline có thể skip các stage sau để mô phỏng quality gate trong CI/CD thật. Cuối cùng terminal in `PIPELINE SUMMARY` với số stage pass, fail, skip và ghi báo cáo vào `reports/ci-pipeline-report.txt`."

### Kết luận
"CI/CD và Reporting giúp nhóm nhìn chất lượng toàn dự án trong một luồng thống nhất. Đây là tư duy quan trọng trong dự án thật: không chỉ viết test, mà còn tự động hóa việc chạy test và báo cáo kết quả."

---

## Lời Kết Video

"Vậy là nhóm em đã demo 8 topic kiểm thử cho DateTimeChecker trong môn SWT301.

Tóm tắt lại:
- Topic 1: Unit Testing kiểm tra logic nhỏ nhất bằng Java test và Jest.
- Topic 2: API Testing kiểm tra backend qua HTTP request và JSON response.
- Topic 3: Web E2E Testing kiểm tra luồng người dùng trên trình duyệt bằng Playwright và Selenium demo.
- Topic 4: Mobile Testing kiểm tra phiên bản Flutter hoặc mô phỏng quy trình mobile testing.
- Topic 5: Performance Testing dùng Autocannon để đo latency, error rate và khả năng chịu tải.
- Topic 6: Visual Regression Testing dùng Playwright screenshot để phát hiện thay đổi UI ngoài ý muốn.
- Topic 7: AI-Assisted Testing dùng Gemini/offline sample để minh họa sinh testcase và self-healing.
- Topic 8: CI/CD & Reporting gom các tầng test vào pipeline local và sinh báo cáo.

Qua 8 topic này, nhóm em chứng minh được DateTimeChecker không chỉ được kiểm tra đúng logic theo URD, mà còn được kiểm thử ở nhiều góc độ: API, UI, mobile, hiệu năng, hình ảnh, AI hỗ trợ và pipeline tự động. Em cảm ơn thầy và các bạn đã theo dõi."

---

## Các điểm đã sửa so với bản cũ

- Topic 5 đổi từ "k6 là tool chính" thành "Autocannon là tool chạy chính, k6 là script tham khảo".
- Topic 7 đổi từ "Playwright MCP / GitHub Copilot" thành "Gemini + offline self-healing demo" đúng với repo.
- Topic 8 bỏ "Allure Report" vì repo hiện tại ghi report local và Playwright report, không có cấu hình Allure.
- Topic 3 sửa phần Close: bản web demo dùng nút `Close App`, không click trực tiếp nút X của cửa sổ Windows.
- Topic 6 sửa câu "khác 1 pixel là fail" thành mô tả có tolerance nhỏ theo cấu hình Playwright.
- Bổ sung testcase và endpoint đúng từ repo: `POST /api/check-date`, `VALID/INVALID/ERROR`, report trong thư mục `reports`.
