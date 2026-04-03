param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RojoArgs
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$aftmanRojo = Join-Path $repoRoot '.aftman\bin\rojo.exe'

if (Test-Path $aftmanRojo) {
    $rojoLauncher = $aftmanRojo
} else {
    $rojoCommand = Get-Command rojo -ErrorAction SilentlyContinue
    if (-not $rojoCommand) {
        Write-Error 'Cannot find Rojo. Run `aftman install` in the repo root first.'
        exit 1
    }

    $rojoLauncher = $rojoCommand.Source
}

& $rojoLauncher @RojoArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
