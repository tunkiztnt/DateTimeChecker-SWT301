param(
    [string]$DeviceId = "",
    [switch]$RefreshApp
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

$root = Split-Path -Parent $PSScriptRoot
$flutterApp = Join-Path $PSScriptRoot "flutter_app"
$userTools = Join-Path $env:USERPROFILE "AndroidTools"
$localTools = Join-Path $root "tools"
$localFlutter = if (Test-Path -LiteralPath (Join-Path $userTools "flutter\bin\flutter.bat")) {
    Join-Path $userTools "flutter\bin\flutter.bat"
} else {
    Join-Path $localTools "flutter\bin\flutter.bat"
}
$localAndroidSdk = if (Test-Path -LiteralPath (Join-Path $userTools "android-sdk")) {
    Join-Path $userTools "android-sdk"
} elseif (Test-Path -LiteralPath (Join-Path $localTools "android-sdk")) {
    Join-Path $localTools "android-sdk"
} else {
    Join-Path $env:LOCALAPPDATA "Android\Sdk"
}
$localAdb = Join-Path $localAndroidSdk "platform-tools\adb.exe"
$appId = "com.datetimechecker.date_time_checker"
$apkOutputDir = Join-Path $flutterApp "build\app\outputs\flutter-apk"
$runTestsScript = Join-Path $PSScriptRoot "run-mobile-testing.ps1"
$optimizedInstallMarker = Join-Path $PSScriptRoot ".optimized-mobile-install"

function Resolve-CommandPath {
    param(
        [string]$Name,
        [string[]]$Candidates = @()
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($candidate in $Candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Ensure-DemoAppInstalled {
    param(
        [string]$FlutterPath,
        [string]$AdbPath,
        [string]$CurrentDeviceId
    )

    $isInstalledOutput = & $AdbPath -s $CurrentDeviceId shell pm list packages $appId 2>$null
    $isInstalled = @($isInstalledOutput | Where-Object { $_ -match [regex]::Escape($appId) }).Count -gt 0

    $releaseApkPath = Join-Path $apkOutputDir "app-release.apk"
    $debugApkPath = Join-Path $apkOutputDir "app-debug.apk"

    $hasOptimizedInstall = Test-Path -LiteralPath $optimizedInstallMarker

    if ($isInstalled -and -not $RefreshApp -and $hasOptimizedInstall -and (Test-Path -LiteralPath $releaseApkPath)) {
        Write-Host "[STEP 2/4] App already installed. Skipping reinstall for faster startup." -ForegroundColor Green
        return
    }

    if ($isInstalled -and -not $RefreshApp -and -not $hasOptimizedInstall) {
        Write-Host "[STEP 2/4] App is installed, but optimized install marker is missing. Installing release build once..." -ForegroundColor Yellow
    } elseif ($isInstalled -and -not $RefreshApp -and -not (Test-Path -LiteralPath $releaseApkPath)) {
        Write-Host "[STEP 2/4] App is installed, but release APK is missing. Building optimized release APK once..." -ForegroundColor Yellow
    } else {
        Write-Host "[STEP 2/4] Build optimized Flutter release APK..." -ForegroundColor Yellow
    }

    $abi = (& $AdbPath -s $CurrentDeviceId shell getprop ro.product.cpu.abi).Trim()
    $targetPlatform = switch ($abi) {
        "x86_64" { "android-x64" }
        "arm64-v8a" { "android-arm64" }
        "armeabi-v7a" { "android-arm" }
        default { "android-x64" }
    }

    Push-Location $flutterApp
    try {
        & $FlutterPath build apk --release --target-platform $targetPlatform
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter build failed."
        }
    } finally {
        Pop-Location
    }

    $apkPath = if (Test-Path -LiteralPath $releaseApkPath) {
        $releaseApkPath
    } else {
        $debugApkPath
    }

    if (-not (Test-Path -LiteralPath $apkPath)) {
        throw "APK was not created at $apkPath"
    }

    Write-Host "[STEP 3/4] Install optimized app on emulator..." -ForegroundColor Yellow
    & $AdbPath -s $CurrentDeviceId install -r $apkPath | Out-Host
    "Installed optimized release APK at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Set-Content -LiteralPath $optimizedInstallMarker -Encoding UTF8
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TOPIC 3 - PREPARE MOBILE DEMO" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[STEP 1/4] Start emulator and optimize it for smoother demo..." -ForegroundColor Yellow

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "start-android-emulator.ps1")

$env:ANDROID_HOME = $localAndroidSdk
$env:ANDROID_SDK_ROOT = $localAndroidSdk
$env:ANDROID_SDK_HOME = $env:USERPROFILE
$env:ANDROID_AVD_HOME = Join-Path $env:USERPROFILE ".android\avd"
$env:HOME = $env:USERPROFILE
$env:Path = @(
    (Join-Path $localAndroidSdk "platform-tools"),
    (Join-Path $localAndroidSdk "emulator"),
    (Join-Path $localAndroidSdk "cmdline-tools\latest\bin"),
    (Split-Path -Parent $localFlutter),
    $env:Path
) -join ";"

$flutter = Resolve-CommandPath "flutter" @($localFlutter)
$adb = Resolve-CommandPath "adb-not-from-path" @($localAdb)

if (-not $flutter) {
    throw "Flutter not found."
}
if (-not $adb) {
    throw "ADB not found."
}

$devicesOutput = & $adb devices
$connectedDevices = @($devicesOutput | Where-Object { $_ -match "`tdevice$" })
if ($connectedDevices.Count -eq 0) {
    throw "No Android emulator/device is connected."
}

if (-not $DeviceId) {
    $DeviceId = ($connectedDevices[0] -split "`t")[0]
}

Ensure-DemoAppInstalled -FlutterPath $flutter -AdbPath $adb -CurrentDeviceId $DeviceId

Write-Host "[STEP 4/4] Return emulator to Home screen for manual demo..." -ForegroundColor Yellow
& $adb -s $DeviceId shell input keyevent 224 2>$null | Out-Null
& $adb -s $DeviceId shell wm dismiss-keyguard 2>$null | Out-Null
& $adb -s $DeviceId shell input keyevent 3 2>$null | Out-Null

Write-Host ""
Write-Host "The emulator is ready and the app is installed." -ForegroundColor Green
Write-Host "Tip: If the app still opens slowly, run start-emulator.bat --refresh once to install the optimized release build." -ForegroundColor Yellow
Write-Host "Open `Date Time Checker` manually on the Android home screen or app drawer." -ForegroundColor Cyan
Write-Host "When your manual demo is done, come back here." -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter when you want to decide about automated testing"

$runAutomation = Read-Host "Run automated mobile test now? (Y/N)"
if ($runAutomation.Trim().ToLower() -eq "y") {
    Write-Host ""
    Write-Host "Starting automated mobile testing on the installed app..." -ForegroundColor Yellow
    powershell -NoProfile -ExecutionPolicy Bypass -File $runTestsScript -DeviceId $DeviceId -ReuseInstalledApp -OpenReport
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Automated testing skipped. Manual demo setup is complete." -ForegroundColor Green
