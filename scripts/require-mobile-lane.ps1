param(
    [ValidateSet("android", "ios", "both")]
    [string]$Lane = "both"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$resolver = Join-Path $projectRoot "scripts\resolve-mobile-mcp-stack.ps1"

if (-not (Test-Path $resolver)) {
    throw "Resolver script not found at $resolver"
}

$raw = & $resolver
$status = $raw | ConvertFrom-Json

$missingByLane = @()

if ($Lane -eq "android" -or $Lane -eq "both") {
    if (-not ($status.androidDevices | Where-Object { $_.alias -eq "Samsung-N960" -and $_.state -eq "device" -and -not $_.isEmulator })) {
        $missingByLane += "Samsung-N960"
    }
}

if ($Lane -eq "ios" -or $Lane -eq "both") {
    if (-not ($status.iosDevices | Where-Object { $_.alias -eq "iPhone-14-Pro-Max" -and $_.state -eq "device" })) {
        $missingByLane += "iPhone-14-Pro-Max"
    }
}

$result = [pscustomobject]@{
    lane = $Lane
    ready = ($missingByLane.Count -eq 0)
    missing = $missingByLane
    androidDevices = $status.androidDevices
    iosDevices = $status.iosDevices
}

$resultJson = $result | ConvertTo-Json -Depth 6
Write-Output $resultJson

if ($missingByLane.Count -gt 0) {
    throw "Mobile lane '$Lane' is not ready. Missing: $($missingByLane -join ', ')"
}
