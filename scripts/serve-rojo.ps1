$ErrorActionPreference = 'Stop'

# Launch the repo-pinned Rojo serve using the project.json in whatever directory the user opened the terminal.
$projectPath = Join-Path (Get-Location) 'default.project.json'
if (-not (Test-Path $projectPath)) {
    Write-Error "default.project.json not found from $(Get-Location)"
    exit 1
}

$invokeRojo = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) 'Invoke-Rojo.ps1'

Write-Host "Serving $projectPath with repo-pinned Rojo"
& $invokeRojo 'serve' $projectPath '--port' '34872'
