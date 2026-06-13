. "$PSScriptRoot\common.ps1"

$tools = Get-JavaTools
$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path

Stop-RunningServer
& "$PSScriptRoot\build.ps1"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$classPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\out\classes")).Path

Set-Location -Path $repoRoot
& $tools.Java -cp $classPath com.datetimechecker.App
exit $LASTEXITCODE
