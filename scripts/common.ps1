function Get-JavaTools {
    $javac = Get-Command javac -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    $java = Get-Command java -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

    if ($null -eq $javac) {
        $jdkDirs = @(
            "C:\Program Files\Java",
            "C:\Program Files\Eclipse Adoptium",
            "C:\Program Files (x86)\Java",
            "$env:USERPROFILE\.jdks"
        )

        foreach ($dir in $jdkDirs) {
            if (Test-Path $dir) {
                $found = Get-ChildItem -Path $dir -Filter "javac.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $javac = $found.FullName
                    $java = Join-Path (Split-Path $javac) "java.exe"
                    break
                }
            }
        }
    }

    if ($null -eq $javac) {
        Write-Host "[ERROR] Could not find JDK compiler (javac.exe)." -ForegroundColor Red
        Write-Host "Please install JDK 17+ or add javac to PATH." -ForegroundColor Yellow
        exit 1
    }

    $javac = $javac.Replace('"', '')
    $java = $java.Replace('"', '')

    return [PSCustomObject]@{
        Javac = $javac
        Java = $java
    }
}

function Stop-RunningServer {
    param(
        [int]$Port = 4173
    )

    Write-Host "Checking for any running processes on port $Port..." -ForegroundColor Yellow

    $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($connections) {
        foreach ($conn in $connections) {
            $processId = $conn.OwningProcess
            if ($processId -and $processId -ne 0 -and $processId -ne $PID) {
                Write-Host "Stopping process $processId listening on port $Port..." -ForegroundColor Cyan
                Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
        }
        return
    }

    $netstat = netstat -ano | Select-String "LISTENING" | Select-String ":$Port\s"
    if ($netstat) {
        foreach ($line in $netstat) {
            if ($line.Line -match '\s+(\d+)\s*$') {
                $processId = $Matches[1]
                if ($processId -and $processId -ne 0 -and $processId -ne $PID) {
                    Write-Host "Stopping process $processId listening on port $Port..." -ForegroundColor Cyan
                    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 1
                }
            }
        }
    }
}
