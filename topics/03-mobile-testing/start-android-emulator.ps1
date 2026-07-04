param(
    [string]$EmulatorId = "",
    [switch]$ResetDevice
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

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
$androidHomeDir = Join-Path $env:USERPROFILE ".android"
$androidAvdHome = Join-Path $androidHomeDir "avd"

$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk
$env:ANDROID_SDK_HOME = $env:USERPROFILE
$env:ANDROID_AVD_HOME = $androidAvdHome
$env:HOME = $env:USERPROFILE
$env:Path = @(
    (Join-Path $androidSdk "platform-tools"),
    (Join-Path $androidSdk "emulator"),
    (Join-Path $androidSdk "cmdline-tools\latest\bin"),
    $env:Path
) -join ";"

$emulator = Join-Path $androidSdk "emulator\emulator.exe"
$adb = Join-Path $androidSdk "platform-tools\adb.exe"
$avdManager = Join-Path $androidSdk "cmdline-tools\latest\bin\avdmanager.bat"

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Get-ConnectedDevices {
    $devicesOutput = & $adb devices
    return @($devicesOutput | Where-Object { $_ -match "^emulator-\d+\s+device$" })
}

function Get-AvailableAvds {
    $avdOutput = & $emulator -list-avds 2>$null
    return @($avdOutput | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ })
}

function Get-AvdConfigPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AvdName
    )

    return Join-Path $androidAvdHome "$AvdName.avd\config.ini"
}

function Get-AvdDirectoryPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AvdName
    )

    return Join-Path $androidAvdHome "$AvdName.avd"
}

function Get-AvdIniPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AvdName
    )

    return Join-Path $androidAvdHome "$AvdName.ini"
}

function Test-AvdIsUsable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AvdName
    )

    $configPath = Get-AvdConfigPath -AvdName $AvdName
    if (-not (Test-Path -LiteralPath $configPath)) {
        return $false
    }

    $imageConfig = Get-Content $configPath | Where-Object { $_ -like "image.sysdir.1*" } | Select-Object -First 1
    if (-not $imageConfig) {
        return $false
    }

    $configuredPath = ($imageConfig -split "=", 2)[1].Trim()
    if (-not $configuredPath) {
        return $false
    }

    $fullImagePath = Join-Path $androidSdk $configuredPath
    return (Test-Path -LiteralPath $fullImagePath)
}

function Remove-AvdIfPresent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AvdName
    )

    $avdDir = Get-AvdDirectoryPath -AvdName $AvdName
    $avdIni = Get-AvdIniPath -AvdName $AvdName

    if (Test-Path -LiteralPath $avdDir) {
        Remove-Item -LiteralPath $avdDir -Recurse -Force
    }
    if (Test-Path -LiteralPath $avdIni) {
        Remove-Item -LiteralPath $avdIni -Force
    }
}

function Resolve-SystemImagePackage {
    $preferred = Join-Path $androidSdk "system-images\android-36\google_apis\x86_64"
    if (Test-Path -LiteralPath $preferred) {
        return "system-images;android-36;google_apis;x86_64"
    }

    $systemImagesRoot = Join-Path $androidSdk "system-images"
    if (-not (Test-Path -LiteralPath $systemImagesRoot)) {
        return $null
    }

    $apiDirs = Get-ChildItem -LiteralPath $systemImagesRoot -Directory -ErrorAction SilentlyContinue
    foreach ($apiDir in $apiDirs) {
        $vendorDirs = Get-ChildItem -LiteralPath $apiDir.FullName -Directory -ErrorAction SilentlyContinue
        foreach ($vendorDir in $vendorDirs) {
            $archDirs = Get-ChildItem -LiteralPath $vendorDir.FullName -Directory -ErrorAction SilentlyContinue
            foreach ($archDir in $archDirs) {
                return "system-images;$($apiDir.Name);$($vendorDir.Name);$($archDir.Name)"
            }
        }
    }

    return $null
}

function Optimize-AvdConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AvdName
    )

    $configPath = Get-AvdConfigPath -AvdName $AvdName
    if (-not (Test-Path -LiteralPath $configPath)) {
        return
    }

    $configLines = [System.Collections.Generic.List[string]]::new()
    $existingLines = Get-Content $configPath
    foreach ($line in $existingLines) {
        $configLines.Add($line)
    }

    $desiredValues = [ordered]@{
        "hw.gpu.enabled" = "yes"
        "hw.gpu.mode" = "host"
        "hw.cpu.ncore" = "4"
        "hw.ramSize" = "3072"
        "vm.heapSize" = "512"
        "hw.lcd.width" = "720"
        "hw.lcd.height" = "1280"
        "hw.lcd.density" = "320"
        "showDeviceFrame" = "no"
        "hw.audioInput" = "no"
        "hw.camera.back" = "none"
        "hw.camera.front" = "none"
        "hw.keyboard" = "yes"
        "fastboot.forceFastBoot" = "yes"
        "fastboot.forceColdBoot" = "no"
        "runtime.network.latency" = "none"
        "runtime.network.speed" = "full"
    }

    foreach ($entry in $desiredValues.GetEnumerator()) {
        $pattern = "^\s*" + [regex]::Escape($entry.Key) + "\s*="
        $replacement = "$($entry.Key) = $($entry.Value)"
        $updated = $false

        for ($index = 0; $index -lt $configLines.Count; $index++) {
            if ($configLines[$index] -match $pattern) {
                $configLines[$index] = $replacement
                $updated = $true
                break
            }
        }

        if (-not $updated) {
            $configLines.Add($replacement)
        }
    }

    Set-Content -LiteralPath $configPath -Value $configLines -Encoding UTF8
}

