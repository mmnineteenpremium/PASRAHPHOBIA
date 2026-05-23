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

$requiredAndroidLanes = [ordered]@{
    # Canonical lane alias plus legacy hardware variants accepted by older runs.
    "Samsung-N960" = @("SM-N960", "SM-N971", "SM-S908")
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
        $model = $Matches["model"]
    }

    if ([string]::IsNullOrWhiteSpace($model)) {
        try {
            $model = (& $adbPath -s $deviceId shell getprop ro.product.model).Trim()
        } catch {
            $model = ""
        }
    }

    $normalizedModel = ""
    if (-not [string]::IsNullOrWhiteSpace($model)) {
        $normalizedModel = $model.Replace("_", "-").Trim().ToUpperInvariant()
    }

    $alias = $null
    foreach ($entry in $requiredAndroidLanes.GetEnumerator()) {
        foreach ($prefix in $entry.Value) {
            if ($normalizedModel.StartsWith($prefix)) {
                $alias = $entry.Key
                break
            }
        }
        if ($alias) {
            break
        }
    }

    $devices += [pscustomobject]@{
        alias = $alias
        deviceId = $deviceId
        state = $state
        model = $normalizedModel
    }
}

$missing = @()
foreach ($entry in $requiredAndroidLanes.GetEnumerator()) {
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
    throw "Required Android lanes missing or offline: $($missing -join ', ')"
}
