param(
    [string]$EmulatorId = "flutter_emulator"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$userTools = Join-Path $env:USERPROFILE "AndroidTools"
$userAndroidSdk = Join-Path $userTools "android-sdk"
$localAndroidSdk = Join-Path $root "tools\android-sdk"
$defaultAndroidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$androidSdk = if (Test-Path -LiteralPath $userAndroidSdk) {
    $userAndroidSdk
} elseif (Test-Path -LiteralPath $localAndroidSdk) {
    $localAndroidSdk
} else {
    $defaultAndroidSdk
}

$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk
$env:Path = @(
    (Join-Path $androidSdk "platform-tools"),
    (Join-Path $androidSdk "emulator"),
    (Join-Path $androidSdk "cmdline-tools\latest\bin"),
    $env:Path
) -join ";"

$emulator = Join-Path $androidSdk "emulator\emulator.exe"
$adb = Join-Path $androidSdk "platform-tools\adb.exe"

if (-not (Test-Path -LiteralPath $emulator)) {
    throw "Android emulator.exe not found at $emulator"
}
if (-not (Test-Path -LiteralPath $adb)) {
    throw "adb.exe not found at $adb"
}

$devices = & $adb devices
if (@($devices | Where-Object { $_ -match "`tdevice$" }).Count -gt 0) {
    Write-Output "Android device/emulator is already connected."
    $devices
    exit 0
}

Write-Output "Starting Android emulator: $EmulatorId"
Start-Process -FilePath $emulator `
    -ArgumentList "-avd", $EmulatorId, "-no-snapshot-save" `
    -WindowStyle Hidden | Out-Null

Write-Output "Waiting for emulator to boot..."
& $adb wait-for-device

for ($attempt = 1; $attempt -le 90; $attempt++) {
    $bootOutput = & $adb shell getprop sys.boot_completed 2>$null
    $boot = if ($bootOutput) { $bootOutput.ToString().Trim() } else { "" }
    if ($boot -eq "1") {
        Write-Output "Emulator is ready."
        & $adb devices
        exit 0
    }
    Start-Sleep -Seconds 2
}

throw "Emulator did not finish booting in time."
