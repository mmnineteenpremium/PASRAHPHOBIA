param(
    [string]$BlenderPath = "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
    [string]$InputPath,
    [string]$OutputPath,
    [string]$Name,
    [string]$ReportPath,
    [double]$Fps = 30.0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($InputPath)) {
    throw "InputPath is required."
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    throw "OutputPath is required."
}
if (-not (Test-Path -LiteralPath $BlenderPath)) {
    throw "Blender executable was not found: $BlenderPath"
}
if (-not (Test-Path -LiteralPath $InputPath)) {
    throw "Input FBX was not found: $InputPath"
}

$scriptPath = Join-Path $PSScriptRoot "blender_fbx_animation_to_rbxmx.py"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Converter script was not found: $scriptPath"
}

$argsList = @(
    "--background",
    "--python", $scriptPath,
    "--",
    "--input", $InputPath,
    "--output", $OutputPath,
    "--fps", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0}", $Fps))
)

if (-not [string]::IsNullOrWhiteSpace($Name)) {
    $argsList += @("--name", $Name)
}
if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    $argsList += @("--report", $ReportPath)
}

& $BlenderPath @argsList
if ($LASTEXITCODE -ne 0) {
    throw "Blender conversion failed with exit code $LASTEXITCODE."
}
