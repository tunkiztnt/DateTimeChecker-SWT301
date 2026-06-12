$root = Split-Path -Parent $PSScriptRoot

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " PERFORMANCE TEST - DateTimeChecker API" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[DEMO] This topic measures non-functional quality: speed, stability and error rate under load." -ForegroundColor Gray
Write-Host "[DEMO] Tool: Autocannon via Node.js. Target endpoint: POST /api/check-date." -ForegroundColor Gray

# 1. Call start-server.ps1 first (from scripts/)
Write-Host "[STEP 1] Starting local server..." -ForegroundColor Yellow
& (Join-Path $root "scripts\start-server.ps1")

$perfTestStatus = 0

try {
    # 2. Run autocannon-test.js
    $testScript = Join-Path $PSScriptRoot "benchmark\autocannon-test.js"
    Write-Host "[STEP 2] Running benchmark scenarios..." -ForegroundColor Yellow
    Write-Host "         Smoke:  1 connection, basic health check." -ForegroundColor Gray
    Write-Host "         Load:   10 connections, p99 < 500ms, error rate < 1%." -ForegroundColor Gray
    Write-Host "         Stress: 50 connections, p99 < 2000ms, error rate < 5%." -ForegroundColor Gray
    node $testScript
    $perfTestStatus = $LASTEXITCODE
} finally {
    # 3. Print the contents of the report file
    $reportFile = Join-Path $root "reports\performance-report.txt"
    if (Test-Path $reportFile) {
        Write-Host "`n[STEP 3] PERFORMANCE REPORT CONTENTS" -ForegroundColor Cyan
        Get-Content $reportFile
    } else {
        Write-Host "`n[WARNING] Performance report file not found at $reportFile" -ForegroundColor Yellow
    }

    # 4. Call stop-server.ps1
    Write-Host "[STEP 4] Stopping local server..." -ForegroundColor Yellow
    & (Join-Path $root "scripts\stop-server.ps1")
}

# Exit with status code of autocannon test run
[System.Environment]::Exit($perfTestStatus)
