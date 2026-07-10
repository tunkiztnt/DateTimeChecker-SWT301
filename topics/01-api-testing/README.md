# Topic 1: API Testing (Postman)

Chủ đề này hướng dẫn kiểm thử các endpoint API của ứng dụng `DateTimeChecker` trực tiếp thông qua **Postman** (công cụ chuyên dụng để kiểm thử API thủ công và bán tự động).

## 🚀 Hướng dẫn Demo

1. **Khởi động backend server:**
   Chạy file `run.bat` trong thư mục này. Nó sẽ tự động biên dịch ứng dụng Java và khởi chạy server cục bộ tại địa chỉ `http://localhost:4173` dưới nền.

2. **Mở ứng dụng Postman:**
   - Tải và mở **Postman** trên máy tính của bạn.
   - Nhấn vào nút **Import** ở góc trên bên trái Postman.
   - Chọn và tải lên file cấu hình kiểm thử sẵn có trong thư mục này: **[DateTimeChecker.postman_collection.json](DateTimeChecker.postman_collection.json)**.

3. **Chạy các API request:**
   Sau khi import thành công, bạn sẽ thấy thư mục `DateTimeChecker API Testing Collection` chứa 4 request mẫu:
   - **Valid Date Check (29/02/2024)**: Kiểm thử ngày nhuận hợp lệ.
   - **Invalid Date Check (29/02/2023)**: Kiểm thử ngày không nhuận (sai số ngày trong tháng).
   - **Error Check - Day Out of Range (32/02/2020)**: Kiểm thử lỗi vượt ngưỡng (Day > 31).

4. **Kiểm tra kết quả tự động trên Postman:**
   Mỗi request đã được cấu hình sẵn mã script kiểm tra (tab **Tests** trong Postman). Khi bạn nhấn **Send**, Postman sẽ tự động chạy script này và hiển thị kết quả xác thực (tab **Test Results**):
   - Kiểm tra mã HTTP Status trả về có phải là `200` hay không.
   - Kiểm tra tính hợp lệ trong trường JSON (`valid`, `result`, `message`).
   - Kiểm tra thông tin hiển thị chi tiết (ví dụ: ngày hiển thị, thứ trong tuần, năm nhuận).