function Ensure-Avd {
    param(
        [string]$RequestedEmulatorId
    )

    $availableAvds = Get-AvailableAvds
    if ($RequestedEmulatorId -and ($availableAvds -contains $RequestedEmulatorId) -and (Test-AvdIsUsable -AvdName $RequestedEmulatorId)) {
        Optimize-AvdConfig -AvdName $RequestedEmulatorId
        return $RequestedEmulatorId
    }

    if ($availableAvds.Count -gt 0) {
        if (($availableAvds -contains "Pixel_5_API_33") -and (Test-AvdIsUsable -AvdName "Pixel_5_API_33")) {
            Optimize-AvdConfig -AvdName "Pixel_5_API_33"
            return "Pixel_5_API_33"
        }

        $firstUsableAvd = $availableAvds | Where-Object { Test-AvdIsUsable -AvdName $_ } | Select-Object -First 1
        if ($firstUsableAvd) {
            Optimize-AvdConfig -AvdName $firstUsableAvd
            return $firstUsableAvd
        }
    }

    if (-not (Test-Path -LiteralPath $avdManager)) {
        throw "No AVD found, and avdmanager.bat is unavailable at $avdManager"
    }

    $targetAvd = if ($RequestedEmulatorId) { $RequestedEmulatorId } else { "Pixel_5_API_33" }
    $systemImagePackage = Resolve-SystemImagePackage
    if (-not $systemImagePackage) {
        throw "No Android system image found under $androidSdk\system-images. Run install_android_tools.ps1 first."
    }

    Write-Host "No usable Android Virtual Device found. Creating or repairing AVD: $targetAvd"
    Write-Host "Using system image: $systemImagePackage"
    Remove-AvdIfPresent -AvdName $targetAvd
    "no" | & $avdManager create avd -n $targetAvd -k $systemImagePackage --device "pixel_5" --force | Out-Null

    $availableAvds = Get-AvailableAvds
    if ((-not ($availableAvds -contains $targetAvd)) -or (-not (Test-AvdIsUsable -AvdName $targetAvd))) {
        throw "AVD creation did not complete successfully for $targetAvd"
    }

    Optimize-AvdConfig -AvdName $targetAvd
    return $targetAvd
}

function Initialize-DeviceForDemo {
    & $adb shell input keyevent 224 2>$null | Out-Null
    & $adb shell wm dismiss-keyguard 2>$null | Out-Null
    & $adb shell input keyevent 82 2>$null | Out-Null
    & $adb shell input keyevent 3 2>$null | Out-Null
    & $adb shell settings put global window_animation_scale 0 2>$null | Out-Null
    & $adb shell settings put global transition_animation_scale 0 2>$null | Out-Null
    & $adb shell settings put global animator_duration_scale 0 2>$null | Out-Null
}

Ensure-Directory -Path (Join-Path $env:LOCALAPPDATA "mobile_dev\maestro\Logs")
Ensure-Directory -Path $androidHomeDir
Ensure-Directory -Path $androidAvdHome

if (-not (Test-Path -LiteralPath $emulator)) {
    throw "Android emulator.exe not found at $emulator"
}
if (-not (Test-Path -LiteralPath $adb)) {
    throw "adb.exe not found at $adb"
}

$devices = Get-ConnectedDevices
if ($devices.Count -gt 0) {
    Write-Output "Android device/emulator is already connected."
    Write-Output "Performance note: GPU/RAM/resolution tuning is applied on the next emulator start. Close the emulator and run start-emulator.bat again if it still feels laggy."
    Initialize-DeviceForDemo
    & $adb devices
    exit 0
}

$resolvedEmulatorId = Ensure-Avd -RequestedEmulatorId $EmulatorId
Write-Output "Starting Android emulator: $resolvedEmulatorId"

$arguments = @(
    "-avd", $resolvedEmulatorId,
    "-gpu", "host",
    "-accel", "on",
    "-cores", "4",
    "-memory", "3072",
    "-no-boot-anim",
    "-noaudio",
    "-camera-back", "none",
    "-camera-front", "none",
    "-netdelay", "none",
    "-netspeed", "full"
)

if ($ResetDevice) {
    $arguments += @("-wipe-data", "-no-snapshot")
}

$emulatorProcess = Start-Process -FilePath $emulator -ArgumentList $arguments -PassThru

Write-Output "Waiting for emulator to boot..."
for ($attempt = 1; $attempt -le 120; $attempt++) {
    if ($emulatorProcess.HasExited) {
        throw "Emulator exited unexpectedly before ADB detected a device. The AVD configuration or system image may be invalid."
    }

    $deviceState = (& $adb devices 2>$null | Where-Object { $_ -match "^emulator-\d+\s+device$" })
    if (-not $deviceState) {
        Start-Sleep -Seconds 2
        continue
    }

    $bootOutput = & $adb shell getprop sys.boot_completed 2>$null
    $boot = if ($bootOutput) { $bootOutput.ToString().Trim() } else { "" }
    if ($boot -eq "1") {
        Initialize-DeviceForDemo
        Write-Output "Emulator is ready."
        & $adb devices
        exit 0
    }

    Start-Sleep -Seconds 2
}

throw "Emulator did not finish booting in time."
