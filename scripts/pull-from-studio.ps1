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
