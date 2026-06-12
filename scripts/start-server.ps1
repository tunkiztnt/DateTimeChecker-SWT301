# scripts/start-server.ps1
. "$PSScriptRoot\common.ps1"

Write-Host "Checking if port 4173 is already in use..."
$netstat = netstat -ano | Select-String "LISTENING" | Select-String ":4173\s"
if ($netstat) {
    foreach ($line in $netstat) {
        if ($line.Line -match '\s+(\d+)\s*$') {
            $pidToKill = $Matches[1]
            if ($pidToKill -and $pidToKill -ne 0) {
                Write-Host "Port 4173 is in use by PID $pidToKill. Killing it..."
                taskkill /PID $pidToKill /F 2>$null | Out-Null
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Compile Java source
Write-Host "Compiling Java source files..."
& "$PSScriptRoot\build.ps1"

# Find Java tools and start server
$tools = Get-JavaTools
Write-Host "Starting Java server..."
$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$proc = Start-Process -FilePath $tools.Java -ArgumentList "-cp", "$PSScriptRoot\..\out\classes", "com.datetimechecker.App" -WorkingDirectory $repoRoot -PassThru -WindowStyle Hidden
$global:SERVER_PID = $proc.Id

# Wait until the server is ready by polling
$ready = $false
for ($i = 0; $i -lt 15; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4173/api/check-date" -Method POST -Body "{}" -ContentType "application/json" -UseBasicParsing -TimeoutSec 1
        if ($response) {
            $ready = $true
            break
        }
    } catch {
        if ($_.Exception -and $_.Exception.Response) {
            # The server responded (e.g. 405 Method Not Allowed), meaning it is alive
            $ready = $true
            break
        }
    }
    Start-Sleep -Seconds 1
}

if ($ready) {
    Write-Host "[SERVER READY] Port 4173 is listening"
} else {
    Write-Host "[WARNING] Server did not respond within timeout"
}

return $global:SERVER_PID
