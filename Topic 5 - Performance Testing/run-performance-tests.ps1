$root = Split-Path -Parent $PSScriptRoot

# 1. Call start-server.ps1 first (from scripts/)
& (Join-Path $root "scripts\start-server.ps1")

$perfTestStatus = 0

try {
    # 2. Run autocannon-test.js
    $testScript = Join-Path $PSScriptRoot "benchmark\autocannon-test.js"
    Write-Output "Running autocannon-test.js..."
    node $testScript
    $perfTestStatus = $LASTEXITCODE
} finally {
    # 3. Print the contents of the report file
    $reportFile = Join-Path $root "reports\performance-report.txt"
    if (Test-Path $reportFile) {
        Write-Output "`n[PERFORMANCE REPORT CONTENTS]"
        Get-Content $reportFile
    } else {
        Write-Output "`n[WARNING] Performance report file not found at $reportFile"
    }

    # 4. Call stop-server.ps1
    & (Join-Path $root "scripts\stop-server.ps1")
}

# Exit with status code of autocannon test run
[System.Environment]::Exit($perfTestStatus)
