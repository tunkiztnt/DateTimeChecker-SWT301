# install_android_tools.ps1
# Automates the download and installation of Android SDK (platform-tools, emulator, system-image) and Maestro CLI on Windows.

$ErrorActionPreference = "Stop"

$sdkRoot = "C:\Users\nem\AppData\Local\Android\Sdk"
$maestroRoot = "C:\Users\nem\.maestro"
$tempDir = Join-Path $env:TEMP "AndroidSetupTemp"

if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

Write-Host "=================================================="
Write-Host " STARTING AUTOMATIC ANDROID SDK & MAESTRO SETUP"
Write-Host "=================================================="

# --- 1. DOWNLOAD & SETUP ANDROID CMDLINE-TOOLS ---
Write-Host "`n[1/5] Downloading Android Command-Line Tools..."
$cmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$cmdlineToolsZip = Join-Path $tempDir "cmdline-tools.zip"

if (!(Test-Path $cmdlineToolsZip)) {
    Invoke-WebRequest -Uri $cmdlineToolsUrl -OutFile $cmdlineToolsZip -Verbose
}

Write-Host "Extracting Command-Line Tools..."
$cmdlineToolsDest = Join-Path $sdkRoot "cmdline-tools"
if (Test-Path $cmdlineToolsDest) {
    Remove-Item -Recurse -Force $cmdlineToolsDest
}
New-Item -ItemType Directory -Path $cmdlineToolsDest | Out-Null

$extractTemp = Join-Path $tempDir "cmdline-tools-extracted"
if (Test-Path $extractTemp) {
    Remove-Item -Recurse -Force $extractTemp
}
Expand-Archive -Path $cmdlineToolsZip -DestinationPath $extractTemp

# Move to the correct layout: sdk/cmdline-tools/latest/
$latestPath = Join-Path $cmdlineToolsDest "latest"
Move-Item -Path (Join-Path $extractTemp "cmdline-tools") -Destination $latestPath

Write-Host "Command-Line Tools successfully set up at $latestPath"

# --- 2. INSTALL SDK COMPONENTS & ACCEPT LICENSES ---
Write-Host "`n[2/5] Installing Android SDK Components (Platform Tools, Emulator, System Image, platforms;android-33)..."
$sdkManager = Join-Path $latestPath "bin\sdkmanager.bat"

# Set ANDROID_HOME environment variable for the current session
$env:ANDROID_HOME = $sdkRoot

# Accept licenses (sending 'y' to the stdin stream)
Write-Host "Accepting Android SDK Licenses..."
$y = @("y") * 30
$y | & $sdkManager --licenses | Out-Null

# Install the components
Write-Host "Installing platform-tools, emulator, platforms;android-33, system-images;android-33;google_apis;x86_64..."
$y | & $sdkManager "platform-tools" "emulator" "platforms;android-33" "system-images;android-33;google_apis;x86_64"

# --- 3. CREATE VIRTUAL DEVICE (AVD) ---
Write-Host "`n[3/5] Creating Android Virtual Device (AVD)..."
$avdManager = Join-Path $latestPath "bin\avdmanager.bat"

# Create Pixel_5_API_33 device (answering 'no' to custom hardware profile prompt if it asks)
"no" | & $avdManager create avd -n "Pixel_5_API_33" -k "system-images;android-33;google_apis;x86_64" --device "pixel_5" --force

Write-Host "AVD 'Pixel_5_API_33' created successfully!"

# --- 4. DOWNLOAD & INSTALL MAESTRO CLI ---
Write-Host "`n[4/5] Downloading and installing Maestro CLI..."
$maestroUrl = "https://github.com/mobile-dev-inc/maestro/releases/latest/download/maestro.zip"
$maestroZip = Join-Path $tempDir "maestro.zip"

if (!(Test-Path $maestroZip)) {
    Invoke-WebRequest -Uri $maestroUrl -OutFile $maestroZip -Verbose
}

Write-Host "Extracting Maestro CLI..."
if (Test-Path $maestroRoot) {
    Remove-Item -Recurse -Force $maestroRoot
}
New-Item -ItemType Directory -Path $maestroRoot | Out-Null

$maestroExtractTemp = Join-Path $tempDir "maestro-extracted"
if (Test-Path $maestroExtractTemp) {
    Remove-Item -Recurse -Force $maestroExtractTemp
}
Expand-Archive -Path $maestroZip -DestinationPath $maestroExtractTemp

# Copy maestro contents to the maestro root directory
Copy-Item -Path (Join-Path $maestroExtractTemp "maestro\*") -Destination $maestroRoot -Recurse

Write-Host "Maestro CLI successfully set up at $maestroRoot"

# --- 5. SETUP PERMANENT ENVIRONMENT VARIABLES ---
Write-Host "`n[5/5] Configuring permanent environment variables (User)..."

# Set ANDROID_HOME
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkRoot, "User")
Write-Host "Set ANDROID_HOME to $sdkRoot"

# Get current User Path
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathParts = $currentPath -split ";"

$pathsToAdd = @(
    (Join-Path $sdkRoot "platform-tools"),
    (Join-Path $sdkRoot "emulator"),
    (Join-Path $sdkRoot "cmdline-tools\latest\bin"),
    (Join-Path $maestroRoot "bin")
)

$updatedPathParts = [System.Collections.Generic.List[string]]::new()
foreach ($part in $pathParts) {
    if ($part -and ($updatedPathParts -notcontains $part)) {
        $updatedPathParts.Add($part)
    }
}

foreach ($pathToAdd in $pathsToAdd) {
    if ($updatedPathParts -notcontains $pathToAdd) {
        $updatedPathParts.Add($pathToAdd)
        Write-Host "Adding path: $pathToAdd"
    }
}

$newPath = $updatedPathParts -join ";"
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
Write-Host "User Path updated successfully!"

# --- CLEANUP ---
Write-Host "`nCleaning up temporary files..."
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}

Write-Host "`n=================================================="
Write-Host " SETUP COMPLETE! Please restart any open terminals."
Write-Host " AVD Name: Pixel_5_API_33"
Write-Host "=================================================="

