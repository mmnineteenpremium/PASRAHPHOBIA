param(
    [string]$PlacePath = "_tmp_release_preflight_build.rbxlx"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "..")
$resolvedPlacePath = (Resolve-Path (Join-Path $repoRoot $PlacePath) -ErrorAction Stop).Path

if (-not (Test-Path $resolvedPlacePath)) {
    throw "Place file not found: $resolvedPlacePath"
}

$versionsRoot = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
if (-not (Test-Path $versionsRoot)) {
    throw "Roblox versions directory not found: $versionsRoot"
}

$studioExe = Get-ChildItem -Path $versionsRoot -Directory |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object { Join-Path $_.FullName "RobloxStudioBeta.exe" } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if (-not $studioExe) {
    throw "RobloxStudioBeta.exe not found under: $versionsRoot"
}

Start-Process -FilePath $studioExe -ArgumentList "`"$resolvedPlacePath`"" -WindowStyle Maximized
Write-Host "Opened Roblox Studio maximized: $studioExe $resolvedPlacePath"
