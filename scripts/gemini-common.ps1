# Shared utilities for Gemini AI Assistant integration
$secretsDir = "$PSScriptRoot\..\.secrets"
$keyFile = "$secretsDir\gemini-api-key.txt"

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
    if ($testResult) {
        $inputKey | Out-File $keyFile -Encoding utf8
        Write-Host "[SUCCESS] API Key hợp lệ và đã được lưu!" -ForegroundColor Green
        return $inputKey
    } else {
        Write-Host "[ERROR] API Key không hoạt động hoặc không hợp lệ. Vui lòng kiểm tra lại." -ForegroundColor Red
        exit 1
    }
}

function Test-KeyWithGemini($key) {
    $uri = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key"
    $body = @{
        contents = @(
            @{
                parts = @(
                    @{ text = "Hello" }
                )
            }
        )
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $body -ErrorAction Stop
        if ($response.candidates) {
            return $true
        }
    } catch {
        # Log response detail if needed
    }
    return $false
}

function Invoke-GeminiPrompt($apiKey, $systemInstruction, $userPrompt) {
    $uri = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey"
    
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
        $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json; charset=utf-8" -Body $bodyBytes
        if ($response.candidates.content.parts.text) {
            return $response.candidates.content.parts.text
        }
    } catch {
        Write-Host "[ERROR] Gọi Gemini API thất bại: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "Chi tiết lỗi: $responseBody" -ForegroundColor DarkRed
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
