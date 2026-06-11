param(
    [switch]$OfflineSample
)

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
Write-Host "------------------------------------------------------------"

$apiKey = $null
if (-not $OfflineSample) {
    $apiKey = Get-GeminiApiKey
}

$systemInstruction = @"
Bạn là Antigravity, trợ lý AI chuyên nghiệp về Đảm bảo chất lượng (SQA) và Kiểm thử phần mềm (Software Testing). 
Bạn đang hỗ trợ một nhóm sinh viên tại FPT University kiểm thử ứng dụng "DateTimeChecker".
Ứng dụng DateTimeChecker là một ứng dụng Web viết bằng Java (sử dụng thư viện JDK HttpServer), kiểm tra ngày tháng hợp lệ:
- Day: 1-31
- Month: 1-12
- Year: 1000-3000
- Thuật toán khớp với lịch Gregorian.
- Giao diện có nút "Dùng hôm nay", nút "Clear", và đổi giao diện sáng/tối.

Hãy trả lời ngắn gọn, thân thiện, mang tính giáo dục chuyên ngành và luôn trả lời bằng Tiếng Việt.
Nếu người dùng muốn tạo testcase hoặc kiểm thử, hãy cung cấp hoặc đề xuất các testcase dạng bảng hoặc JSON.
Nếu người dùng gõ /demo-self-heal, hãy nhắc họ rằng hệ thống sẽ tự động chạy quy trình demo kiểm thử tự phục hồi (Self-Healing).
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
        Write-Host "  /demo-self-heal   - Chạy demo quy trình tự phát hiện lỗi và tự sửa (Self-Healing)" -ForegroundColor White
        Write-Host "  /exit             - Thoát chương trình" -ForegroundColor White
        Write-Host ""
        continue
    }

    if ($userPrompt -eq "/demo-self-heal") {
        Write-Host ""
        Write-Host "Đang khởi chạy Demo Self-Healing..." -ForegroundColor Yellow
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

    Write-Host "Gemini Assistant đang suy nghĩ..." -ForegroundColor DarkGray
    Write-Host ""
    if ($OfflineSample) {
        $response = "[OFFLINE MODE] Tôi có thể giúp bạn kiểm thử ứng dụng DateTimeChecker. Trong chế độ Offline Sample, bạn có thể nhập lệnh '/demo-self-heal' để xem demo tự động phát hiện lỗi và tự sửa (Self-Healing) bằng Selenium và AI dựa trên các mẫu dữ liệu có sẵn."
        Write-Host "Gemini Assistant: $response" -ForegroundColor Green
    } else {
        $response = Invoke-GeminiPrompt -apiKey $apiKey -systemInstruction $systemInstruction -userPrompt $userPrompt
        if ($response) {
            Write-Host "Gemini Assistant: $response" -ForegroundColor Green
        } else {
            Write-Host "Gemini Assistant: Xin lỗi, tôi không thể xử lý yêu cầu lúc này." -ForegroundColor Red
        }
    }
    Write-Host ""
}
