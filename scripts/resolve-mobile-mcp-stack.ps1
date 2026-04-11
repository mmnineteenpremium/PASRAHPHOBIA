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

$requiredAndroidModels = [ordered]@{
    "Samsung-N960" = "^SM-N960"
}

$requiredIosDevices = @(
    [pscustomobject]@{
        alias = "iPhone-14-Pro-Max"
        productType = "iPhone15,3"
        namePattern = "iPhone 14 Pro Max"
    }
)

$goIosCandidates = @()
if (-not [string]::IsNullOrWhiteSpace($env:GO_IOS_PATH)) {
    $goIosCandidates += $env:GO_IOS_PATH
}
$goIosCandidates += @(
    (Join-Path $env:USERPROFILE "go\bin\go-ios.exe"),
    "go-ios.exe",
    "ios"
)

$goIosPath = $null
foreach ($candidate in $goIosCandidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        continue
    }

    if (Test-Path $candidate) {
        $goIosPath = (Resolve-Path $candidate).Path
        break
    }

    $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($cmd) {
        $goIosPath = $cmd.Source
        break
    }
}

$androidDevices = @()
$legacyEmulators = @()
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

    $isEmulator = $deviceId -like "emulator-*"
    $alias = $null
    foreach ($entry in $requiredAndroidModels.GetEnumerator()) {
        if ($model -match $entry.Value) {
            $alias = $entry.Key
            break
        }
    }

    $androidDevices += [pscustomobject]@{
        alias = $alias
        deviceId = $deviceId
        state = $state
        model = $model
        isEmulator = $isEmulator
    }

    if ($isEmulator) {
        $legacyEmulators += $deviceId
    }
}

$missingAndroid = @()
foreach ($entry in $requiredAndroidModels.GetEnumerator()) {
    $match = $androidDevices | Where-Object { $_.alias -eq $entry.Key -and $_.state -eq "device" -and -not $_.isEmulator }
    if (-not $match) {
        $missingAndroid += $entry.Key
    }
}

$iosDevices = @()
$iosIssues = @()

if (-not $goIosPath) {
    $iosIssues += "go-ios command not found (set GO_IOS_PATH or install go-ios)"
} else {
    $iosRaw = $null
    try {
        $iosRaw = & $goIosPath list
        $iosList = $iosRaw | ConvertFrom-Json
        if ($iosList.deviceList) {
            foreach ($udid in $iosList.deviceList) {
                $deviceName = $null
                $productType = $null
                $productVersion = $null

                try {
                    $info = (& $goIosPath info --udid $udid | ConvertFrom-Json)
                    $deviceName = $info.DeviceName
                    $productType = $info.ProductType
                    $productVersion = $info.ProductVersion
                } catch {
                    $iosIssues += "Failed to query iOS info for ${udid}: $($_.Exception.Message)"
                }

                $alias = $null
                foreach ($required in $requiredIosDevices) {
                    $nameMatch = -not [string]::IsNullOrWhiteSpace($deviceName) -and $deviceName -match $required.namePattern
                    $productMatch = -not [string]::IsNullOrWhiteSpace($productType) -and $productType -eq $required.productType
                    if ($nameMatch -or $productMatch) {
                        $alias = $required.alias
                        break
                    }
                }

                $iosDevices += [pscustomobject]@{
                    alias = $alias
                    deviceId = $udid
                    state = "device"
                    deviceName = $deviceName
                    productType = $productType
                    productVersion = $productVersion
                }
            }
        }
    } catch {
        $iosIssues += "Failed to list iOS devices: $($_.Exception.Message)"
    }
}

$missingIos = @()
foreach ($required in $requiredIosDevices) {
    $match = $iosDevices | Where-Object { $_.alias -eq $required.alias -and $_.state -eq "device" }
    if (-not $match) {
        $missingIos += $required.alias
    }
}

$missing = @($missingAndroid + $missingIos)

$result = [pscustomobject]@{
    ready = ($missing.Count -eq 0)
    adbPath = $adbPath
    mobileMcpPath = $mobileMcpPath
    robloxStudioMcpBat = $robloxStudioMcpBat
    rojoServeScript = $rojoServeScript
    androidDevices = $androidDevices
    iosDevices = $iosDevices
    legacyEmulators = $legacyEmulators
    iosIssues = $iosIssues
    goIosPath = $goIosPath
    requiredAndroidModels = $requiredAndroidModels
    requiredIosDevices = $requiredIosDevices
    missing = $missing
}

$json = $result | ConvertTo-Json -Depth 6
Write-Output $json

if ($Strict -and $missing.Count -gt 0) {
    $msg = "Required physical devices missing or offline: $($missing -join ', ')"
    if ($iosIssues.Count -gt 0) {
        $msg += ". iOS discovery issues: $($iosIssues -join '; ')"
    }
    throw $msg
}
