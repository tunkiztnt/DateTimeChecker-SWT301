# Báo cáo Kiểm thử có sự hỗ trợ của AI (AI-Assisted Testing Report)
## Môn học: Software Quality Assurance and Testing (SWT301)
## Dự án: Date Time Checker

---

## 1. Giới thiệu về AI-Assisted Testing (Kiểm thử hỗ trợ bởi AI)
AI-Assisted Testing là phương pháp ứng dụng Trí tuệ Nhân tạo (AI) để tối ưu hóa quy trình kiểm thử phần mềm. Trong dự án này, AI đóng vai trò là một trợ lý thông minh hỗ trợ các công việc:
1. **AI Test Generation (AI sinh ca kiểm thử)**: AI phân tích mã nguồn và tài liệu đặc tả yêu cầu (URD) để tự động thiết kế các ca kiểm thử tối ưu.
2. **AI E2E Test Execution (AI thực thi E2E)**: AI chạy các bài kiểm thử tự động trên trình duyệt thực tế bằng Playwright.
3. **AI Self-Healing Locators (Tự phục hồi lỗi định vị)**: Khả năng tự động dò tìm và khắc phục các phần tử UI bị thay đổi ID/Class trên trang Web để bài kiểm thử không bị gãy giữa chừng.

### Triết lý "Human-in-the-Loop" (Con người kiểm soát)
* **AI không thay thế con người**: AI có thể đưa ra các suy đoán hoặc tự động hóa các thao tác lặp đi lặp lại, nhưng con người vẫn phải đóng vai trò kiểm duyệt và ra quyết định cuối cùng (Sign-off) trước khi phát hành (release) sản phẩm.
* **Quy trình hoạt động trong Demo**:
  $$\text{AI phân tích URD} \rightarrow \text{Sinh bộ test} \rightarrow \mathbf{\text{Con người duyệt (Approve)}} \rightarrow \text{AI chạy test} \rightarrow \text{Self-healing nếu có lỗi} \rightarrow \mathbf{\text{Con người ký duyệt kết quả}}$$

---

## 2. Thiết kế kịch bản kiểm thử (Test Design)
Bộ test E2E do AI sinh ra áp dụng các kỹ thuật thiết kế test case chuẩn mực của môn học SWT301:

| Mã số (TC) | Tên ca kiểm thử | Kỹ thuật áp dụng | Dữ liệu đầu vào (Input) | Kết quả mong đợi (Expected Output) |
| :--- | :--- | :--- | :--- | :--- |
| **TC01** | Ngày hợp lệ (Năm nhuận) | Giá trị biên (Biên năm nhuận) | Day: `29`, Month: `2`, Year: `2024` | `29/02/2024 is correct date time!` (Message) |
| **TC02** | Ngày không hợp lệ (Năm thường)| Giá trị biên (Biên năm thường) | Day: `29`, Month: `2`, Year: `2023` | `29/02/2023 is NOT correct date time!` (Message) |
| **TC03** | Lỗi định dạng Ngày (Số thập phân)| Phân vùng tương đương & Đoán lỗi | Day: `1.5`, Month: `2`, Year: `2020` | `Input data for Day is incorrect format!` (Error) |
| **TC04** | Ngày ngoài khoảng giá trị | Phân tích giá trị biên ($32 > 31$) | Day: `32`, Month: `2`, Year: `2020` | `Input data for Day is out of range!` (Error) |
| **TC05** | Chức năng nút Clear | Kiểm thử chức năng (Reset Form) | Day: `15`, Month: `6`, Year: `2026` | Các ô nhập liệu bị xóa trắng hoàn toàn. |
| **TC06** | Hộp thoại xác nhận Đóng | Kiểm thử luồng giao diện (Modal) | Nhấn nút Close (X) $\rightarrow$ Chọn "No" | Hộp thoại ẩn đi, ứng dụng giữ nguyên trạng thái. |
| **TC07** | Kiểm thử với Self-Healing | **AI Self-Healing** (Tự phục hồi) | Nhập ngày đúng $\rightarrow$ Click `#btnCheck` | Tìm thấy nút thay thế "Check", test vượt qua thành công! |

---

## 3. Cơ chế Tự phục hồi (Self-Healing) hoạt động thế nào?
Trong file kiểm thử [tests/datetime.spec.js](file:///c:/Users/nem/Desktop/DateTimeChecker/DateTimeChecker-SWT301/tests/datetime.spec.js), AI đã cài đặt hàm định vị thông minh `selfHealingClick(page, selector, fallbackText)`:
* **Tình huống lỗi**: Dev thay đổi cấu trúc mã nguồn HTML (Ví dụ: Đổi ID hoặc xóa thuộc tính của nút bấm).
* **Quá trình tự sửa**:
  1. Khi Playwright không tìm thấy nút theo Selector gốc (`#btnCheck`), lỗi timeout sẽ được ném ra.
  2. Cơ chế Self-healing được kích hoạt: Quét cây thư mục DOM của trang web để tìm kiếm các nút bấm có chứa nhãn là `"Check"` hoặc `"Submit"`.
  3. Nếu tìm thấy, nó sẽ ghi nhận giải pháp thay thế, tiến hành click và cho phép bài kiểm thử tiếp tục chạy thành công.

---

## 4. Hướng dẫn chạy Demo cho giảng viên xem
Để chạy demo bảng điều khiển tương tác thể hiện quy trình duyệt của con người:

1. Mở terminal tại thư mục dự án.
2. Chạy lệnh:
   ```bash
   npm run ai-test
   ```
3. Bảng điều khiển kiểm thử của AI sẽ hiện ra:
   * **Bước 1 (Duyệt kịch bản)**: AI hiển thị danh sách 7 TC đã sinh ra và hỏi: `Do you approve the AI-generated test suite? (Y/N):`. Hãy nhập `Y` để duyệt.
   * **Bước 2 (Quan sát chạy tự động)**: AI tự động khởi động server Java, mở trình duyệt Chrome lên trên màn hình và tự động điền/nhấp chuột cho 7 ca kiểm thử (bạn có thể chỉ cho thầy xem trình duyệt chạy tự động thực tế).
   * **Bước 3 (Self-Healing kích hoạt)**: Tại **TC07**, trình duyệt sẽ cố tìm nút có ID không tồn tại (`#btnCheck`), sau đó bạn sẽ thấy bảng điều khiển thông báo:
     `[AI SELF-HEALING SUCCESS] Found alternative element! Resolving locator path to: "button:has-text('Check')"`
   * **Bước 4 (Ký duyệt báo cáo)**: Khi toàn bộ test chạy xong, AI hiển thị bảng báo cáo kết quả và yêu cầu con người ký duyệt: `Do you accept these test results and sign-off on the build? (Y/N):`. Nhập `Y` để hoàn thành.
