. (Join-Path $PSScriptRoot "..\scripts\common.ps1")

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

$root = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $root "reports\api-testing-report.tsv"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " API INTEGRATION TEST - POST /api/datetime/check" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[DEMO] This script sends real HTTP POST requests to the local Java server." -ForegroundColor Gray
Write-Host "[DEMO] PASS criteria: HTTP 200, expected valid flag, and latency <= 1000 ms." -ForegroundColor Gray

# Start the server using the shared helper script
Write-Host "[STEP 1] Starting local server..." -ForegroundColor Yellow
& (Join-Path $root "scripts\start-server.ps1")
$serverUrl = "http://localhost:4173"

$testCases = @(
    @{ Id = "API01"; Name = "Valid date"; Day = "30"; Month = "5"; Year = "2026"; ExpectedValid = $true },
    @{ Id = "API02"; Name = "Invalid day in month"; Day = "31"; Month = "4"; Year = "2026"; ExpectedValid = $false },
    @{ Id = "API03"; Name = "Leap year valid"; Day = "29"; Month = "2"; Year = "2024"; ExpectedValid = $true },
    @{ Id = "API04"; Name = "Non-leap year invalid"; Day = "29"; Month = "2"; Year = "2025"; ExpectedValid = $false },
    @{ Id = "API05"; Name = "Day below range"; Day = "0"; Month = "5"; Year = "2026"; ExpectedValid = $false },
    @{ Id = "API06"; Name = "Month above range"; Day = "30"; Month = "13"; Year = "2026"; ExpectedValid = $false },
    @{ Id = "API07"; Name = "Year below range"; Day = "30"; Month = "5"; Year = "999"; ExpectedValid = $false },
    @{ Id = "API08"; Name = "Year above range"; Day = "30"; Month = "5"; Year = "3001"; ExpectedValid = $false },
    @{ Id = "API09"; Name = "Day is not a number"; Day = "abc"; Month = "5"; Year = "2026"; ExpectedValid = $false },
    @{ Id = "API10"; Name = "Month is decimal"; Day = "30"; Month = "5.5"; Year = "2026"; ExpectedValid = $false }
)

$rows = New-Object System.Collections.Generic.List[string]
$rows.Add("id`tname`tinput`texpected_valid`tactual_valid`tstatus_code`telapsed_ms`tresult")
$failures = New-Object System.Collections.Generic.List[string]

try {
    Write-Host "[STEP 2] Sending $($testCases.Count) API requests..." -ForegroundColor Yellow
    Write-Host "ID    RESULT  INPUT         EXPECTED  ACTUAL  HTTP  LATENCY  PURPOSE" -ForegroundColor Cyan
    Write-Host "----  ------  ------------  --------  ------  ----  -------  ------------------------------" -ForegroundColor Cyan

    foreach ($testCase in $testCases) {
        $body = @{
            day = $testCase.Day
            month = $testCase.Month
            year = $testCase.Year
        } | ConvertTo-Json

        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Method Post `
            -Uri "$serverUrl/api/datetime/check" `
            -ContentType "application/json; charset=utf-8" `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 5
        $elapsed.Stop()

        $json = $response.Content | ConvertFrom-Json
        $passed = ($response.StatusCode -eq 200) -and ($json.valid -eq $testCase.ExpectedValid) -and ($elapsed.ElapsedMilliseconds -le 1000)
        $result = if ($passed) { "PASS" } else { "FAIL" }
        $input = "$($testCase.Day)/$($testCase.Month)/$($testCase.Year)"

        $expected = if ($testCase.ExpectedValid) { "true " } else { "false" }
        $actual = if ($json.valid) { "true " } else { "false" }
        Write-Host ("{0,-4}  {1,-6}  {2,-12}  {3,-8}  {4,-6}  {5,-4}  {6,5}ms  {7}" -f `
            $testCase.Id, $result, $input, $expected, $actual, $response.StatusCode, $elapsed.ElapsedMilliseconds, $testCase.Name)
        $rows.Add("$($testCase.Id)`t$($testCase.Name)`t$input`t$($testCase.ExpectedValid)`t$($json.valid)`t$($response.StatusCode)`t$($elapsed.ElapsedMilliseconds)`t$result")

        if (-not $passed) {
            $failures.Add($testCase.Id)
        }
    }

    $parentDir = Split-Path -Parent $reportPath
    if (!(Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    $rows | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Host ""
    Write-Host "[STEP 3] API testing report: $reportPath" -ForegroundColor Cyan

    if ($failures.Count -gt 0) {
        throw "$($failures.Count) API test(s) failed: $($failures -join ', ')"
    }

    Write-Host "[PASS] All $($testCases.Count) API tests passed." -ForegroundColor Green
} finally {
    Write-Host "[STEP 4] Stopping local server..." -ForegroundColor Yellow
    & (Join-Path $root "scripts\stop-server.ps1")
}
[System.Environment]::Exit(0)
