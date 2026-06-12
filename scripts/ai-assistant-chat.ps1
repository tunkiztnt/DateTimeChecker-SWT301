param(
    [switch]$OfflineSample
)

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

. "$PSScriptRoot\gemini-common.ps1"

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
if ($OfflineSample) {
    Write-Host "     OFFLINE MOCK AI TESTING ASSISTANT CHAT" -ForegroundColor Green
} else {
    Write-Host "     GEMINI SQA TESTING ASSISTANT CHAT TOOL" -ForegroundColor Green
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Nhập câu hỏi hoặc câu lệnh của bạn. Nhập '/help' để xem các lệnh." -ForegroundColor Gray
Write-Host "Lệnh demo nhanh: /demo-self-heal" -ForegroundColor Gray
Write-Host "Thoát chương trình: /exit" -ForegroundColor Gray
Write-Host "------------------------------------------------------------"

$apiKey = $null
if (-not $OfflineSample) {
    Write-Host "[STEP] Kiểm tra Gemini API Key..." -ForegroundColor Cyan
    $apiKey = Get-GeminiApiKey
    Write-Host "[STEP] AI Assistant đã sẵn sàng gọi Gemini." -ForegroundColor Cyan
} else {
    Write-Host "[STEP] Đang chạy chế độ offline sample, không cần API key." -ForegroundColor Cyan
}

$systemInstruction = @"
Bạn là Antigravity, trợ lý AI chuyên nghiệp về Đảm bảo chất lượng (SQA) và Kiểm thử phần mềm (Software Testing).
Bạn đang hỗ trợ một nhóm sinh viên tại FPT University kiểm thử ứng dụng "DateTimeChecker".
Ứng dụng DateTimeChecker là một ứng dụng Web viết bằng Java, sử dụng JDK HttpServer, để kiểm tra ngày tháng hợp lệ:
- Day: 1-31
- Month: 1-12
- Year: 1000-3000
- Thuật toán khớp với lịch Gregorian.
- Giao diện có nút "Use Today", nút "Clear", nút "Check" và chế độ sáng/tối.

Hãy trả lời ngắn gọn, thân thiện, có tính giáo dục chuyên ngành và luôn trả lời bằng tiếng Việt.
Nếu người dùng muốn tạo testcase hoặc kiểm thử, hãy đề xuất testcase dạng bảng hoặc JSON.
Nếu người dùng gõ /demo-self-heal, hãy nhắc rằng hệ thống sẽ chạy quy trình demo kiểm thử tự phục hồi (Self-Healing).
"@

Write-Host ""
Write-Host "Gemini Assistant: Xin chào! Tôi đã sẵn sàng hỗ trợ bạn kiểm thử ứng dụng DateTimeChecker. Bạn cần tôi trợ giúp gì?" -ForegroundColor Green
Write-Host ""

while ($true) {
    $userPrompt = Read-Host "Bạn"
    $userPrompt = $userPrompt.Trim()

    if ($userPrompt -eq "/exit") {
        Write-Host "Tạm biệt!" -ForegroundColor Green
        break
    }

    if ($userPrompt -eq "/help") {
        Write-Host ""
        Write-Host "Các lệnh khả dụng:" -ForegroundColor Yellow
        Write-Host "  /demo-self-heal   - Chạy demo tự phát hiện lỗi và tự sửa trong bản sao tạm" -ForegroundColor White
        Write-Host "  /exit             - Thoát chương trình" -ForegroundColor White
        Write-Host ""
        Write-Host "Gợi ý prompt demo:" -ForegroundColor Yellow
        Write-Host "  Hãy tạo testcase kiểm thử DateTimeChecker cho ngày nhuận, biên tháng và dữ liệu sai định dạng." -ForegroundColor White
        Write-Host ""
        continue
    }

    if ($userPrompt -eq "/demo-self-heal") {
        Write-Host ""
        Write-Host "[STEP] Đang khởi chạy Demo Self-Healing..." -ForegroundColor Yellow
        if ($OfflineSample) {
            powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\ai-self-healing-demo.ps1" -OfflineSample
        } else {
            powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\ai-self-healing-demo.ps1" -ApiKey $apiKey
        }
        Write-Host ""
        continue
    }

    if ($userPrompt -eq "") {
        continue
    }

    Write-Host "[STEP] Gemini Assistant đang phân tích yêu cầu..." -ForegroundColor DarkGray
    Write-Host ""
    if ($OfflineSample) {
        $response = "[OFFLINE MODE] Tôi có thể giúp bạn kiểm thử ứng dụng DateTimeChecker. Trong chế độ Offline Sample, bạn có thể nhập '/demo-self-heal' để xem demo tự động phát hiện lỗi và tự sửa bằng Selenium và AI dựa trên dữ liệu mẫu."
        Write-Host "Gemini Assistant: $response" -ForegroundColor Green
    } else {
        $response = Invoke-GeminiPrompt -apiKey $apiKey -systemInstruction $systemInstruction -userPrompt $userPrompt
        if ($response) {
            Write-Host "Gemini Assistant: $response" -ForegroundColor Green
        } else {
            Write-Host "Gemini Assistant: Xin lỗi, tôi chưa thể xử lý yêu cầu lúc này. Hãy kiểm tra API key, quota hoặc kết nối mạng rồi thử lại." -ForegroundColor Red
        }
    }
    Write-Host ""
}
