param(
    [string]$SourceRoot = "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\GHOST\ALL_GHOSTS_FINAL",
    [string]$NormalizedAnimationRoot = "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-animation-rbxm\normalized-animation-fbx",
    [string]$OutputPath = ".codex/asset-imports/20260513-ghost-animation-rbxm/roblox-upload-plan.json",
    [string]$ConvertedExtension = ".rbxmx"
)

$ErrorActionPreference = "Stop"

if ($ConvertedExtension -notin @(".rbxm", ".rbxmx")) {
    throw "ConvertedExtension must be .rbxm or .rbxmx."
}

$ghostBaseRigIds = [ordered]@{
    Banaspati = "125985418520274"
    Genderuwo = "116514308503184"
    HantuTanah = "97068595212213"
    Jerangkong = "115554451751983"
    Kuntilanak = "111714179492317"
    Leak = "98855032697085"
    Palasik = "78260225419720"
    Pocong = "135270375666027"
    SilumanUlar = "87361945667344"
    SundelBolong = "89326336764042"
    Tuyul = "128588579954533"
    WeweGombel = "101666948803556"
}

$clipAliases = @(
    [ordered]@{ sourceClip = "Idle"; runtimeKey = "GhostIdle" }
    [ordered]@{ sourceClip = "WalkPatrol"; runtimeKey = "GhostRoam" }
    [ordered]@{ sourceClip = "HuntStride"; runtimeKey = "GhostHunt" }
    [ordered]@{ sourceClip = "Manifest"; runtimeKey = "GhostManifest" }
    [ordered]@{ sourceClip = "Attack"; runtimeKey = "GhostAttack" }
    [ordered]@{ sourceClip = "Jumpscare"; runtimeKey = "GhostJumpscare" }
    [ordered]@{ sourceClip = "Vanish"; runtimeKey = "GhostCooldown" }
)

function Get-RelativePathCompat([string]$basePath, [string]$path) {
    $baseUri = [System.Uri](([System.IO.Path]::GetFullPath($basePath).TrimEnd('\') + '\'))
    $pathUri = [System.Uri]([System.IO.Path]::GetFullPath($path))
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "Source root was not found: $SourceRoot"
}

$items = New-Object System.Collections.Generic.List[object]

foreach ($ghostName in $ghostBaseRigIds.Keys) {
    $animationDir = Join-Path (Join-Path $SourceRoot $ghostName) "_generated_animations"
    if (-not (Test-Path -LiteralPath $animationDir)) {
        throw "Animation folder was not found for $ghostName`: $animationDir"
    }

    foreach ($alias in $clipAliases) {
        $sourceClip = [string]$alias.sourceClip
        $runtimeKey = [string]$alias.runtimeKey
        $sourceMatches = @(
            Get-ChildItem -LiteralPath $animationDir -Filter "$ghostName`_$sourceClip`_*.fbx" -File |
                Where-Object {
                    $_.Name -notmatch '\.wrong-' -and
                    $_.Name -notmatch '\.backup' -and
                    $_.Name -notmatch '\.bak'
                }
        )

        if ($sourceMatches.Count -ne 1) {
            $matchNames = ($sourceMatches | Select-Object -ExpandProperty Name) -join ", "
            throw "Expected exactly one FBX for $ghostName/$sourceClip, found $($sourceMatches.Count): $matchNames"
        }

        $sourceFbxPath = $sourceMatches[0].FullName
        $sourceFbx = Get-RelativePathCompat -basePath $SourceRoot -path $sourceFbxPath
        $sourceOverride = $null

        $normalizedGhostDir = Join-Path $NormalizedAnimationRoot $ghostName
        if (Test-Path -LiteralPath $normalizedGhostDir) {
            $normalizedMatches = @(Get-ChildItem -LiteralPath $normalizedGhostDir -Filter "$ghostName`_$sourceClip`_*_NORMALIZED.fbx" -File)
            if ($normalizedMatches.Count -gt 1) {
                $matchNames = ($normalizedMatches | Select-Object -ExpandProperty Name) -join ", "
                throw "Expected at most one normalized FBX for $ghostName/$sourceClip, found $($normalizedMatches.Count): $matchNames"
            }
            if ($normalizedMatches.Count -eq 1) {
                $sourceFbxPath = $normalizedMatches[0].FullName
                $sourceFbx = $sourceFbxPath
                $sourceOverride = "normalized-animation-fbx"
            }
        }

        $convertedFile = Join-Path $ghostName "$ghostName`_$runtimeKey$ConvertedExtension"

        $items.Add([ordered]@{
            key = "$ghostName.$runtimeKey"
            ghost = $ghostName
            runtimeKey = $runtimeKey
            sourceClip = $sourceClip
            baseRigModelAssetId = $ghostBaseRigIds[$ghostName]
            sourceFbx = $sourceFbx
            sourceFbxPath = $sourceFbxPath
            sourceOverride = $sourceOverride
            file = $convertedFile
            displayName = "PASRAH_GHOST_${ghostName}_${runtimeKey}"
            description = "PASRAHPHOBIA ghost animation $ghostName $runtimeKey. Converted from $($sourceMatches[0].Name)."
        })
    }
}

$outputDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($OutputPath))
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$items | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Generated $($items.Count) ghost animation upload plan items: $OutputPath"
