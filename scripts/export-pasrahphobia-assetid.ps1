param(
    [string]$OutputMarkdownPath = "C:\Projects\ROBLOX\PASRAHPHOBIA\PASRAHPHOBIA_ASSETID.md",
    [string]$OutputJsonPath = ".codex/asset-permissions/pasrahphobia-assetid-report.json",
    [string[]]$ScanRoots = @(
        "C:\Projects\ROBLOX\PASRAHPHOBIA",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\brian-second-final",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth"
    ),
    [string[]]$UniverseIds = @("10138560838", "9802743087"),
    [string[]]$UserIds = @("8603977492", "10576163165"),
    [string]$GroupId = "407883270",
    [int]$InventoryPageSize = 100,
    [int]$PermissionBatchSize = 25,
    [int]$MetadataThrottle = 24,
    [switch]$SkipPermissionProbe
)

$ErrorActionPreference = "Stop"

function Get-OpenCloudApiKey {
    $fromProcess = [Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "Process")
    if (-not [string]::IsNullOrWhiteSpace($fromProcess)) {
        return $fromProcess.Trim()
    }
    $fromUser = [Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "User")
    if (-not [string]::IsNullOrWhiteSpace($fromUser)) {
        return $fromUser.Trim()
    }
    throw "ROBLOX_OPEN_CLOUD_API_KEY was not found in Process/User environment."
}

function Get-ShortHash {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = ($sha.ComputeHash($bytes) | ForEach-Object ToString x2) -join ""
    return $hash.Substring(0, 12)
}

function Invoke-JsonGet {
    param(
        [string]$Uri,
        [hashtable]$Headers
    )

    try {
        $body = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -TimeoutSec 40
        return [ordered]@{
            ok = $true
            status = 200
            body = $body
            error = ""
        }
    } catch {
        $status = -1
        if ($_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = -1 }
        }
        $message = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
        return [ordered]@{
            ok = $false
            status = $status
            body = $null
            error = [string]$message
        }
    }
}

function Invoke-JsonPatch {
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [object]$Body
    )

    try {
        $json = $Body | ConvertTo-Json -Depth 20 -Compress
        $result = Invoke-RestMethod -Method Patch -Uri $Uri -Headers $Headers -ContentType "application/json" -Body $json -TimeoutSec 60
        return [ordered]@{
            ok = $true
            status = 200
            body = $result
            error = ""
        }
    } catch {
        $status = -1
        if ($_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = -1 }
        }
        $message = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
        return [ordered]@{
            ok = $false
            status = $status
            body = $null
            error = [string]$message
        }
    }
}

function Test-KeyForUserQuota {
    param(
        [string]$ApiKey,
        [string]$UserId
    )
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        return $false
    }
    $headers = @{ "x-api-key" = $ApiKey }
    $url = "https://apis.roblox.com/cloud/v2/users/$UserId/asset-quotas"
    $res = Invoke-JsonGet -Uri $url -Headers $headers
    return ($res.ok -and $res.status -eq 200)
}

function Get-ApiKeyCandidates {
    $result = [System.Collections.Generic.List[string]]::new()
    $current = Get-OpenCloudApiKey
    if (-not [string]::IsNullOrWhiteSpace($current)) {
        $result.Add($current.Trim())
    }

    $historyPath = Join-Path $env:APPDATA "Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    if (Test-Path -LiteralPath $historyPath) {
        $lines = Get-Content -LiteralPath $historyPath -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match 'ROBLOX_OPEN_CLOUD_API_KEY\s*=\s*"([^"]{80,})"') {
                $result.Add($Matches[1])
            }
            if ($line -match 'setx\s+ROBLOX_OPEN_CLOUD_API_KEY\s+"([^"]{80,})"') {
                $result.Add($Matches[1])
            }
            if ($line -match 'Read-Host\s+"([A-Za-z0-9_/\-\+=]{80,})"') {
                $result.Add($Matches[1])
            }
        }
    }

    return @($result | Select-Object -Unique)
}

