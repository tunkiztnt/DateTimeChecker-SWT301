. "$PSScriptRoot\common.ps1"

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " BUILD STEP - DateTimeChecker Java source" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[DEMO] This step checks that backend app and Java tests compile before automation runs." -ForegroundColor Gray

$tools = Get-JavaTools
Write-Host "[TOOL] JDK compiler: $($tools.Javac)" -ForegroundColor Cyan

# Output directory for classes
$outDir = "$PSScriptRoot\..\out\classes"
if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

Write-Host "[SCAN] Looking for Java files in src/main/java and src/test/java..." -ForegroundColor Yellow

# Gather all .java files from src/main and src/test
$javaFiles = @()
if (Test-Path "$PSScriptRoot\..\src\main\java") {
    $javaFiles += Get-ChildItem -Path "$PSScriptRoot\..\src\main\java" -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
}
if (Test-Path "$PSScriptRoot\..\src\test\java") {
    $javaFiles += Get-ChildItem -Path "$PSScriptRoot\..\src\test\java" -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
}

if ($javaFiles.Count -eq 0) {
    Write-Host "[WARNING] No Java source files found to compile." -ForegroundColor Yellow
    exit 0
}

Write-Host "[INFO] Found $($javaFiles.Count) Java source file(s)." -ForegroundColor Cyan
foreach ($file in $javaFiles) {
    $relative = Resolve-Path -LiteralPath $file -Relative
    Write-Host "       - $relative" -ForegroundColor DarkGray
}
Write-Host "[RUN] javac -encoding UTF-8 -cp junit-platform-console -d out/classes ..." -ForegroundColor Yellow

# Compile command
$classpath = "$PSScriptRoot\..\lib\junit-platform-console-standalone-1.10.2.jar"
& $tools.Javac -encoding UTF-8 -cp $classpath -d $outDir $javaFiles

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

Write-Host "[PASS] Compilation completed successfully." -ForegroundColor Green
Write-Host "[OUTPUT] Compiled classes: $outDir" -ForegroundColor Green
exit 0
