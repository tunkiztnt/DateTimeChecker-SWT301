# AI-Assisted Testing and Self-Healing Demo

## Mục tiêu demo

Tài liệu này dùng cho phần quay video Topic 7. Mục tiêu là chứng minh AI có thể hỗ trợ tester tạo testcase, giải thích rủi ro kiểm thử và mô phỏng self-healing testing cho DateTimeChecker.

## Demo 1: Chat với Gemini

Chạy:

```powershell
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat.bat
```

Lần đầu dùng, nhập Gemini API key khi được hỏi. Key được lưu cục bộ tại `.secrets/gemini-api-key.txt`; thư mục `.secrets` đã được đưa vào `.gitignore`.

Prompt gợi ý:

```text
Hãy tạo testcase kiểm thử DateTimeChecker cho ngày nhuận, biên tháng, biên năm và dữ liệu sai định dạng.
```

Kết quả mong đợi:

- Gemini trả lời bằng tiếng Việt.
- Có danh sách testcase rõ input, expected result và lý do.
- Nếu API key lỗi, CMD in chi tiết lỗi để kiểm tra key, quota hoặc model.

## Demo 2: Offline sample

Chạy:

```powershell
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat-offline-sample.bat
```

Chế độ này dùng khi mạng không ổn định hoặc chưa có key. Nội dung trả lời là mẫu, nhưng luồng demo vẫn giống thật.

## Demo 3: Self-healing

Trong cửa sổ chat, nhập:

```text
/demo-self-heal
```

Luồng hiển thị:

1. AI phân tích source và sinh testcase.
2. Detector mô phỏng test bị fail do locator thay đổi.
3. AI Heal tìm locator tương đương bằng label text.
4. Script hiển thị locator mới bền hơn.
5. Regression chạy lại và pass.

Kết quả mong đợi:

- CMD hiển thị các bước `[AI]`, `[DETECTOR]`, `[AI HEAL]`, `[HEALED]`, `[RESULT]`.
- Cuối demo có bảng tổng kết `AI-ASSISTED TESTING DEMO COMPLETE`.

## Cách xử lý lỗi thường gặp

- Sai API key: chạy `reset-gemini-key.bat` rồi nhập key mới.
- Hết quota hoặc API chưa bật: kiểm tra Google AI Studio.
- Model không gọi được: đặt biến môi trường `GEMINI_MODEL`, ví dụ `gemini-1.5-flash`.
- CMD hiển thị sai tiếng Việt: đảm bảo file `.bat` đang có `chcp 65001` và chạy bằng terminal hỗ trợ UTF-8.

## Gợi ý lời thuyết trình

"AI không thay thế tester. AI giúp sinh ý tưởng và phân tích nhanh, còn tester vẫn phải review testcase, chạy automation và quyết định kết quả có đáng tin cậy hay không."
