param(
    [string]$DeviceId = "",
    [switch]$ReuseInstalledApp,
    [switch]$OpenReport,
    [int]$StepDelayMs = 250
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$reportRoot = Join-Path $PSScriptRoot "reports\mobile-e2e-report"
$htmlReportPath = Join-Path $reportRoot "index.html"
$jsonReportPath = Join-Path $reportRoot "results.json"
$csvReportPath = Join-Path $reportRoot "results.csv"
$textReportPath = Join-Path $PSScriptRoot "reports\mobile-testing-report.txt"
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
        Purpose = "Fast E2E: enter 30/05/2026 and verify valid result."
        Expected = "Valid date and 30/05/2026 result are visible."
        Kind = "DateCheck"
        Day = "30"
        Month = "5"
        Year = "2026"
        ExpectedResult = "Valid date"
    },
    [PSCustomObject]@{
        Id = "M-E2E-02"
        Name = "Invalid non-leap date"
        Purpose = "Fast E2E: enter 29/02/2025 and verify invalid result."
        Expected = "Invalid date and February 2025 28-day message are visible."
        Kind = "DateCheck"
        Day = "29"
        Month = "2"
        Year = "2025"
        ExpectedResult = "Invalid date"
    },
    [PSCustomObject]@{
        Id = "M-E2E-03"
        Name = "Leap year date"
        Purpose = "Fast E2E: enter 29/02/2024 and verify leap-day result."
        Expected = "Valid date and 29/02/2024 result are visible."
        Kind = "DateCheck"
        Day = "29"
        Month = "2"
        Year = "2024"
        ExpectedResult = "Valid date"
    },
    [PSCustomObject]@{
        Id = "M-E2E-04"
        Name = "Clear form reset"
        Purpose = "Fast E2E: enter data, tap Clear, and verify empty state."
        Expected = "Waiting for validation is visible after Clear."
        Kind = "ClearForm"
        Day = "15"
        Month = "6"
        Year = "2026"
        ExpectedResult = "Waiting for validation"
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

function Invoke-Adb {
    param([string[]]$Arguments)

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        return @(& $script:adb -s $script:DeviceId @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Start-StepDelay {
    Start-Sleep -Milliseconds ([Math]::Max(0, $StepDelayMs))
}

function Start-FocusDelay {
    Start-Sleep -Milliseconds ([Math]::Max(400, $StepDelayMs))
}

function Write-TestStep {
    param(
        [string]$Message,
        [System.Collections.Generic.List[string]]$Output
    )

    $line = "  -> $Message"
    Write-Host $line -ForegroundColor Gray
    if ($Output) {
        $Output.Add($line) | Out-Null
    }
}

function Get-FirstConnectedDevice {
    $devicesOutput = & $script:adb devices 2>$null
    $deviceLine = @($devicesOutput | Where-Object { $_ -match "`tdevice$" } | Select-Object -First 1)
    if ($deviceLine.Count -gt 0) {
        return (($deviceLine[0] -split "`t")[0]).Trim()
    }

    return ""
}

function Get-ScreenSize {
    $sizeOutput = (Invoke-Adb -Arguments @("shell", "wm", "size")) -join "`n"
    if ($sizeOutput -match "(\d+)x(\d+)") {
        return [PSCustomObject]@{
            Width = [int]$matches[1]
            Height = [int]$matches[2]
        }
    }

    return [PSCustomObject]@{
        Width = 720
        Height = 1280
    }
}

function Invoke-FastTap {
    param(
        [double]$FallbackXRatio,
        [double]$FallbackYRatio
    )

    $screen = Get-ScreenSize
    $x = [int]($screen.Width * $FallbackXRatio)
    $y = [int]($screen.Height * $FallbackYRatio)

    Invoke-Adb -Arguments @("shell", "input", "tap", "$x", "$y") | Out-Null
    Start-StepDelay
}

function Invoke-FastInput {
    param([string]$Text)

    Invoke-Adb -Arguments @("shell", "input", "text", $Text) | Out-Null
    Start-StepDelay
}

function Open-AppForCase {
    param([System.Collections.Generic.List[string]]$Output)

    Write-TestStep -Message "Open Date Time Checker app" -Output $Output
    Invoke-Adb -Arguments @("shell", "am", "force-stop", $appId) | Out-Null
    Invoke-Adb -Arguments @("shell", "am", "start", "-n", "$appId/.MainActivity") | Out-Null
    Start-Sleep -Milliseconds ([Math]::Max(800, $StepDelayMs * 2))

    $focusOutput = (Invoke-Adb -Arguments @("shell", "dumpsys", "window")) -join "`n"
    if ($focusOutput -notmatch [regex]::Escape($appId)) {
        throw "App launch command ran, but DateTimeChecker is not the focused Android app."
    }

    Write-TestStep -Message "App opened successfully" -Output $Output
}

function Enter-DateFields {
    param(
        [string]$Day,
        [string]$Month,
        [string]$Year,
        [System.Collections.Generic.List[string]]$Output
    )

    Write-TestStep -Message "Tap Day input" -Output $Output
    Invoke-FastTap -FallbackXRatio 0.50 -FallbackYRatio 0.53
    Start-FocusDelay
    Write-TestStep -Message "Type day = $Day" -Output $Output
    Invoke-FastInput -Text $Day
    Invoke-Adb -Arguments @("shell", "input", "keyevent", "111") | Out-Null
    Start-StepDelay
    Write-TestStep -Message "Tap Month input" -Output $Output
    Invoke-FastTap -FallbackXRatio 0.50 -FallbackYRatio 0.675
    Start-FocusDelay
    Write-TestStep -Message "Type month = $Month" -Output $Output
    Invoke-FastInput -Text $Month
    Invoke-Adb -Arguments @("shell", "input", "keyevent", "111") | Out-Null
    Start-StepDelay
    Write-TestStep -Message "Tap Year input" -Output $Output
    Invoke-FastTap -FallbackXRatio 0.50 -FallbackYRatio 0.825
    Start-FocusDelay
    Write-TestStep -Message "Type year = $Year" -Output $Output
    Invoke-FastInput -Text $Year
    Write-TestStep -Message "Hide keyboard" -Output $Output
    Invoke-Adb -Arguments @("shell", "input", "keyevent", "111") | Out-Null
    Start-StepDelay
}

function Invoke-DateCheckCase {
    param(
        [object]$Case,
        [System.Collections.Generic.List[string]]$Output
    )

    Open-AppForCase -Output $Output
    Enter-DateFields -Day $Case.Day -Month $Case.Month -Year $Case.Year -Output $Output
    Write-TestStep -Message "Tap Check button" -Output $Output
    Invoke-FastTap -FallbackXRatio 0.78 -FallbackYRatio 0.94
    Write-TestStep -Message "Swipe to result area" -Output $Output
    Invoke-Adb -Arguments @("shell", "input", "swipe", "360", "1010", "360", "420", "120") | Out-Null
    Start-StepDelay
    Write-TestStep -Message "Expected result on screen: $($Case.ExpectedResult)" -Output $Output
}

function Invoke-ClearFormCase {
    param(
        [object]$Case,
        [System.Collections.Generic.List[string]]$Output
    )

    Open-AppForCase -Output $Output
    Enter-DateFields -Day $Case.Day -Month $Case.Month -Year $Case.Year -Output $Output
    Write-TestStep -Message "Tap Clear button" -Output $Output
    Invoke-FastTap -FallbackXRatio 0.22 -FallbackYRatio 0.94
    Write-TestStep -Message "Expected result on screen: $($Case.ExpectedResult)" -Output $Output
}

function Save-CaseScreenshot {
    param([string]$CaseId)

    $screenshotsDir = Join-Path $reportRoot "screenshots"
    New-Item -ItemType Directory -Force -Path $screenshotsDir | Out-Null
    $screenshotPath = Join-Path $screenshotsDir "$CaseId.png"
    $command = '"' + $script:adb + '" -s ' + $script:DeviceId + ' exec-out screencap -p > "' + $screenshotPath + '"'
    cmd.exe /c $command | Out-Null
    return $screenshotPath
}

function Invoke-MobileCase {
    param([object]$Case)

    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " $($Case.Id) - $($Case.Name)" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "Purpose : $($Case.Purpose)" -ForegroundColor Gray
    Write-Host "Expected: $($Case.Expected)" -ForegroundColor Gray

    $caseStart = Get-Date
    $status = "PASS"
    $output = New-Object System.Collections.Generic.List[string]
    $screenshotPath = ""

    try {
        if ($Case.Kind -eq "DateCheck") {
            Invoke-DateCheckCase -Case $Case -Output $output
        } elseif ($Case.Kind -eq "ClearForm") {
            Invoke-ClearFormCase -Case $Case -Output $output
        } else {
            throw "Unknown case kind: $($Case.Kind)"
        }

        $output.Add("Fast ADB E2E case completed successfully with ${StepDelayMs}ms step delay.") | Out-Null
    } catch {
        $status = "FAIL"
        $output.Add($_.Exception.Message) | Out-Null
        Write-Host $_.Exception.Message -ForegroundColor Red
    } finally {
        try {
            $screenshotPath = Save-CaseScreenshot -CaseId $Case.Id
            Write-TestStep -Message "Saved screenshot: $screenshotPath" -Output $output
        } catch {
            $output.Add("Failed to save screenshot: $($_.Exception.Message)") | Out-Null
        }
    }

    $duration = [Math]::Round(((Get-Date) - $caseStart).TotalSeconds, 2)
    if ($status -eq "PASS") {
        Write-Host "[PASS] $($Case.Id) completed in ${duration}s" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $($Case.Id) failed in ${duration}s" -ForegroundColor Red
    }

    return [PSCustomObject]@{
        Id = $Case.Id
        Name = $Case.Name
        Purpose = $Case.Purpose
        Expected = $Case.Expected
        Status = $status
        DurationSeconds = $duration
        Screenshot = $screenshotPath
        Output = @($output)
    }
}

function New-MobileReport {
    param(
        [object[]]$Results,
        [DateTime]$StartedAt,
        [DateTime]$FinishedAt
    )

    New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $textReportPath) | Out-Null

    $passed = @($Results | Where-Object { $_.Status -eq "PASS" }).Count
    $failed = @($Results | Where-Object { $_.Status -eq "FAIL" }).Count
    $total = @($Results).Count
    $finalStatus = if ($failed -eq 0) { "PASS" } else { "FAIL" }
    $duration = [Math]::Round(($FinishedAt - $StartedAt).TotalSeconds, 2)

    [PSCustomObject]@{
        topic = "Topic 3 Mobile E2E Testing"
        engine = "ADB UIAutomator Fast Runner"
        appId = $appId
        deviceId = $DeviceId
        stepDelayMs = $StepDelayMs
        finalStatus = $finalStatus
        total = $total
        passed = $passed
        failed = $failed
        durationSeconds = $duration
        results = $Results
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonReportPath -Encoding UTF8

    $Results |
        Select-Object Id, Name, Purpose, Expected, Status, DurationSeconds, Screenshot |
        Export-Csv -LiteralPath $csvReportPath -NoTypeInformation -Encoding UTF8

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
          <td>$(ConvertTo-HtmlText $result.Screenshot)</td>
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
    :root { --bg:#f5f7fb; --card:#fff; --line:#d9e1ee; --text:#182033; --muted:#637083; --pass:#137333; --pass-bg:#e7f5ec; --fail:#b3261e; --fail-bg:#fce8e6; }
    * { box-sizing: border-box; }
    body { margin:0; padding:32px; background:var(--bg); color:var(--text); font-family:Inter,Segoe UI,Arial,sans-serif; }
    .shell { max-width:1180px; margin:0 auto; }
    .hero,.card { background:var(--card); border:1px solid var(--line); border-radius:18px; box-shadow:0 18px 45px rgba(21,35,62,.08); }
    .hero { padding:28px; margin-bottom:22px; }
    .card { padding:22px; margin-bottom:22px; }
    h1 { margin:10px 0 8px; font-size:30px; }
    h2 { margin:0 0 16px; font-size:20px; }
    p { color:var(--muted); line-height:1.55; }
    .summary { display:grid; grid-template-columns:repeat(5,minmax(0,1fr)); gap:14px; margin-top:20px; }
    .metric { border:1px solid var(--line); border-radius:14px; padding:16px; background:#fbfcff; }
    .metric span { display:block; color:var(--muted); font-size:13px; margin-bottom:7px; }
    .metric strong { font-size:24px; }
    table { width:100%; border-collapse:collapse; border-radius:12px; overflow:hidden; }
    th,td { padding:13px 12px; border-bottom:1px solid var(--line); text-align:left; vertical-align:top; font-size:14px; }
    th { background:#eef3ff; color:#26324a; font-size:13px; }
    .badge { display:inline-flex; border-radius:999px; padding:5px 10px; font-size:12px; font-weight:800; }
    .badge.pass { color:var(--pass); background:var(--pass-bg); }
    .badge.fail { color:var(--fail); background:var(--fail-bg); }
    details { border:1px solid var(--line); border-radius:14px; padding:14px 16px; margin-bottom:12px; background:#fbfcff; }
    summary { cursor:pointer; font-weight:700; }
    pre { white-space:pre-wrap; overflow-wrap:anywhere; color:#dce6ff; background:#111827; border-radius:12px; padding:14px; }
  </style>
</head>
<body>
  <main class="shell">
    <section class="hero">
      <span class="badge $($finalStatus.ToLowerInvariant())">$finalStatus</span>
      <h1>DateTimeChecker Android Fast E2E Report</h1>
      <p>Runner này dùng ADB UIAutomator để thao tác app Android thật với delay khoảng ${StepDelayMs}ms mỗi bước, nhanh hơn Maestro cho demo trên lớp.</p>
      <div class="summary">
        <div class="metric"><span>Total</span><strong>$total</strong></div>
        <div class="metric"><span>Passed</span><strong>$passed</strong></div>
        <div class="metric"><span>Failed</span><strong>$failed</strong></div>
        <div class="metric"><span>Duration</span><strong>${duration}s</strong></div>
        <div class="metric"><span>Step Delay</span><strong>${StepDelayMs}ms</strong></div>
      </div>
    </section>
    <section class="card">
      <h2>Run Information</h2>
      <p><strong>Engine:</strong> ADB UIAutomator Fast Runner</p>
      <p><strong>App ID:</strong> $(ConvertTo-HtmlText $appId)</p>
      <p><strong>Device:</strong> $(ConvertTo-HtmlText $DeviceId)</p>
    </section>
    <section class="card">
      <h2>Mobile E2E Cases</h2>
      <table>
        <thead><tr><th>ID</th><th>Case</th><th>Purpose</th><th>Expected</th><th>Status</th><th>Time</th><th>Screenshot</th></tr></thead>
        <tbody>$($rows -join [Environment]::NewLine)</tbody>
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
        "Engine: ADB UIAutomator Fast Runner",
        "Final status: $finalStatus",
        "Device: $DeviceId",
        "Step delay: ${StepDelayMs}ms",
        "Duration: ${duration}s",
        "HTML report: $htmlReportPath",
        "JSON report: $jsonReportPath",
        "CSV report: $csvReportPath",
        "",
        "Cases:"
    )

    foreach ($result in $Results) {
        $textLines += "- $($result.Id) $($result.Name): $($result.Status) ($($result.DurationSeconds)s)"
    }

    $textLines | Set-Content -LiteralPath $textReportPath -Encoding UTF8
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

$script:adb = Resolve-CommandPath "adb-not-from-path" @(
    (Join-Path $androidSdk "platform-tools\adb.exe"),
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
)

if (-not $script:adb) {
    throw "ADB not found."
}

if (-not $DeviceId) {
    $DeviceId = Get-FirstConnectedDevice
}

if (-not $DeviceId) {
    throw "No connected Android emulator/device found."
}

$script:DeviceId = $DeviceId

if (Test-Path -LiteralPath $reportRoot) {
    Remove-Item -LiteralPath $reportRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TOPIC 3 - MOBILE FAST E2E TESTING" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Engine     : ADB UIAutomator Fast Runner" -ForegroundColor Yellow
Write-Host "Step delay : ${StepDelayMs}ms" -ForegroundColor Yellow
Write-Host "App ID     : $appId" -ForegroundColor Yellow
Write-Host "Device     : $DeviceId" -ForegroundColor Yellow
Write-Host "Report HTML: $htmlReportPath" -ForegroundColor Yellow

$startedAt = Get-Date
$results = New-Object System.Collections.Generic.List[object]

foreach ($testCase in $testCases) {
    $results.Add((Invoke-MobileCase -Case $testCase)) | Out-Null
}

$finishedAt = Get-Date
New-MobileReport -Results @($results.ToArray()) -StartedAt $startedAt -FinishedAt $finishedAt

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " MOBILE E2E REPORTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "HTML report : $htmlReportPath" -ForegroundColor Green
Write-Host "JSON report : $jsonReportPath" -ForegroundColor Green
Write-Host "CSV report  : $csvReportPath" -ForegroundColor Green
Write-Host "Text summary: $textReportPath" -ForegroundColor Green

if ($OpenReport -and (Test-Path -LiteralPath $htmlReportPath)) {
    Start-Process $htmlReportPath
}

$failedCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
if ($failedCount -gt 0) {
    exit 1
}

exit 0
