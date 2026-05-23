param(
    [string]$IconDir = "asset mentah\creator-hub-product-icons",
    [string]$OutputPath = "asset-id-icon-crawl.txt",
    [string]$UserId = "10576163165",
    [ValidateSet("ItemConfiguration", "CreatorStore")]
    [string]$SearchSource = "ItemConfiguration",
    [string]$AssetType = "Image",
    [string]$SearchCategoryType = "Decal",
    [string]$ApiKey = $env:ROBLOX_OPEN_CLOUD_API_KEY,
    [string]$Cookie = $env:ROBLOX_COOKIE
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$resolvedIconDir = Resolve-Path (Join-Path $repoRoot $IconDir)
$resolvedOutputPath = Join-Path $repoRoot $OutputPath
$endpoint = 'https://apis.roblox.com/toolbox-service/v2/assets:search'
$itemConfigurationEndpoint = 'https://itemconfiguration.roblox.com/v1/creations/get-assets'

function Get-AuthHeaders {
    $headers = @{}
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $headers['x-api-key'] = $ApiKey
    }
    if (-not [string]::IsNullOrWhiteSpace($Cookie)) {
        if ($Cookie -match '^\.ROBLOSECURITY=') {
            $headers['Cookie'] = $Cookie
        } else {
            $headers['Cookie'] = ".ROBLOSECURITY=$Cookie"
        }
    }
    return $headers
}

function Invoke-AssetSearch([string]$name) {
    $params = @{
        searchCategoryType = $SearchCategoryType
        query = $name
        userId = $UserId
        maxPageSize = '20'
    }
    $queryString = ($params.GetEnumerator() | ForEach-Object {
        [uri]::EscapeDataString($_.Key) + '=' + [uri]::EscapeDataString($_.Value)
    }) -join '&'

    $uri = "$endpoint`?$queryString"
    $headers = Get-AuthHeaders

    if ($headers.Count -eq 0) {
        Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec 30
    } else {
        Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -TimeoutSec 30
    }
}

function Get-AssetIdFromResult($result) {
    foreach ($prop in @('id', 'assetId', 'asset_id', 'targetId')) {
        if ($null -ne $result.$prop -and "$($result.$prop)" -match '^\d+$') {
            return "$($result.$prop)"
        }
    }
    return $null
}

function Get-CreatedAssets {
    $headers = Get-AuthHeaders
    if ($headers.Count -eq 0) {
        throw "ItemConfiguration source requires ROBLOX_COOKIE or -Cookie."
    }

    $assets = New-Object System.Collections.Generic.List[object]
    $cursor = $null

    do {
        $params = @{
            assetType = $AssetType
            limit = '100'
            sortOrder = 'Desc'
        }
        if (-not [string]::IsNullOrWhiteSpace($cursor)) {
            $params['cursor'] = $cursor
        }

        $queryString = ($params.GetEnumerator() | ForEach-Object {
            [uri]::EscapeDataString($_.Key) + '=' + [uri]::EscapeDataString($_.Value)
        }) -join '&'

        $uri = "$itemConfigurationEndpoint`?$queryString"
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -TimeoutSec 30
        foreach ($asset in @($response.data)) {
            $assets.Add($asset)
        }
        $cursor = $response.nextPageCursor
    } while (-not [string]::IsNullOrWhiteSpace($cursor))

    return $assets
}

$icons = Get-ChildItem -LiteralPath $resolvedIconDir -File |
    Where-Object { $_.Extension -in @('.png', '.jpg', '.jpeg') } |
    Sort-Object Name

$createdAssetsByName = @{}
if ($SearchSource -eq "ItemConfiguration") {
    foreach ($asset in Get-CreatedAssets) {
        if (-not [string]::IsNullOrWhiteSpace($asset.name) -and -not $createdAssetsByName.ContainsKey($asset.name)) {
            $createdAssetsByName[$asset.name] = $asset
        }
    }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('no-nama-assetid-jenis')

$index = 1
foreach ($icon in $icons) {
    $name = [IO.Path]::GetFileNameWithoutExtension($icon.Name)
    if ($SearchSource -eq "ItemConfiguration") {
        $match = $createdAssetsByName[$name]
    } else {
        $response = Invoke-AssetSearch $name
        $items = @($response.data) + @($response.assets) + @($response.results)
        $match = $items | Where-Object {
            $_.displayName -eq $name -or $_.name -eq $name -or $_.assetName -eq $name
        } | Select-Object -First 1

        if (-not $match) {
            $match = $items | Select-Object -First 1
        }
    }

    $assetId = if ($match) { Get-AssetIdFromResult $match } else { $null }
    if ([string]::IsNullOrWhiteSpace($assetId)) {
        $assetId = 'NOT_FOUND'
    } else {
        $assetId = "rbxassetid://$assetId"
    }

    $lines.Add("$index-$name-$assetId-icon image")
    $index += 1
}

Set-Content -LiteralPath $resolvedOutputPath -Value $lines -Encoding UTF8
Write-Output "Wrote $($lines.Count - 1) rows to $resolvedOutputPath"
