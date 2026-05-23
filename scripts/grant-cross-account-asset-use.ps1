param(
    [string[]]$BranchRoots = @(
        "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\brian-second-final",
        "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth"
    ),
    [string[]]$UniverseIds = @("10138560838", "9802743087"),
    [string[]]$UserIds = @("8603977492", "10576163165"),
    [string]$GroupId = "407883270",
    [string]$OutputPath = ".codex/asset-permissions/cross-account-use-grant-report.json",
    [int]$BatchSize = 25,
    [int]$MetadataThrottle = 32,
    [switch]$GrantAllDiscovered,
    [switch]$Apply
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

    throw "ROBLOX_OPEN_CLOUD_API_KEY was not found in Process/User env."
}

function Read-ErrorBody($response) {
    if ($null -eq $response) {
        return ""
    }

    try {
        $stream = $response.GetResponseStream()
        if ($null -eq $stream) {
            return ""
        }
        $reader = [System.IO.StreamReader]::new($stream)
        return $reader.ReadToEnd()
    } catch {
        return ""
    }
}

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "PATCH")]
        [string]$Method,
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,
        [object]$Body = $null
    )

    try {
        if ($null -eq $Body) {
            return [ordered]@{
                ok = $true
                status = 200
                body = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers
                rawError = ""
            }
        }

        $json = $Body | ConvertTo-Json -Depth 20 -Compress
        return [ordered]@{
            ok = $true
            status = 200
            body = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers -ContentType "application/json" -Body $json
            rawError = ""
        }
    } catch {
        $status = -1
        if ($_.Exception.Response) {
            try {
                $status = [int]$_.Exception.Response.StatusCode
            } catch {
                $status = -1
            }
        }

        return [ordered]@{
            ok = $false
            status = $status
            body = $null
            rawError = (Read-ErrorBody $_.Exception.Response)
            exception = $_.Exception.Message
        }
    }
}

function Get-CandidateFiles {
    param([string]$Root)

    $files = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $Root)) {
        return $files
    }

    $directFiles = @(
        "PASRAHPHOBIA.rbxlx",
        "ghost-assetid.md",
        "meshparts-assetid.md",
        "InvestigationTools-Assetid.md",
        "image-icon-assetid.md",
        "audio-assetid.md"
    )
    foreach ($relative in $directFiles) {
        $path = Join-Path $Root $relative
        if (Test-Path -LiteralPath $path) {
            $files.Add((Resolve-Path -LiteralPath $path).Path)
        }
    }

    $scanRoots = @(
        "src",
        ".codex\asset-imports"
    )
    $allowedExtensions = @(".lua", ".json", ".md", ".csv", ".txt", ".model.json", ".rbxmx", ".rbxm")

    foreach ($relativeRoot in $scanRoots) {
        $scanRoot = Join-Path $Root $relativeRoot
        if (-not (Test-Path -LiteralPath $scanRoot)) {
            continue
        }

        Get-ChildItem -LiteralPath $scanRoot -File -Recurse -Force |
            Where-Object {
                $name = $_.Name
                $extension = $_.Extension.ToLowerInvariant()
                if ($_.FullName -match "\\Packages\\|\\node_modules\\|\\.git\\") {
                    return $false
                }
                if ($name -like "*.bak" -or $name -like "*sharedstring-broken*") {
                    return $false
                }
                return $allowedExtensions -contains $extension -or $name.EndsWith(".model.json", [System.StringComparison]::OrdinalIgnoreCase)
            } |
            ForEach-Object { $files.Add($_.FullName) }
    }

    $docFiles = @(
        "DOCUMENTATION\SOURCE OF TRUTH\TASK_ACTIVE.md",
        "DOCUMENTATION\SOURCE OF TRUTH\GHOST_RIGGED_REIMPORT_REFACTOR_GUIDE.md",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\ASSET_LICENSE_LEDGER_2026-04-03.md",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\AUDIO_REPLACEMENT_PLAN_2026-04-03.md",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\GHOST_ANIMATION_BATCH_UPLOAD_2026-05-13.md",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\GHOST_BASE_NORMALIZED_REUPLOAD_AUDIT_2026-05-13.md",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\GHOST_CREATOR_HUB_ASSET_IDS_2026-05-10.md",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\GHOST_CREATOR_HUB_ASSET_IDS_2026-05-10.csv",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\GHOST_RIGGED_ANIMATION_UPLOAD_MANIFEST_2026-05-13.md",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\READY_TO_PLAY_GHOST_BASE_SMOKE_2026-05-13.md",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\ROBLOX_STUDIO_IMPORTED_INVENTORY_ASSETS_2026-04-17.csv",
        "DOCUMENTATION\SOURCE OF TRUTH\reports\SECOND_ACCOUNT_TOOL_ASSET_REFRESH_2026-05-13.md"
    )
    foreach ($relative in $docFiles) {
        $path = Join-Path $Root $relative
        if (Test-Path -LiteralPath $path) {
            $files.Add((Resolve-Path -LiteralPath $path).Path)
        }
    }

    return $files
}

