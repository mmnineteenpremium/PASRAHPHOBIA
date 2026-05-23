param(
    [string]$OutputMarkdownPath = "C:\Projects\ROBLOX\PASRAHPHOBIA\PASRAHPHOBIA_ASSETID.md",
    [string]$OutputJsonPath = "C:\Projects\ROBLOX\PASRAHPHOBIA\PASRAHPHOBIA_ASSETID.json",
    [string[]]$UserIds = @("8603977492", "10576163165"),
    [string]$GroupId = "407883270",
    [string[]]$UniverseIds = @("10138560838", "9802743087")
)

$ErrorActionPreference = "Stop"

function Get-OpenCloudApiKey {
    $k = [Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "Process")
    if ([string]::IsNullOrWhiteSpace($k)) {
        $k = [Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "User")
    }
    if ([string]::IsNullOrWhiteSpace($k)) {
        throw "ROBLOX_OPEN_CLOUD_API_KEY not found in Process/User env."
    }
    return $k.Trim()
}

function Get-ShortHash([string]$text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hash = ($sha.ComputeHash($bytes) | ForEach-Object ToString x2) -join ""
    return $hash.Substring(0, 12)
}

function Invoke-JsonGet {
    param([string]$Uri, [hashtable]$Headers = @{})
    try {
        $r = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -TimeoutSec 40
        return [ordered]@{ ok = $true; status = 200; body = $r; error = "" }
    } catch {
        $status = -1
        if ($_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = -1 }
        }
        $msg = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
        return [ordered]@{ ok = $false; status = $status; body = $null; error = [string]$msg }
    }
}

function Get-InventoryAssetIds {
    param([string]$ApiKey, [string]$UserId)
    $headers = @{ "x-api-key" = $ApiKey }
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    $types = [System.Collections.Generic.Dictionary[string, string]]::new()
    $allowedTypes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($t in @("MODEL", "MESH_PART", "AUDIO", "ANIMATION", "PLUGIN", "IMAGE", "DECAL", "VIDEO", "MESH")) {
        [void]$allowedTypes.Add($t)
    }
    $token = $null
    $pages = 0
    $items = 0

    while ($true) {
        $url = "https://apis.roblox.com/cloud/v2/users/$UserId/inventory-items?maxPageSize=100"
        if (-not [string]::IsNullOrWhiteSpace($token)) {
            $url += "&pageToken=$([uri]::EscapeDataString($token))"
        }
        $res = Invoke-JsonGet -Uri $url -Headers $headers
        if (-not $res.ok) {
            return [ordered]@{
                ok = $false
                userId = $UserId
                pages = $pages
                items = $items
                error = $res.error
                ids = @()
                types = @{}
            }
        }

        foreach ($inv in @($res.body.inventoryItems)) {
            $aid = [string]$inv.assetDetails.assetId
            $invType = [string]$inv.assetDetails.inventoryItemAssetType
            if ([string]::IsNullOrWhiteSpace($aid)) { continue }
            if (-not $allowedTypes.Contains($invType)) { continue }
            [void]$ids.Add($aid)
            if (-not $types.ContainsKey($aid)) {
                $types[$aid] = $invType
            }
        }
        $pages += 1
        $items += @($res.body.inventoryItems).Count
        $token = [string]$res.body.nextPageToken
        if ([string]::IsNullOrWhiteSpace($token)) { break }
    }

    return [ordered]@{
        ok = $true
        userId = $UserId
        pages = $pages
        items = $items
        error = ""
        ids = @($ids)
        types = $types
    }
}

function Get-EconomyDetails {
    param([string]$AssetId)
    $headers = @{ "User-Agent" = "Mozilla/5.0"; "Accept" = "application/json" }
    $maxRetries = 6
    for ($attempt = 0; $attempt -le $maxRetries; $attempt++) {
        try {
            $resp = Invoke-WebRequest -Method Get -Uri "https://economy.roblox.com/v2/assets/$AssetId/details" -Headers $headers -TimeoutSec 40 -ErrorAction Stop
            $body = $resp.Content | ConvertFrom-Json
            return [ordered]@{ ok = $true; body = $body; status = [int]$resp.StatusCode; error = "" }
        } catch {
            $status = -1
            if ($_.Exception.Response) {
                try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = -1 }
            }
            if ($status -eq 429 -and $attempt -lt $maxRetries) {
                $sleepMs = [Math]::Min(2500, 250 * [Math]::Pow(2, $attempt))
                Start-Sleep -Milliseconds ([int]$sleepMs)
                continue
            }
            $msg = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
            return [ordered]@{ ok = $false; body = $null; status = $status; error = [string]$msg }
        }
    }
    return [ordered]@{ ok = $false; body = $null; status = 429; error = "rate_limited_retry_exhausted" }
}

