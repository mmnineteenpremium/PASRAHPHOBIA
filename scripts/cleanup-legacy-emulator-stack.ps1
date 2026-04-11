param(
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

$androidHome = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
$adbPath = Join-Path $androidHome "platform-tools\adb.exe"

$result = [ordered]@{
    adbPath = $adbPath
    emulatorIds = @()
    killedEmulators = @()
    stoppedProcesses = @()
    hypervState = $null
    warnings = @()
}

if (-not (Test-Path $adbPath)) {
    throw "adb.exe not found at $adbPath"
}

foreach ($line in (& $adbPath devices)) {
    if ($line -match "^(emulator-\d+)\s+") {
        $result.emulatorIds += $Matches[1]
    }
}

foreach ($emulatorId in $result.emulatorIds) {
    try {
        & $adbPath disconnect $emulatorId | Out-Null
        & $adbPath -s $emulatorId emu kill | Out-Null
        $result.killedEmulators += $emulatorId
    } catch {
        $result.warnings += "Unable to kill ${emulatorId}: $($_.Exception.Message)"
    }
}

$legacyProcessNames = @(
    "dnplayer",
    "dnmultiplayer",
    "LdBoxHeadless",
    "LdBoxSVC",
    "LdVBoxHeadless",
    "Ld9BoxHeadless",
    "qemu-system-x86_64",
    "qemu-system-x86_64-headless"
)

foreach ($name in $legacyProcessNames) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    foreach ($proc in $procs) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            $result.stoppedProcesses += "$($proc.ProcessName):$($proc.Id)"
        } catch {
            $result.warnings += "Unable to stop process $($proc.ProcessName):$($proc.Id) - $($_.Exception.Message)"
        }
    }
}

try {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
    $result.hypervState = $feature.State.ToString()
} catch {
    $result.warnings += "Could not query Hyper-V state: $($_.Exception.Message)"
}

if ($Strict -and $result.hypervState -ne "Disabled") {
    throw "Hyper-V still enabled: $($result.hypervState)"
}

$result | ConvertTo-Json -Depth 6
