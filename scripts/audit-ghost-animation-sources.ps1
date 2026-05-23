param(
    [string]$SourceRoot = "C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\GHOST\ALL_GHOSTS_FINAL",
    [string]$PlanPath = ".codex/asset-imports/20260513-ghost-animation-rbxm/roblox-upload-plan.json",
    [string]$OutputPath = ".codex/asset-imports/20260513-ghost-animation-rbxm/source-preflight-audit.json"
)

$ErrorActionPreference = "Stop"

function Get-RelativePathCompat([string]$basePath, [string]$path) {
    $baseUri = [System.Uri](([System.IO.Path]::GetFullPath($basePath).TrimEnd('\') + '\'))
    $pathUri = [System.Uri]([System.IO.Path]::GetFullPath($path))
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

function Get-PropertyValue($obj, [string]$name) {
    if ($null -eq $obj) {
        return $null
    }
    if ($obj -is [System.Collections.IDictionary]) {
        if ($obj.Contains($name)) {
            return $obj[$name]
        }
        return $null
    }
    if ($obj.PSObject.Properties.Name -contains $name) {
        return $obj.$name
    }
    return $null
}

function Count-IssuesBySeverity($items, [string]$severity) {
    $count = 0
    foreach ($item in $items) {
        if ([string](Get-PropertyValue -obj $item -name "severity") -eq $severity) {
            $count++
        }
    }
    return $count
}

if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "Source root was not found: $SourceRoot"
}
if (-not (Test-Path -LiteralPath $PlanPath)) {
    throw "Plan file was not found: $PlanPath"
}

$fullSourceRoot = [System.IO.Path]::GetFullPath($SourceRoot)
$plan = Get-Content -LiteralPath $PlanPath -Raw | ConvertFrom-Json
if ($null -eq $plan) {
    throw "Plan file is empty: $PlanPath"
}
if ($plan -isnot [System.Collections.IEnumerable] -or $plan -is [string]) {
    $plan = @($plan)
}

$reportsByGhost = @{}
Get-ChildItem -LiteralPath $fullSourceRoot -Directory | ForEach-Object {
    $ghostName = $_.Name
    $animationDir = Join-Path $_.FullName "_generated_animations"
    if (-not (Test-Path -LiteralPath $animationDir)) {
        return
    }

    $reportFiles = @(Get-ChildItem -LiteralPath $animationDir -Filter "*animation_report.json" -File)
    $report = $null
    $reportError = $null
    if ($reportFiles.Count -eq 1) {
        try {
            $report = Get-Content -LiteralPath $reportFiles[0].FullName -Raw | ConvertFrom-Json
        } catch {
            $reportError = $_.Exception.Message
        }
    }

    $reportsByGhost[$ghostName] = [ordered]@{
        ghost = $ghostName
        animationDir = $animationDir
        reportCount = $reportFiles.Count
        reportPath = if ($reportFiles.Count -gt 0) { $reportFiles[0].FullName } else { $null }
        report = $report
        reportError = $reportError
    }
}

$rows = New-Object System.Collections.Generic.List[object]
$issues = New-Object System.Collections.Generic.List[object]

foreach ($item in $plan) {
    $ghost = [string]$item.ghost
    $sourceClip = [string]$item.sourceClip
    $runtimeKey = [string]$item.runtimeKey
    $sourceFbxRelative = [string]$item.sourceFbx
    $sourceFbxPath = if ($item.PSObject.Properties.Name -contains "sourceFbxPath" -and -not [string]::IsNullOrWhiteSpace([string]$item.sourceFbxPath)) {
        [string]$item.sourceFbxPath
    } else {
        Join-Path $fullSourceRoot $sourceFbxRelative
    }
    $sourceFbxFull = [System.IO.Path]::GetFullPath($sourceFbxPath)
    $sourceOverride = if ($item.PSObject.Properties.Name -contains "sourceOverride") { [string]$item.sourceOverride } else { $null }
    $ghostReport = $reportsByGhost[$ghost]
    $clipReport = $null
    $reportPath = $null
    $expectedBones = $null

    if ($null -eq $ghostReport) {
        $issues.Add([pscustomobject][ordered]@{
            severity = "error"
            key = [string]$item.key
            issue = "missing_animation_folder_or_report_context"
        })
    } else {
        $reportPath = $ghostReport.reportPath
        if ($ghostReport.reportCount -ne 1) {
            $issues.Add([pscustomobject][ordered]@{
                severity = "error"
                key = [string]$item.key
                issue = "unexpected_report_count"
                reportCount = $ghostReport.reportCount
            })
        }
        if (-not [string]::IsNullOrWhiteSpace($ghostReport.reportError)) {
            $issues.Add([pscustomobject][ordered]@{
                severity = "error"
                key = [string]$item.key
                issue = "report_parse_failed"
                error = $ghostReport.reportError
            })
        }
        if ($ghostReport.report) {
            $expectedBones = Get-PropertyValue -obj $ghostReport.report -name "expected_bones"
            $clips = @(Get-PropertyValue -obj $ghostReport.report -name "clips")
            $matches = @($clips | Where-Object { [string]$_.clip -eq $sourceClip })
            if ($matches.Count -eq 1) {
                $clipReport = $matches[0]
            } else {
                $issues.Add([pscustomobject][ordered]@{
                    severity = "error"
                    key = [string]$item.key
                    issue = "unexpected_clip_report_count"
                    clip = $sourceClip
                    count = $matches.Count
                })
            }
        }
    }

    $targetBoneCount = if ($clipReport) { Get-PropertyValue -obj $clipReport -name "target_bone_count" } else { $null }
    $fbxAction = if ($clipReport) { Get-PropertyValue -obj $clipReport -name "fbx_action" } else { $null }
    $reportFbx = if ($clipReport) { [string](Get-PropertyValue -obj $clipReport -name "fbx") } else { $null }
    $reportFbxRelative = if (-not [string]::IsNullOrWhiteSpace($reportFbx)) { Get-RelativePathCompat -basePath $fullSourceRoot -path $reportFbx } else { $null }
    $meshCount = if ($clipReport) { Get-PropertyValue -obj $clipReport -name "mesh_count" } else { $null }
    $meshVertices = $null
    $weightedVertices = $null
    $vertexGroups = $null
    if ($clipReport) {
        $meshes = @(Get-PropertyValue -obj $clipReport -name "meshes")
        if ($meshes.Count -gt 0) {
            $meshVertices = Get-PropertyValue -obj $meshes[0] -name "vertices"
            $weightedVertices = Get-PropertyValue -obj $meshes[0] -name "weighted_vertices"
            $vertexGroups = Get-PropertyValue -obj $meshes[0] -name "vertex_groups"
        }
    }

    if (-not (Test-Path -LiteralPath $sourceFbxFull)) {
        $issues.Add([pscustomobject][ordered]@{
            severity = "error"
            key = [string]$item.key
            issue = "missing_source_fbx"
            sourceFbx = $sourceFbxRelative
        })
    }

    if ([string]::IsNullOrWhiteSpace($sourceOverride) -and $reportFbxRelative -and $reportFbxRelative -ne $sourceFbxRelative) {
        $issues.Add([pscustomobject][ordered]@{
            severity = "error"
            key = [string]$item.key
            issue = "plan_fbx_does_not_match_report_fbx"
            planFbx = $sourceFbxRelative
            reportFbx = $reportFbxRelative
        })
    }

    if ($expectedBones -and $targetBoneCount -and [int]$targetBoneCount -ne [int]$expectedBones) {
        $issues.Add([pscustomobject][ordered]@{
            severity = "error"
            key = [string]$item.key
            issue = "target_bone_count_mismatch"
            expectedBones = [int]$expectedBones
            targetBoneCount = [int]$targetBoneCount
        })
    }

    if ($targetBoneCount -and $vertexGroups -and [int]$vertexGroups -gt [int]$targetBoneCount) {
        $issues.Add([pscustomobject][ordered]@{
            severity = "warning"
            key = [string]$item.key
            issue = "vertex_groups_exceed_target_bones"
            targetBoneCount = [int]$targetBoneCount
            vertexGroups = [int]$vertexGroups
        })
    }

    if ($targetBoneCount -and $weightedVertices -ne $null -and [int]$weightedVertices -eq 0) {
        $issues.Add([pscustomobject][ordered]@{
            severity = "error"
            key = [string]$item.key
            issue = "no_weighted_vertices"
        })
    }

    $rows.Add([pscustomobject][ordered]@{
        key = [string]$item.key
        ghost = $ghost
        runtimeKey = $runtimeKey
        sourceClip = $sourceClip
        sourceFbx = $sourceFbxRelative
        sourceFbxPath = $sourceFbxFull
        sourceOverride = $sourceOverride
        sourceFbxExists = Test-Path -LiteralPath $sourceFbxFull
        reportPath = $reportPath
        reportFbx = $reportFbxRelative
        expectedBones = $expectedBones
        targetBoneCount = $targetBoneCount
        fbxAction = $fbxAction
        meshCount = $meshCount
        meshVertices = $meshVertices
        weightedVertices = $weightedVertices
        vertexGroups = $vertexGroups
    })
}

$summaryByGhost = $rows |
    Group-Object ghost |
    Sort-Object Name |
    ForEach-Object {
        $groupName = $_.Name
        $ghostIssues = New-Object System.Collections.Generic.List[object]
        foreach ($issue in $issues) {
            if (([string](Get-PropertyValue -obj $issue -name "key")).StartsWith($groupName + ".")) {
                $ghostIssues.Add($issue)
            }
        }
        [pscustomobject][ordered]@{
            ghost = $groupName
            clipCount = $_.Count
            sourceFbxMissing = @($_.Group | Where-Object { -not $_.sourceFbxExists }).Count
            errors = Count-IssuesBySeverity -items $ghostIssues -severity "error"
            warnings = Count-IssuesBySeverity -items $ghostIssues -severity "warning"
            targetBoneCounts = @($_.Group | ForEach-Object { $_.targetBoneCount } | Where-Object { $_ -ne $null } | Sort-Object -Unique)
        }
    }

$errorCount = Count-IssuesBySeverity -items $issues -severity "error"
$warningCount = Count-IssuesBySeverity -items $issues -severity "warning"
$issueArray = $issues.ToArray()
$rowArray = $rows.ToArray()
$summaryByGhostArray = @($summaryByGhost)

$output = [ordered]@{
    generatedAt = (Get-Date).ToString("o")
    sourceRoot = $fullSourceRoot
    planPath = [System.IO.Path]::GetFullPath($PlanPath)
    summary = [ordered]@{
        planItems = @($plan).Count
        rows = $rows.Count
        errors = $errorCount
        warnings = $warningCount
    }
    summaryByGhost = $summaryByGhostArray
    issues = $issueArray
    rows = $rowArray
}

$outputDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($OutputPath))
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$output | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Ghost animation source audit written: $OutputPath"
Write-Host "Items=$($output.summary.planItems) Errors=$($output.summary.errors) Warnings=$($output.summary.warnings)"
