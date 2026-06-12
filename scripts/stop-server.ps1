# scripts/stop-server.ps1

if ($global:SERVER_PID) {
    Write-Host "Killing server process with PID $global:SERVER_PID..."
    taskkill /PID $global:SERVER_PID /F 2>$null
    $global:SERVER_PID = $null
}

# Fallback: kill anything on port 4173 via netstat
$netstat = netstat -ano | Select-String ":4173"
if ($netstat) {
    foreach ($line in $netstat) {
        if ($line.Line -match '\s+(\d+)\s*$') {
            $pidToKill = $Matches[1]
            if ($pidToKill -and $pidToKill -ne 0) {
                Write-Host "Fallback: Killing process on port 4173 (PID: $pidToKill)..."
                taskkill /PID $pidToKill /F 2>$null
            }
        }
    }
}

Write-Host "[SERVER STOPPED]"
