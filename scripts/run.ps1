. "$PSScriptRoot\common.ps1"

$tools = Get-JavaTools
Write-Host "Using Java: $($tools.Java)" -ForegroundColor Cyan

# Ensure code is compiled
Write-Host "Biên dịch dự án..." -ForegroundColor Yellow
powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\build.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Biên dịch thất bại!" -ForegroundColor Red
    exit 1
}

Write-Host "Đang khởi động DateTimeChecker Server..." -ForegroundColor Green
Write-Host "Mở trình duyệt tại: http://localhost:4173" -ForegroundColor Yellow

# Start the browser asynchronously
Start-Process "http://localhost:4173"

# Run the server in foreground
$classPath = (Resolve-Path -LiteralPath "$PSScriptRoot\..\out\classes").Path
Stop-RunningServer
$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
Set-Location -Path $repoRoot
& $tools.Java -cp $classPath com.datetimechecker.App
