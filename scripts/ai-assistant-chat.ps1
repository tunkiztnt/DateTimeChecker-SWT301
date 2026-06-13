param(
    [switch]$OfflineSample
)

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

. "$PSScriptRoot\gemini-common.ps1"

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-JsonArrayText {
    param([string]$Text)

    if (-not $Text) {
        return $null
    }

    $trimmed = $Text.Trim()
    if ($trimmed.StartsWith('```')) {
        $trimmed = ($trimmed -replace '^```json\s*', '') -replace '^```\s*', ''
        $trimmed = ($trimmed -replace '\s*```$', '')
    }

    $match = [regex]::Match($trimmed, '\[[\s\S]*\]')
    if ($match.Success) {
        return $match.Value
    }

    return $null
}

function Convert-ChatExactTestcases {
    param(
        [object[]]$Cases,
        [int]$ExpectedCount
    )

    if (-not $Cases -or @($Cases).Count -eq 0) {
        throw "No testcases were returned."
    }

    if (@($Cases).Count -ne $ExpectedCount) {
        throw "Returned testcase count does not match the current list size."
    }

    $allowedExpectedResults = @("VALID", "INVALID", "ERROR")
    $normalized = @()

    foreach ($case in $Cases) {
        $propertyNames = @($case.PSObject.Properties.Name)
        foreach ($required in @('id', 'name', 'testType', 'day', 'month', 'year', 'expectedValid', 'expectedResult', 'reason')) {
            if ($propertyNames -notcontains $required) {
                throw "A testcase is missing required key '$required'."
            }
        }

        $expectedResult = ([string]$case.expectedResult).ToUpperInvariant()
        if ($allowedExpectedResults -notcontains $expectedResult) {
            throw "Invalid expectedResult '$($case.expectedResult)'."
        }

        $normalized += [PSCustomObject]@{
            id = [string]$case.id
            name = [string]$case.name
            testType = [string]$case.testType
            day = if ($null -eq $case.day) { "" } else { [string]$case.day }
            month = if ($null -eq $case.month) { "" } else { [string]$case.month }
            year = if ($null -eq $case.year) { "" } else { [string]$case.year }
            expectedValid = [bool]$case.expectedValid
            expectedResult = $expectedResult
            expectedDisplay = if ($null -eq $case.expectedDisplay) { $null } else { [string]$case.expectedDisplay }
            expectedMessageIncludes = if ($null -eq $case.expectedMessageIncludes) { $null } else { [string]$case.expectedMessageIncludes }
            reason = [string]$case.reason
        }
    }

    return $normalized
}

function Test-IsTestcasePrompt {
    param([string]$PromptText)

    if ([string]::IsNullOrWhiteSpace($PromptText)) {
        return $false
    }

    $promptLower = $PromptText.ToLowerInvariant()
    return (
        $promptLower -match "test case|testcase|test cases|kiểm thử|kiem thu|ca kiểm thử|test"
    )
}

function Test-IsTestcaseModificationPrompt {
    param([string]$PromptText)

    if ([string]::IsNullOrWhiteSpace($PromptText)) {
        return $false
    }

    $promptLower = $PromptText.ToLowerInvariant()
    return (
        $promptLower -match "(thay đổi|sửa|đổi|change|modify|update).*(test case|testcase|tc\s*\d+|ai\s*\d+|case\s*\d+)" -or
        $promptLower -match "(test case|testcase|tc\s*\d+|ai\s*\d+|case\s*\d+).*(thay đổi|sửa|đổi|change|modify|update)"
    )
}

function Get-TestcaseModificationTarget {
    param([string]$PromptText)

    $patterns = @(
        'tc\s*(\d+)',
        'ai\s*0*(\d+)',
        '(?:test\s*case|testcase)\s*(?:số|so|#)?\s*(\d+)',
        'case\s*(\d+)',
        'số\s*(\d+)'
    )

    foreach ($pattern in $patterns) {
        $match = [regex]::Match($PromptText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($match.Success) {
            return [int]$match.Groups[1].Value
        }
    }

    return $null
}

function Invoke-TestcaseGeneration {
    param(
        [string]$PromptText,
        [string]$OutputFile,
        [switch]$UseOfflineSample,
        [string]$GeminiApiKey
    )

    $args = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "$PSScriptRoot\generate-ai-testcases.ps1",
        "-OutputFile", $OutputFile,
        "-Prompt", $PromptText
    )

    if ($UseOfflineSample) {
        $args += "-OfflineSample"
    } elseif ($GeminiApiKey) {
        $args += @("-ApiKey", $GeminiApiKey)
    }

    & powershell @args
    return ($LASTEXITCODE -eq 0)
}

