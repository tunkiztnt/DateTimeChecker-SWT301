# Topic 7: AI-Assisted Testing - Kiểm thử hỗ trợ bởi AI

## Dùng để làm gì?

AI-Assisted Testing dùng Google Gemini để hỗ trợ tester tạo testcase, giải thích chiến lược kiểm thử và mô phỏng self-healing testing. Topic này không thay tester, mà giúp tester suy nghĩ nhanh hơn và có thêm gợi ý kiểm thử.

## Vai trò và ý nghĩa

- Sinh ý tưởng testcase từ yêu cầu tự nhiên bằng tiếng Việt.
- Giải thích vì sao cần test ngày nhuận, biên tháng, khoảng năm và sai định dạng.
- Mô phỏng self-healing: phát hiện locator/test bị lỗi, đề xuất cách sửa và chạy lại regression.
- Có offline sample để demo ổn định khi không có mạng hoặc chưa có Gemini API key.

## Thành phần chính

- Chat AI thật: `Topic 7 - AI-Assisted Testing/ai-assistant-chat.bat`
- Chat offline sample: `Topic 7 - AI-Assisted Testing/ai-assistant-chat-offline-sample.bat`
- Chạy luồng AI sinh file testcase rồi thực thi test: `Topic 7 - AI-Assisted Testing/run-ai-generated-tests.bat`
- Reset key: `Topic 7 - AI-Assisted Testing/reset-gemini-key.bat`
- Script chat: `scripts/ai-assistant-chat.ps1`
- Gemini helper: `scripts/gemini-common.ps1`
- Self-healing demo: `scripts/ai-self-healing-demo.ps1`
- AI testcase generator: `scripts/generate-ai-testcases.ps1`
- AI testcase runner: `scripts/run-ai-generated-tests.ps1`
- Hướng dẫn chi tiết: `Topic 7 - AI-Assisted Testing/AI-ASSISTED-TESTING-DEMO.md`

## Cách chạy

Chạy Gemini thật:

```powershell
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat.bat
```

Chạy offline sample:

```powershell
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat-offline-sample.bat
```

Chạy demo sinh file testcase rồi dùng file đó làm tham số cho Playwright E2E:

```powershell
.\Topic 7 - AI-Assisted Testing\run-ai-generated-tests.bat
```

Chạy bản gọi Gemini thật:

```powershell
.\Topic 7 - AI-Assisted Testing\run-ai-generated-tests.bat --real
```

Reset Gemini API key:

```powershell
.\Topic 7 - AI-Assisted Testing\reset-gemini-key.bat
```

## Chuẩn bị Gemini API key

1. Vào Google AI Studio và tạo API key.
2. Chạy `ai-assistant-chat.bat`.
3. Nhập key khi CMD hỏi.
4. Script sẽ thử gọi Gemini bằng model mặc định `gemini-3.1-flash-lite` và tự fallback sang một số model free-tier phổ biến nếu cần.
5. Nếu key sai, hết quota hoặc API chưa bật, CMD sẽ in chi tiết lỗi và gợi ý reset key.

Có thể đổi model bằng biến môi trường:

```powershell
$env:GEMINI_MODEL="gemini-1.5-flash"
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat.bat
```

## Luồng hoạt động khi demo

1. Mở chat AI.
2. Nhập prompt: `Hãy tạo testcase kiểm thử DateTimeChecker cho ngày nhuận, biên tháng và dữ liệu sai định dạng.`
3. AI trả lời bằng tiếng Việt, đề xuất testcase.
4. Gõ `/demo-self-heal`.
5. Script chạy demo AI test generation, self-healing locator và natural language to test code.

Luồng demo file-based mới:

1. Gõ `/export-testcases` hoặc chạy `run-ai-generated-tests.bat`.
2. AI sinh testcase và lưu vào `reports/ai-generated-testcases.json`.
3. Playwright đọc file JSON này, mở UI web và tự tạo danh sách E2E test để chạy.
4. Kết quả pass/fail bám theo chính bộ testcase mà AI vừa xuất.

## Kết quả mong đợi

- Chữ tiếng Việt hiển thị đúng trong CMD.
- Với API key hợp lệ, Gemini trả lời bằng tiếng Việt.
- Với offline sample, demo vẫn chạy không cần key.
- Self-healing demo in các bước `[AI]`, `[DETECTOR]`, `[AI HEAL]`, `[RESULT]`.

## Gợi ý lời demo

"Topic 7 cho thấy AI có thể hỗ trợ tester tạo testcase và phân tích lỗi. Tester vẫn là người kiểm chứng, quyết định testcase nào dùng và xác nhận kết quả sau khi AI đề xuất."