function Get-UserInventoryAssetIds {
    param(
        [string]$ApiKey,
        [string]$UserId,
        [int]$MaxPageSize = 100
    )

    $headers = @{ "x-api-key" = $ApiKey }
    $assetIds = [System.Collections.Generic.HashSet[string]]::new()
    $assetTypes = [System.Collections.Generic.Dictionary[string, string]]::new()
    $pageToken = $null
    $pageCount = 0
    $itemCount = 0

    while ($true) {
        $url = "https://apis.roblox.com/cloud/v2/users/$UserId/inventory-items?maxPageSize=$MaxPageSize"
        if (-not [string]::IsNullOrWhiteSpace($pageToken)) {
            $url += "&pageToken=$([uri]::EscapeDataString($pageToken))"
        }

        $res = Invoke-JsonGet -Uri $url -Headers $headers
        if (-not $res.ok) {
            return [ordered]@{
                ok = $false
                userId = $UserId
                pageCount = $pageCount
                itemCount = $itemCount
                error = $res.error
                status = $res.status
                assetIds = @()
                assetTypes = @{}
            }
        }

        $items = @($res.body.inventoryItems)
        foreach ($item in $items) {
            $aid = [string]$item.assetDetails.assetId
            if ([string]::IsNullOrWhiteSpace($aid)) {
                continue
            }
            [void]$assetIds.Add($aid)
            if (-not $assetTypes.ContainsKey($aid)) {
                $assetTypes[$aid] = [string]$item.assetDetails.inventoryItemAssetType
            }
        }

        $itemCount += $items.Count
        $pageCount += 1
        $pageToken = [string]$res.body.nextPageToken
        if ([string]::IsNullOrWhiteSpace($pageToken)) {
            break
        }
    }

    return [ordered]@{
        ok = $true
        userId = $UserId
        pageCount = $pageCount
        itemCount = $itemCount
        error = ""
        status = 200
        assetIds = @($assetIds)
        assetTypes = $assetTypes
    }
}

function Get-ScanFiles {
    param([string[]]$Roots)

    $files = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $allowedExtensions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($ext in @(".lua", ".luau", ".json", ".md", ".txt", ".csv", ".rbxlx", ".rbxmx", ".rbxm", ".toml")) {
        [void]$allowedExtensions.Add($ext)
    }

    foreach ($root in $Roots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $directFiles = @(
            "PASRAHPHOBIA.rbxlx",
            "ghost-assetid.md",
            "meshparts-assetid.md",
            "InvestigationTools-Assetid.md",
            "image-icon-assetid.md",
            "audio-assetid.md"
        )
        foreach ($direct in $directFiles) {
            $path = Join-Path $root $direct
            if (Test-Path -LiteralPath $path) {
                [void]$files.Add((Resolve-Path -LiteralPath $path).Path)
            }
        }

        $includeRoots = @(
            (Join-Path $root "src"),
            (Join-Path $root "scripts"),
            (Join-Path $root "DOCUMENTATION\SOURCE OF TRUTH"),
            (Join-Path $root "asset mentah\ROBLOX CREATOR HUB"),
            (Join-Path $root ".codex\asset-imports")
        ) | Select-Object -Unique

        foreach ($scanRoot in $includeRoots) {
            if (-not (Test-Path -LiteralPath $scanRoot)) {
                continue
            }

            Get-ChildItem -LiteralPath $scanRoot -File -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object {
                    $path = $_.FullName
                    if ($path -match "\\.git\\|\\node_modules\\|\\Packages\\_Index\\|\\AppData\\|\\Local\\Temp\\") { return $false }
                    if ($_.Length -gt 30MB) { return $false }
                    return $allowedExtensions.Contains($_.Extension)
                } |
                ForEach-Object { [void]$files.Add($_.FullName) }
        }
    }

    return @($files)
}

