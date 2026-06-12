. "$PSScriptRoot\common.ps1"

$tools = Get-JavaTools
$classPath = Join-Path $PSScriptRoot "..\out\classes"

& $tools.Java -cp $classPath com.datetimechecker.App
exit $LASTEXITCODE