function Add-AssetIdsFromFile {
    param(
        [string]$FilePath,
        [System.Collections.Generic.HashSet[string]]$Ids,
        [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]$Sources
    )

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    $name = [System.IO.Path]::GetFileName($FilePath)
    $useLooseNumeric = $true
    if ($extension -in @(".rbxlx", ".json", ".rbxmx", ".rbxm") -or $name.EndsWith(".model.json", [System.StringComparison]::OrdinalIgnoreCase)) {
        $useLooseNumeric = $false
    }
    $pattern = if ($useLooseNumeric) {
        "rbxassetid://[0-9]{6,}|(?<![0-9.])[0-9]{10,15}(?![0-9.])"
    } else {
        "rbxassetid://[0-9]{6,}"
    }

    $rg = Get-Command rg -ErrorAction SilentlyContinue
    if ($rg) {
        try {
            $matches = & $rg.Source -P -o $pattern -- $FilePath 2>$null
            foreach ($rawMatch in $matches) {
                if ($rawMatch -match "([0-9]{6,15})$") {
                    $id = $Matches[1]
                    if ($id.Length -lt 10) {
                        continue
                    }
                    [void]$Ids.Add($id)
                    if (-not $Sources.ContainsKey($id)) {
                        $Sources[$id] = [System.Collections.Generic.List[string]]::new()
                    }
                    if ($Sources[$id].Count -lt 5) {
                        $Sources[$id].Add($FilePath)
                    }
                }
            }
            return
        } catch {
            Write-Warning ("rg scan failed for {0}; falling back to streaming scan: {1}" -f $FilePath, $_.Exception.Message)
        }
    }

    try {
        $reader = [System.IO.File]::OpenText($FilePath)
        try {
            while ($null -ne ($line = $reader.ReadLine())) {
                foreach ($match in [regex]::Matches($line, "rbxassetid://([0-9]{6,})")) {
                    $id = $match.Groups[1].Value
                    [void]$Ids.Add($id)
                    if (-not $Sources.ContainsKey($id)) {
                        $Sources[$id] = [System.Collections.Generic.List[string]]::new()
                    }
                    if ($Sources[$id].Count -lt 5) {
                        $Sources[$id].Add($FilePath)
                    }
                }

                if ($useLooseNumeric) {
                    foreach ($match in [regex]::Matches($line, "(?<![0-9.])([0-9]{10,15})(?![0-9.])")) {
                        $id = $match.Groups[1].Value
                        [void]$Ids.Add($id)
                        if (-not $Sources.ContainsKey($id)) {
                            $Sources[$id] = [System.Collections.Generic.List[string]]::new()
                        }
                        if ($Sources[$id].Count -lt 5) {
                            $Sources[$id].Add($FilePath)
                        }
                    }
                }
            }
        } finally {
            $reader.Dispose()
        }
    } catch {
        Write-Warning ("Failed to scan file {0}: {1}" -f $FilePath, $_.Exception.Message)
    }
}