function Add-IdsFromFile {
    param(
        [string]$FilePath,
        [System.Collections.Generic.HashSet[string]]$AssetIds,
        [System.Collections.Generic.Dictionary[string, System.Collections.Generic.HashSet[string]]]$Sources
    )

    $ext = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    $useLooseNumeric = $ext -in @(".md", ".csv", ".txt")
    $pattern = if ($useLooseNumeric) {
        'rbxassetid://([0-9]{6,15})|(?<![0-9.])([0-9]{10,15})(?![0-9.])'
    } else {
        'rbxassetid://([0-9]{6,15})|(?:assetid|asset_id|AssetId|meshid|audioid)\s*[:=]\s*["'']?([0-9]{10,15})["'']?'
    }
    try {
        $text = Get-Content -LiteralPath $FilePath -Raw -ErrorAction Stop
        foreach ($match in [regex]::Matches($text, $pattern)) {
            $id = ""
            if ($match.Groups[1].Success) {
                $id = $match.Groups[1].Value
            } elseif ($match.Groups[2].Success) {
                $id = $match.Groups[2].Value
            }
            if ([string]::IsNullOrWhiteSpace($id)) {
                continue
            }
            [void]$AssetIds.Add($id)
            if (-not $Sources.ContainsKey($id)) {
                $Sources[$id] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
            [void]$Sources[$id].Add($FilePath)
        }
    } catch {
    }
}

function Get-EconomyAssetDetails {
    param(
        [string]$AssetId,
        [int]$MaxRetries = 6
    )

    $url = "https://economy.roblox.com/v2/assets/$AssetId/details"
    $headers = @{
        "User-Agent" = "Mozilla/5.0"
        "Accept" = "application/json"
    }

    $attempt = 0
    while ($attempt -le $MaxRetries) {
        try {
            $resp = Invoke-WebRequest -Uri $url -Headers $headers -Method Get -TimeoutSec 40 -ErrorAction Stop
            $body = $resp.Content | ConvertFrom-Json
            return [ordered]@{
                ok = $true
                status = [int]$resp.StatusCode
                body = $body
                error = ""
            }
        } catch {
            $status = -1
            if ($_.Exception.Response) {
                try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = -1 }
            }
            $message = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }

            if ($status -eq 429 -and $attempt -lt $MaxRetries) {
                $sleepMs = [Math]::Min(2000, 250 * [Math]::Pow(2, $attempt))
                Start-Sleep -Milliseconds ([int]$sleepMs)
                $attempt += 1
                continue
            }

            return [ordered]@{
                ok = $false
                status = $status
                body = $null
                error = [string]$message
            }
        }
    }

    return [ordered]@{
        ok = $false
        status = 429
        body = $null
        error = "rate_limited_retry_exhausted"
    }
}

function Convert-AssetTypeIdToName {
    param([int]$AssetTypeId)
    $map = @{
        1 = "Image"
        2 = "TShirt"
        3 = "Audio"
        4 = "Mesh"
        5 = "Lua"
        8 = "Hat"
        9 = "Place"
        10 = "Model"
        11 = "Shirt"
        12 = "Pants"
        13 = "Decal"
        17 = "Head"
        18 = "Face"
        19 = "Gear"
        21 = "Badge"
        24 = "Animation"
        27 = "Torso"
        28 = "RightArm"
        29 = "LeftArm"
        30 = "LeftLeg"
        31 = "RightLeg"
        32 = "Package"
        34 = "GamePass"
        38 = "Plugin"
        40 = "MeshPart"
        41 = "HairAccessory"
        42 = "FaceAccessory"
        43 = "NeckAccessory"
        44 = "ShoulderAccessory"
        45 = "FrontAccessory"
        46 = "BackAccessory"
        47 = "WaistAccessory"
        48 = "ClimbAnimation"
        49 = "DeathAnimation"
        50 = "FallAnimation"
        51 = "IdleAnimation"
        52 = "JumpAnimation"
        53 = "RunAnimation"
        54 = "SwimAnimation"
        55 = "WalkAnimation"
        61 = "EmoteAnimation"
        64 = "Video"
    }
    if ($map.ContainsKey($AssetTypeId)) {
        return [string]$map[$AssetTypeId]
    }
    return "AssetTypeId_$AssetTypeId"
}

