param(
    [string]$ApiKey,
    [switch]$OfflineSample,
    [string]$Prompt = "Create JSON test cases for DateTimeChecker covering leap year, month boundary, invalid format, and invalid range.",
    [string]$TestcaseFile = "$PSScriptRoot\..\reports\ai-generated-testcases.json",
    [string]$ReportFile = "$PSScriptRoot\..\reports\ai-generated-e2e-report.csv",
    [switch]$Headless,
    [switch]$SkipGeneration
)

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

function Escape-CsvValue {
    param([object]$Value)

    $text = [string]$Value
    $text = $text -replace "(`r`n|`n|`r)", " "
    if ($text.Contains('"')) {
        $text = $text.Replace('"', '""')
    }
    if ($text.Contains(',') -or $text.Contains('"')) {
        return '"' + $text + '"'
    }
    return $text
}

function Initialize-AiReportFile {
    param([string]$CsvPath)

    $reportDirectory = Split-Path -Parent $CsvPath
    if (-not (Test-Path $reportDirectory)) {
        New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
    }

    $header = 'timestamp,id,name,testType,day,month,year,expectedResult,actualResult,expectedValid,actualValid,status,note'
    try {
        [System.IO.File]::WriteAllText($CsvPath, $header + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        return $CsvPath
    } catch {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($CsvPath)
        $extension = [System.IO.Path]::GetExtension($CsvPath)
        $fallbackPath = Join-Path $reportDirectory ("{0}-{1}{2}" -f $baseName, $timestamp, $extension)
        Write-Host "[WARN] Report file is locked: $CsvPath" -ForegroundColor Yellow
        Write-Host "[WARN] Switching to a new report file for this run: $fallbackPath" -ForegroundColor Yellow
        [System.IO.File]::WriteAllText($fallbackPath, $header + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        return $fallbackPath
    }
}

function Assert-AiReportMatchesTestcases {
    param(
        [string]$JsonPath,
        [string]$CsvPath
    )

    if (-not (Test-Path $JsonPath)) {
        throw "Testcase file not found: $JsonPath"
    }

    $cases = Get-Content $JsonPath -Raw | ConvertFrom-Json
    $jsonCount = @($cases).Count

    if (-not (Test-Path $CsvPath)) {
        throw "CSV report not found after execution: $CsvPath"
    }

    $reportRows = Import-Csv -Path $CsvPath
    $csvCount = @($reportRows).Count

    if ($csvCount -ne $jsonCount) {
        throw "CSV report row count ($csvCount) does not match testcase count ($jsonCount)."
    }

    foreach ($case in $cases) {
        $matchedRows = @($reportRows | Where-Object { $_.id -eq [string]$case.id })
        if ($matchedRows.Count -ne 1) {
            throw "CSV report does not contain exactly one row for testcase id '$($case.id)'."
        }

        $row = $matchedRows[0]
        if ([string]$row.name -ne [string]$case.name) {
            throw "CSV report name mismatch for testcase id '$($case.id)'."
        }
        if ([string]$row.testType -ne [string]$case.testType) {
            throw "CSV report testType mismatch for testcase id '$($case.id)'."
        }
        if ([string]$row.day -ne [string]$case.day -or [string]$row.month -ne [string]$case.month -or [string]$row.year -ne [string]$case.year) {
            throw "CSV report input mismatch for testcase id '$($case.id)'."
        }
        if ([string]$row.expectedResult -ne [string]$case.expectedResult) {
            throw "CSV report expectedResult mismatch for testcase id '$($case.id)'."
        }
        if ([string]$row.expectedValid -ne [string]$case.expectedValid) {
            throw "CSV report expectedValid mismatch for testcase id '$($case.id)'."
        }
        if ([string]::IsNullOrWhiteSpace([string]$row.actualResult)) {
            throw "CSV report actualResult is empty for testcase id '$($case.id)'."
        }
        if ([string]::IsNullOrWhiteSpace([string]$row.status)) {
            throw "CSV report status is empty for testcase id '$($case.id)'."
        }
    }
}

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$generatorScript = Join-Path $PSScriptRoot "generate-ai-testcases.ps1"
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TOPIC 7 - AI GENERATED TEST EXECUTION" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
if ($SkipGeneration) {
    Write-Host "[STEP 1/3] Reuse existing testcase file." -ForegroundColor Cyan
    Write-Host "[INFO] Testcase file: $TestcaseFile" -ForegroundColor DarkCyan
    if (-not (Test-Path $TestcaseFile)) {
        Write-Host "[ERROR] Existing testcase file not found." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[STEP 1/3] Generate testcase file from AI output." -ForegroundColor Cyan
    Write-Host "[INFO] Prompt: $Prompt" -ForegroundColor DarkCyan

    $generatorArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $generatorScript,
        "-OutputFile", $TestcaseFile,
        "-Prompt", $Prompt
    )

    if ($OfflineSample) {
        $generatorArgs += "-OfflineSample"
    } elseif ($ApiKey) {
        $generatorArgs += @("-ApiKey", $ApiKey)
    }

    & powershell @generatorArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to generate testcase file." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "[STEP 2/3] Run Playwright tests using the generated testcase file." -ForegroundColor Cyan
$env:AI_TESTCASE_FILE = (Resolve-Path $TestcaseFile).Path
$reportDirectory = Split-Path -Parent $ReportFile
if (-not (Test-Path $reportDirectory)) {
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
}
$activeReportFile = Initialize-AiReportFile -CsvPath $ReportFile
$env:AI_TEST_REPORT_PATH = $activeReportFile
$env:AI_E2E_STEP_DELAY_MS = if ($Headless) { "0" } else { "450" }
Push-Location $repoRoot
try {
    $playwrightArgs = @("playwright", "test", "--config=playwright.config.js", "--grep", "@ai-generated-e2e")
    if (-not $Headless) {
        $playwrightArgs += "--headed"
    }
    & npx @playwrightArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] AI-driven testcase execution failed." -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Assert-AiReportMatchesTestcases -JsonPath $TestcaseFile -CsvPath $activeReportFile

Write-Host ""
Write-Host "[STEP 3/3] Summary" -ForegroundColor Cyan
Write-Host " Testcase file: $TestcaseFile" -ForegroundColor White
Write-Host " Playwright spec: Topic 7 - AI-Assisted Testing\playwright-ai\generated-e2e.spec.js" -ForegroundColor White
Write-Host " Result report: $activeReportFile" -ForegroundColor White
Write-Host " AI-generated E2E execution: PASS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
