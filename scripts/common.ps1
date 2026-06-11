function Get-JavaTools {
    # Check if javac is in current PATH
    $javac = Get-Command javac -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    $java = Get-Command java -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

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

function Start-DateTimeCheckerServerForDemo {
    param(
        [string]$Java,
        [string]$Classes,
        [string]$Root
    )

    $port = 4173
    Write-Host "Starting background test server on port $port..." -ForegroundColor Yellow

    # Run Java App in background
    $proc = Start-Process -FilePath $Java -ArgumentList "-cp", $Classes, "com.datetimechecker.App" -PassThru -NoNewWindow

    # Wait for the port to open and server to be ready
    $ready = $false
    for ($i = 0; $i -lt 10; $i++) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $connect = $tcp.BeginConnect("127.0.0.1", $port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(500, $false)
            if ($tcp.Connected) {
                $tcp.Close()
                $ready = $true
                break
            }
            $tcp.Close()
        } catch {
            # Ignore connection errors while waiting
        }
        Start-Sleep -Milliseconds 500
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


