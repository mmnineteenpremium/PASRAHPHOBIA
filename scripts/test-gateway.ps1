param()

# Test script for Anthropic-compatible gateway (Olagon)
# Usage: PowerShell -ExecutionPolicy Bypass -File .\scripts\test-gateway.ps1

function Read-EnvFile($path) {
    if (-Not (Test-Path $path)) { return }
    Get-Content $path | ForEach-Object {
        if ($_ -match "^\s*#") { return }
        if ($_ -match "^(\w+)=(.*)$") { Set-Variable -Name $matches[1] -Value $matches[2] -Scope Script }
    }
}

# Prefer .env in current working directory, then fallback to script folder parent
$cwd = Get-Location
$envPath1 = Join-Path $cwd '.env'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath2 = Join-Path $scriptDir '..\.env' | Resolve-Path -ErrorAction SilentlyContinue

if (Test-Path $envPath1) { Read-EnvFile $envPath1 }
elseif ($envPath2) { Read-EnvFile $envPath2 }

$apiBase = $env:ANTHROPIC_API_BASE
if (-not $apiBase) { $apiBase = ${script:ANTHROPIC_API_BASE} }

if (-not $apiBase) { $apiBase = 'https://gateway.olagon.site/anthropic/v1' }
elseif ($apiBase -match '/anthropic$') { $apiBase = "$apiBase/v1" }

$endpoint = "$apiBase/messages"
$bodyObj = @{ model = 'claude-2.1'; messages = @( @{ role = 'user'; content = 'Halo dari skrip tes' } ) }
$body = $bodyObj | ConvertTo-Json -Depth 10

function Invoke-GatewayTest {
    param(
        [string]$Key,
        [string]$Label
    )

    $headers = @{
        'x-api-key' = $Key
        'Content-Type' = 'application/json'
    }

    try {
        Write-Host "POST $endpoint using $Label" -ForegroundColor Cyan
        $resp = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body -ErrorAction Stop
        Write-Host "Response:" -ForegroundColor Green
        $resp | ConvertTo-Json -Depth 10
        return $true
    } catch {
        Write-Host "Request failed for ${Label}:" -ForegroundColor Yellow
        Write-Host $_.Exception.Message
        return $false
    }
}

$attempts = @()

if ($env:OLOGON_API_KEY_1) { $attempts += @{ key = $env:OLOGON_API_KEY_1; label = 'OLOGON_API_KEY_1 (env)' } }
if ($env:OLOGON_API_KEY_2) { $attempts += @{ key = $env:OLOGON_API_KEY_2; label = 'OLOGON_API_KEY_2 (env)' } }
if (${script:OLOGON_API_KEY_1}) { $attempts += @{ key = ${script:OLOGON_API_KEY_1}; label = 'OLOGON_API_KEY_1 (.env)' } }
if (${script:OLOGON_API_KEY_2}) { $attempts += @{ key = ${script:OLOGON_API_KEY_2}; label = 'OLOGON_API_KEY_2 (.env)' } }

if ($attempts.Count -eq 0) {
    Write-Host "No Olagon API keys found. Set OLOGON_API_KEY_1 and optionally OLOGON_API_KEY_2 in .env." -ForegroundColor Red
    exit 2
}

foreach ($attempt in $attempts) {
    if (Invoke-GatewayTest -Key $attempt.key -Label $attempt.label) {
        exit 0
    }
}

exit 3
