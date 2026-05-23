param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,
    [string]$UniverseId = "10138560838"
)

$ErrorActionPreference = "Stop"

if (Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue) {
    Write-Warning "Roblox Studio terdeteksi masih berjalan. Tutup Studio sebelum upload/publish Open Cloud."
}

$key = $ApiKey.Trim()
if ($key.StartsWith(":")) {
    $key = $key.Substring(1)
}

$env:ROBLOX_OPEN_CLOUD_API_KEY = $key
[Environment]::SetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", $key, "User")

$meta = [pscustomobject]@{
    ProcessLen = $env:ROBLOX_OPEN_CLOUD_API_KEY.Length
    UserLen = ([Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "User")).Length
    HasWhitespace = ($key -match "\s")
    Prefix = $key.Substring(0, [Math]::Min(8, $key.Length))
}

Write-Host "Key metadata:"
$meta | Format-List

$url = "https://apis.roblox.com/cloud/v2/universes/$UniverseId"
try {
    $res = Invoke-WebRequest -Uri $url -Headers @{ "x-api-key" = $key } -Method Get -TimeoutSec 30 -ErrorAction Stop
    Write-Host "AUTH OK: status=$([int]$res.StatusCode) endpoint=$url"
} catch {
    $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { "NO_STATUS" }
    Write-Host "AUTH FAIL: status=$status endpoint=$url"
    $errorDetails = $_.ErrorDetails
    if ($errorDetails -and $errorDetails.Message) {
        Write-Host $errorDetails.Message
    } else {
        Write-Host $_.Exception.Message
    }
}