function Get-AssetMetadata {
    param(
        [string]$ApiKey,
        [string]$AssetId
    )

    $economyUri = "https://economy.roblox.com/v2/assets/$AssetId/details"
    $economyResult = Invoke-JsonRequest -Method "GET" -Uri $economyUri -Headers @{}
    if ($economyResult.ok -and $economyResult.body) {
        $body = $economyResult.body
        $creatorKind = "Unknown"
        $creatorId = ""
        if ($body.Creator) {
            if ([string]$body.Creator.CreatorType -eq "Group") {
                $creatorKind = "Group"
                $creatorId = [string]$body.Creator.CreatorTargetId
            } elseif ([string]$body.Creator.CreatorType -eq "User") {
                $creatorKind = "User"
                $creatorId = [string]$body.Creator.CreatorTargetId
            }
        }

        return [ordered]@{
            ok = $true
            assetId = [string]$body.AssetId
            displayName = [string]$body.Name
            assetType = [string]$body.AssetTypeId
            assetTypeId = [int]$body.AssetTypeId
            state = ""
            creatorKind = $creatorKind
            creatorId = $creatorId
            raw = $body
        }
    }

    $headers = @{ "x-api-key" = $ApiKey }
    $uri = "https://apis.roblox.com/assets/v1/assets/$AssetId"
    $result = Invoke-JsonRequest -Method "GET" -Uri $uri -Headers $headers
    if (-not $result.ok) {
        return [ordered]@{
            ok = $false
            assetId = $AssetId
            status = $result.status
            error = $result.rawError
            exception = $result.exception
        }
    }

    $body = $result.body
    $creator = $null
    if ($body.creationContext -and $body.creationContext.creator) {
        $creator = $body.creationContext.creator
    }

    $creatorKind = "Unknown"
    $creatorId = ""
    if ($creator -and $creator.groupId) {
        $creatorKind = "Group"
        $creatorId = [string]$creator.groupId
    } elseif ($creator -and $creator.userId) {
        $creatorKind = "User"
        $creatorId = [string]$creator.userId
    }

    return [ordered]@{
        ok = $true
        assetId = [string]$body.assetId
        displayName = [string]$body.displayName
        assetType = [string]$body.assetType
        assetTypeId = $null
        state = [string]$body.state
        creatorKind = $creatorKind
        creatorId = $creatorId
        raw = $body
    }
}

function Invoke-GrantUse {
    param(
        [string]$ApiKey,
        [string]$SubjectType,
        [string]$SubjectId,
        [string[]]$AssetIds
    )

    $headers = @{
        "x-api-key" = $ApiKey
    }

    if ($SubjectType -eq "Universe") {
        $requests = @()
        foreach ($assetId in $AssetIds) {
            $requests += @{
                assetId = [Int64]$assetId
                grantToDependencies = $true
                parentVersionNumber = 0
            }
        }

        $body = @{
            subjectType = $SubjectType
            subjectId = [string]$SubjectId
            action = "Use"
            requests = $requests
            enableDeepAccessCheck = $true
        }
    } else {
        $numericAssetIds = @()
        foreach ($assetId in $AssetIds) {
            $numericAssetIds += [Int64]$assetId
        }
        $body = @{
            subjectType = $SubjectType
            subjectId = [string]$SubjectId
            action = "Use"
            assetIds = $numericAssetIds
        }
    }

    return Invoke-JsonRequest -Method "PATCH" -Uri "https://apis.roblox.com/asset-permissions-api/v1/assets/permissions" -Headers $headers -Body $body
}

$apiKey = Get-OpenCloudApiKey
$allIds = [System.Collections.Generic.HashSet[string]]::new()
$sources = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()
$scannedFiles = New-Object System.Collections.Generic.List[string]

foreach ($root in $BranchRoots) {
    $files = Get-CandidateFiles -Root $root
    foreach ($file in $files) {
        $scannedFiles.Add($file)
        Add-AssetIdsFromFile -FilePath $file -Ids $allIds -Sources $sources
    }
}

$metadata = New-Object System.Collections.Generic.List[object]
$creatorAssetIds = New-Object System.Collections.Generic.List[string]
$allowedCreatorKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
[void]$allowedCreatorKeys.Add("Group:$GroupId")
foreach ($userId in $UserIds) {
    [void]$allowedCreatorKeys.Add("User:$userId")
}

