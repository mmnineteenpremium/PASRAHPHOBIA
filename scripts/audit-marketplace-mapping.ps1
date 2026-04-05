param(
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$catalogPath = Join-Path $repoRoot 'src\shared\DataTypes\ShopCatalog.lua'
$configPath = Join-Path $repoRoot 'src\shared\DataTypes\ShopMarketplaceConfig.lua'

if (-not (Test-Path $catalogPath)) {
    Write-Error "Shop catalog not found: $catalogPath"
    exit 1
}

if (-not (Test-Path $configPath)) {
    Write-Error "Marketplace config not found: $configPath"
    exit 1
}

$catalogText = Get-Content $catalogPath -Raw
$configText = Get-Content $configPath -Raw

function Get-MatchValue {
    param(
        [string]$Text,
        [string]$Pattern
    )

    $match = [regex]::Match($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($match.Success) {
        return $match.Groups[1].Value
    }
    return $null
}

function Parse-RobuxCatalogItems {
    param(
        [string]$Text
    )

    $sectionMatch = [regex]::Match(
        $Text,
        '(?ms)-- Robux catalog .*?(?=^}\s*$)'
    )

    if (-not $sectionMatch.Success) {
        return @()
    }

    $section = $sectionMatch.Value
    $blockMatches = [regex]::Matches($section, '(?ms)^\s*\{.*?^\s*\},?')
    $items = @()

    foreach ($blockMatch in $blockMatches) {
        $block = $blockMatch.Value
        $currency = Get-MatchValue -Text $block -Pattern 'currency\s*=\s*"([^"]+)"'
        if ($currency -notin @('Robux', 'RBX')) {
            continue
        }

        $itemId = Get-MatchValue -Text $block -Pattern 'id\s*=\s*"([^"]+)"'
        if (-not $itemId) {
            continue
        }

        $grantCurrency = Get-MatchValue -Text $block -Pattern 'grantCurrency\s*=\s*"([^"]+)"'
        $grantAmount = Get-MatchValue -Text $block -Pattern 'grantCurrencyAmount\s*=\s*([0-9]+)'
        $items += [pscustomobject]@{
            ItemId           = $itemId
            Name             = Get-MatchValue -Text $block -Pattern 'name\s*=\s*"([^"]+)"'
            Category         = Get-MatchValue -Text $block -Pattern 'category\s*=\s*"([^"]+)"'
            MarketplaceType  = Get-MatchValue -Text $block -Pattern 'marketplaceType\s*=\s*"([^"]+)"'
            Price            = [int](Get-MatchValue -Text $block -Pattern 'price\s*=\s*([0-9]+)')
            CatalogEnabled   = (Get-MatchValue -Text $block -Pattern 'enabled\s*=\s*(true|false)')
            GrantCurrency    = $grantCurrency
            GrantAmount      = if ($grantAmount) { [int]$grantAmount } else { 0 }
            SetupHint        = Get-MatchValue -Text $block -Pattern 'setupHint\s*=\s*"([^"]+)"'
        }
    }

    return $items
}

function Parse-MarketplaceConfig {
    param(
        [string]$Text
    )

    $matches = [regex]::Matches(
        $Text,
        '(?ms)^\s*([a-zA-Z0-9_]+)\s*=\s*\{\s*marketplaceId\s*=\s*([0-9]+)\s*,\s*enabled\s*=\s*(true|false)\s*,\s*\}'
    )

    $map = @{}
    foreach ($match in $matches) {
        $map[$match.Groups[1].Value] = [pscustomobject]@{
            MarketplaceId = [int64]$match.Groups[2].Value
            Enabled       = $match.Groups[3].Value -eq 'true'
        }
    }
    return $map
}

$safeNowIds = @(
    'pp_pack_small',
    'pp_pack_standard',
    'pp_pack_large',
    'mm_pack_small',
    'mm_pack_medium',
    'mm_pack_large'
)

$holdIds = @(
    'royalpass_premium_track',
    'class_dukun_unlock',
    'class_detective_unlock',
    'lifetime_bonus_pass'
)

$configMap = Parse-MarketplaceConfig -Text $configText
$rows = foreach ($item in (Parse-RobuxCatalogItems -Text $catalogText)) {
    $config = $configMap[$item.ItemId]
    $group = if ($safeNowIds -contains $item.ItemId) {
        'safe_enable_now'
    } elseif ($holdIds -contains $item.ItemId) {
        'keep_disabled'
    } else {
        'unclassified'
    }

    [pscustomobject]@{
        ItemId          = $item.ItemId
        MarketplaceType = $item.MarketplaceType
        Category        = $item.Category
        Price           = $item.Price
        Grant           = if ($item.GrantCurrency) { "$($item.GrantCurrency)+$($item.GrantAmount)" } else { '-' }
        Group           = $group
        ConfigId        = if ($config) { $config.MarketplaceId } else { 0 }
        ConfigEnabled   = if ($config) { $config.Enabled } else { $false }
    }
}

$safeMissing = @($rows | Where-Object { $_.Group -eq 'safe_enable_now' -and $_.ConfigId -le 0 })
$safeDisabled = @($rows | Where-Object { $_.Group -eq 'safe_enable_now' -and -not $_.ConfigEnabled })
$holdEnabled = @($rows | Where-Object { $_.Group -eq 'keep_disabled' -and $_.ConfigEnabled })
$unknown = @($rows | Where-Object { $_.Group -eq 'unclassified' })

Write-Host '== Creator Hub Marketplace Mapping Audit ==' -ForegroundColor Cyan
Write-Host ("Catalog Robux items: {0}" -f $rows.Count)
Write-Host ("Safe enable now:   {0}" -f (@($rows | Where-Object Group -eq 'safe_enable_now').Count))
Write-Host ("Keep disabled:     {0}" -f (@($rows | Where-Object Group -eq 'keep_disabled').Count))
Write-Host ''

$rows |
    Sort-Object Group, ItemId |
    Format-Table ItemId, MarketplaceType, Price, Grant, Group, ConfigId, ConfigEnabled -AutoSize

Write-Host ''
Write-Host ("Safe items missing marketplaceId: {0}" -f $safeMissing.Count)
Write-Host ("Safe items still disabled:        {0}" -f $safeDisabled.Count)
Write-Host ("Hold items accidentally enabled:  {0}" -f $holdEnabled.Count)
Write-Host ("Unclassified items:               {0}" -f $unknown.Count)

if ($safeMissing.Count -gt 0) {
    Write-Host ''
    Write-Host 'Safe items missing marketplaceId:' -ForegroundColor Yellow
    $safeMissing | Sort-Object ItemId | ForEach-Object { Write-Host ("- {0}" -f $_.ItemId) }
}

if ($holdEnabled.Count -gt 0) {
    Write-Host ''
    Write-Host 'Hold items that should stay disabled:' -ForegroundColor Yellow
    $holdEnabled | Sort-Object ItemId | ForEach-Object { Write-Host ("- {0}" -f $_.ItemId) }
}

if ($unknown.Count -gt 0) {
    Write-Host ''
    Write-Host 'Unclassified Robux items:' -ForegroundColor Yellow
    $unknown | Sort-Object ItemId | ForEach-Object { Write-Host ("- {0}" -f $_.ItemId) }
}

if ($Strict -and (($safeMissing.Count -gt 0) -or ($holdEnabled.Count -gt 0) -or ($unknown.Count -gt 0))) {
    exit 1
}
