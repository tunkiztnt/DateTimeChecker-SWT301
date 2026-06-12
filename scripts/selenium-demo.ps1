param(
    [switch]$AutoClose,
    [switch]$Headless
)

. "$PSScriptRoot\common.ps1"

# 1. Setup Directories
$libDir = "$PSScriptRoot\..\lib"
if (!(Test-Path $libDir)) {
    New-Item -ItemType Directory -Path $libDir -Force | Out-Null
}

$seleniumJar = "$libDir\selenium-server.jar"
$seleniumUrl = "https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.21.0/selenium-server-4.21.0.jar"

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

# 4. Check if server is already running on port 4173
$isPortActive = $false
$tcp = $null
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", 4173)
    $isPortActive = $true
} catch {
} finally {
    if ($null -ne $tcp) { $tcp.Close() }
}

$serverProcess = $null
if (-not $isPortActive) {
    Stop-RunningServer
    Write-Host "Starting local DateTimeChecker server in the background..." -ForegroundColor Yellow
    $repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
    $serverClassPath = (Resolve-Path $outDir).Path
    $serverProcess = Start-Process -FilePath $tools.Java -ArgumentList @("-cp", "`"$serverClassPath`"", "com.datetimechecker.App") -WorkingDirectory $repoRoot -PassThru -NoNewWindow
    # Wait for server to boot up
    Start-Sleep -Seconds 2
} else {
    Write-Host "Server is already running on port 4173. Reusing it." -ForegroundColor Green
}

# 5. Run Selenium E2E Automation
Write-Host "Running Selenium E2E Automation..." -ForegroundColor Green
$appArgs = @()
if ($AutoClose) {
    $appArgs += "--auto-close"
}
if ($Headless) {
    $appArgs += "--headless"
}
try {
    & $tools.Java -cp "$outDir;$seleniumJar" "-Ddatetimechecker.url=http://localhost:4173" com.datetimechecker.SeleniumVisibleDemo $appArgs
} finally {
    # 6. Tear down background server if we started it
    if ($null -ne $serverProcess) {
        Write-Host "Stopping background server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
}
