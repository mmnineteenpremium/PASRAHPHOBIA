param(
    [string]$BlenderPath = "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
    [string]$PlanPath = "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-animation-rbxm\roblox-upload-plan.json",
    [string]$OutputRoot = "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-animation-rbxm\converted",
    [string]$ReportPath = "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-animation-rbxm\conversion-results.json",
    [string[]]$Key = @(),
    [double]$Fps = 30.0,
    [switch]$OnlyMissing
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $BlenderPath)) {
    throw "Blender executable was not found: $BlenderPath"
}
if (-not (Test-Path -LiteralPath $PlanPath)) {
    throw "Plan file was not found: $PlanPath"
}

$scriptPath = Join-Path $PSScriptRoot "blender_fbx_animation_to_rbxmx.py"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Converter script was not found: $scriptPath"
}

$argsList = @(
    "--background",
    "--python", $scriptPath,
    "--",
    "--plan", $PlanPath,
    "--output-root", $OutputRoot,
    "--fps", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0}", $Fps)),
    "--report", $ReportPath
)

if ($OnlyMissing) {
    $argsList += "--only-missing"
}
foreach ($item in $Key) {
    if (-not [string]::IsNullOrWhiteSpace($item)) {
        $argsList += @("--key", $item)
    }
}

& $BlenderPath @argsList
if ($LASTEXITCODE -ne 0) {
    throw "Blender plan conversion failed with exit code $LASTEXITCODE."
}
