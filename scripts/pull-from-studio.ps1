param(
    [string]$InputPath = 'PASRAHPHOBIA.rbxlx',
    [string]$ProjectPath = 'syncback.ghosts.project.json'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$resolvedProjectPath = Join-Path $repoRoot $ProjectPath
$resolvedInputPath = Join-Path $repoRoot $InputPath
$inputPathForSyncback = $resolvedInputPath
$rojo77Path = Join-Path $env:USERPROFILE '.aftman\tool-storage\rojo-rbx\rojo\7.7.0-rc.1\rojo.exe'

function Resolve-SyncbackRojo {
    param(
        [string]$RepoRoot
    )

    if (Test-Path $rojo77Path) {
        return $rojo77Path
    }

    $repoPinned = Join-Path $RepoRoot '.aftman\bin\rojo.exe'
    if (Test-Path $repoPinned) {
        $helpText = & $repoPinned '--help' 2>$null
        if ($LASTEXITCODE -eq 0 -and ($helpText -match '\bsyncback\b')) {
            return $repoPinned
        }
    }

    $rojoCommand = Get-Command rojo -ErrorAction SilentlyContinue
    if ($rojoCommand) {
        $helpText = & $rojoCommand.Source '--help' 2>$null
        if ($LASTEXITCODE -eq 0 -and ($helpText -match '\bsyncback\b')) {
            return $rojoCommand.Source
        }
    }

    Write-Error 'Cannot find a Rojo binary with syncback support. Install Rojo 7.7.x or newer via aftman.'
    exit 1
}

function Restore-PocongGhostArtifacts {
    param(
        [string]$RepoRoot
    )

    $pocongModelPath = Join-Path $RepoRoot 'src\ReplicatedStorage\Assets\Models\Ghosts\Pocong.model.json'
    $pocongProfilePath = Join-Path $RepoRoot 'src\ReplicatedStorage\Assets\GhostVisualProfiles\Pocong.lua'

    $pocongModel = @'
{
  "className": "Model",
  "properties": {
    "Name": "Pocong"
  },
  "children": [
    {
      "className": "Part",
      "properties": {
        "Name": "HumanoidRootPart",
        "Anchored": true,
        "CanCollide": false,
        "CanTouch": false,
        "CanQuery": false,
        "Transparency": 1.0,
        "Position": [
          0.0,
          0.0,
          0.0
        ],
        "Size": [
          2.0,
          2.0,
          1.0
        ],
        "Material": "SmoothPlastic",
        "Color": [
          0.31,
          0.34,
          0.38
        ]
      }
    },
    {
      "className": "MeshPart",
      "properties": {
        "Name": "material",
        "Anchored": true,
        "CanCollide": false,
        "CanTouch": false,
        "CanQuery": false,
        "Transparency": 0.0,
        "Position": [
          0.0,
          0.1,
          0.0
        ],
        "Size": [
          1.4,
          5.2,
          1.2
        ],
        "MeshId": "rbxassetid://118360815663860",
        "TextureID": ""
      },
      "children": [
        {
          "className": "SurfaceAppearance",
          "properties": {
            "Name": "SurfaceAppearance",
            "ColorMap": "rbxassetid://119582538265133",
            "NormalMap": "rbxassetid://133491195386808",
            "RoughnessMap": "rbxassetid://108763420495258",
            "MetalnessMap": "rbxassetid://112794460017202"
          }
        }
      ]
    }
  ]
}
'@

    $pocongProfile = @'
return {
	profileType = "SingleMesh",
	modelName = "Ghost_Pocong",
	meshPartName = "material",
	rootSize = { 2, 2, 1 },
	size = { 1.4, 5.2, 1.2 },
	visualOffset = { 0, 0.1, 0 },
	meshId = "rbxassetid://118360815663860",
	textureId = "",
	colorMap = "rbxassetid://119582538265133",
	normalMap = "rbxassetid://133491195386808",
	roughnessMap = "rbxassetid://108763420495258",
	metalnessMap = "rbxassetid://112794460017202",
	transparency = 0,
	castShadow = false,
}
'@

    Set-Content -Path $pocongModelPath -Value $pocongModel
    Set-Content -Path $pocongProfilePath -Value $pocongProfile
}

if (-not (Test-Path $resolvedProjectPath)) {
    Write-Error "Syncback project file not found: $resolvedProjectPath"
    exit 1
}

if (-not (Test-Path $resolvedInputPath)) {
    Write-Error "Studio snapshot not found: $resolvedInputPath. Save the open Studio place to this file first, or pass -InputPath."
    exit 1
}

$extension = [System.IO.Path]::GetExtension($resolvedInputPath)
if ($extension -ieq '.rbxlx') {
    $headerBytes = [System.IO.File]::ReadAllBytes($resolvedInputPath)
    if ($headerBytes.Length -ge 8) {
        $headerText = [System.Text.Encoding]::ASCII.GetString($headerBytes, 0, 8)
        if ($headerText -eq '<roblox!') {
            $binaryInputPath = [System.IO.Path]::ChangeExtension($resolvedInputPath, '.rbxl')
            Copy-Item $resolvedInputPath $binaryInputPath -Force
            $inputPathForSyncback = $binaryInputPath
            Write-Host "Detected binary Roblox place data stored as .rbxlx. Using $binaryInputPath for syncback."
        }
    }
}

$syncbackRojo = Resolve-SyncbackRojo -RepoRoot $repoRoot
Write-Host "Syncing Studio snapshot $inputPathForSyncback back into the repo"
& $syncbackRojo 'syncback' $resolvedProjectPath '--input' $inputPathForSyncback '-y'

Restore-PocongGhostArtifacts -RepoRoot $repoRoot
