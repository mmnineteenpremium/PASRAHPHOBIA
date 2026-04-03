param(
    [string]$InputPath = 'PASRAHPHOBIA.rbxlx',
    [string]$ProjectPath = 'syncback.ghosts.project.json'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$resolvedProjectPath = Join-Path $repoRoot $ProjectPath
$resolvedInputPath = Join-Path $repoRoot $InputPath
$inputPathForSyncback = $resolvedInputPath

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

$invokeRojo = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) 'Invoke-Rojo.ps1'
Write-Host "Syncing Studio snapshot $inputPathForSyncback back into the repo"
& $invokeRojo 'syncback' $resolvedProjectPath '--input' $inputPathForSyncback '-y'
