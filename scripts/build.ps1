. "$PSScriptRoot\common.ps1"

$tools = Get-JavaTools
Write-Host "Using JDK compiler: $($tools.Javac)" -ForegroundColor Cyan

# Output directory for classes
$outDir = "$PSScriptRoot\..\out\classes"
if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

Write-Host "Compiling all Java source files (main and test)..." -ForegroundColor Yellow

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

# Compile command
$classpath = "$PSScriptRoot\..\lib\junit-platform-console-standalone-1.10.2.jar"
& $tools.Javac -encoding UTF-8 -cp $classpath -d $outDir $javaFiles

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

Write-Host "Compilation completed successfully. Output class folder: $outDir" -ForegroundColor Green
exit 0
