. "$PSScriptRoot\common.ps1"

# 1. Setup Directories
$libDir = "$PSScriptRoot\..\lib"
if (!(Test-Path $libDir)) {
    New-Item -ItemType Directory -Path $libDir -Force | Out-Null
}

$seleniumJar = "$libDir\selenium-server.jar"
$seleniumUrl = "https://repo1.maven.org/maven2/org/seleniumhq/selenium/selenium-server/4.21.0/selenium-server-4.21.0.jar"

# 2. Download Selenium Standalone Server if missing
if (!(Test-Path $seleniumJar)) {
    Write-Host "Downloading Selenium Standalone Server JAR..." -ForegroundColor Yellow
    Write-Host "From: $seleniumUrl" -ForegroundColor Gray
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $seleniumUrl -OutFile $seleniumJar -UseBasicParsing
        Write-Host "Download successful." -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to download Selenium jar: $_" -ForegroundColor Red
        exit 1
    }
}

# 3. Compile everything including Selenium test
$tools = Get-JavaTools
$outDir = "$PSScriptRoot\..\out\classes"
if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

Write-Host "Compiling main application and Selenium test code..." -ForegroundColor Yellow
$javaFiles = @(
    (Resolve-Path "$PSScriptRoot\..\src\main\java\com\datetimechecker\*.java").Path
    (Resolve-Path "$PSScriptRoot\..\src\selenium\java\com\datetimechecker\*.java").Path
)

& $tools.Javac -encoding UTF-8 -cp "$seleniumJar" -d $outDir $javaFiles
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed." -ForegroundColor Red
    exit 1
}

# 4. Start Java Server on port 4173 in the background
Write-Host "Starting local DateTimeChecker server in the background..." -ForegroundColor Yellow
$serverProcess = Start-Process -FilePath $tools.Java -ArgumentList "-cp", "$outDir", "com.datetimechecker.App" -PassThru -NoNewWindow

# Wait for server to boot up
Start-Sleep -Seconds 2

# 5. Run Selenium visible demo
Write-Host "Running Selenium E2E Automation Demo (Edge browser will open)..." -ForegroundColor Green
try {
    & $tools.Java -cp "$outDir;$seleniumJar" -Ddatetimechecker.url="http://localhost:4173" com.datetimechecker.SeleniumVisibleDemo
} finally {
    # 6. Tear down background server
    Write-Host "Stopping background server..." -ForegroundColor Yellow
    Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
}
