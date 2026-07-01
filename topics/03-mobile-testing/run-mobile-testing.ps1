param(
    [string]$DeviceId = "",
    [switch]$ReuseInstalledApp,
    [switch]$OpenReport,
    [switch]$DebugArtifacts
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$reportRoot = Join-Path $PSScriptRoot "reports\mobile-e2e-report"
$htmlReportPath = Join-Path $reportRoot "index.html"
$jsonReportPath = Join-Path $reportRoot "results.json"
$legacyTextReportPath = Join-Path $PSScriptRoot "reports\mobile-testing-report.txt"
$flowDir = Join-Path $PSScriptRoot "maestro\e2e"
$appId = "com.datetimechecker.date_time_checker"
$userTools = Join-Path $env:USERPROFILE "AndroidTools"
$localTools = Join-Path $repoRoot "tools"
$androidSdk = if (Test-Path -LiteralPath (Join-Path $userTools "android-sdk")) {
    Join-Path $userTools "android-sdk"
} elseif (Test-Path -LiteralPath (Join-Path $localTools "android-sdk")) {
    Join-Path $localTools "android-sdk"
} else {
    Join-Path $env:LOCALAPPDATA "Android\Sdk"
}

$testCases = @(
    [PSCustomObject]@{
        Id = "M-E2E-01"
        Name = "Valid date validation"
        Flow = "01-valid-date.yaml"
        Purpose = "User enters 30/05/2026 and the app must show a valid result."
        Expected = "Valid date and display value 30/05/2026."
    },
    [PSCustomObject]@{
        Id = "M-E2E-02"
        Name = "Invalid non-leap date"
        Flow = "02-invalid-non-leap-date.yaml"
        Purpose = "User enters 29/02/2025 and the app must reject the date."
        Expected = "Invalid date message shows that February 2025 has only 28 days."
    },
    [PSCustomObject]@{
        Id = "M-E2E-03"
        Name = "Leap year date"
        Flow = "03-leap-year-date.yaml"
        Purpose = "User enters 29/02/2024 and the app must accept leap-day input."
        Expected = "Valid date and display value 29/02/2024."
    },
    [PSCustomObject]@{
        Id = "M-E2E-04"
        Name = "Clear form reset"
        Flow = "04-clear-form.yaml"
        Purpose = "User enters data, taps Clear, and the app must return to the empty state."
        Expected = "Waiting for validation is visible after clearing the form."
    }
)

function Resolve-CommandPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Candidates = @()
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($candidate in $Candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function ConvertTo-HtmlText {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode($Value.ToString())
}

function Get-FirstConnectedDevice {
    param([string]$AdbPath)

    if (-not $AdbPath) {
        return ""
    }

    try {
        $devicesOutput = & $AdbPath devices 2>$null
        $deviceLine = @($devicesOutput | Where-Object { $_ -match "`tdevice$" } | Select-Object -First 1)
        if ($deviceLine.Count -gt 0) {
            return (($deviceLine[0] -split "`t")[0]).Trim()
        }
    } catch {
        return ""
    }

    return ""
}

function New-MobileReport {
    param(
        [object[]]$Results,
        [DateTime]$StartedAt,
        [DateTime]$FinishedAt,
        [string]$SelectedDeviceId,
        [string]$MaestroPath
    )

    if (-not (Test-Path -LiteralPath $reportRoot)) {
        New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
    }

    $passed = @($Results | Where-Object { $_.Status -eq "PASS" }).Count
    $failed = @($Results | Where-Object { $_.Status -eq "FAIL" }).Count
    $total = @($Results).Count
    $finalStatus = if ($failed -eq 0) { "PASS" } else { "FAIL" }
    $duration = [Math]::Round(($FinishedAt - $StartedAt).TotalSeconds, 2)

    $json = [PSCustomObject]@{
        topic = "Topic 3 Mobile E2E Testing"
        appId = $appId
        deviceId = $SelectedDeviceId
        tool = "Maestro"
        maestro = $MaestroPath
        startedAt = $StartedAt.ToString("yyyy-MM-dd HH:mm:ss")
        finishedAt = $FinishedAt.ToString("yyyy-MM-dd HH:mm:ss")
        durationSeconds = $duration
        finalStatus = $finalStatus
        total = $total
        passed = $passed
        failed = $failed
        results = $Results
    }
    $json | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonReportPath -Encoding UTF8

    $rows = foreach ($result in $Results) {
        $statusClass = if ($result.Status -eq "PASS") { "pass" } else { "fail" }
        @"
        <tr>
          <td><strong>$(ConvertTo-HtmlText $result.Id)</strong></td>
          <td>$(ConvertTo-HtmlText $result.Name)</td>
          <td>$(ConvertTo-HtmlText $result.Purpose)</td>
          <td>$(ConvertTo-HtmlText $result.Expected)</td>
          <td><span class="badge $statusClass">$(ConvertTo-HtmlText $result.Status)</span></td>
          <td>$($result.DurationSeconds)s</td>
        </tr>
"@
    }

    $details = foreach ($result in $Results) {
        $statusClass = if ($result.Status -eq "PASS") { "pass" } else { "fail" }
        $output = ConvertTo-HtmlText (($result.Output -join [Environment]::NewLine).Trim())
        @"
        <details>
          <summary><span class="badge $statusClass">$(ConvertTo-HtmlText $result.Status)</span> $(ConvertTo-HtmlText $result.Id) - $(ConvertTo-HtmlText $result.Name)</summary>
          <pre>$output</pre>
        </details>
"@
    }

    $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Topic 3 Mobile E2E Report</title>
  <style>
    :root {
      --bg: #f5f7fb;
      --card: #ffffff;
      --line: #d9e1ee;
      --text: #182033;
      --muted: #637083;
      --pass: #137333;
      --pass-bg: #e7f5ec;
      --fail: #b3261e;
      --fail-bg: #fce8e6;
      --brand: #3159e8;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 32px;
      background: var(--bg);
      color: var(--text);
      font-family: Inter, Segoe UI, Arial, sans-serif;
    }
    .shell { max-width: 1180px; margin: 0 auto; }
    .hero, .card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 18px;
      box-shadow: 0 18px 45px rgba(21, 35, 62, 0.08);
    }
    .hero { padding: 28px; margin-bottom: 22px; }
    .card { padding: 22px; margin-bottom: 22px; }
    h1 { margin: 0 0 8px; font-size: 30px; }
    h2 { margin: 0 0 16px; font-size: 20px; }
    p { color: var(--muted); line-height: 1.55; }
    .summary { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px; margin-top: 20px; }
    .metric { border: 1px solid var(--line); border-radius: 14px; padding: 16px; background: #fbfcff; }
    .metric span { display: block; color: var(--muted); font-size: 13px; margin-bottom: 7px; }
    .metric strong { font-size: 24px; }
    table { width: 100%; border-collapse: collapse; overflow: hidden; border-radius: 12px; }
    th, td { padding: 13px 12px; border-bottom: 1px solid var(--line); text-align: left; vertical-align: top; }
    th { background: #eef3ff; color: #26324a; font-size: 13px; }
    td { font-size: 14px; }
    .badge { display: inline-flex; align-items: center; border-radius: 999px; padding: 5px 10px; font-size: 12px; font-weight: 800; letter-spacing: 0.02em; }
    .badge.pass { color: var(--pass); background: var(--pass-bg); }
    .badge.fail { color: var(--fail); background: var(--fail-bg); }
    details { border: 1px solid var(--line); border-radius: 14px; padding: 14px 16px; margin-bottom: 12px; background: #fbfcff; }
    summary { cursor: pointer; font-weight: 700; }
    pre { white-space: pre-wrap; overflow-wrap: anywhere; color: #dce6ff; background: #111827; border-radius: 12px; padding: 14px; line-height: 1.45; }
    code { background: #eef3ff; padding: 2px 6px; border-radius: 6px; }
    .status-line { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
  </style>
</head>
<body>
  <main class="shell">
    <section class="hero">
      <div class="status-line">
        <span class="badge $($finalStatus.ToLowerInvariant())">$finalStatus</span>
        <span>Topic 3 - Mobile E2E Testing</span>
      </div>
      <h1>DateTimeChecker Android E2E Report</h1>
      <p>Report này giống hướng E2E trên PC: mỗi case có mục tiêu, expected result, trạng thái pass/fail, thời gian chạy và log chi tiết. Runner không build lại APK và không kiểm tra môi trường dài dòng; nó chạy trực tiếp trên app đã cài sẵn.</p>
      <div class="summary">
        <div class="metric"><span>Total cases</span><strong>$total</strong></div>
        <div class="metric"><span>Passed</span><strong>$passed</strong></div>
        <div class="metric"><span>Failed</span><strong>$failed</strong></div>
        <div class="metric"><span>Duration</span><strong>${duration}s</strong></div>
      </div>
    </section>

    <section class="card">
      <h2>Run Information</h2>
      <p><strong>App ID:</strong> <code>$(ConvertTo-HtmlText $appId)</code></p>
      <p><strong>Device:</strong> <code>$(ConvertTo-HtmlText $(if ($SelectedDeviceId) { $SelectedDeviceId } else { "Auto selected by Maestro" }))</code></p>
      <p><strong>Started:</strong> $(ConvertTo-HtmlText $StartedAt.ToString("yyyy-MM-dd HH:mm:ss"))</p>
      <p><strong>Finished:</strong> $(ConvertTo-HtmlText $FinishedAt.ToString("yyyy-MM-dd HH:mm:ss"))</p>
    </section>

    <section class="card">
      <h2>Mobile E2E Cases</h2>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Case</th>
            <th>Purpose</th>
            <th>Expected</th>
            <th>Status</th>
            <th>Time</th>
          </tr>
        </thead>
        <tbody>
          $($rows -join [Environment]::NewLine)
        </tbody>
      </table>
    </section>

    <section class="card">
      <h2>Execution Logs</h2>
      $($details -join [Environment]::NewLine)
    </section>
  </main>
</body>
</html>
"@

    $html | Set-Content -LiteralPath $htmlReportPath -Encoding UTF8

    $textLines = @(
        "Topic 3 Mobile E2E Testing Report",
        "==================================",
        "Final status: $finalStatus",
        "Started: $($StartedAt.ToString("yyyy-MM-dd HH:mm:ss"))",
        "Finished: $($FinishedAt.ToString("yyyy-MM-dd HH:mm:ss"))",
        "Duration: ${duration}s",
        "Device: $(if ($SelectedDeviceId) { $SelectedDeviceId } else { "Auto selected by Maestro" })",
        "HTML report: $htmlReportPath",
        "JSON report: $jsonReportPath",
        "",
        "Cases:"
    )

    foreach ($result in $Results) {
        $textLines += "- $($result.Id) $($result.Name): $($result.Status) ($($result.DurationSeconds)s)"
    }

    $textLines | Set-Content -LiteralPath $legacyTextReportPath -Encoding UTF8
}

function Invoke-MobileE2ECase {
    param(
        [object]$Case,
        [string]$MaestroPath
    )

    $flowPath = Join-Path $flowDir $Case.Flow
    if (-not (Test-Path -LiteralPath $flowPath)) {
        throw "Flow file not found: $flowPath"
    }

    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " $($Case.Id) - $($Case.Name)" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "Purpose : $($Case.Purpose)" -ForegroundColor Gray
    Write-Host "Expected: $($Case.Expected)" -ForegroundColor Gray

    $caseStart = Get-Date
    $output = @()
    $status = "PASS"
    $maestroArgs = @(
        "test",
        "--no-ansi",
        "--no-reinstall-driver",
        "--format",
        "NOOP"
    )

    if ($DebugArtifacts) {
        $debugOutputDir = Join-Path $reportRoot ("debug\" + $Case.Id)
        $maestroArgs += @(
            "--debug-output",
            $debugOutputDir,
            "--flatten-debug-output"
        )
    }

    if ($DeviceId) {
        $maestroArgs += @("--udid", $DeviceId)
    }

    $maestroArgs += $flowPath

    try {
        $output = @(& $MaestroPath @maestroArgs 2>&1 | ForEach-Object { $_.ToString() })
        $exitCode = $LASTEXITCODE
        $output | ForEach-Object { Write-Host $_ }

        if ($exitCode -ne 0) {
            $status = "FAIL"
            $output += "Maestro exit code: $exitCode"
            if ($output.Count -eq 1) {
                $output += "No detailed Maestro output was returned. Check device connection, installed app, and flow selectors."
            }
        }
    } catch {
        $status = "FAIL"
        $output += $_.Exception.Message
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    $caseEnd = Get-Date
    $duration = [Math]::Round(($caseEnd - $caseStart).TotalSeconds, 2)

    if ($status -eq "PASS") {
        Write-Host "[PASS] $($Case.Id) completed in ${duration}s" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $($Case.Id) failed in ${duration}s" -ForegroundColor Red
    }

    return [PSCustomObject]@{
        Id = $Case.Id
        Name = $Case.Name
        Flow = $Case.Flow
        Purpose = $Case.Purpose
        Expected = $Case.Expected
        Status = $status
        DurationSeconds = $duration
        Output = $output
    }
}

if (Test-Path -LiteralPath $androidSdk) {
    $env:ANDROID_HOME = $androidSdk
    $env:ANDROID_SDK_ROOT = $androidSdk
    $env:Path = @(
        (Join-Path $androidSdk "platform-tools"),
        (Join-Path $androidSdk "emulator"),
        (Join-Path $androidSdk "cmdline-tools\latest\bin"),
        $env:Path
    ) -join ";"
}

$env:ANDROID_SDK_HOME = $env:USERPROFILE
$env:ANDROID_AVD_HOME = Join-Path $env:USERPROFILE ".android\avd"
$env:HOME = $env:USERPROFILE
$env:MAESTRO_CLI_NO_ANALYTICS = "1"
$env:MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED = "true"
$env:JAVA_TOOL_OPTIONS = $null

$adb = Resolve-CommandPath "adb-not-from-path" @(
    (Join-Path $androidSdk "platform-tools\adb.exe"),
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
)

$maestro = Resolve-CommandPath "maestro" @(
    "$env:USERPROFILE\.maestro\bin\maestro.bat",
    "$env:USERPROFILE\.maestro\bin\maestro"
)

if (-not $DeviceId) {
    $DeviceId = Get-FirstConnectedDevice -AdbPath $adb
}

if ($DeviceId) {
    $env:ANDROID_SERIAL = $DeviceId
}

if (Test-Path -LiteralPath $reportRoot) {
    Remove-Item -LiteralPath $reportRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $legacyTextReportPath) | Out-Null

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TOPIC 3 - MOBILE E2E TESTING" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Mode       : Fast demo runner - no Flutter build, no reinstall, no mock fallback" -ForegroundColor Yellow
Write-Host "Speed      : --no-reinstall-driver, minimal assertions, debug artifacts off" -ForegroundColor Yellow
Write-Host "App ID     : $appId" -ForegroundColor Yellow
Write-Host "Device     : $(if ($DeviceId) { $DeviceId } else { "Auto selected by Maestro" })" -ForegroundColor Yellow
Write-Host "Report HTML: $htmlReportPath" -ForegroundColor Yellow

$startedAt = Get-Date
$results = New-Object System.Collections.Generic.List[object]

try {
    if (-not $maestro) {
        throw "Maestro CLI not found. Install it once with topics\03-mobile-testing\install-maestro-free.ps1."
    }

    foreach ($testCase in $testCases) {
        $results.Add((Invoke-MobileE2ECase -Case $testCase -MaestroPath $maestro)) | Out-Null
    }
} catch {
    Write-Host "[FAIL] Mobile E2E runner failed: $($_.Exception.Message)" -ForegroundColor Red
    $results.Add([PSCustomObject]@{
        Id = "M-E2E-00"
        Name = "Runner startup"
        Flow = ""
        Purpose = "Start mobile E2E automation."
        Expected = "Maestro can run flows against the installed Android app."
        Status = "FAIL"
        DurationSeconds = 0
        Output = @($_.Exception.Message)
    }) | Out-Null
} finally {
    $finishedAt = Get-Date
    New-MobileReport -Results @($results.ToArray()) -StartedAt $startedAt -FinishedAt $finishedAt -SelectedDeviceId $DeviceId -MaestroPath $maestro
}

$failedCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " MOBILE E2E REPORTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "HTML report : $htmlReportPath" -ForegroundColor Green
Write-Host "JSON report : $jsonReportPath" -ForegroundColor Green
Write-Host "Text summary: $legacyTextReportPath" -ForegroundColor Green

if ($OpenReport -and (Test-Path -LiteralPath $htmlReportPath)) {
    Start-Process $htmlReportPath
}

if ($failedCount -gt 0) {
    exit 1
}

exit 0
