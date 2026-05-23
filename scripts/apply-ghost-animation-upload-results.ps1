param(
    [string]$ResultsPath = ".codex/asset-imports/20260513-ghost-animation-rbxm/roblox-upload-results.json",
    [string]$AnimationsRoot = "src/ReplicatedStorage/Assets/Animations/Ghosts",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$loopedByRuntimeKey = @{
    GhostIdle = $true
    GhostRoam = $true
    GhostHunt = $true
    GhostManifest = $false
    GhostAttack = $false
    GhostJumpscare = $false
    GhostCooldown = $false
}

function New-AnimationModelJson([string]$assetId, [bool]$looped) {
    $children = @(
        [ordered]@{
            name = "Looped"
            className = "BoolValue"
            properties = [ordered]@{
                Value = $looped
            }
        }
    )

    return [ordered]@{
        className = "Animation"
        children = $children
        properties = [ordered]@{
            AnimationId = "rbxassetid://$assetId"
        }
    } | ConvertTo-Json -Depth 20
}

function Write-Utf8NoBom([string]$path, [string]$content) {
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($path, $content, $encoding)
}

if (-not (Test-Path -LiteralPath $ResultsPath)) {
    throw "Upload results file was not found: $ResultsPath"
}

$results = Get-Content -LiteralPath $ResultsPath -Raw | ConvertFrom-Json
if ($null -eq $results) {
    throw "Upload results file is empty: $ResultsPath"
}
if ($results -isnot [System.Collections.IEnumerable] -or $results -is [string]) {
    $results = @($results)
}

$applied = New-Object System.Collections.Generic.List[object]

foreach ($item in $results) {
    if ([string]$item.status -ne "uploaded") {
        continue
    }

    $ghost = [string]$item.ghost
    $runtimeKey = [string]$item.runtimeKey
    $assetId = [string]$item.assetId

    if ([string]::IsNullOrWhiteSpace($ghost) -or [string]::IsNullOrWhiteSpace($runtimeKey) -or [string]::IsNullOrWhiteSpace($assetId)) {
        continue
    }

    if (-not $loopedByRuntimeKey.ContainsKey($runtimeKey)) {
        throw "Unknown runtimeKey '$runtimeKey' in upload result '$($item.key)'."
    }

    $ghostDir = Join-Path $AnimationsRoot $ghost
    $targetPath = Join-Path $ghostDir "$runtimeKey.model.json"

    $applied.Add([ordered]@{
        key = $item.key
        ghost = $ghost
        runtimeKey = $runtimeKey
        assetId = $assetId
        targetPath = $targetPath
        looped = [bool]$loopedByRuntimeKey[$runtimeKey]
        status = if ($DryRun) { "dry_run_ready" } else { "written" }
    })

    if ($DryRun) {
        continue
    }

    New-Item -ItemType Directory -Path $ghostDir -Force | Out-Null
    $json = New-AnimationModelJson -assetId $assetId -looped ([bool]$loopedByRuntimeKey[$runtimeKey])
    Write-Utf8NoBom -path $targetPath -content $json
}

$applied | ConvertTo-Json -Depth 20
Write-Host "Prepared $($applied.Count) per-ghost animation model JSON entries."
