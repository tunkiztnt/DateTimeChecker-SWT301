. (Join-Path $PSScriptRoot "..\scripts\common.ps1")

$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $root "scripts\build.ps1")
$tools = Get-JavaTools
$classes = Join-Path $root "out\classes"

Write-Output "Starting application server for performance testing..."
$server = Start-DateTimeCheckerServerForDemo -Java $tools.Java -Classes $classes -Root $root

try {
    $hasK6 = Get-Command "k6" -ErrorAction SilentlyContinue
    $env:DATETIMECHECKER_URL = $server.Url
    if ($hasK6) {
        Write-Output "k6 is installed. Running k6 load test..."
        & k6 run (Join-Path $PSScriptRoot "k6\load-test.js")
    } else {
        Write-Output "k6 not found in PATH. Running fallback Node.js Autocannon benchmark..."
        Set-Location -LiteralPath $root
        & npm run test:perf
    }
} finally {
    if ($server.Started -and $server.Process) {
        Write-Output "Stopping application server..."
        Stop-Process -Id $server.Process.Id -Force -ErrorAction SilentlyContinue
        $server.Process.Dispose()
    }
}
[System.Environment]::Exit(0)
