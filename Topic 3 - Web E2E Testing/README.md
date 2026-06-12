# Topic 3: Web E2E Testing - Kiểm thử Web từ đầu đến cuối

## Dùng để làm gì?

Web E2E Testing mô phỏng hành vi người dùng thật trên trình duyệt: mở app, nhập ngày tháng, bấm `Check`, đọc kết quả và đóng hộp thoại. Topic này chứng minh toàn bộ luồng web hoạt động từ UI đến API và quay về UI.

## Vai trò và ý nghĩa

- Kiểm tra tích hợp giữa HTML/CSS/JavaScript, API Java server và phản hồi hiển thị.
- Phù hợp demo trực quan vì Selenium có thể mở trình duyệt Edge để người xem thấy từng thao tác.
- Bắt lỗi mà unit/API test có thể bỏ sót, ví dụ sai locator, sai text hiển thị, modal không đóng được.

## Thành phần chính

- Playwright E2E tests: `Topic 3 - Web E2E Testing/e2e/web-e2e.spec.js`
- Selenium demo Java: `src/selenium/java/com/datetimechecker/SeleniumVisibleDemo.java`
- Selenium runner: `scripts/selenium-demo.ps1`
- Script chạy topic: `Topic 3 - Web E2E Testing/run-tests.bat`
- Script demo Selenium riêng: `Topic 3 - Web E2E Testing/selenium/run-selenium-demo.bat`

## Cách chạy

Chạy topic chính:

```powershell
.\Topic 3 - Web E2E Testing\run-tests.bat
```

Chạy Playwright E2E riêng:

```powershell
npm run test:e2e
```

Chạy Selenium UI demo riêng:

```powershell
.\Topic 3 - Web E2E Testing\selenium\run-selenium-demo.bat
```

## Luồng hoạt động khi chạy

1. Khởi động server DateTimeChecker tại `http://localhost:4173`.
2. Mở trình duyệt tự động.
3. Nhập các bộ dữ liệu như `15/06/2023`, `29/02/2023`, `32/01/2023`, `abc/1/2023`.
4. Bấm `Check`, đợi API trả kết quả và xác nhận modal/message.
5. Dừng server sau khi test xong.

## Kết quả mong đợi

- Các test Playwright/Selenium hiển thị PASS.
- Có thể thấy các tình huống: ngày hợp lệ, ngày không hợp lệ, sai khoảng, sai định dạng, đóng app.
- CMD in rõ input, expected result, actual result và PASS/FAIL.

## Gợi ý lời demo

"Topic 3 là kiểm thử từ góc nhìn người dùng. Khi test pass, ta chứng minh người dùng có thể thao tác đầy đủ trên web và nhận kết quả đúng."