$excludedAssetTypes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
[void]$excludedAssetTypes.Add("Place")
$excludedAssetTypeIds = [System.Collections.Generic.HashSet[int]]::new()
[void]$excludedAssetTypeIds.Add(9)

$idList = @($allIds) | Sort-Object {[Int64]$_}
$skipIds = [System.Collections.Generic.HashSet[string]]::new()
foreach ($universeId in $UniverseIds) {
    [void]$skipIds.Add([string]$universeId)
}
foreach ($userId in $UserIds) {
    [void]$skipIds.Add([string]$userId)
}
[void]$skipIds.Add([string]$GroupId)
[void]$skipIds.Add("89787959603872")
[void]$skipIds.Add("113010869463813")

if ($GrantAllDiscovered) {
    foreach ($assetId in $idList) {
        if (-not $skipIds.Contains([string]$assetId)) {
            $creatorAssetIds.Add([string]$assetId)
            $metadata.Add([ordered]@{
                assetId = [string]$assetId
                displayName = ""
                assetType = ""
                assetTypeId = $null
                state = ""
                creatorKind = "UnverifiedGrantAllDiscovered"
                creatorId = ""
                targetCreator = $true
                excludedType = $false
                sources = if ($sources.ContainsKey([string]$assetId)) { @($sources[[string]$assetId]) } else { @() }
            })
        }
    }
} else {
    $metadataItems = $null
    if ($PSVersionTable.PSVersion.Major -ge 7) {
    $metadataItems = $idList | ForEach-Object -Parallel {
        $assetId = [string]$_
        try {
            $body = Invoke-RestMethod -Method Get -Uri "https://economy.roblox.com/v2/assets/$assetId/details"
            $creatorKind = "Unknown"
            $creatorId = ""
            if ($body.Creator) {
                if ([string]$body.Creator.CreatorType -eq "Group") {
                    $creatorKind = "Group"
                    $creatorId = [string]$body.Creator.CreatorTargetId
                } elseif ([string]$body.Creator.CreatorType -eq "User") {
                    $creatorKind = "User"
                    $creatorId = [string]$body.Creator.CreatorTargetId
                }
            }
            [pscustomobject]@{
                ok = $true
                assetId = [string]$body.AssetId
                displayName = [string]$body.Name
                assetType = [string]$body.AssetTypeId
                assetTypeId = [int]$body.AssetTypeId
                state = ""
                creatorKind = $creatorKind
                creatorId = $creatorId
                raw = $body
            }
        } catch {
            [pscustomobject]@{
                ok = $false
                assetId = $assetId
                status = if ($_.Exception.Response) { try { [int]$_.Exception.Response.StatusCode } catch { -1 } } else { -1 }
                error = $_.Exception.Message
                exception = $_.Exception.Message
            }
        }
    } -ThrottleLimit $MetadataThrottle
    } else {
        $metadataItems = foreach ($assetId in $idList) {
            Get-AssetMetadata -ApiKey $apiKey -AssetId $assetId
        }
    }

    foreach ($item in $metadataItems) {
        if ($item.ok) {
            $creatorKey = "{0}:{1}" -f $item.creatorKind, $item.creatorId
            $isTargetCreator = $allowedCreatorKeys.Contains($creatorKey)
            $assetTypeId = $null
            if (($item.PSObject.Properties.Name -contains "assetTypeId") -and $null -ne $item.assetTypeId) {
                $assetTypeId = [int]$item.assetTypeId
            }
            $isExcludedType = $excludedAssetTypes.Contains([string]$item.assetType) -or ($null -ne $assetTypeId -and $excludedAssetTypeIds.Contains($assetTypeId))
            $metadata.Add([ordered]@{
                assetId = $item.assetId
                displayName = $item.displayName
                assetType = $item.assetType
                assetTypeId = $assetTypeId
                state = $item.state
                creatorKind = $item.creatorKind
                creatorId = $item.creatorId
                targetCreator = $isTargetCreator
                excludedType = $isExcludedType
                sources = if ($sources.ContainsKey([string]$item.assetId)) { @($sources[[string]$item.assetId]) } else { @() }
            })
            if ($isTargetCreator -and -not $isExcludedType) {
                $creatorAssetIds.Add([string]$item.assetId)
            }
        } else {
            $metadata.Add($item)
        }
    }
}

