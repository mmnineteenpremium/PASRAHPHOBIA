param(
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

$androidHome = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
$adbPath = Join-Path $androidHome "platform-tools\adb.exe"
$mobileMcpPath = "C:\Users\User\.codex\memories\mobile-mcp-local\lib\index.js"
$robloxStudioMcpBat = Join-Path $env:LOCALAPPDATA "Roblox\mcp.bat"
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$rojoServeScript = Join-Path $projectRoot "scripts\serve-rojo.ps1"

if (-not (Test-Path $adbPath)) {
    throw "adb.exe not found at $adbPath"
}
if (-not (Test-Path $mobileMcpPath)) {
    throw "mobile-mcp build not found at $mobileMcpPath"
}
if (-not (Test-Path $robloxStudioMcpBat)) {
    throw "Roblox Studio MCP launcher not found at $robloxStudioMcpBat"
}
if (-not (Test-Path $rojoServeScript)) {
    throw "Rojo serve script not found at $rojoServeScript"
}

$requiredModels = [ordered]@{
    "Samsung-NOTE10" = "SM-N971N"
    "S22-ultra" = "SM-S908N"
}

$devices = @()
foreach ($line in (& $adbPath devices -l)) {
    if ($line -notmatch "^(?<id>\S+)\s+(?<state>device|offline|unauthorized)\b") {
        continue
    }

    $deviceId = $Matches["id"]
    $state = $Matches["state"]
    $model = $null

    if ($line -match "model:(?<model>\S+)") {
        $model = $Matches["model"].Replace("_", "-")
    }

    if ([string]::IsNullOrWhiteSpace($model)) {
        try {
            $model = (& $adbPath -s $deviceId shell getprop ro.product.model).Trim()
        } catch {
            $model = ""
        }
    }

    $alias = $null
    foreach ($entry in $requiredModels.GetEnumerator()) {
        if ($model -eq $entry.Value) {
            $alias = $entry.Key
            break
        }
    }

    $devices += [pscustomobject]@{
        alias = $alias
        deviceId = $deviceId
        state = $state
        model = $model
    }
}

$missing = @()
foreach ($entry in $requiredModels.GetEnumerator()) {
    $match = $devices | Where-Object { $_.alias -eq $entry.Key -and $_.state -eq "device" }
    if (-not $match) {
        $missing += $entry.Key
    }
}

$result = [pscustomobject]@{
    ready = ($missing.Count -eq 0)
    adbPath = $adbPath
    mobileMcpPath = $mobileMcpPath
    robloxStudioMcpBat = $robloxStudioMcpBat
    rojoServeScript = $rojoServeScript
    devices = $devices
    missing = $missing
}

$json = $result | ConvertTo-Json -Depth 6
Write-Output $json

if ($Strict -and $missing.Count -gt 0) {
    throw "Required Android emulators missing or offline: $($missing -join ', ')"
}