function CreatorKey([string]$creatorType, [string]$creatorId) {
    return "{0}:{1}" -f $creatorType, $creatorId
}

function AssetTypeName([int]$id) {
    $map = @{
        1 = "Image"; 2 = "TShirt"; 3 = "Audio"; 4 = "Mesh"; 8 = "Hat"; 9 = "Place"; 10 = "Model";
        11 = "Shirt"; 12 = "Pants"; 13 = "Decal"; 21 = "Badge"; 24 = "Animation"; 34 = "GamePass";
        38 = "Plugin"; 40 = "MeshPart"; 48 = "ClimbAnimation"; 49 = "DeathAnimation"; 50 = "FallAnimation";
        51 = "IdleAnimation"; 52 = "JumpAnimation"; 53 = "RunAnimation"; 54 = "SwimAnimation";
        55 = "WalkAnimation"; 61 = "EmoteAnimation"; 64 = "Video"
    }
    if ($map.ContainsKey($id)) { return [string]$map[$id] }
    return "AssetTypeId_$id"
}

function Get-LocalAssetHints {
    $nameHints = [System.Collections.Generic.Dictionary[string, string]]::new()
    $typeHints = [System.Collections.Generic.Dictionary[string, string]]::new()
    $creatorHints = [System.Collections.Generic.Dictionary[string, string]]::new()
    $sourceHints = [System.Collections.Generic.Dictionary[string, string]]::new()

    $paths = @(
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[ASSETID]\Models & Packages.csv",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[ASSETID]\Meshes.csv",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[SECOND ACCOUNT]\[ASSETID]\ghost-assetid.md",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[SECOND ACCOUNT]\[ASSETID]\meshparts-assetid.md",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[SECOND ACCOUNT]\[ASSETID]\InvestigationTools-Assetid.md",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[SECOND ACCOUNT]\[ASSETID]\audio-assetid.md",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[SECOND ACCOUNT]\[ASSETID]\image-icon-assetid.md",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[SECOND ACCOUNT]\[ASSETID]\assetid-image-button.md",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\roblox-audio-ready\roblox-audio-upload-results-combined.csv",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\props fbx\ASSETID-PROP.md"
    )

    foreach ($p in $paths) {
        if (-not (Test-Path -LiteralPath $p)) { continue }
        $isSecondAccount = $p -like "*[SECOND ACCOUNT]*"
        $isAudioReady = $p -like "*roblox-audio-ready*"
        $isPropRegistry = $p -like "*ASSETID-PROP.md"
        $defaultCreator = if ($isSecondAccount -or $isAudioReady) { "User:8603977492" } elseif ($isPropRegistry) { "Group:407883270" } else { "User:10576163165" }

        if ($p.ToLowerInvariant().EndsWith(".csv")) {
            try {
                $rows = Import-Csv -LiteralPath $p
                foreach ($row in $rows) {
                    $id = ""
                    if ($row.PSObject.Properties.Name -contains "assetid") { $id = [string]$row.assetid }
                    elseif ($row.PSObject.Properties.Name -contains "assetId") { $id = [string]$row.assetId }
                    $nm = ""
                    if ($row.PSObject.Properties.Name -contains "nama asset") { $nm = [string]$row.'nama asset' }
                    elseif ($row.PSObject.Properties.Name -contains "name") { $nm = [string]$row.name }
                    if ([string]::IsNullOrWhiteSpace($id)) { continue }
                    if (-not $nameHints.ContainsKey($id) -and -not [string]::IsNullOrWhiteSpace($nm)) {
                        $nameHints[$id] = $nm
                    }
                    if (-not $typeHints.ContainsKey($id)) {
                        if ($isAudioReady) {
                            $typeHints[$id] = "AUDIO"
                        } elseif ($p -like "*Meshes.csv") {
                            $typeHints[$id] = "MESH_PART"
                        } else {
                            $typeHints[$id] = "MODEL"
                        }
                    }
                    if (-not $creatorHints.ContainsKey($id)) {
                        $creatorHints[$id] = $defaultCreator
                    }
                    if (-not $sourceHints.ContainsKey($id)) {
                        $sourceHints[$id] = $p
                    }
                }
            } catch {
            }
            continue
        }

        try {
            $lines = Get-Content -LiteralPath $p -ErrorAction Stop
            foreach ($line in $lines) {
                if ($isPropRegistry -and $line -match '^\|\s*\d+\s*\|\s*([^|]+?)\s*\|\s*([0-9]{10,15})\s*\|\s*([^|]+?)\s*\|.*\|\s*([^|]+?)\s*\|\s*$') {
                    $nm = $Matches[1].Trim()
                    $id = $Matches[2].Trim()
                    $tp = $Matches[3].Trim().ToUpperInvariant()
                    $creator = $Matches[4].Trim()
                    if (-not $nameHints.ContainsKey($id) -and -not [string]::IsNullOrWhiteSpace($nm)) { $nameHints[$id] = $nm }
                    if (-not $typeHints.ContainsKey($id) -and -not [string]::IsNullOrWhiteSpace($tp)) { $typeHints[$id] = $tp }
                    if (-not $creatorHints.ContainsKey($id)) {
                        if ($creator -match "PASRAHPHOBIA DEVELOPER") { $creatorHints[$id] = "Group:407883270" }
                        else { $creatorHints[$id] = $defaultCreator }
                    }
                    if (-not $sourceHints.ContainsKey($id)) { $sourceHints[$id] = $p }
                } elseif ($line -match '^\s*(.+?)\s*-\s*([0-9]{10,15})\s*-\s*([A-Za-z_ ]+)\s*$') {
                    $nm = $Matches[1].Trim()
                    $id = $Matches[2].Trim()
                    $tp = $Matches[3].Trim().ToUpperInvariant()
                    if (-not $nameHints.ContainsKey($id) -and -not [string]::IsNullOrWhiteSpace($nm)) { $nameHints[$id] = $nm }
                    if (-not $typeHints.ContainsKey($id) -and -not [string]::IsNullOrWhiteSpace($tp)) { $typeHints[$id] = $tp }
                    if (-not $creatorHints.ContainsKey($id)) { $creatorHints[$id] = $defaultCreator }
                    if (-not $sourceHints.ContainsKey($id)) { $sourceHints[$id] = $p }
                } elseif ($line -match '(?<![0-9])([0-9]{10,15})(?![0-9])') {
                    $id = $Matches[1]
                    if (-not $creatorHints.ContainsKey($id)) { $creatorHints[$id] = $defaultCreator }
                    if (-not $sourceHints.ContainsKey($id)) { $sourceHints[$id] = $p }
                }
            }
        } catch {
        }
    }

    return [ordered]@{
        names = $nameHints
        types = $typeHints
        creators = $creatorHints
        sources = $sourceHints
    }
}

