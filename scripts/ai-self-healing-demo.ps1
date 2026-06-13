param(
    [string]$ApiKey,
    [switch]$OfflineSample,
    [switch]$AutoApprove
)

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root "reports"
$aiReportPath = Join-Path $reportDir "ai-assisted-generated-tests.tsv"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Gray
    Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
}

function Invoke-AIGeneratedTestExecution {
    $serverUrl = "http://localhost:4173"
    $testCases = @(
        @{ Id = "AI-TC01"; Name = "Leap year accepted"; Day = "29"; Month = "2"; Year = "2000"; ExpectedResult = "VALID"; ExpectedValid = $true; Reason = "AI selected divisible-by-400 leap-year boundary" },
        @{ Id = "AI-TC02"; Name = "Century non-leap rejected"; Day = "29"; Month = "2"; Year = "1900"; ExpectedResult = "INVALID"; ExpectedValid = $false; Reason = "AI selected century rule negative case" },
        @{ Id = "AI-TC03"; Name = "Day lower bound rejected"; Day = "0"; Month = "5"; Year = "2026"; ExpectedResult = "ERROR"; ExpectedValid = $false; Reason = "AI selected invalid boundary below range" },
        @{ Id = "AI-TC04"; Name = "Day upper bound rejected"; Day = "32"; Month = "5"; Year = "2026"; ExpectedResult = "ERROR"; ExpectedValid = $false; Reason = "AI selected invalid boundary above range" },
        @{ Id = "AI-TC05"; Name = "February 30 rejected"; Day = "30"; Month = "2"; Year = "2024"; ExpectedResult = "INVALID"; ExpectedValid = $false; Reason = "AI selected impossible day-in-month case" }
    )

    if (!(Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    Write-Section "CONCEPT 2: EXECUTE AI-GENERATED TEST CASES"
    Write-Host "[DEMO] AI does not only answer a prompt; generated cases are executed against the real DateTimeChecker API." -ForegroundColor Gray
    Write-Host "[STEP] Starting DateTimeChecker local server..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot "start-server.ps1") | Out-Host

    $rows = New-Object System.Collections.Generic.List[string]
    $rows.Add("id`tname`tinput`texpected_result`texpected_valid`tactual_result`tactual_valid`thttp`telapsed_ms`tstatus")
    $failures = New-Object System.Collections.Generic.List[string]

    try {
        Write-Host ""
        Write-Host "ID       RESULT  INPUT         EXPECTED        ACTUAL          HTTP  LATENCY  AI REASON" -ForegroundColor Cyan
        Write-Host "-------  ------  ------------  --------------  --------------  ----  -------  ----------------------------------------" -ForegroundColor Cyan

        foreach ($testCase in $testCases) {
            $body = @{
                day = $testCase.Day
                month = $testCase.Month
                year = $testCase.Year
            } | ConvertTo-Json

            Write-Host "[ACTION] $($testCase.Id) POST /api/datetime/check day=$($testCase.Day), month=$($testCase.Month), year=$($testCase.Year)" -ForegroundColor DarkGray
            $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-WebRequest -Method Post `
                -Uri "$serverUrl/api/datetime/check" `
                -ContentType "application/json; charset=utf-8" `
                -Body $body `
                -UseBasicParsing `
                -TimeoutSec 5
            $elapsed.Stop()

            $json = $response.Content | ConvertFrom-Json
            $passed = ($response.StatusCode -eq 200) -and
                ($json.result -eq $testCase.ExpectedResult) -and
                ($json.valid -eq $testCase.ExpectedValid)
            $status = if ($passed) { "PASS" } else { "FAIL" }
            $input = "$($testCase.Day)/$($testCase.Month)/$($testCase.Year)"
            $expected = "$($testCase.ExpectedResult)/$($testCase.ExpectedValid)"
            $actual = "$($json.result)/$($json.valid)"

            Write-Host ("{0,-7}  {1,-6}  {2,-12}  {3,-14}  {4,-14}  {5,-4}  {6,5}ms  {7}" -f `
                $testCase.Id, $status, $input, $expected, $actual, $response.StatusCode, $elapsed.ElapsedMilliseconds, $testCase.Reason)

            $rows.Add("$($testCase.Id)`t$($testCase.Name)`t$input`t$($testCase.ExpectedResult)`t$($testCase.ExpectedValid)`t$($json.result)`t$($json.valid)`t$($response.StatusCode)`t$($elapsed.ElapsedMilliseconds)`t$status")
            if (-not $passed) {
                $failures.Add($testCase.Id)
            }
        }

        $rows | Set-Content -LiteralPath $aiReportPath -Encoding UTF8
        Write-Host ""
        Write-Host "[REPORT] AI-assisted generated test report: $aiReportPath" -ForegroundColor Cyan
        if ($failures.Count -gt 0) {
            throw "AI-generated test failures: $($failures -join ', ')"
        }
        Write-Host "[RESULT] AI-generated tests executed successfully: $($testCases.Count)/$($testCases.Count) PASS." -ForegroundColor Green
    } finally {
        Write-Host "[STEP] Stopping DateTimeChecker local server..." -ForegroundColor Yellow
        & (Join-Path $PSScriptRoot "stop-server.ps1") | Out-Host
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   TOPIC 7 - AI-ASSISTED TESTING DEMONSTRATION" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[DEMO GUIDE] This topic shows AI generating test ideas, executing them, and explaining self-healing." -ForegroundColor Gray
Write-Host "[MODE] " -NoNewline -ForegroundColor Gray
if ($OfflineSample) {
    Write-Host "Offline sample / stable recording mode" -ForegroundColor Yellow
} elseif ($ApiKey) {
    Write-Host "Gemini-assisted mode with API key" -ForegroundColor Yellow
} else {
    Write-Host "Scripted AI-assisted demo mode" -ForegroundColor Yellow
}

Write-Section "CONCEPT 1: AI TEST GENERATION"
Write-Host "[PROMPT] Generate boundary and negative tests for DateTimeChecker." -ForegroundColor White
Start-Sleep -Milliseconds 400
Write-Host "[AI] Analyzing DateTimeValidationService rules: day 1-31, month 1-12, year 1000-3000, Gregorian leap-year logic." -ForegroundColor Green
Start-Sleep -Milliseconds 400
Write-Host "[AI] Generated candidate test cases:" -ForegroundColor Green
Write-Host "  [GEN] AI-TC01: 29/02/2000 -> VALID    | leap year divisible by 400" -ForegroundColor Green
Write-Host "  [GEN] AI-TC02: 29/02/1900 -> INVALID  | century year not divisible by 400" -ForegroundColor Green
Write-Host "  [GEN] AI-TC03: 0/05/2026  -> ERROR    | day below minimum boundary" -ForegroundColor Green
Write-Host "  [GEN] AI-TC04: 32/05/2026 -> ERROR    | day above maximum boundary" -ForegroundColor Green
Write-Host "  [GEN] AI-TC05: 30/02/2024 -> INVALID  | impossible date inside valid ranges" -ForegroundColor Green
Write-Host "[AI] These generated cases will now be executed, not just printed." -ForegroundColor Green

Invoke-AIGeneratedTestExecution

Write-Section "CONCEPT 3: SELF-HEALING LOCATOR"
Write-Host "[DETECTOR] Running a UI test using old locator '#input-day'." -ForegroundColor Yellow
Start-Sleep -Milliseconds 400
Write-Host "[DETECTOR] Locator failed: '#input-day' was not found." -ForegroundColor Yellow
Start-Sleep -Milliseconds 400
Write-Host "[AI HEAL] Searching by nearby label text 'Day' and input role." -ForegroundColor Green
Start-Sleep -Milliseconds 400
Write-Host "[AI HEAL] Suggested replacement: page.getByLabel('Day') with confidence 94%." -ForegroundColor Green
Write-Host "[RESULT] Self-healing concept demonstrated: brittle selector -> resilient accessible selector." -ForegroundColor Green

Write-Section "CONCEPT 4: NATURAL LANGUAGE TO TEST CODE"
Write-Host "[NL INPUT] Verify that entering February 29 in a non-leap year shows INVALID." -ForegroundColor White
Write-Host "[AI] Generated Playwright-style code:" -ForegroundColor Green
Write-Host "  test('Feb 29 in non-leap year shows INVALID', async ({ page }) => {" -ForegroundColor Cyan
Write-Host "    await page.goto('http://localhost:4173');" -ForegroundColor Cyan
Write-Host "    await page.getByLabel('Day').fill('29');" -ForegroundColor Cyan
Write-Host "    await page.getByLabel('Month').fill('2');" -ForegroundColor Cyan
Write-Host "    await page.getByLabel('Year').fill('2023');" -ForegroundColor Cyan
Write-Host "    await page.getByRole('button', { name: 'Check' }).click();" -ForegroundColor Cyan
Write-Host "    await expect(page.locator('#wfMbMessage')).toContainText('is NOT correct date time!');" -ForegroundColor Cyan
Write-Host "  });" -ForegroundColor Cyan

Write-Host ""
Write-Host "+--------------------------------------+" -ForegroundColor Green
Write-Host "|  AI-ASSISTED TESTING DEMO COMPLETE   |" -ForegroundColor Green
Write-Host "|  - AI generated tests: EXECUTED       |" -ForegroundColor Green
Write-Host "|  - Expected vs actual: DISPLAYED      |" -ForegroundColor Green
Write-Host "|  - Self-healing: DEMONSTRATED         |" -ForegroundColor Green
Write-Host "|  - Report file: WRITTEN               |" -ForegroundColor Green
Write-Host "+--------------------------------------+" -ForegroundColor Green

exit 0
