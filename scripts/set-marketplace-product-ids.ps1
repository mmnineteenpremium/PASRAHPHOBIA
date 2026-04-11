param(
    [string]$PpPackSmallId,
    [string]$PpPackStandardId,
    [string]$PpPackLargeId,
    [string]$MmPackSmallId,
    [string]$MmPackMediumId,
    [string]$MmPackLargeId,
    [switch]$ShowCurrent
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$configPath = Join-Path $repoRoot 'src\shared\DataTypes\ShopMarketplaceConfig.lua'

if (-not (Test-Path $configPath)) {
    throw "Config file not found: $configPath"
}

$targets = @(
    @{
        ItemId = 'pp_pack_small'
        ProductId = $PpPackSmallId
    },
    @{
        ItemId = 'pp_pack_standard'
        ProductId = $PpPackStandardId
    },
    @{
        ItemId = 'pp_pack_large'
        ProductId = $PpPackLargeId
    },
    @{
        ItemId = 'mm_pack_small'
        ProductId = $MmPackSmallId
    },
    @{
        ItemId = 'mm_pack_medium'
        ProductId = $MmPackMediumId
    },
    @{
        ItemId = 'mm_pack_large'
        ProductId = $MmPackLargeId
    }
)

function Normalize-ProductId([string]$value, [string]$name) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    $trimmed = $value.Trim()
    if ($trimmed -notmatch '^\d+$') {
        throw "Invalid ProductId for ${name}: '$value' (must be numeric)."
    }

    [int64]$numericValue = 0
    if (-not [int64]::TryParse($trimmed, [ref]$numericValue)) {
        throw "Invalid ProductId for ${name}: '$value' (out of 64-bit range)."
    }
    if ($numericValue -le 0) {
        throw "Invalid ProductId for ${name}: '$value' (must be > 0)."
    }

    return [string]$numericValue
}

$rawConfig = Get-Content -LiteralPath $configPath -Raw

if ($ShowCurrent) {
    foreach ($target in $targets) {
        $pattern = "(?ms)^\s*{0}\s*=\s*\{{\s*marketplaceId\s*=\s*([0-9]+)\s*,\s*enabled\s*=\s*(true|false)\s*," -f [regex]::Escape($target.ItemId)
        $match = [regex]::Match($rawConfig, $pattern)
        if ($match.Success) {
            Write-Host ("{0}: marketplaceId={1} enabled={2}" -f $target.ItemId, $match.Groups[1].Value, $match.Groups[2].Value)
        } else {
            Write-Host ("{0}: <not found>" -f $target.ItemId)
        }
    }
}

$normalized = @{}
foreach ($target in $targets) {
    $normalized[$target.ItemId] = Normalize-ProductId -value $target.ProductId -name $target.ItemId
}

$provided = @($normalized.Values | Where-Object { $_ -ne $null })
if ($provided.Count -eq 0) {
    if (-not $ShowCurrent) {
        Write-Host 'No ProductId arguments provided. Nothing changed.'
    }
    exit 0
}

$duplicates = $provided | Group-Object | Where-Object { $_.Count -gt 1 }
if ($duplicates.Count -gt 0) {
    $dupeText = ($duplicates | ForEach-Object { $_.Name }) -join ', '
    throw "Duplicate ProductId detected: $dupeText"
}

$updatedConfig = $rawConfig
$changes = 0

foreach ($target in $targets) {
    $productId = $normalized[$target.ItemId]
    if ($null -eq $productId) {
        continue
    }

    $pattern = "(?ms)(^\s*{0}\s*=\s*\{{\s*marketplaceId\s*=\s*)([0-9]+)(\s*,\s*enabled\s*=\s*)(true|false)(\s*,)" -f [regex]::Escape($target.ItemId)
    $match = [regex]::Match($updatedConfig, $pattern)
    if (-not $match.Success) {
        throw "Failed to find block for item: $($target.ItemId)"
    }

    $replacement = "{0}{1}{2}true{3}" -f $match.Groups[1].Value, $productId, $match.Groups[3].Value, $match.Groups[5].Value
    $updatedConfig = [regex]::Replace($updatedConfig, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement }, 1)
    Write-Host ("Updated {0} -> marketplaceId={1}, enabled=true" -f $target.ItemId, $productId)
    $changes += 1
}

if ($changes -eq 0) {
    Write-Host 'No matching items were updated.'
    exit 0
}

Set-Content -LiteralPath $configPath -Value $updatedConfig
Write-Host ("Applied {0} ProductId updates to ShopMarketplaceConfig.lua" -f $changes)