function Invoke-PermissionGrantProbe {
    param(
        [string]$ApiKey,
        [string]$SubjectType,
        [string]$SubjectId,
        [string[]]$AssetIds
    )

    if ($AssetIds.Count -eq 0) {
        return [ordered]@{
            ok = $true
            status = 200
            response = @{ successAssetIds = @(); errors = @() }
            error = ""
        }
    }

    $headers = @{ "x-api-key" = $ApiKey }
    if ($SubjectType -eq "Universe") {
        $requests = @()
        foreach ($aid in $AssetIds) {
            $requests += @{
                assetId = [Int64]$aid
                grantToDependencies = $true
                parentVersionNumber = 0
            }
        }
        $body = @{
            subjectType = "Universe"
            subjectId = [string]$SubjectId
            action = "Use"
            requests = $requests
            enableDeepAccessCheck = $true
        }
    } else {
        $numericIds = @()
        foreach ($aid in $AssetIds) {
            $numericIds += [Int64]$aid
        }
        $body = @{
            subjectType = [string]$SubjectType
            subjectId = [string]$SubjectId
            action = "Use"
            assetIds = $numericIds
        }
    }

    $res = Invoke-JsonPatch -Uri "https://apis.roblox.com/asset-permissions-api/v1/assets/permissions" -Headers $headers -Body $body
    return [ordered]@{
        ok = $res.ok
        status = $res.status
        response = $res.body
        error = $res.error
    }
}

function Normalize-CreatorKey {
    param([string]$CreatorType, [string]$CreatorId)
    return "{0}:{1}" -f $CreatorType, $CreatorId
}

$mainApiKey = Get-OpenCloudApiKey
$keyCandidates = Get-ApiKeyCandidates

$selectedKeys = [ordered]@{
    main = [ordered]@{
        hash = Get-ShortHash -Text $mainApiKey
        length = $mainApiKey.Length
    }
    byOwner = [ordered]@{}
}

foreach ($userId in $UserIds) {
    $selected = $null
    foreach ($candidate in $keyCandidates) {
        if (Test-KeyForUserQuota -ApiKey $candidate -UserId $userId) {
            $selected = $candidate
            break
        }
    }
    if ($null -ne $selected) {
        $selectedKeys.byOwner[$userId] = [ordered]@{
            found = $true
            hash = Get-ShortHash -Text $selected
            length = $selected.Length
        }
    } else {
        $selectedKeys.byOwner[$userId] = [ordered]@{
            found = $false
            hash = ""
            length = 0
        }
    }
}

$inventoryCollection = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.HashSet[string]]]::new()
$inventoryTypeHints = [System.Collections.Generic.Dictionary[string, string]]::new()
$inventoryStats = [System.Collections.Generic.List[object]]::new()
foreach ($userId in $UserIds) {
    $inv = Get-UserInventoryAssetIds -ApiKey $mainApiKey -UserId $userId -MaxPageSize $InventoryPageSize
    $inventoryStats.Add($inv)
    $set = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($aid in $inv.assetIds) {
        [void]$set.Add([string]$aid)
        if (-not $inventoryTypeHints.ContainsKey([string]$aid) -and $inv.assetTypes.ContainsKey([string]$aid)) {
            $inventoryTypeHints[[string]$aid] = [string]$inv.assetTypes[[string]$aid]
        }
    }
    $inventoryCollection[$userId] = $set
}

$allIds = [System.Collections.Generic.HashSet[string]]::new()
$idSources = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.HashSet[string]]]::new()