function Invoke-TestcaseModification {
    param(
        [string]$PromptText,
        [string]$JsonPath,
        [switch]$UseOfflineSample,
        [string]$GeminiApiKey
    )

    if (-not (Test-Path $JsonPath)) {
        Write-Host "Gemini Assistant: Chưa có file testcase hiện tại để chỉnh sửa." -ForegroundColor Red
        return $false
    }

    $targetIndex = Get-TestcaseModificationTarget -PromptText $PromptText
    if ($null -eq $targetIndex) {
        Write-Host "Gemini Assistant: Tôi chưa xác định được bạn muốn sửa testcase số mấy." -ForegroundColor Red
        return $false
    }

    $currentCases = @(Get-Content $JsonPath -Raw | ConvertFrom-Json | ForEach-Object { $_ })
    if ($targetIndex -lt 1 -or $targetIndex -gt $currentCases.Count) {
        Write-Host "Gemini Assistant: Testcase số $targetIndex không tồn tại. Hiện chỉ có $($currentCases.Count) testcase." -ForegroundColor Red
        return $false
    }

    if ($UseOfflineSample) {
        Write-Host "Gemini Assistant: Chế độ offline sample chưa hỗ trợ AI chỉnh sửa testcase cụ thể. Hãy dùng Gemini real mode để sửa đúng từng case." -ForegroundColor Yellow
        return $false
    }

    $targetCase = $currentCases[$targetIndex - 1]
    $currentJson = $currentCases | ConvertTo-Json -Depth 6
    $differentTypeHint = ""
    if ($PromptText.ToLowerInvariant() -match "loại test khác|test type khác|different test type|another test type|khác loại|other type") {
        $differentTypeHint = "- The modified testcase must use a different testType from the current testcase testType `"$($targetCase.testType)`".`n"
    }
    $systemInstruction = @"
You are editing an existing JSON testcase array for DateTimeChecker.
Return only a JSON array.

Rules:
- Keep exactly $($currentCases.Count) testcase objects.
- Keep the same array order.
- Modify only testcase at array position $targetIndex (1-based), currently id "$($targetCase.id)".
- Keep all other testcase objects unchanged in meaning and keep their current ids.
- The modified testcase must satisfy this user request: "$PromptText"
- Keep the modified testcase id as "$($targetCase.id)".
$differentTypeHint- Current testcase testType is "$($targetCase.testType)".
- Every testcase must include all keys: id, name, testType, day, month, year, expectedValid, expectedResult, expectedDisplay, expectedMessageIncludes, reason.
- If a testcase is for empty input, use empty string values instead of removing keys.
- expectedResult must be one of VALID, INVALID, ERROR.
- Return raw JSON only. No markdown fences. No explanation.
Current testcase array:
$currentJson
"@

    $response = Invoke-GeminiPrompt -apiKey $GeminiApiKey -systemInstruction $systemInstruction -userPrompt $PromptText
    $jsonText = Get-JsonArrayText -Text $response
    if (-not $jsonText) {
        Write-Host "Gemini Assistant: AI không trả về được JSON hợp lệ cho yêu cầu chỉnh sửa." -ForegroundColor Red
        return $false
    }

    try {
        $cases = $jsonText | ConvertFrom-Json
        $normalized = Convert-ChatExactTestcases -Cases $cases -ExpectedCount $currentCases.Count
        Write-Utf8NoBomFile -Path $JsonPath -Content ($normalized | ConvertTo-Json -Depth 6)
        Write-Host "Gemini Assistant: Tôi đã cập nhật testcase số $targetIndex và giữ nguyên các testcase còn lại." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Gemini Assistant: Không thể áp dụng chỉnh sửa testcase: $_" -ForegroundColor Red
        return $false
    }
}

