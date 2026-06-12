. "$PSScriptRoot\common.ps1"

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " UNIT TEST STEP - Backend Java validation logic" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[DEMO] Scope: DateTimeValidationService validates date range, month length, leap year and input format." -ForegroundColor Gray
Write-Host "[DEMO] Test style: fast isolated unit tests, no browser and no network." -ForegroundColor Gray

Write-Host "[STEP 1] Rebuilding the project..." -ForegroundColor Yellow
powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\build.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Rebuilding failed. Cannot run Java unit tests." -ForegroundColor Red
    exit 1
}

$tools = Get-JavaTools
$classPath = "$PSScriptRoot\..\out\classes"

Write-Host "[STEP 2] Running Java backend unit tests..." -ForegroundColor Green
Write-Host "         Case groups: valid dates, invalid month length, leap years, boundaries, blank/decimal/non-number input." -ForegroundColor Gray
& $tools.Java "-Dfile.encoding=UTF-8" -cp "$classPath;$PSScriptRoot\..\lib\junit-platform-console-standalone-1.10.2.jar" com.datetimechecker.DateTimeValidationServiceTest

$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    Write-Host "[FAIL] Java unit tests failed." -ForegroundColor Red
    exit $exitCode
} else {
    Write-Host "[PASS] Java unit tests passed." -ForegroundColor Green
    Write-Host "[MEANING] The core date validation rules are stable enough for API, Web E2E and CI/CD tests." -ForegroundColor Green
    exit 0
}
