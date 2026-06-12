# Topic 6: Visual Regression - Kiểm thử hồi quy giao diện

## Dùng để làm gì?

Visual Regression Testing chụp ảnh giao diện web và so sánh với ảnh baseline để phát hiện thay đổi UI ngoài ý muốn. Topic này phù hợp sau khi sửa HTML/CSS, logo, layout hoặc màu sắc.

## Vai trò và ý nghĩa

- Phát hiện lỗi giao diện mà assertion text thông thường khó bắt, ví dụ lệch layout, mất logo, modal hiển thị sai.
- Giữ giao diện ổn định sau các lần sửa code.
- Tạo bằng chứng trực quan cho báo cáo và video demo.

## Thành phần chính

- Playwright visual tests: `Topic 6 - Visual Regression/visual/visual.spec.js`
- Baseline screenshots: `Topic 6 - Visual Regression/visual/visual.spec.js-snapshots/`
- Script chạy topic: `Topic 6 - Visual Regression/run-tests.bat`
- Tài liệu phụ: `Topic 6 - Visual Regression/README-visual.md`

## Cách chạy

Từ thư mục gốc dự án:

```powershell
.\Topic 6 - Visual Regression\run-tests.bat
```

Cập nhật ảnh baseline khi thay đổi giao diện có chủ đích:

```powershell
npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
```

## Luồng hoạt động khi chạy

1. Khởi động server DateTimeChecker.
2. Mở trang web bằng Playwright.
3. Cố định ngày hiển thị thành `Thursday, 11 June 2026` để ảnh ổn định.
4. Chụp 5 trạng thái: empty form, nhập hợp lệ, kết quả hợp lệ, kết quả không hợp lệ, lỗi định dạng.
5. So sánh ảnh mới với baseline.
6. Tắt server sau khi test xong.

## Kết quả mong đợi

- Nếu UI không đổi ngoài ý muốn: các screenshot tests PASS.
- Nếu UI thay đổi có chủ đích, Playwright báo khác ảnh; nhóm kiểm tra ảnh mới rồi chạy lệnh update snapshots.
- Kết quả chi tiết nằm trong Playwright report và `test-results/` khi có lỗi.

## Gợi ý lời demo

"Topic 6 kiểm thử bằng mắt của máy. Sau khi đổi logo FPT University hoặc sửa CSS, visual regression giúp nhóm xác nhận giao diện vẫn ổn định."
