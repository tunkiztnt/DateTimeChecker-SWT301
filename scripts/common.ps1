function Get-JavaTools {
    $javac = $null
    $java = $null

    # Prefer the real JDK pointed to by JAVA_HOME instead of Windows shim paths.
    if ($env:JAVA_HOME) {
        $javaHomeJavac = Join-Path $env:JAVA_HOME "bin\javac.exe"
        $javaHomeJava = Join-Path $env:JAVA_HOME "bin\java.exe"
        if ((Test-Path $javaHomeJavac) -and (Test-Path $javaHomeJava)) {
            $javac = $javaHomeJavac
            $java = $javaHomeJava
        }
    }

    # Fall back to commands from PATH if JAVA_HOME is not available.
    if ($null -eq $javac) {
        $javac = Get-Command javac -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        $java = Get-Command java -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    }

    if ($null -eq $javac) {
        # Check standard installation paths on Windows
        $jdkDirs = @(
            "C:\Program Files\Java",
            "C:\Program Files (x86)\Java",
            "$env:USERPROFILE\.jdks"
        )
        
        foreach ($dir in $jdkDirs) {
            if (Test-Path $dir) {
                # Look for javac.exe in subdirectories
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
        Write-Host "Please ensure JDK is installed and javac is accessible." -ForegroundColor Yellow
        exit 1
    }

    # Clean up double quotes/formatting
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
    
    # Try using Get-NetTCPConnection (PowerShell 4.0+)
    $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($connections) {
        foreach ($conn in $connections) {
            $pid = $conn.OwningProcess
            if ($pid -and $pid -ne 0 -and $pid -ne $PID) {
                Write-Host "Found process $pid listening on port $Port. Killing it..." -ForegroundColor Cyan
                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
        }
    } else {
        # Fallback using netstat
        $netstat = netstat -ano | Select-String "LISTENING" | Select-String ":$Port\s"
        if ($netstat) {
            foreach ($line in $netstat) {
                if ($line.Line -match '\s+(\d+)\s*$') {
                    $pid = $Matches[1]
                    if ($pid -and $pid -ne 0 -and $pid -ne $PID) {
                        Write-Host "Found process $pid listening on port $Port via netstat. Killing it..." -ForegroundColor Cyan
                        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 1
                    }
                }
            }
        }
    }
}

function Start-DateTimeCheckerServerForDemo {
    param(
        [string]$Java,
        [string]$Classes,
        [string]$Root
    )

    # Free up port 4173 first
    Stop-RunningServer

    $port = 4173
    Write-Host "Starting background test server on port $port..." -ForegroundColor Yellow

    # Run Java App in background using a hidden window to prevent console handle sharing and hangs
    $proc = Start-Process -FilePath $Java -ArgumentList "-cp", $Classes, "com.datetimechecker.App" -PassThru -WindowStyle Hidden

    # Wait for the port to open and server to be ready
    $ready = $false
    for ($i = 0; $i -lt 15; $i++) {
        $tcp = $null
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect("127.0.0.1", $port)
            $ready = $true
            break
        } catch {
            # Ignore connection errors while waiting
        } finally {
            if ($null -ne $tcp) {
                $tcp.Close()
            }
        }
        Start-Sleep -Milliseconds 300
    }

    if (-not $ready) {
        Write-Host "[WARNING] Server port $port did not respond within timeout." -ForegroundColor Red
    } else {
        Write-Host "Server is ready." -ForegroundColor Green
    }

    return [PSCustomObject]@{
        Url = "http://localhost:$port"
        Started = $true
        Process = $proc
    }
}


