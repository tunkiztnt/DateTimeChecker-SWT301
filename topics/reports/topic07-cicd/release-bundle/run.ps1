. "$PSScriptRoot\common.ps1"

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

$tools = Get-JavaTools
Write-Host "Using Java: $($tools.Java)" -ForegroundColor Cyan

Write-Host "Compiling DateTimeChecker app..." -ForegroundColor Yellow
powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\build.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Starting DateTimeChecker server..." -ForegroundColor Green
Write-Host "Opening browser at: http://localhost:4173" -ForegroundColor Yellow

Start-Process "http://localhost:4173"

$classPath = "$PSScriptRoot\..\out\classes"
Stop-RunningServer
$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
Set-Location -Path $repoRoot
& $tools.Java -cp $classPath com.datetimechecker.App
