param()

$repoRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $repoRoot '.env'
$stateDir = Join-Path $repoRoot '.claude'
$statePath = Join-Path $stateDir 'olagon-key-state.txt'

function Read-EnvValue {
    param(
        [string]$Path,
        [string]$Name
    )

    if (-not (Test-Path $Path)) { return $null }
    foreach ($line in Get-Content $Path) {
        if ($line -match '^\s*#') { continue }
        if ($line -match "^\s*$Name=(.*)$") {
            return $matches[1].Trim()
        }
    }
    return $null
}

$key1 = Read-EnvValue -Path $envPath -Name 'OLOGON_API_KEY_1'
$key2 = Read-EnvValue -Path $envPath -Name 'OLOGON_API_KEY_2'

if (-not $key1 -and $env:OLOGON_API_KEY_1) { $key1 = $env:OLOGON_API_KEY_1 }
if (-not $key2 -and $env:OLOGON_API_KEY_2) { $key2 = $env:OLOGON_API_KEY_2 }

$keys = @()
if ($key1) { $keys += $key1 }
if ($key2) { $keys += $key2 }

if ($keys.Count -eq 0) {
    throw 'No Olagon API keys found. Set OLOGON_API_KEY_1 and optionally OLOGON_API_KEY_2 in .env.'
}

if ($key2) {
    Write-Output $key2
    exit 0
}

if ($key1) {
    Write-Output $key1
    exit 0
}

throw 'No Olagon API keys found after environment lookup.'