$creatorAssetIdArray = @($creatorAssetIds.ToArray() | Sort-Object {[Int64]$_} -Unique)

$subjects = New-Object System.Collections.Generic.List[object]
foreach ($universeId in $UniverseIds) {
    $subjects.Add([ordered]@{ subjectType = "Universe"; subjectId = [string]$universeId })
}
foreach ($userId in $UserIds) {
    $subjects.Add([ordered]@{ subjectType = "User"; subjectId = [string]$userId })
}
if (-not [string]::IsNullOrWhiteSpace($GroupId)) {
    $subjects.Add([ordered]@{ subjectType = "Group"; subjectId = [string]$GroupId })
}

$grantResults = New-Object System.Collections.Generic.List[object]
if ($Apply -and $creatorAssetIdArray.Count -gt 0) {
    foreach ($subject in $subjects) {
        for ($offset = 0; $offset -lt $creatorAssetIdArray.Count; $offset += $BatchSize) {
            $count = [Math]::Min($BatchSize, $creatorAssetIdArray.Count - $offset)
            $batch = @($creatorAssetIdArray[$offset..($offset + $count - 1)])
            $grant = Invoke-GrantUse -ApiKey $apiKey -SubjectType $subject.subjectType -SubjectId $subject.subjectId -AssetIds $batch
            $grantResults.Add([ordered]@{
                subjectType = $subject.subjectType
                subjectId = $subject.subjectId
                assetIds = $batch
                ok = $grant.ok
                status = $grant.status
                response = $grant.body
                rawError = $grant.rawError
                exception = if ($grant.Contains("exception")) { $grant.exception } else { "" }
            })
        }
    }
}

$targetAssetIdArray = @()
foreach ($assetId in $creatorAssetIdArray) {
    $targetAssetIdArray += [string]$assetId
}

$subjectArray = @()
foreach ($subject in $subjects) {
    $subjectArray += [pscustomobject]@{
        subjectType = [string]$subject.subjectType
        subjectId = [string]$subject.subjectId
    }
}

$scannedFileArray = @()
foreach ($scannedFile in $scannedFiles) {
    $scannedFileArray += [string]$scannedFile
}

$summary = @{
    apply = [bool]$Apply
    grantAllDiscovered = [bool]$GrantAllDiscovered
    branchRoots = [string[]]$BranchRoots
    scannedFileCount = $scannedFiles.Count
    discoveredNumericIdCount = $idList.Count
    targetAssetCount = $creatorAssetIdArray.Count
    targetAssetIds = $targetAssetIdArray
    subjects = $subjectArray
    creators = @{
        teamGroupId = [string]$GroupId
        userIds = [string[]]$UserIds
    }
}

$metadataArray = @()
foreach ($entry in $metadata) {
    $metadataArray += $entry
}

$grantResultArray = @()
foreach ($entry in $grantResults) {
    $grantResultArray += $entry
}

$report = @{
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    summary = $summary
    scannedFiles = $scannedFileArray
    metadata = $metadataArray
    grantResults = $grantResultArray
}

$outFull = [System.IO.Path]::GetFullPath($OutputPath)
$outDir = Split-Path -Parent $outFull
if (-not [string]::IsNullOrWhiteSpace($outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
$report | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $outFull -Encoding UTF8

$successGrantCount = 0
$errorGrantCount = 0
foreach ($grant in $grantResults) {
    if ($grant.ok) {
        $successGrantCount += 1
    } else {
        $errorGrantCount += 1
    }
}

[ordered]@{
    apply = [bool]$Apply
    report = $outFull
    scannedFileCount = $scannedFiles.Count
    discoveredNumericIdCount = $idList.Count
    targetAssetCount = $creatorAssetIdArray.Count
    subjectCount = $subjects.Count
    grantBatchSuccessCount = $successGrantCount
    grantBatchErrorCount = $errorGrantCount
} | ConvertTo-Json -Depth 10