function Show-TestcasePreview {
    param([string]$JsonPath)

    if (-not (Test-Path $JsonPath)) {
        Write-Host "Gemini Assistant: Tôi chưa tìm thấy file testcase để hiển thị." -ForegroundColor Red
        return
    }

    $cases = @(Get-Content $JsonPath -Raw | ConvertFrom-Json | ForEach-Object { $_ })
    if ($cases.Count -eq 0) {
        Write-Host "Gemini Assistant: File testcase đang trống." -ForegroundColor Red
        return
    }

    $previewCases = @()
    $previewIndex = 0
    foreach ($case in $cases) {
        $previewType = [string]$case.testType
        if ([string]::IsNullOrWhiteSpace($previewType)) {
            $previewType = "-"
        }
        $previewCases += [PSCustomObject]@{
            order = $previewIndex
            id = [string]$case.id
            name = [string]$case.name
            testType = $previewType
            day = [string]$case.day
            month = [string]$case.month
            year = [string]$case.year
            expectedResult = [string]$case.expectedResult
        }
        $previewIndex++
    }

    $previewCases = @($previewCases | Sort-Object testType, order)

    Write-Host "Gemini Assistant: Tôi đã sinh $($cases.Count) testcase và preview đang nhóm theo test type cho dễ nhìn." -ForegroundColor Green
    Write-Host "Gemini Assistant: File export vẫn giữ nguyên đúng bộ testcase gốc." -ForegroundColor Green
    Write-Host ""

    $currentType = $null
    foreach ($case in $previewCases) {
        if ($currentType -ne $case.testType) {
            $currentType = $case.testType
            Write-Host ("[Type] {0}" -f $currentType) -ForegroundColor Cyan
            Write-Host ("{0,-6} {1,-26} {2,-14} {3,-10}" -f "ID", "Name", "Input", "Expected") -ForegroundColor Yellow
            Write-Host ("{0,-6} {1,-26} {2,-14} {3,-10}" -f "--", "----", "-----", "--------") -ForegroundColor DarkYellow
        }

        $displayName = [string]$case.name
        if ($displayName.Length -gt 26) {
            $displayName = $displayName.Substring(0, 23) + "..."
        }
        $inputText = "{0}/{1}/{2}" -f ([string]$case.day), ([string]$case.month), ([string]$case.year)
        if ($inputText.Length -gt 14) {
            $inputText = $inputText.Substring(0, 11) + "..."
        }
        Write-Host ("{0,-6} {1,-26} {2,-14} {3,-10}" -f ([string]$case.id), $displayName, $inputText, ([string]$case.expectedResult)) -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Gemini Assistant: Bạn có thể gõ '/export-testcases' để dùng lại đúng file này, hoặc '/run-generated-tests' để chạy đúng bộ này." -ForegroundColor Green
}

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
Write-Host "Lệnh xuất file testcase: /export-testcases" -ForegroundColor Gray
Write-Host "Lệnh chạy testcase từ file: /run-generated-tests" -ForegroundColor Gray
Write-Host "Thoát chương trình: /exit" -ForegroundColor Gray
Write-Host "------------------------------------------------------------"

$script:lastTestingPrompt = "Create JSON test cases for DateTimeChecker covering leap year, month boundary, invalid format, and invalid range."
$script:lastGeneratedPrompt = $null
$script:lastGeneratedTestcaseFile = "$PSScriptRoot\..\reports\ai-generated-testcases.json"
$script:hasActiveGeneratedSet = $false

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
        Write-Host "  /export-testcases - Sinh testcase AI từ prompt gần nhất và lưu thành file JSON" -ForegroundColor White
        Write-Host "  /run-generated-tests - Sinh file testcase từ prompt gần nhất rồi chạy Playwright từ file đó" -ForegroundColor White
        Write-Host "  /exit             - Thoát chương trình" -ForegroundColor White
        Write-Host ""
        Write-Host "Gợi ý prompt demo:" -ForegroundColor Yellow
        Write-Host "  Hãy tạo testcase kiểm thử DateTimeChecker cho ngày nhuận, biên tháng và dữ liệu sai định dạng." -ForegroundColor White
        Write-Host "  Thay đổi test case số 2 sang một boundary case hợp lệ." -ForegroundColor White
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

    if ($userPrompt -eq "/export-testcases") {
        Write-Host ""
        Write-Host "[STEP] Đang sinh testcase và lưu thành file JSON..." -ForegroundColor Yellow
        $outFile = $script:lastGeneratedTestcaseFile
        Write-Host "[INFO] Prompt đang dùng: $script:lastTestingPrompt" -ForegroundColor DarkCyan
        if ($script:hasActiveGeneratedSet -and (Test-Path $outFile)) {
            Write-Host "[INFO] Đang dùng lại đúng bộ testcase đã sinh gần nhất." -ForegroundColor DarkCyan
        } else {
            $ok = Invoke-TestcaseGeneration -PromptText $script:lastTestingPrompt -OutputFile $outFile -UseOfflineSample:$OfflineSample -GeminiApiKey $apiKey
            if ($ok) {
                $script:lastGeneratedPrompt = $script:lastTestingPrompt
                $script:hasActiveGeneratedSet = $true
            }
        }
        Write-Host ""
        continue
    }

    if ($userPrompt -eq "/run-generated-tests") {
        Write-Host ""
        Write-Host "[STEP] Đang sinh file testcase và chạy Playwright từ file đó..." -ForegroundColor Yellow
        Write-Host "[INFO] Prompt đang dùng: $script:lastTestingPrompt" -ForegroundColor DarkCyan
        $runArgs = @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "$PSScriptRoot\run-ai-generated-tests.ps1",
            "-Prompt", $script:lastTestingPrompt,
            "-TestcaseFile", $script:lastGeneratedTestcaseFile
        )
        if ($script:hasActiveGeneratedSet -and (Test-Path $script:lastGeneratedTestcaseFile)) {
            $runArgs += "-SkipGeneration"
        }
        if ($OfflineSample) {
            $runArgs += "-OfflineSample"
        } else {
            $runArgs += @("-ApiKey", $apiKey)
        }
        & powershell @runArgs
        Write-Host ""
        continue
    }

    if ($userPrompt -eq "") {
        continue
    }

    if (Test-IsTestcaseModificationPrompt -PromptText $userPrompt -and $script:hasActiveGeneratedSet -and (Test-Path $script:lastGeneratedTestcaseFile)) {
        Write-Host "[STEP] Gemini Assistant đang cập nhật testcase hiện tại..." -ForegroundColor DarkGray
        Write-Host ""
        $modified = Invoke-TestcaseModification -PromptText $userPrompt -JsonPath $script:lastGeneratedTestcaseFile -UseOfflineSample:$OfflineSample -GeminiApiKey $apiKey
        if ($modified) {
            Show-TestcasePreview -JsonPath $script:lastGeneratedTestcaseFile
        }
        Write-Host ""
        continue
    }

    Write-Host "[STEP] Gemini Assistant đang phân tích yêu cầu..." -ForegroundColor DarkGray
    Write-Host ""
    if ($OfflineSample) {
        if (Test-IsTestcasePrompt -PromptText $userPrompt) {
            $ok = Invoke-TestcaseGeneration -PromptText $userPrompt -OutputFile $script:lastGeneratedTestcaseFile -UseOfflineSample -GeminiApiKey $null
            if ($ok) {
                $script:lastTestingPrompt = $userPrompt
                $script:lastGeneratedPrompt = $userPrompt
                $script:hasActiveGeneratedSet = $true
                Show-TestcasePreview -JsonPath $script:lastGeneratedTestcaseFile
            } else {
                Write-Host "Gemini Assistant: Tôi chưa thể sinh testcase ở chế độ offline lúc này." -ForegroundColor Red
            }
        } else {
            $response = "[OFFLINE MODE] Tôi có thể giúp bạn kiểm thử ứng dụng DateTimeChecker. Trong chế độ Offline Sample, bạn có thể nhập '/demo-self-heal' để xem demo tự động phát hiện lỗi và tự sửa bằng Selenium và AI dựa trên dữ liệu mẫu."
            Write-Host "Gemini Assistant: $response" -ForegroundColor Green
        }
    } else {
        if (Test-IsTestcasePrompt -PromptText $userPrompt) {
            $ok = Invoke-TestcaseGeneration -PromptText $userPrompt -OutputFile $script:lastGeneratedTestcaseFile -UseOfflineSample:$false -GeminiApiKey $apiKey
            if ($ok) {
                $script:lastTestingPrompt = $userPrompt
                $script:lastGeneratedPrompt = $userPrompt
                $script:hasActiveGeneratedSet = $true
                Show-TestcasePreview -JsonPath $script:lastGeneratedTestcaseFile
            } else {
                Write-Host "Gemini Assistant: Tôi chưa thể sinh testcase JSON lúc này. Hãy kiểm tra API key, quota hoặc prompt rồi thử lại." -ForegroundColor Red
            }
        } else {
            $response = Invoke-GeminiPrompt -apiKey $apiKey -systemInstruction $systemInstruction -userPrompt $userPrompt
            if ($response) {
                Write-Host "Gemini Assistant: $response" -ForegroundColor Green
            } else {
                Write-Host "Gemini Assistant: Xin lỗi, tôi chưa thể xử lý yêu cầu lúc này. Hãy kiểm tra API key, quota hoặc kết nối mạng rồi thử lại." -ForegroundColor Red
            }
        }
    }
    Write-Host ""
}
