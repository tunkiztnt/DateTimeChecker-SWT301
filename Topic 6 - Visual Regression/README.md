# Topic 6: Visual Regression - Kiểm thử Hồi quy Giao diện

Thư mục này chứa kịch bản kiểm thử giao diện trực quan (**Visual Regression Testing** / **PW shots**) nhằm đảm bảo bố cục, màu sắc và các thành phần giao diện không bị lệch hoặc biến đổi ngoài ý muốn sau khi cập nhật mã nguồn.

---

## 1. Thành phần

- **Bộ kịch bản so khớp giao diện**: `visual/visual.spec.js`
- **Thư mục chứa ảnh giao diện gốc (Baselines)**: `visual/visual.spec.js-snapshots/`

---

## 2. Kịch bản kiểm thử

Playwright chụp và so sánh năm trạng thái:

1. `empty-form.png`: form vừa mở và chưa nhập dữ liệu.
2. `valid-input-entered.png`: đã nhập `15/06/2023` nhưng chưa bấm Check.
3. `valid-result.png`: kết quả ngày hợp lệ.
4. `invalid-result.png`: kết quả ngày không tồn tại.
5. `error-state.png`: lỗi sai định dạng đầu vào.

Ngày hiển thị được cố định thành `Thursday, 11 June 2026` và animation bị tắt để ảnh ổn định.

---

## 3. Cách chạy Demo

Để chạy kiểm tra hồi quy giao diện, hãy chạy tệp batch sau:

```powershell
.\Topic 6 - Visual Regression\run-tests.bat
```

*Nếu bạn cố ý thay đổi CSS/HTML giao diện và muốn lưu lại giao diện mới làm ảnh mẫu gốc, hãy chạy lệnh sau trong terminal:*
```powershell
npx playwright test --config=playwright.config.js --grep="@visual" --update-snapshots
```

## 4. Log cần giải thích khi quay video

CMD sẽ ghi rõ năm trạng thái giao diện đang được chụp và tên baseline tương ứng. Playwright quyết định `PASS` khi ảnh hiện tại khớp baseline trong ngưỡng sai lệch cho phép.

Nếu test thất bại, mở Playwright report để trình bày ba ảnh: expected, actual và diff. Kịch bản quay tổng hợp nằm tại `HUONG-DAN-QUAY-VIDEO-8-TOPIC.md`.