$apiKey = Get-OpenCloudApiKey
$apiHash = Get-ShortHash -text $apiKey
$localHints = Get-LocalAssetHints

$targetCreatorKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($u in $UserIds) { [void]$targetCreatorKeys.Add((CreatorKey -creatorType "User" -creatorId $u)) }
[void]$targetCreatorKeys.Add((CreatorKey -creatorType "Group" -creatorId $GroupId))

$allIds = [System.Collections.Generic.HashSet[string]]::new()
$sourceMap = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.HashSet[string]]]::new()
$invTypeHint = [System.Collections.Generic.Dictionary[string, string]]::new()
$inventoryStats = [System.Collections.Generic.List[object]]::new()

$localIds = [System.Collections.Generic.HashSet[string]]::new()
foreach ($dictName in @("names", "types", "creators")) {
    foreach ($id in $localHints[$dictName].Keys) {
        if (-not [string]::IsNullOrWhiteSpace([string]$id)) {
            [void]$localIds.Add([string]$id)
        }
    }
}
foreach ($id in $localIds) {
    [void]$allIds.Add([string]$id)
    if (-not $sourceMap.ContainsKey([string]$id)) {
        $sourceMap[[string]$id] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
    if ($localHints.sources.ContainsKey([string]$id)) {
        [void]$sourceMap[[string]$id].Add("local:$($localHints.sources[[string]$id])")
    } else {
        [void]$sourceMap[[string]$id].Add("local:asset-hint")
    }
    if ($localHints.types.ContainsKey([string]$id) -and -not $invTypeHint.ContainsKey([string]$id)) {
        $invTypeHint[[string]$id] = [string]$localHints.types[[string]$id]
    }
}

foreach ($u in $UserIds) {
    $inv = Get-InventoryAssetIds -ApiKey $apiKey -UserId $u
    $inventoryStats.Add($inv)
    foreach ($id in $inv.ids) {
        [void]$allIds.Add([string]$id)
        if (-not $sourceMap.ContainsKey([string]$id)) {
            $sourceMap[[string]$id] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }
        [void]$sourceMap[[string]$id].Add("inventory:user:$u")
        if (-not $invTypeHint.ContainsKey([string]$id) -and $inv.types.ContainsKey([string]$id)) {
            $invTypeHint[[string]$id] = [string]$inv.types[[string]$id]
        }
    }
}

$reportPaths = @(
    "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\brian-second-final\.codex\asset-permissions\cross-account-use-grant-report.json",
    "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\brian-second-final\.codex\asset-permissions\cross-account-use-grant-users-group-retry.json",
    "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\asset-permissions\cross-account-use-grant-report.json",
    "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\asset-permissions\cross-account-use-grant-users-group-retry.json"
)

$loadedReports = [System.Collections.Generic.List[object]]::new()
foreach ($rp in $reportPaths) {
    if (Test-Path -LiteralPath $rp) {
        try {
            $r = Get-Content -LiteralPath $rp -Raw | ConvertFrom-Json
            $loadedReports.Add([ordered]@{ path = $rp; report = $r })
        } catch {
        }
    }
}

$metadataById = [System.Collections.Generic.Dictionary[string, object]]::new()
foreach ($entry in $loadedReports) {
    $r = $entry.report
    if ($r.summary -and $r.summary.targetAssetIds) {
        foreach ($id in @($r.summary.targetAssetIds)) {
            $sid = [string]$id
            [void]$allIds.Add($sid)
            if (-not $sourceMap.ContainsKey($sid)) {
                $sourceMap[$sid] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
            [void]$sourceMap[$sid].Add("report:targetAssetIds:$($entry.path)")
        }
    }
    if ($r.metadata) {
        foreach ($m in @($r.metadata)) {
            if (-not $m.assetId) { continue }
            $sid = [string]$m.assetId
            [void]$allIds.Add($sid)
            if (-not $sourceMap.ContainsKey($sid)) {
                $sourceMap[$sid] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
            [void]$sourceMap[$sid].Add("report:metadata:$($entry.path)")
            if ($m.targetCreator -eq $true -and -not $metadataById.ContainsKey($sid)) {
                $metadataById[$sid] = [ordered]@{
                    assetId = $sid
                    name = [string]$m.displayName
                    assetTypeId = if ($null -ne $m.assetTypeId) { [int]$m.assetTypeId } else { -1 }
                    creatorType = [string]$m.creatorKind
                    creatorId = [string]$m.creatorId
                    creatorName = [string]$m.creatorId
                    created = ""
                    updated = ""
                    fromReportTarget = $true
                }
            }
        }
    }
}

$assetIds = @($allIds) | Sort-Object { [int64]$_ }
$assets = [System.Collections.Generic.List[object]]::new()
$metadataFailCount = 0

foreach ($aid in $assetIds) {
    $meta = $null
    if ($metadataById.ContainsKey([string]$aid)) {
        $meta = $metadataById[[string]$aid]
    } else {
        $inventoryOwners = @()
        if ($sourceMap.ContainsKey([string]$aid)) {
            foreach ($src in $sourceMap[[string]$aid]) {
                if ($src -match '^inventory:user:(\d+)$') {
                    $inventoryOwners += $Matches[1]
                }
            }
        }
        $inventoryOwners = @($inventoryOwners | Select-Object -Unique)
        if ($inventoryOwners.Count -eq 1) {
            $creatorType = "User"
            $creatorId = [string]$inventoryOwners[0]
            $creatorName = $creatorId
            if ($creatorId -eq "8603977492") { $creatorName = "briankotak" }
            if ($creatorId -eq "10576163165") { $creatorName = "Zyraaavex" }
        } else {
            $creatorType = "Unknown"
            $creatorId = ""
            $creatorName = "Unknown"
        }
        $meta = [ordered]@{
            assetId = [string]$aid
            name = "(inventory asset)"
            assetTypeId = -1
            creatorType = [string]$creatorType
            creatorId = [string]$creatorId
            creatorName = [string]$creatorName
            created = ""
            updated = ""
            fromReportTarget = $false
            assumedFromInventory = $true
        }
        $metadataById[[string]$aid] = $meta
    }

    if ($localHints.creators.ContainsKey([string]$aid)) {
        $creatorHint = [string]$localHints.creators[[string]$aid]
        if ($creatorHint -match '^User:(\d+)$') {
            $meta.creatorType = "User"
            $meta.creatorId = $Matches[1]
            if ($Matches[1] -eq "8603977492") { $meta.creatorName = "briankotak" }
            elseif ($Matches[1] -eq "10576163165") { $meta.creatorName = "Zyraaavex" }
        } elseif ($creatorHint -eq "Group:407883270") {
            $meta.creatorType = "Group"
            $meta.creatorId = "407883270"
            $meta.creatorName = "PASRAHPHOBIA DEVELOPER & TEAM"
        }
    }
    if ($localHints.names.ContainsKey([string]$aid)) {
        if ([string]::IsNullOrWhiteSpace([string]$meta.name) -or [string]$meta.name -eq "(inventory asset)" -or [string]$meta.name -eq "(no-name)") {
            $meta.name = [string]$localHints.names[[string]$aid]
        }
    }
    if ($localHints.types.ContainsKey([string]$aid)) {
        if (($meta.assetTypeId -eq $null) -or ([int]$meta.assetTypeId -lt 0)) {
            $hintType = [string]$localHints.types[[string]$aid]
            $typeMapByHint = @{
                "MODEL" = 10
                "MESH" = 4
                "MESHPART" = 40
                "MESH_PART" = 40
                "AUDIO" = 3
                "ANIMATION" = 24
                "IMAGE" = 1
                "DECAL" = 13
                "PLUGIN" = 38
                "VIDEO" = 64
            }
            if ($typeMapByHint.ContainsKey($hintType)) {
                $meta.assetTypeId = [int]$typeMapByHint[$hintType]
            }
        }
    }

    $ck = CreatorKey -creatorType $meta.creatorType -creatorId $meta.creatorId
    $includeAsset = $false
    if ($meta.fromReportTarget -eq $true) {
        $includeAsset = $true
    } elseif ($targetCreatorKeys.Contains($ck)) {
        $includeAsset = $true
    }
    if (-not $includeAsset) { continue }
    $sources = @()
    if ($sourceMap.ContainsKey([string]$aid)) {
        $sources = @($sourceMap[[string]$aid] | Sort-Object)
    }
    $assets.Add([ordered]@{
        assetId = [string]$meta.assetId
        name = [string]$meta.name
        assetTypeId = [int]$meta.assetTypeId
        assetTypeName = AssetTypeName -id ([int]$meta.assetTypeId)
        creatorType = [string]$meta.creatorType
        creatorId = [string]$meta.creatorId
        creatorName = [string]$meta.creatorName
        created = [string]$meta.created
        updated = [string]$meta.updated
        inventoryTypeHint = if ($invTypeHint.ContainsKey([string]$aid)) { [string]$invTypeHint[[string]$aid] } else { "" }
        sources = $sources
    })
}

$assets = @($assets | Sort-Object `
    @{ Expression = { $_.creatorType } }, `
    @{ Expression = { $_.creatorName } }, `
    @{ Expression = { $_.assetTypeName } }, `
    @{ Expression = { $_.name } }, `
    @{ Expression = { [int64]$_.assetId } })

$permissionByAsset = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.Dictionary[string, string]]]::new()
foreach ($a in $assets) {
    $permissionByAsset[[string]$a.assetId] = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

foreach ($entry in $loadedReports) {
    $r = $entry.report
    if (-not $r.grantResults) { continue }
    foreach ($g in @($r.grantResults)) {
        $sKey = "{0}:{1}" -f [string]$g.subjectType, [string]$g.subjectId
        if ($g.response -and $g.response.successAssetIds) {
            foreach ($sid in @($g.response.successAssetIds)) {
                $aid = [string]$sid
                if ($permissionByAsset.ContainsKey($aid)) {
                    $permissionByAsset[$aid][$sKey] = "Use"
                }
            }
        }
        if ($g.response -and $g.response.errors) {
            foreach ($e in @($g.response.errors)) {
                $aid = [string]$e.assetId
                if ($permissionByAsset.ContainsKey($aid)) {
                    $permissionByAsset[$aid][$sKey] = "ERR:$([string]$e.code)"
                }
            }
        }
        if (-not $g.ok -and $g.assetIds) {
            foreach ($aid in @($g.assetIds | ForEach-Object { [string]$_ })) {
                if ($permissionByAsset.ContainsKey($aid) -and -not $permissionByAsset[$aid].ContainsKey($sKey)) {
                    $permissionByAsset[$aid][$sKey] = "BATCH_FAIL"
                }
            }
        }
    }
}

$userLabel = @{
    "10576163165" = "Zyraaavex"
    "8603977492" = "briankotak"
}

$groupName = "PASRAHPHOBIA DEVELOPER & TEAM"
$gInfo = Invoke-JsonGet -Uri "https://apis.roblox.com/cloud/v2/groups/$GroupId" -Headers @{ "x-api-key" = $apiKey }
if ($gInfo.ok -and $gInfo.body -and -not [string]::IsNullOrWhiteSpace([string]$gInfo.body.displayName)) {
    $groupName = [string]$gInfo.body.displayName
}

$universeLabel = [System.Collections.Generic.Dictionary[string, string]]::new()
foreach ($uid in $UniverseIds) {
    $name = $uid
    $uInfo = Invoke-JsonGet -Uri "https://apis.roblox.com/cloud/v2/universes/$uid" -Headers @{ "x-api-key" = $apiKey }
    if ($uInfo.ok -and $uInfo.body -and -not [string]::IsNullOrWhiteSpace([string]$uInfo.body.displayName)) {
        $name = "{0} ({1})" -f [string]$uInfo.body.displayName, $uid
    }
    $universeLabel[$uid] = $name
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# PASRAHPHOBIA Asset ID")
$lines.Add("")
$lines.Add("Generated UTC: $(Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')")
$lines.Add("API key fingerprint: $apiHash")
$lines.Add("")
$lines.Add("## Scope")
$lines.Add("- Creators: Zyraaavex (10576163165), briankotak (8603977492), $groupName ($GroupId)")
$lines.Add("- Universes: $(($UniverseIds | ForEach-Object { $universeLabel[$_] }) -join '; ')")
$lines.Add("- Source blend: cloud inventory (user) + existing cross-account permission reports + local asset registries")
$lines.Add("")
$lines.Add("## Summary")
$lines.Add("- Inventory stats:")
foreach ($s in $inventoryStats) {
    $lines.Add("  - user $($s.userId): ok=$($s.ok), pages=$($s.pages), items=$($s.items), uniqueAssetIds=$(@($s.ids).Count)")
}
$lines.Add("- Loaded permission reports: $($loadedReports.Count)")
$lines.Add("- Candidate IDs before filter: $($assetIds.Count)")
$lines.Add("- Scoped assets after creator filter: $($assets.Count)")
$lines.Add("- Metadata failures: $metadataFailCount")
$lines.Add("")
$lines.Add("## Assets")
$lines.Add("| Name | Asset Type | Asset ID | Creator | Permission ke mana saja (User/Group) | Permission ke experience siapa saja (Universe) | Sources |")
$lines.Add("|---|---|---:|---|---|---|---|")

foreach ($a in $assets) {
    $aid = [string]$a.assetId
    $ck = CreatorKey -creatorType $a.creatorType -creatorId $a.creatorId
    $creatorLabel = if ($ck -eq "User:10576163165") { "Zyraaavex" } elseif ($ck -eq "User:8603977492") { "briankotak" } elseif ($ck -eq "Group:$GroupId") { $groupName } elseif ([string]$a.creatorType -like "Unverified*") { "UNVERIFIED_FROM_REPORT" } else { "$($a.creatorName) ($ck)" }
    $ug = [System.Collections.Generic.List[string]]::new()
    foreach ($u in $UserIds) {
        $key = "User:$u"
        $label = if ($userLabel.ContainsKey($u)) { $userLabel[$u] } else { $u }
        $val = "unknown"
        if ($permissionByAsset.ContainsKey($aid) -and $permissionByAsset[$aid].ContainsKey($key)) { $val = $permissionByAsset[$aid][$key] }
        $ug.Add("$label=$val")
    }
    $gKey = "Group:$GroupId"
    $gVal = "unknown"
    if ($permissionByAsset.ContainsKey($aid) -and $permissionByAsset[$aid].ContainsKey($gKey)) { $gVal = $permissionByAsset[$aid][$gKey] }
    $ug.Add("$groupName=$gVal")

    $ux = [System.Collections.Generic.List[string]]::new()
    foreach ($uid in $UniverseIds) {
        $uKey = "Universe:$uid"
        $uVal = "unknown"
        if ($permissionByAsset.ContainsKey($aid) -and $permissionByAsset[$aid].ContainsKey($uKey)) { $uVal = $permissionByAsset[$aid][$uKey] }
        $ux.Add("$($universeLabel[$uid])=$uVal")
    }

    $src = if (@($a.sources).Count -gt 0) { (@($a.sources) | Select-Object -First 3) -join "<br>" } else { "-" }
    $nm = if ([string]::IsNullOrWhiteSpace($a.name)) { "(no-name)" } else { [string]$a.name }
    $nm = $nm.Replace("|", "\|")
    $type = [string]$a.assetTypeName
    if (-not [string]::IsNullOrWhiteSpace($a.inventoryTypeHint)) { $type = "$type / $($a.inventoryTypeHint)" }
    $lines.Add("| $nm | $type | $aid | $creatorLabel | $($ug -join '<br>') | $($ux -join '<br>') | $src |")
}

$lines.Add("")
$lines.Add("## Catatan")
$lines.Add("- Status permission diambil dari report grant pada dua branch: brian-second-final dan final-source-of-truth.")
$lines.Add("- `Use` = granted/already granted menurut response report. `ERR:*` = error code terakhir di report.")
$lines.Add("- Jika API key owner tertentu tidak aktif/expired pada sesi ini, permission bisa tampil unknown atau ERR:CannotManageAsset.")

$jsonObj = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    apiKeyFingerprint = $apiHash
    creators = [ordered]@{
        users = $UserIds
        groupId = $GroupId
        groupName = $groupName
    }
    universes = $UniverseIds
    universeLabels = $universeLabel
    inventoryStats = $inventoryStats
    loadedReports = @($loadedReports | ForEach-Object { $_.path })
    candidateIdCount = $assetIds.Count
    scopedAssetCount = $assets.Count
    metadataFailCount = $metadataFailCount
    assets = $assets
    permissions = $permissionByAsset
}

$mdDir = Split-Path -Parent $OutputMarkdownPath
if (-not [string]::IsNullOrWhiteSpace($mdDir)) {
    New-Item -ItemType Directory -Path $mdDir -Force | Out-Null
}
$lines -join "`r`n" | Set-Content -LiteralPath $OutputMarkdownPath -Encoding UTF8

$jsonDir = Split-Path -Parent $OutputJsonPath
if (-not [string]::IsNullOrWhiteSpace($jsonDir)) {
    New-Item -ItemType Directory -Path $jsonDir -Force | Out-Null
}
$jsonObj | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $OutputJsonPath -Encoding UTF8

[ordered]@{
    ok = $true
    markdown = $OutputMarkdownPath
    json = $OutputJsonPath
    scopedAssetCount = $assets.Count
    candidateIdCount = $assetIds.Count
    metadataFailCount = $metadataFailCount
    loadedReports = $loadedReports.Count
} | ConvertTo-Json -Depth 8
