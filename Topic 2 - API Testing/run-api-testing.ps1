. (Join-Path $PSScriptRoot "..\scripts\common.ps1")

$root = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $root "reports\api-testing-report.tsv"

# Start the server using the shared helper script
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
$exitCode = 0

try {
    Write-Output ""
    Write-Output "[API TEST FLOW]"
    Write-Output "1. Tao JSON body tu du lieu test."
    Write-Output "2. Gui POST request den $serverUrl/api/datetime/check."
    Write-Output "3. Doc HTTP status va JSON response."
    Write-Output "4. So sanh actual valid voi expected valid va nguong 1000 ms."
    Write-Output ""

    foreach ($testCase in $testCases) {
        $body = @{
            day = $testCase.Day
            month = $testCase.Month
            year = $testCase.Year
        } | ConvertTo-Json

        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $input = "$($testCase.Day)/$($testCase.Month)/$($testCase.Year)"
        $response = $null
        $json = $null
        $errorMessage = ""

        try {
            $response = Invoke-WebRequest -Method Post `
                -Uri "$serverUrl/api/datetime/check" `
                -ContentType "application/json; charset=utf-8" `
                -Body $body `
                -UseBasicParsing `
                -TimeoutSec 5
            $json = $response.Content | ConvertFrom-Json
        } catch {
            $errorMessage = $_.Exception.Message
        } finally {
            $elapsed.Stop()
        }

        $statusCode = if ($response) { $response.StatusCode } else { "NO_RESPONSE" }
        $actualValid = if ($json) { $json.valid } else { "N/A" }
        $passed = ($response -ne $null) -and ($response.StatusCode -eq 200) -and ($json.valid -eq $testCase.ExpectedValid) -and ($elapsed.ElapsedMilliseconds -le 1000)
        $result = if ($passed) { "PASS" } else { "FAIL" }

        Write-Output "------------------------------------------------------------"
        Write-Output "[$($testCase.Id)] $($testCase.Name)"
        Write-Output "  Request : POST /api/datetime/check"
        Write-Output "  JSON    : $($body -replace '\s+', ' ')"
        Write-Output "  Expected: HTTP 200, valid=$($testCase.ExpectedValid), time<=1000ms"
        Write-Output "  Actual  : HTTP $statusCode, valid=$actualValid, time=$($elapsed.ElapsedMilliseconds)ms"
        if ($errorMessage) {
            Write-Output "  Error   : $errorMessage"
        }
        Write-Output "  Result  : $result"
        $rows.Add("$($testCase.Id)`t$($testCase.Name)`t$input`t$($testCase.ExpectedValid)`t$actualValid`t$statusCode`t$($elapsed.ElapsedMilliseconds)`t$result")

        if (-not $passed) {
            $failures.Add($testCase.Id)
        }
    }

    $parentDir = Split-Path -Parent $reportPath
    if (!(Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    $rows | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Output ""
    Write-Output "API testing report: $reportPath"

    if ($failures.Count -gt 0) {
        throw "$($failures.Count) API test(s) failed: $($failures -join ', ')"
    }

    Write-Output "All $($testCases.Count) API tests passed."
} catch {
    $exitCode = 1
    Write-Output ""
    Write-Output "[ERROR] API testing failed: $($_.Exception.Message)"
} finally {
    & (Join-Path $root "scripts\stop-server.ps1")
}
[System.Environment]::Exit($exitCode)
