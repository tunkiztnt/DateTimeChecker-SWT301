# Topic 7: AI-Assisted Testing - Kiểm thử Hỗ trợ bởi Trí tuệ Nhân tạo (AI)

Thư mục này chứa các tệp tin và hướng dẫn demo chức năng kiểm thử có sự hỗ trợ của trí tuệ nhân tạo (AI-assisted testing) thông qua mô hình ngôn ngữ **Google Gemini AI**.

---

## 1. Thành phần

- **Tài liệu hướng dẫn demo**: [AI-ASSISTED-TESTING-DEMO.md](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%207%20-%20AI-Assisted%20Testing/AI-ASSISTED-TESTING-DEMO.md) (Hướng dẫn từng bước thực hành cho buổi thuyết trình).
- **Kịch bản khởi động chat**: [ai-assistant-chat.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%207%20-%20AI-Assisted%20Testing/ai-assistant-chat.bat) (Dùng API key thật kết nối Gemini).
- **Kịch bản chạy Offline (Dự phòng)**: [ai-assistant-chat-offline-sample.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%207%20-%20AI-Assisted%20Testing/ai-assistant-chat-offline-sample.bat) (Chạy không cần API key, sử dụng dữ liệu mẫu, rất an toàn khi demo).
- **Reset API key**: [reset-gemini-key.bat](file:///d:/DataFPTU/Semester5/SWT301/DateTimeChecker-AI-Assistant/Topic%207%20-%20AI-Assisted%20Testing/reset-gemini-key.bat) (Xóa key cũ để nhập key mới khi cần thiết).

---

## 2. Quy trình Demo chính

1. **Khởi chạy ứng dụng**: Bấm đúp tệp `run.bat` ở thư mục gốc để khởi chạy Web Server.
2. **Mở Trình trợ lý AI**: Bấm đúp `ai-assistant-chat.bat` (hoặc bản offline nếu không có mạng/key).
3. **Nhập câu lệnh tự nhiên (Tiếng Việt)**:
   > *"Vui lòng giúp tôi testing cái project này để kiểm thử có sai gì không"*
4. **Xem AI xử lý**:
   - AI sẽ tự động phân tích yêu cầu.
   - Sinh danh sách 10 test case động bằng JSON.
   - Gọi Selenium WebDriver mở trình duyệt Microsoft Edge và tự động nhập/chạy từng test case trên giao diện thực.
5. **Thử nghiệm tính năng Self-Healing (Tự sửa lỗi)**:
   - Trong cửa sổ chat AI, gõ `/demo-self-heal`.
   - AI sẽ tự động phát hiện lỗi giả lập trong source code tạm, đề xuất sửa mã nguồn và chạy lại regression testing để kiểm chứng.

---

## 3. Cách chuẩn bị Gemini API Key

Bạn có thể tạo một API Key miễn phí tại [Google AI Studio](https://aistudio.google.com/app/apikey). Key sẽ được lưu cục bộ dưới dạng mã hóa trên máy tính của bạn tại thư mục `.secrets` và không bao giờ bị đẩy lên Git.
