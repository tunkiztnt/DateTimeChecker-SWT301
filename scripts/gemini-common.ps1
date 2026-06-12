# Shared utilities for Gemini AI Assistant integration
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

$secretsDir = "$PSScriptRoot\..\.secrets"
$keyFile = "$secretsDir\gemini-api-key.txt"
$script:GeminiModel = if ($env:GEMINI_MODEL -and $env:GEMINI_MODEL.Trim() -ne "") {
    $env:GEMINI_MODEL.Trim()
} else {
    "gemini-2.0-flash"
}

function Get-GeminiModelCandidates {
    $models = New-Object System.Collections.Generic.List[string]
    $models.Add($script:GeminiModel)
    foreach ($model in @("gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-flash-latest", "gemini-pro")) {
        if (-not $models.Contains($model)) {
            $models.Add($model)
        }
    }
    return $models
}

function Get-GeminiApiKey {
    if (Test-Path $keyFile) {
        $key = Get-Content $keyFile
        if ($key -and $key.Trim() -ne "") {
            return $key.Trim()
        }
    }

    if (!(Test-Path $secretsDir)) {
        New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null
    }

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " GEMINI API KEY REQUIRED" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Hãy nhập Gemini API Key của bạn để sử dụng AI Assistant."
    Write-Host "Lưu ý: Key sẽ được lưu bảo mật tại .secrets/gemini-api-key.txt"
    Write-Host "Bạn có thể lấy key miễn phí tại: https://aistudio.google.com/"
    Write-Host "Model mặc định: $script:GeminiModel (có thể đổi bằng biến môi trường GEMINI_MODEL)"
    Write-Host "------------------------------------------------------------"
    
    $inputKey = Read-Host "Nhập Gemini API Key"
    $inputKey = $inputKey.Trim()

    if ($inputKey -eq "") {
        Write-Host "[ERROR] API Key không được để trống." -ForegroundColor Red
        exit 1
    }

    # Test key
    Write-Host "Đang xác thực API Key với Gemini API..." -ForegroundColor Yellow
    $testResult = Test-KeyWithGemini $inputKey
    if ($testResult.Success) {
        $script:GeminiModel = $testResult.Model
        $inputKey | Out-File $keyFile -Encoding utf8
        Write-Host "[SUCCESS] API Key hợp lệ và đã được lưu!" -ForegroundColor Green
        Write-Host "[INFO] Gemini model sẽ dùng: $script:GeminiModel" -ForegroundColor Cyan
        return $inputKey
    } else {
        Write-Host "[ERROR] API Key không hoạt động hoặc không hợp lệ. Vui lòng kiểm tra lại." -ForegroundColor Red
        if ($testResult.ErrorMessage) {
            Write-Host "[DETAIL] $($testResult.ErrorMessage)" -ForegroundColor DarkYellow
        }
        Write-Host "Gợi ý: kiểm tra key trong Google AI Studio, bật Gemini API, kiểm tra quota/billing và thử reset key bằng reset-gemini-key.bat." -ForegroundColor Yellow
        exit 1
    }
}

function Test-KeyWithGemini($key) {
    $body = @{
        contents = @(
            @{
                parts = @(
                    @{ text = "Hello" }
                )
            }
        )
    } | ConvertTo-Json -Depth 5

    foreach ($model in Get-GeminiModelCandidates) {
        $uri = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=$key"
        try {
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
            Write-Host "[WARN] Model $model chưa gọi được: $message" -ForegroundColor DarkYellow
            $lastError = $message
        }
    }

    return [PSCustomObject]@{
        Success = $false
        Model = $null
        ErrorMessage = $lastError
    }
}

function Get-GeminiErrorMessage($errorRecord) {
    try {
        if ($errorRecord.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($errorRecord.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            if ($responseBody) {
                return $responseBody
            }
        }
    } catch {
        # Fall back to the exception message below.
    }
    return $errorRecord.Exception.Message
}

function Invoke-GeminiPrompt($apiKey, $systemInstruction, $userPrompt) {
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

    # Set response schema to JSON if we expect structured output
    $payloadJson = ConvertTo-Json -InputObject $payload -Depth 10 -Compress
    
    # Fix UTF-8 encoding issue for body in PowerShell
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json; charset=utf-8" -Body $bodyBytes -ErrorAction Stop
        if ($response.candidates.content.parts.text) {
            return $response.candidates.content.parts.text
        }
    } catch {
        Write-Host "[ERROR] Gọi Gemini API thất bại: $_" -ForegroundColor Red
        Write-Host "Chi tiết lỗi: $(Get-GeminiErrorMessage $_)" -ForegroundColor DarkRed
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
