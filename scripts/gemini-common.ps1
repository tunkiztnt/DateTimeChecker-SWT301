# Shared utilities for Gemini AI Assistant integration
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$secretsDir = "$PSScriptRoot\..\.secrets"
$keyFile = "$secretsDir\gemini-api-key.txt"
$script:GeminiModel = if ($env:GEMINI_MODEL -and $env:GEMINI_MODEL.Trim() -ne "") {
    $env:GEMINI_MODEL.Trim()
} else {
    "gemini-2.5-flash"
}

function Normalize-GeminiApiKey {
    param([string]$Key)
    if (-not $Key) {
        return ""
    }
    return $Key.Trim().Trim('"').Trim("'")
}

function Read-SavedGeminiApiKey {
    if (Test-Path $keyFile) {
        $key = Get-Content -LiteralPath $keyFile -Raw -ErrorAction SilentlyContinue
        return Normalize-GeminiApiKey $key
    }
    return ""
}

function Save-GeminiApiKey {
    param([string]$Key)
    if (!(Test-Path $secretsDir)) {
        New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null
    }
    (Normalize-GeminiApiKey $Key) | Set-Content -LiteralPath $keyFile -Encoding UTF8
}

function Get-GeminiErrorMessage {
    param($ErrorRecord)
    try {
        if ($ErrorRecord.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($ErrorRecord.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            if ($responseBody) {
                return $responseBody
            }
        }
    } catch {
        # Fall back to the exception message below.
    }
    return $ErrorRecord.Exception.Message
}

function Get-FriendlyGeminiError {
    param([string]$Message)
    if (-not $Message) {
        return "Không nhận được chi tiết lỗi từ Gemini API."
    }
    if ($Message -match "API key not valid|API_KEY_INVALID|invalid api key") {
        return "API key không hợp lệ hoặc đã bị thu hồi."
    }
    if ($Message -match "quota|RESOURCE_EXHAUSTED|billing") {
        return "API key hợp lệ nhưng đã hết quota hoặc cần kiểm tra billing/quota."
    }
    if ($Message -match "not found|NOT_FOUND|not supported for generateContent") {
        return "Model đang thử không hỗ trợ generateContent hoặc đã bị Google đổi tên/ngừng hỗ trợ."
    }
    if ($Message -match "PERMISSION_DENIED|permission|disabled") {
        return "Project của API key chưa bật Gemini API hoặc không có quyền gọi model."
    }
    return $Message
}

function Show-GeminiTroubleshootingHint {
    Write-Host "Gợi ý sửa lỗi:" -ForegroundColor Yellow
    Write-Host "  1. Mở https://aistudio.google.com/app/apikey và tạo API key mới." -ForegroundColor Yellow
    Write-Host "  2. Đảm bảo key thuộc project đã bật Gemini API / Generative Language API." -ForegroundColor Yellow
    Write-Host "  3. Nếu key cũ bị lưu sai, chạy Topic 7\reset-gemini-key.bat rồi nhập lại." -ForegroundColor Yellow
    Write-Host "  4. Không nhập model thủ công là gemini-pro vì model này không còn phù hợp với generateContent v1beta." -ForegroundColor Yellow
}

function Get-GeminiModelCandidates {
    param([string]$ApiKey = "")

    $preferredModels = @(
        $script:GeminiModel,
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite",
        "gemini-1.5-flash-latest",
        "gemini-1.5-flash"
    )

    $fallbackModels = New-Object System.Collections.Generic.List[string]
    foreach ($model in $preferredModels) {
        if ($model -and -not $fallbackModels.Contains($model)) {
            $fallbackModels.Add($model)
        }
    }

    if ($ApiKey) {
        try {
            Write-Host "[STEP] Đang lấy danh sách model Gemini hỗ trợ generateContent..." -ForegroundColor Cyan
            $listUri = "https://generativelanguage.googleapis.com/v1beta/models?key=$ApiKey"
            $modelList = Invoke-RestMethod -Uri $listUri -Method Get -ErrorAction Stop
            $apiModels = @($modelList.models | Where-Object {
                $_.supportedGenerationMethods -contains "generateContent"
            } | ForEach-Object {
                $_.name -replace '^models/', ''
            })

            $orderedModels = New-Object System.Collections.Generic.List[string]
            foreach ($model in $preferredModels) {
                if ($apiModels -contains $model -and -not $orderedModels.Contains($model)) {
                    $orderedModels.Add($model)
                }
            }
            foreach ($model in $apiModels) {
                if ($model -and -not $orderedModels.Contains($model)) {
                    $orderedModels.Add($model)
                }
            }

            if ($orderedModels.Count -gt 0) {
                Write-Host "[INFO] Model có thể thử: $($orderedModels -join ', ')" -ForegroundColor Gray
                return $orderedModels
            }
        } catch {
            $message = Get-GeminiErrorMessage $_
            Write-Host "[WARN] Chưa lấy được danh sách model tự động: $(Get-FriendlyGeminiError $message)" -ForegroundColor DarkYellow
            Write-Host "[WARN] Sẽ thử danh sách model mặc định." -ForegroundColor DarkYellow
        }
    }

    return $fallbackModels
}

function Test-KeyWithGemini {
    param([string]$Key)

    $body = @{
        contents = @(
            @{
                parts = @(
                    @{ text = "Hello" }
                )
            }
        )
    } | ConvertTo-Json -Depth 5

    $lastError = $null
    foreach ($model in Get-GeminiModelCandidates -ApiKey $Key) {
        $uri = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=$Key"
        try {
            Write-Host "[STEP] Thử Gemini model: $model" -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ErrorAction Stop
            if ($response.candidates) {
                return [PSCustomObject]@{
                    Success = $true
                    Model = $model
                    ErrorMessage = $null
                }
            }
        } catch {
            $message = Get-GeminiErrorMessage $_
            Write-Host "[WARN] Model $model chưa gọi được: $(Get-FriendlyGeminiError $message)" -ForegroundColor DarkYellow
            $lastError = $message

            if ($message -match "API key not valid|API_KEY_INVALID|PERMISSION_DENIED|permission|disabled") {
                break
            }
        }
    }

    return [PSCustomObject]@{
        Success = $false
        Model = $null
        ErrorMessage = $lastError
    }
}

function Get-GeminiApiKey {
    $savedKey = Read-SavedGeminiApiKey
    if ($savedKey) {
        Write-Host "[STEP] Tìm thấy Gemini API key đã lưu. Đang xác thực lại key và model..." -ForegroundColor Cyan
        $savedTestResult = Test-KeyWithGemini $savedKey
        if ($savedTestResult.Success) {
            $script:GeminiModel = $savedTestResult.Model
            Write-Host "[SUCCESS] API key đã lưu vẫn dùng được." -ForegroundColor Green
            Write-Host "[INFO] Gemini model sẽ dùng: $script:GeminiModel" -ForegroundColor Cyan
            return $savedKey
        }

        Write-Host "[WARN] API key đã lưu không dùng được nữa: $(Get-FriendlyGeminiError $savedTestResult.ErrorMessage)" -ForegroundColor Yellow
        Remove-Item -LiteralPath $keyFile -Force -ErrorAction SilentlyContinue
        Write-Host "[INFO] Đã xóa key cũ, vui lòng nhập key mới." -ForegroundColor Yellow
    }

    if (!(Test-Path $secretsDir)) {
        New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null
    }

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " GEMINI API KEY REQUIRED" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Hãy nhập Gemini API Key của bạn để sử dụng AI Assistant."
    Write-Host "Lưu ý: Key sẽ được lưu tại .secrets/gemini-api-key.txt"
    Write-Host "Bạn có thể lấy key tại: https://aistudio.google.com/app/apikey"
    Write-Host "Model mặc định ưu tiên: $script:GeminiModel (có thể đổi bằng biến môi trường GEMINI_MODEL)"
    Write-Host "------------------------------------------------------------"

    $inputKey = Normalize-GeminiApiKey (Read-Host "Nhập Gemini API Key")

    if ($inputKey -eq "") {
        Write-Host "[ERROR] API Key không được để trống." -ForegroundColor Red
        exit 1
    }

    Write-Host "Đang xác thực API Key với Gemini API..." -ForegroundColor Yellow
    $testResult = Test-KeyWithGemini $inputKey
    if ($testResult.Success) {
        $script:GeminiModel = $testResult.Model
        Save-GeminiApiKey $inputKey
        Write-Host "[SUCCESS] API Key hợp lệ và đã được lưu!" -ForegroundColor Green
        Write-Host "[INFO] Gemini model sẽ dùng: $script:GeminiModel" -ForegroundColor Cyan
        return $inputKey
    }

    Write-Host "[ERROR] API Key chưa gọi được Gemini generateContent." -ForegroundColor Red
    if ($testResult.ErrorMessage) {
        Write-Host "[DETAIL] $(Get-FriendlyGeminiError $testResult.ErrorMessage)" -ForegroundColor DarkYellow
        Write-Host "[RAW] $($testResult.ErrorMessage)" -ForegroundColor DarkGray
    }
    Show-GeminiTroubleshootingHint
    exit 1
}

function Invoke-GeminiPrompt {
    param(
        [string]$apiKey,
        [string]$systemInstruction,
        [string]$userPrompt
    )

    $uri = "https://generativelanguage.googleapis.com/v1beta/models/${script:GeminiModel}:generateContent?key=$apiKey"

    $contents = @(
        @{
            role = "user"
            parts = @(
                @{ text = $userPrompt }
            )
        }
    )

    $payload = @{
        contents = $contents
    }

    if ($systemInstruction) {
        $payload.systemInstruction = @{
            parts = @(
                @{ text = $systemInstruction }
            )
        }
    }

    $payloadJson = ConvertTo-Json -InputObject $payload -Depth 10 -Compress
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json; charset=utf-8" -Body $bodyBytes -ErrorAction Stop
        if ($response.candidates.content.parts.text) {
            return $response.candidates.content.parts.text
        }
    } catch {
        $message = Get-GeminiErrorMessage $_
        Write-Host "[ERROR] Gọi Gemini API thất bại với model $script:GeminiModel." -ForegroundColor Red
        Write-Host "Chi tiết lỗi: $(Get-FriendlyGeminiError $message)" -ForegroundColor DarkRed

        Write-Host "[STEP] Thử tự chọn lại model khác..." -ForegroundColor Yellow
        $testResult = Test-KeyWithGemini $apiKey
        if ($testResult.Success -and $testResult.Model -ne $script:GeminiModel) {
            $script:GeminiModel = $testResult.Model
            Write-Host "[INFO] Đã đổi sang model: $script:GeminiModel. Đang gọi lại..." -ForegroundColor Cyan
            return Invoke-GeminiPrompt -apiKey $apiKey -systemInstruction $systemInstruction -userPrompt $userPrompt
        }
    }
    return $null
}

function Clear-GeminiApiKey {
    if (Test-Path $keyFile) {
        Remove-Item $keyFile -Force
        Write-Host "Đã xóa API Key thành công." -ForegroundColor Green
    } else {
        Write-Host "Không tìm thấy API Key nào để xóa." -ForegroundColor Yellow
    }
}


