. "$PSScriptRoot\common.ps1"

Write-Host "Rebuilding the project..." -ForegroundColor Yellow
powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\build.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Rebuilding failed. Cannot run Java unit tests." -ForegroundColor Red
    exit 1
}

$tools = Get-JavaTools
$classPath = "$PSScriptRoot\..\out\classes"

Write-Host "Running Java backend unit tests..." -ForegroundColor Green
& $tools.Java -cp $classPath com.datetimechecker.DateTimeValidationServiceTest

$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    Write-Host "[FAIL] Java unit tests failed." -ForegroundColor Red
    exit $exitCode
} else {
    Write-Host "[SUCCESS] All Java unit tests passed." -ForegroundColor Green
    exit 0
}
