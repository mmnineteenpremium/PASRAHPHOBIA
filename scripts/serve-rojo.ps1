$ErrorActionPreference = 'Stop'

# Launch Rojo 7.6.1 serve using the project.json in whatever directory the user opened the terminal.
$projectPath = Join-Path (Get-Location) 'default.project.json'
if (-not (Test-Path $projectPath)) {
    Write-Error "default.project.json not found from $(Get-Location)"
    exit 1
}

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$aftmanRojo = Join-Path $repoRoot '.aftman\bin\rojo.exe'
$localRojo = Join-Path $repoRoot 'rojo-7.6.1\rojo.exe'

if (Test-Path $aftmanRojo) {
    $rojoLauncher = $aftmanRojo
    $rojoLabel = 'Aftman (7.6.1)'
} elseif (Test-Path $localRojo) {
    $rojoLauncher = $localRojo
    $rojoLabel = 'Local (7.6.1)'
} else {
    Write-Error 'Cannot find Rojo 7.6.1. Run `aftman install` in the repo root.'
    exit 1
}

Write-Host "Serving $projectPath with Rojo $rojoLabel"
& $rojoLauncher serve --project $projectPath
