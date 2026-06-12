# Topic 1: Unit Testing - Kiểm thử đơn vị

## Dùng để làm gì?

Unit Testing kiểm tra từng hàm, từng lớp xử lý nhỏ của DateTimeChecker trước khi ghép với giao diện web, API hoặc các tầng test lớn hơn. Topic này tập trung vào logic quan trọng nhất của hệ thống: kiểm tra ngày, tháng, năm có hợp lệ hay không.

## Vai trò và ý nghĩa

- Phát hiện lỗi sớm trong logic nghiệp vụ như năm nhuận, số ngày tối đa của từng tháng, giới hạn năm `1000-3000`.
- Giúp nhóm chứng minh phần lõi của ứng dụng đúng trước khi chạy API Testing, Web E2E Testing và CI/CD.
- Là tầng test nhanh nhất, phù hợp chạy thường xuyên sau mỗi lần sửa code.

## Thành phần chính

- Backend Java logic: `src/main/java/com/datetimechecker/DateTimeValidationService.java`
- Backend Java tests: `src/test/java/com/datetimechecker/DateTimeValidationServiceTest.java`
- Frontend helper: `Topic 1 - Unit Testing/javascript-unit-testing/date-helpers.js`
- Frontend helper tests: `Topic 1 - Unit Testing/javascript-unit-testing/date-helpers.test.js`
- Script chạy demo: `Topic 1 - Unit Testing/run-tests.bat`

## Cách chạy

Từ thư mục gốc dự án:

```powershell
.\Topic 1 - Unit Testing\run-tests.bat
```

Hoặc chạy riêng từng phần:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
npm run test:unit
```

## Luồng hoạt động khi chạy

1. Script biên dịch source Java vào `out/classes`.
2. Chạy các test Java cho `DateTimeValidationService`.
3. Chạy Jest cho các helper JavaScript.
4. In từng testcase PASS/FAIL ra CMD để quay demo rõ ràng.

## Kết quả mong đợi

- CMD hiển thị `ALL UNIT TESTS COMPLETED SUCCESSFULLY`.
- Java test pass các ca như `30/05/2026`, `29/02/2024`, `29/02/2025`, `31/04/2026`, giá trị rỗng và sai định dạng.
- Jest test pass các hàm format ngày và kiểm tra khoảng giá trị.

## Gợi ý lời demo

"Topic 1 kiểm thử đơn vị giúp nhóm kiểm tra phần logic nhỏ nhất của DateTimeChecker. Nếu tầng này pass, nhóm có cơ sở tin rằng rule ngày tháng đã đúng trước khi test qua API, giao diện web và pipeline CI/CD."
