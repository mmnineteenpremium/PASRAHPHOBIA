param(
    [string]$PlaceId = '89787959603872',
    [string]$UniverseId = '10138560838',
    [string]$ApiKey = $env:ROBLOX_OPEN_CLOUD_API_KEY,
    [string]$Project = 'default.project.json',
    [int]$Retries = 6,
    [int]$RetryDelaySeconds = 120
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$projectPath = Join-Path $repoRoot $Project

if ([string]::IsNullOrWhiteSpace($PlaceId)) {
    throw 'PlaceId is required.'
}

if ([string]::IsNullOrWhiteSpace($UniverseId)) {
    throw 'UniverseId is required.'
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'ROBLOX_OPEN_CLOUD_API_KEY is required. Set it in the terminal; do not commit it.'
}

if (-not (Test-Path $projectPath)) {
    throw "Project file not found: $projectPath"
}

$rojoScript = Join-Path $repoRoot 'scripts\Invoke-Rojo.ps1'
$maxAttempts = [Math]::Max(1, $Retries)
$exitCode = 1
$studioProcesses = Get-Process -Name RobloxStudioBeta -ErrorAction SilentlyContinue

if ($studioProcesses) {
    Write-Warning 'Roblox Studio is currently open. Close Studio before publishing if it is attached to the same place or if Roblox returns Conflict/Server busy.'
}

for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    Write-Host "Publishing branch target to PlaceId=$PlaceId UniverseId=$UniverseId (attempt $attempt/$maxAttempts)..."
    & $rojoScript upload --api_key $ApiKey --asset_id $PlaceId --universe_id $UniverseId $Project
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        exit 0
    }

    if ($attempt -lt $maxAttempts) {
        Write-Warning "Rojo upload failed with exit code $exitCode. Retrying in $RetryDelaySeconds seconds..."
        Start-Sleep -Seconds $RetryDelaySeconds
    }
}

exit $exitCode
