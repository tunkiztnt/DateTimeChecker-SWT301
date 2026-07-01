. "$PSScriptRoot\..\..\scripts\common.ps1"

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$topicRoot = (Resolve-Path $PSScriptRoot).Path
$nodeScript = Join-Path $topicRoot "node-perf-run.js"
$reportDir = Join-Path $repoRoot "topics\reports"
$reportPath = Join-Path $reportDir "performance-testing-report.txt"

if (-not $env:PERF_CONCURRENCY) {
    $env:PERF_CONCURRENCY = "10"
}
if (-not $env:PERF_DURATION_MS) {
    $env:PERF_DURATION_MS = "5000"
}
if (-not $env:PERF_LIVE_INTERVAL_MS) {
    $env:PERF_LIVE_INTERVAL_MS = "1000"
}

function Resolve-NodeCommand {
    $command = Get-Command node -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    throw "Node.js was not found. Please install Node.js or add it to PATH."
}

function Convert-ToPlainTextLines {
    param(
        [string[]]$Lines
    )

    return @(
        $Lines | ForEach-Object {
            if ($null -eq $_) {
                ""
            } else {
                ([string]$_) -replace '\x1B\[[0-9;]*[A-Za-z]', ''
            }
        }
    )
}

function Wait-ForServerReady {
    param(
        [int]$TimeoutSeconds = 20
    )

    for ($attempt = 0; $attempt -lt $TimeoutSeconds; $attempt++) {
        try {
            $response = Invoke-WebRequest `
                -Uri "http://localhost:4173/api/datetime/check" `
                -Method POST `
                -Body '{"day":"1","month":"1","year":"2024"}' `
                -ContentType "application/json" `
                -UseBasicParsing `
                -TimeoutSec 2

            if ($response.StatusCode -eq 200) {
                return $true
            }
        } catch {
            Start-Sleep -Seconds 1
        }
    }

    return $false
}

function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [string[]]$Arguments = @(),

        [string]$WorkingDirectory = ""
    )

    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Cyan

    $previousLocation = Get-Location
    try {
        if ($WorkingDirectory) {
            Set-Location -LiteralPath $WorkingDirectory
        }

        $capturedOutput = New-Object System.Collections.Generic.List[string]
        & $FilePath $Arguments 2>&1 | ForEach-Object {
            $text = $_.ToString()
            $capturedOutput.Add($text)
            Write-Host $text
        }

        if ($LASTEXITCODE -ne 0) {
            throw "$Title failed with exit code $LASTEXITCODE."
        }

        return @($capturedOutput.ToArray())
    } finally {
        Set-Location -LiteralPath $previousLocation
    }
}

if (-not (Test-Path -LiteralPath $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$log = New-Object System.Collections.Generic.List[string]
$log.Add("Performance Testing Report")
$log.Add("==========================")
$log.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')")
$log.Add("Target: http://localhost:4173/api/datetime/check")
$log.Add("")

$serverProcess = $null
$exitCode = 0

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TOPIC 4 - PERFORMANCE TESTING" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[STEP 1/4] Compile Java backend." -ForegroundColor Yellow
Write-Host "[STEP 2/4] Start backend server and wait until it is ready." -ForegroundColor Yellow
Write-Host "[STEP 3/4] Run concurrent performance test." -ForegroundColor Yellow
Write-Host "[STEP 4/4] Save report and stop server." -ForegroundColor Yellow
Write-Host "[CONFIG] Concurrency: $($env:PERF_CONCURRENCY) workers | Duration: $([int]$env:PERF_DURATION_MS / 1000)s | Live interval: $([int]$env:PERF_LIVE_INTERVAL_MS / 1000)s" -ForegroundColor Gray

try {
    Stop-RunningServer -Port 4173

    $buildOutput = Invoke-LoggedCommand `
        -Title "Build Java backend" `
        -FilePath "powershell" `
        -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ".\scripts\build.ps1") `
        -WorkingDirectory $repoRoot
    $log.Add("Build:")
    $log.AddRange([string[]](Convert-ToPlainTextLines -Lines $buildOutput))
    $log.Add("")

    $tools = Get-JavaTools
    $node = Resolve-NodeCommand

    Write-Host ""
    Write-Host "== Start backend server ==" -ForegroundColor Cyan
    $serverProcess = Start-Process `
        -FilePath $tools.Java `
        -ArgumentList @("-cp", (Join-Path $repoRoot "out\classes"), "com.datetimechecker.App") `
        -WorkingDirectory $repoRoot `
        -PassThru `
        -WindowStyle Hidden
    Write-Host "Server PID: $($serverProcess.Id)"
    $log.Add("Server PID: $($serverProcess.Id)")
    $log.Add("")

    if (-not (Wait-ForServerReady)) {
        throw "Backend server did not become ready on http://localhost:4173."
    }

    Write-Host "[SERVER READY] http://localhost:4173" -ForegroundColor Green
    $log.Add("Server status: READY")
    $log.Add("")

    $env:PERF_REPORT_PATH = $reportPath
    $perfOutput = Invoke-LoggedCommand `
        -Title "Run performance test" `
        -FilePath $node `
        -Arguments @($nodeScript) `
        -WorkingDirectory $repoRoot
    $log.Add("Performance test:")
    $log.AddRange([string[]](Convert-ToPlainTextLines -Lines $perfOutput))
    $log.Add("")

    Write-Host ""
    Write-Host "[PASS] Topic 4 performance testing completed successfully." -ForegroundColor Green
} catch {
    $exitCode = 1
    $log.Add("Result: FAIL")
    $log.Add("Error: $($_.Exception.Message)")
    Write-Host ""
    Write-Host "[FAIL] Topic 4 performance testing failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
} finally {
    Remove-Item Env:PERF_REPORT_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:PERF_LIVE_INTERVAL_MS -ErrorAction SilentlyContinue
    Remove-Item Env:PERF_DURATION_MS -ErrorAction SilentlyContinue
    Remove-Item Env:PERF_CONCURRENCY -ErrorAction SilentlyContinue

    if ($serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }

    try {
        powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\stop-server.ps1" | Out-Null
    } catch {
    }

    if (-not ($log -contains "Result: FAIL")) {
        $log.Add("Result: PASS")
    }
    $log | Set-Content -LiteralPath $reportPath -Encoding UTF8

    Write-Host ""
    Write-Host "Performance report: $reportPath"
}

exit $exitCode