foreach ($userId in $UserIds) {
    if ($inventoryCollection.ContainsKey($userId)) {
        foreach ($aid in $inventoryCollection[$userId]) {
            [void]$allIds.Add($aid)
            if (-not $idSources.ContainsKey($aid)) {
                $idSources[$aid] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
            [void]$idSources[$aid].Add("inventory:user:$userId")
        }
    }
}

$scanFiles = Get-ScanFiles -Roots $ScanRoots
foreach ($file in $scanFiles) {
    Add-IdsFromFile -FilePath $file -AssetIds $allIds -Sources $idSources
}

$allIdsArray = @($allIds) | Sort-Object { [int64]$_ }

$targetCreatorKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($uid in $UserIds) {
    [void]$targetCreatorKeys.Add((Normalize-CreatorKey -CreatorType "User" -CreatorId $uid))
}
[void]$targetCreatorKeys.Add((Normalize-CreatorKey -CreatorType "Group" -CreatorId $GroupId))

$metadataRows = [System.Collections.Generic.List[object]]::new()
foreach ($aid in $allIdsArray) {
    $res = Get-EconomyAssetDetails -AssetId ([string]$aid)
    if ($res.ok -and $res.body) {
        $body = $res.body
        $creatorType = ""
        $creatorId = ""
        $creatorName = ""
        if ($body.Creator) {
            $creatorType = [string]$body.Creator.CreatorType
            $creatorId = [string]$body.Creator.CreatorTargetId
            $creatorName = [string]$body.Creator.Name
        }
        $metadataRows.Add([pscustomobject]@{
            ok = $true
            assetId = [string]$body.AssetId
            name = [string]$body.Name
            assetTypeId = [int]$body.AssetTypeId
            creatorType = $creatorType
            creatorId = $creatorId
            creatorName = $creatorName
            created = [string]$body.Created
            updated = [string]$body.Updated
            raw = $body
        })
    } else {
        $metadataRows.Add([pscustomobject]@{
            ok = $false
            assetId = [string]$aid
            name = ""
            assetTypeId = -1
            creatorType = ""
            creatorId = ""
            creatorName = ""
            created = ""
            updated = ""
            raw = $null
        })
    }

    Start-Sleep -Milliseconds 35
}

$assets = [System.Collections.Generic.List[object]]::new()
foreach ($row in $metadataRows) {
    if (-not $row.ok) {
        continue
    }
    $creatorKey = Normalize-CreatorKey -CreatorType $row.creatorType -CreatorId $row.creatorId
    if (-not $targetCreatorKeys.Contains($creatorKey)) {
        continue
    }
    if ([string]::IsNullOrWhiteSpace($row.assetId)) {
        continue
    }
    $sourceList = @()
    if ($idSources.ContainsKey([string]$row.assetId)) {
        $sourceList = @($idSources[[string]$row.assetId] | Sort-Object)
    }
    $assets.Add([ordered]@{
        assetId = [string]$row.assetId
        name = [string]$row.name
        assetTypeId = [int]$row.assetTypeId
        assetTypeName = Convert-AssetTypeIdToName -AssetTypeId ([int]$row.assetTypeId)
        creatorType = [string]$row.creatorType
        creatorId = [string]$row.creatorId
        creatorName = [string]$row.creatorName
        created = [string]$row.created
        updated = [string]$row.updated
        inventoryTypeHint = if ($inventoryTypeHints.ContainsKey([string]$row.assetId)) { [string]$inventoryTypeHints[[string]$row.assetId] } else { "" }
        discoveredFrom = $sourceList
    })
}

$assets = @($assets | Sort-Object `
    @{ Expression = { $_.creatorType } }, `
    @{ Expression = { $_.creatorName } }, `
    @{ Expression = { $_.assetTypeName } }, `
    @{ Expression = { $_.name } }, `
    @{ Expression = { [int64]$_.assetId } })

$subjects = [System.Collections.Generic.List[object]]::new()
foreach ($uid in $UserIds) {
    $subjects.Add([ordered]@{ subjectType = "User"; subjectId = [string]$uid })
}
$subjects.Add([ordered]@{ subjectType = "Group"; subjectId = [string]$GroupId })
foreach ($universeId in $UniverseIds) {
    $subjects.Add([ordered]@{ subjectType = "Universe"; subjectId = [string]$universeId })
}

$permissionMap = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.Dictionary[string, object]]]::new()
foreach ($asset in $assets) {
    $permissionMap[[string]$asset.assetId] = [System.Collections.Generic.Dictionary[string, object]]::new()
}

if (-not $SkipPermissionProbe) {
    foreach ($subject in $subjects) {
        $assetIdList = @($assets | ForEach-Object { [string]$_.assetId })
        for ($offset = 0; $offset -lt $assetIdList.Count; $offset += $PermissionBatchSize) {
            $count = [Math]::Min($PermissionBatchSize, $assetIdList.Count - $offset)
            $batch = @($assetIdList[$offset..($offset + $count - 1)])
            $probe = Invoke-PermissionGrantProbe -ApiKey $mainApiKey -SubjectType $subject.subjectType -SubjectId $subject.subjectId -AssetIds $batch
            $subjectKey = "{0}:{1}" -f $subject.subjectType, $subject.subjectId

            $successIds = @()
            $errorByAsset = @{}
            if ($probe.ok -and $probe.response) {
                if ($probe.response.successAssetIds) {
                    $successIds = @($probe.response.successAssetIds | ForEach-Object { [string]$_ })
                }
                if ($probe.response.errors) {
                    foreach ($err in @($probe.response.errors)) {
                        $errAsset = [string]$err.assetId
                        if (-not [string]::IsNullOrWhiteSpace($errAsset)) {
                            $errorByAsset[$errAsset] = [string]$err.code
                        }
                    }
                }
            }

            foreach ($aid in $batch) {
                if (-not $permissionMap.ContainsKey($aid)) {
                    continue
                }
                if ($errorByAsset.ContainsKey($aid)) {
                    $permissionMap[$aid][$subjectKey] = [ordered]@{
                        status = "error"
                        code = $errorByAsset[$aid]
                    }
                } elseif ($successIds -contains $aid) {
                    $permissionMap[$aid][$subjectKey] = [ordered]@{
                        status = "granted_or_already_granted"
                        code = ""
                    }
                } elseif (-not $probe.ok) {
                    $permissionMap[$aid][$subjectKey] = [ordered]@{
                        status = "batch_failed"
                        code = [string]$probe.error
                    }
                } else {
                    $permissionMap[$aid][$subjectKey] = [ordered]@{
                        status = "unknown"
                        code = ""
                    }
                }
            }
        }
    }
}

$universeInfo = [System.Collections.Generic.List[object]]::new()
$headers = @{ "x-api-key" = $mainApiKey }
foreach ($universeId in $UniverseIds) {
    $uri = "https://apis.roblox.com/cloud/v2/universes/$universeId"
    $res = Invoke-JsonGet -Uri $uri -Headers $headers
    if ($res.ok -and $res.body) {
        $universeInfo.Add([ordered]@{
            universeId = [string]$universeId
            displayName = [string]$res.body.displayName
            description = [string]$res.body.description
            path = [string]$res.body.path
        })
    } else {
        $universeInfo.Add([ordered]@{
            universeId = [string]$universeId
            displayName = ""
            description = ""
            path = ""
        })
    }
}

$groupInfo = Invoke-JsonGet -Uri "https://apis.roblox.com/cloud/v2/groups/$GroupId" -Headers $headers
$groupName = if ($groupInfo.ok -and $groupInfo.body) { [string]$groupInfo.body.displayName } else { "PASRAHPHOBIA DEVELOPER & TEAM" }

$creatorLabelByKey = @{
    "User:8603977492" = "briankotak"
    "User:10576163165" = "Zyraaavex"
    ("Group:{0}" -f $GroupId) = $groupName
}

$assetRows = [System.Collections.Generic.List[string]]::new()
$universeSummaryItems = @()
foreach ($u in $universeInfo) {
    $name = if ([string]::IsNullOrWhiteSpace($u.displayName)) { "Unknown" } else { [string]$u.displayName }
    $universeSummaryItems += ("{0} ({1})" -f [string]$u.universeId, $name)
}
$universeSummary = $universeSummaryItems -join "; "

$assetRows.Add("# PASRAHPHOBIA Asset ID Registry")
$assetRows.Add("")
$assetRows.Add("Generated (UTC): $(Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')")
$assetRows.Add("Workspace: C:\Projects\ROBLOX\PASRAHPHOBIA")
$assetRows.Add("")
$assetRows.Add("## Scope")
$assetRows.Add("- Creators: Zyraaavex (10576163165), briankotak (8603977492), PASRAHPHOBIA DEVELOPER & TEAM ($GroupId)")
$assetRows.Add("- Universes checked: $universeSummary")
$assetRows.Add("- API key (active process) fingerprint: `$($selectedKeys.main.hash)` (len=$($selectedKeys.main.length))")
$assetRows.Add("- Owner-key discovery:")
foreach ($uid in $UserIds) {
    $entry = $selectedKeys.byOwner[$uid]
    if ($entry.found) {
        $assetRows.Add("  - user `$uid`: key found (fingerprint `$($entry.hash)`, len=$($entry.length))")
    } else {
        $assetRows.Add("  - user `$uid`: key not found in current env/history candidates")
    }
}
$assetRows.Add("")

$assetRows.Add("## Summary")
$assetRows.Add("- Total discovered numeric IDs: $($allIdsArray.Count)")
$assetRows.Add("- Total scoped assets (creator matched): $($assets.Count)")
foreach ($creatorKey in @("User:10576163165", "User:8603977492", "Group:$GroupId")) {
    $count = (@($assets | Where-Object { (Normalize-CreatorKey -CreatorType $_.creatorType -CreatorId $_.creatorId) -eq $creatorKey })).Count
    $label = if ($creatorLabelByKey.ContainsKey($creatorKey)) { $creatorLabelByKey[$creatorKey] } else { $creatorKey }
    $assetRows.Add("- ${label}: $count assets")
}
$assetRows.Add("")

$assetRows.Add("## Asset Table")
$assetRows.Add("| Name | Asset Type | Asset ID | Creator | Permission (User/Group) | Permission (Experience/Universe) | Sources |")
$assetRows.Add("|---|---|---:|---|---|---|---|")

foreach ($asset in $assets) {
    $aid = [string]$asset.assetId
    $creatorKey = Normalize-CreatorKey -CreatorType $asset.creatorType -CreatorId $asset.creatorId
    $creatorLabel = if ($creatorLabelByKey.ContainsKey($creatorKey)) { $creatorLabelByKey[$creatorKey] } else { "$($asset.creatorName) ($($asset.creatorType):$($asset.creatorId))" }

    $permUserGroupBits = [System.Collections.Generic.List[string]]::new()
    foreach ($subject in @(
        [ordered]@{ t = "User"; id = "10576163165"; label = "Zyraaavex" },
        [ordered]@{ t = "User"; id = "8603977492"; label = "briankotak" },
        [ordered]@{ t = "Group"; id = $GroupId; label = $groupName }
    )) {
        $sKey = "{0}:{1}" -f $subject.t, $subject.id
        $cell = "unknown"
        if ($permissionMap.ContainsKey($aid) -and $permissionMap[$aid].ContainsKey($sKey)) {
            $entry = $permissionMap[$aid][$sKey]
            if ($entry.status -eq "granted_or_already_granted") {
                $cell = "Use"
            } elseif ($entry.status -eq "error") {
                $cell = "ERR:$($entry.code)"
            } else {
                $cell = $entry.status
            }
        }
        $permUserGroupBits.Add("$($subject.label)=$cell")
    }

    $permUniverseBits = [System.Collections.Generic.List[string]]::new()
    foreach ($uni in $universeInfo) {
        $sKey = "Universe:$($uni.universeId)"
        $uLabel = if ([string]::IsNullOrWhiteSpace($uni.displayName)) { $uni.universeId } else { "$($uni.displayName) ($($uni.universeId))" }
        $cell = "unknown"
        if ($permissionMap.ContainsKey($aid) -and $permissionMap[$aid].ContainsKey($sKey)) {
            $entry = $permissionMap[$aid][$sKey]
            if ($entry.status -eq "granted_or_already_granted") {
                $cell = "Use"
            } elseif ($entry.status -eq "error") {
                $cell = "ERR:$($entry.code)"
            } else {
                $cell = $entry.status
            }
        }
        $permUniverseBits.Add("$uLabel=$cell")
    }

    $sources = @($asset.discoveredFrom | Select-Object -First 3)
    $sourceCell = if ($sources.Count -gt 0) { ($sources -join "<br>") } else { "-" }
    $nameCell = if ([string]::IsNullOrWhiteSpace($asset.name)) { "(no-name)" } else { $asset.name.Replace("|", "\|") }
    $typeCell = $asset.assetTypeName
    if (-not [string]::IsNullOrWhiteSpace($asset.inventoryTypeHint)) {
        $typeCell = "$typeCell / $($asset.inventoryTypeHint)"
    }

    $assetRows.Add("| $nameCell | $typeCell | $aid | $creatorLabel | $($permUserGroupBits -join '<br>') | $($permUniverseBits -join '<br>') | $sourceCell |")
}

$assetRows.Add("")
$assetRows.Add("## Notes")
$assetRows.Add("- Permission columns are based on `Use` grant probe results from `asset-permissions-api` with the active API key in this session.")
$assetRows.Add("- `Use` means granted or already granted by Roblox response. `ERR:*` means probe failed for that subject/asset pair.")
$assetRows.Add("- If a creator key is unavailable/expired, cross-owner permissions can show `ERR:CannotManageAsset` until that owner key is used.")

$reportObject = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    outputMarkdownPath = [System.IO.Path]::GetFullPath($OutputMarkdownPath)
    scanRoots = $ScanRoots
    scannedFileCount = $scanFiles.Count
    discoveredIdCount = $allIdsArray.Count
    scopedAssetCount = $assets.Count
    creators = [ordered]@{
        users = $UserIds
        groupId = $GroupId
        groupName = $groupName
    }
    universes = $universeInfo
    keyDiscovery = $selectedKeys
    inventoryStats = $inventoryStats
    assets = $assets
    permissionMap = $permissionMap
}

$jsonOutFull = [System.IO.Path]::GetFullPath($OutputJsonPath)
$jsonOutDir = Split-Path -Parent $jsonOutFull
if (-not [string]::IsNullOrWhiteSpace($jsonOutDir)) {
    New-Item -ItemType Directory -Path $jsonOutDir -Force | Out-Null
}
$reportObject | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $jsonOutFull -Encoding UTF8

$mdOutFull = [System.IO.Path]::GetFullPath($OutputMarkdownPath)
$mdOutDir = Split-Path -Parent $mdOutFull
if (-not [string]::IsNullOrWhiteSpace($mdOutDir)) {
    New-Item -ItemType Directory -Path $mdOutDir -Force | Out-Null
}
$assetRows -join "`r`n" | Set-Content -LiteralPath $mdOutFull -Encoding UTF8

[ordered]@{
    ok = $true
    markdown = $mdOutFull
    json = $jsonOutFull
    scopedAssetCount = $assets.Count
    discoveredIdCount = $allIdsArray.Count
    scannedFileCount = $scanFiles.Count
    skipPermissionProbe = [bool]$SkipPermissionProbe
} | ConvertTo-Json -Depth 8
