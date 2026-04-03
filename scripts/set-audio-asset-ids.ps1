param(
    [string]$AmbientLoopMainId,
    [string]$EnvironmentalCreakId,
    [string]$GhostManifestId,
    [string]$GhostWhisperId,
    [string]$HuntStartId,
    [string]$UIButtonClickId,
    [switch]$ShowCurrent
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')

$targets = @(
    @{
        Name = 'AmbientLoop_Main'
        Path = 'src\ReplicatedStorage\Assets\Audio\Ambient\AmbientLoop_Main.model.json'
        AssetId = $AmbientLoopMainId
    },
    @{
        Name = 'EnvironmentalCreak_01'
        Path = 'src\ReplicatedStorage\Assets\Audio\Environment\EnvironmentalCreak_01.model.json'
        AssetId = $EnvironmentalCreakId
    },
    @{
        Name = 'GhostManifest_01'
        Path = 'src\ReplicatedStorage\Assets\Audio\Ghost\GhostManifest_01.model.json'
        AssetId = $GhostManifestId
    },
    @{
        Name = 'GhostWhisper_01'
        Path = 'src\ReplicatedStorage\Assets\Audio\Ghost\GhostWhisper_01.model.json'
        AssetId = $GhostWhisperId
    },
    @{
        Name = 'HuntStart_01'
        Path = 'src\ReplicatedStorage\Assets\Audio\Ghost\HuntStart_01.model.json'
        AssetId = $HuntStartId
    },
    @{
        Name = 'ButtonClick_01'
        Path = 'src\ReplicatedStorage\Assets\Audio\UI\ButtonClick_01.model.json'
        AssetId = $UIButtonClickId
    }
)

function Resolve-AudioContent([string]$assetId) {
    if ([string]::IsNullOrWhiteSpace($assetId)) {
        return $null
    }

    $trimmed = $assetId.Trim()
    if ($trimmed -match '^rbxassetid://\d+$') {
        return $trimmed
    }
    if ($trimmed -match '^\d+$') {
        return "rbxassetid://$trimmed"
    }

    throw "Invalid asset id format: $assetId"
}

if ($ShowCurrent) {
    foreach ($target in $targets) {
        $fullPath = Join-Path $repoRoot $target.Path
        if (-not (Test-Path $fullPath)) {
            Write-Host "$($target.Name): missing file"
            continue
        }

        $json = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
        $audioContent = $json.properties.AudioContent
        if ([string]::IsNullOrWhiteSpace($audioContent)) {
            $audioContent = '<empty>'
        }
        Write-Host "$($target.Name): $audioContent"
    }

    if (-not ($AmbientLoopMainId -or $EnvironmentalCreakId -or $GhostManifestId -or $GhostWhisperId -or $HuntStartId -or $UIButtonClickId)) {
        exit 0
    }
}

$updated = 0

foreach ($target in $targets) {
    $audioContent = Resolve-AudioContent $target.AssetId
    if ($null -eq $audioContent) {
        continue
    }

    $fullPath = Join-Path $repoRoot $target.Path
    if (-not (Test-Path $fullPath)) {
        throw "Target file not found: $fullPath"
    }

    $json = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
    if ($null -eq $json.properties) {
        throw "JSON missing properties block: $fullPath"
    }

    $json.properties.AudioContent = $audioContent
    $serialized = $json | ConvertTo-Json -Depth 16
    Set-Content -LiteralPath $fullPath -Value $serialized
    Write-Host "Updated $($target.Name) -> $audioContent"
    $updated += 1
}

if ($updated -eq 0) {
    Write-Host 'No audio asset IDs were provided. Nothing changed.'
}
