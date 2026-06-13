# Topic 7: AI-Assisted Testing - Kiểm thử hỗ trợ bởi AI

## Dùng để làm gì?

AI-Assisted Testing dùng Google Gemini để hỗ trợ tester tạo testcase, giải thích chiến lược kiểm thử và mô phỏng self-healing testing. Topic này không thay tester, mà giúp tester suy nghĩ nhanh hơn và có thêm gợi ý kiểm thử.

## Vai trò và ý nghĩa

- Sinh ý tưởng testcase từ yêu cầu tự nhiên bằng tiếng Việt.
- Giải thích vì sao cần test ngày nhuận, biên tháng, khoảng năm và sai định dạng.
- Mô phỏng self-healing: phát hiện locator/test bị lỗi, đề xuất cách sửa và chạy lại regression.
- Có offline sample để demo ổn định khi không có mạng hoặc chưa có Gemini API key.

## Thành phần chính

- Demo chạy test AI-assisted trực tiếp: `Topic 7 - AI-Assisted Testing/run-tests.bat`
- Chat AI thật: `Topic 7 - AI-Assisted Testing/ai-assistant-chat.bat`
- Chat offline sample: `Topic 7 - AI-Assisted Testing/ai-assistant-chat-offline-sample.bat`
- Reset key: `Topic 7 - AI-Assisted Testing/reset-gemini-key.bat`
- Script chat: `scripts/ai-assistant-chat.ps1`
- Gemini helper: `scripts/gemini-common.ps1`
- Self-healing demo: `scripts/ai-self-healing-demo.ps1`
- Hướng dẫn chi tiết: `Topic 7 - AI-Assisted Testing/AI-ASSISTED-TESTING-DEMO.md`

## Cách chạy

Chạy demo kiểm thử AI-assisted trực tiếp để quay video:

```powershell
.\Topic 7 - AI-Assisted Testing\run-tests.bat
```

Lệnh này không chỉ nhập prompt. Nó sẽ mô phỏng AI sinh testcase, khởi động server thật, gọi API thật, rồi in bảng `input / expected / actual / HTTP / latency / PASS`.

Chạy Gemini thật:

```powershell
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat.bat
```

Chạy offline sample:

```powershell
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat-offline-sample.bat
```

Reset Gemini API key:

```powershell
.\Topic 7 - AI-Assisted Testing\reset-gemini-key.bat
```

## Chuẩn bị Gemini API key

1. Vào Google AI Studio và tạo API key.
2. Chạy `ai-assistant-chat.bat`.
3. Nhập key khi CMD hỏi.
4. Script sẽ thử gọi Gemini bằng model mặc định `gemini-2.5-flash`, tự lấy danh sách model hỗ trợ `generateContent`, rồi fallback sang model phù hợp nếu cần.
5. Nếu key sai, hết quota hoặc API chưa bật, CMD sẽ in chi tiết lỗi và gợi ý reset key.

Có thể đổi model bằng biến môi trường:

```powershell
$env:GEMINI_MODEL="gemini-1.5-flash"
.\Topic 7 - AI-Assisted Testing\ai-assistant-chat.bat
```

## Luồng hoạt động khi demo

1. Chạy `run-tests.bat`.
2. AI demo phân tích rule của DateTimeChecker và sinh các testcase biên/ngày nhuận/dữ liệu lỗi.
3. Script chạy các testcase được AI sinh ra trên API thật `/api/datetime/check`.
4. CMD in từng dòng `AI-TCxx`, input, expected, actual, HTTP code, latency và lý do AI chọn case đó.
5. Script tiếp tục minh họa self-healing locator và natural-language-to-test-code.

## Kết quả mong đợi

- Chữ tiếng Việt hiển thị đúng trong CMD.
- Với API key hợp lệ, Gemini trả lời bằng tiếng Việt.
- Với offline sample, demo vẫn chạy không cần key.
- AI-generated tests hiển thị rõ expected vs actual và tạo report `reports/ai-assisted-generated-tests.tsv`.
- Self-healing demo in các bước `[AI]`, `[DETECTOR]`, `[AI HEAL]`, `[RESULT]`.

## Gợi ý lời demo

"Topic 7 cho thấy AI có thể hỗ trợ tester tạo testcase và phân tích lỗi. Tester vẫn là người kiểm chứng, quyết định testcase nào dùng và xác nhận kết quả sau khi AI đề xuất."
