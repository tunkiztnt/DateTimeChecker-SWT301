# Shared utilities for Gemini AI Assistant integration
$secretsDir = "$PSScriptRoot\..\.secrets"
$keyFile = "$secretsDir\gemini-api-key.txt"
$geminiModel = if ($env:GEMINI_MODEL) { $env:GEMINI_MODEL } else { "gemini-2.5-flash" }
$script:GeminiLastError = $null

function Get-GeminiErrorDetail($errorRecord) {
    try {
        if ($errorRecord.ErrorDetails -and $errorRecord.ErrorDetails.Message) {
            $errorJson = $errorRecord.ErrorDetails.Message | ConvertFrom-Json
            if ($errorJson.error.message) {
                return $errorJson.error.message
            }
        }

        if ($errorRecord.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($errorRecord.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            if ($responseBody) {
                $errorJson = $responseBody | ConvertFrom-Json
                if ($errorJson.error.message) {
                    return $errorJson.error.message
                }
                return $responseBody
            }
        }
    } catch {
        # Fall back to the PowerShell exception message below.
    }

    return $errorRecord.Exception.Message
}

function Get-GeminiHeaders($key) {
    return @{
        "x-goog-api-key" = $key
    }
}

function Read-StoredGeminiApiKey {
    if (-not (Test-Path $keyFile)) {
        return $null
    }

    $storedValue = (Get-Content $keyFile -Raw).Trim()
    if (-not $storedValue) {
        return $null
    }

    try {
        $secureKey = $storedValue | ConvertTo-SecureString
        return (New-Object System.Net.NetworkCredential("", $secureKey)).Password
    } catch {
        # Compatibility with older versions that stored the key as plain text.
        return $storedValue
    }
}

function Save-GeminiApiKey($key) {
    $secureKey = ConvertTo-SecureString $key -AsPlainText -Force
    $secureKey | ConvertFrom-SecureString | Set-Content $keyFile -Encoding utf8
}

function Get-GeminiApiKey {
    $key = Read-StoredGeminiApiKey
    if ($key) {
        return $key
    }

    if (!(Test-Path $secretsDir)) {
        New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null
    }

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " GEMINI API KEY REQUIRED" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Hãy nhập Gemini API Key của bạn để sử dụng AI Assistant."
    Write-Host "Lưu ý: Key sẽ được mã hóa bằng tài khoản Windows hiện tại và lưu tại .secrets/gemini-api-key.txt"
    Write-Host "Bạn có thể lấy key tại: https://aistudio.google.com/app/apikey"
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
        Save-GeminiApiKey $inputKey
        Write-Host "[SUCCESS] API Key hợp lệ và đã được lưu!" -ForegroundColor Green
        return $inputKey
    } else {
        Write-Host "[ERROR] Gemini API không chấp nhận yêu cầu." -ForegroundColor Red
        Write-Host "Chi tiết: $script:GeminiLastError" -ForegroundColor DarkRed
        exit 1
    }
}

function Test-KeyWithGemini($key) {
    $script:GeminiLastError = $null
    $uri = "https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent"
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
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers (Get-GeminiHeaders $key) -ContentType "application/json" -Body $body -ErrorAction Stop
        if ($response.candidates) {
            return $true
        }
    } catch {
        $script:GeminiLastError = Get-GeminiErrorDetail $_
    }
    return $false
}

function Invoke-GeminiPrompt($apiKey, $systemInstruction, $userPrompt) {
    $uri = "https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent"
    
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
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers (Get-GeminiHeaders $apiKey) -ContentType "application/json; charset=utf-8" -Body $bodyBytes -ErrorAction Stop
        if ($response.candidates.content.parts.text) {
            return $response.candidates.content.parts.text
        }
    } catch {
        $errorDetail = Get-GeminiErrorDetail $_
        Write-Host "[ERROR] Gọi Gemini API thất bại." -ForegroundColor Red
        Write-Host "Chi tiết: $errorDetail" -ForegroundColor DarkRed
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
