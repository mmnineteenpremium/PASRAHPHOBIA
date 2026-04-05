param(
    [switch]$Strict,
    [switch]$Json,
    [string]$BuildOutput = '_tmp_release_preflight_build.rbxlx'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')
$invokeRojo = Join-Path $repoRoot 'scripts\Invoke-Rojo.ps1'
$auditScript = Join-Path $repoRoot 'scripts\audit-marketplace-mapping.ps1'

$requiredReports = @(
    'DOCUMENTATION\SOURCE OF TRUTH\reports\PUBLISH_REVIEW_FINAL_2026-04-06.md',
    'DOCUMENTATION\SOURCE OF TRUTH\reports\FINAL_RELEASE_CHECKLIST_2026-04-06.md',
    'DOCUMENTATION\SOURCE OF TRUTH\reports\CREATOR_HUB_MARKETPLACE_MAPPING_2026-04-06.md',
    'DOCUMENTATION\SOURCE OF TRUTH\reports\QA_MULTIPLAYER_MANUAL_CHECKLIST_2026-04-06.md',
    'DOCUMENTATION\SOURCE OF TRUTH\reports\QA_MULTIPLAYER_RESULT_TEMPLATE_2026-04-06.md',
    'DOCUMENTATION\SOURCE OF TRUTH\reports\PERSISTENCE_MANUAL_CHECKLIST_2026-04-06.md',
    'DOCUMENTATION\SOURCE OF TRUTH\reports\PERSISTENCE_RESULT_TEMPLATE_2026-04-06.md',
    'DOCUMENTATION\SOURCE OF TRUTH\reports\VISUAL_RUNTIME_VERIFICATION_2026-04-06.md'
)

$missingReports = @(
    $requiredReports |
        Where-Object { -not (Test-Path (Join-Path $repoRoot $_)) }
)

$buildOk = $false
$buildError = $null
try {
    & $invokeRojo 'build' 'default.project.json' '--output' $BuildOutput
    if ($LASTEXITCODE -eq 0) {
        $buildOk = $true
    } else {
        $buildError = "rojo_build_exit_$LASTEXITCODE"
    }
} catch {
    $buildError = $_.Exception.Message
}

$mappingRaw = & pwsh $auditScript -Json
$mapping = $mappingRaw | ConvertFrom-Json

$manualBlockers = @(
    'Creator Hub marketplaceId resmi belum diisi'
    'smoke test 2 client nyata belum dijalankan'
    'persistence non-mock belum divalidasi'
    'legal/licensing final review belum dikonfirmasi'
)

$summary = [pscustomobject]@{
    buildOk = $buildOk
    buildOutput = $BuildOutput
    buildError = $buildError
    missingReports = @($missingReports)
    mapping = $mapping.summary
    manualBlockers = @($manualBlockers)
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 6

    if ($Strict -and (-not $buildOk -or $missingReports.Count -gt 0)) {
        exit 1
    }

    exit 0
}

Write-Host '== Release Preflight ==' -ForegroundColor Cyan
Write-Host ("Build ok:              {0}" -f $buildOk)
Write-Host ("Build output:          {0}" -f $BuildOutput)
if ($buildError) {
    Write-Host ("Build error:           {0}" -f $buildError) -ForegroundColor Yellow
}
Write-Host ("Missing reports:       {0}" -f $missingReports.Count)
Write-Host ("Robux items:           {0}" -f $mapping.summary.catalogRobuxItems)
Write-Host ("Safe items missing ID: {0}" -f $mapping.summary.safeItemsMissingMarketplaceId)
Write-Host ("Safe items disabled:   {0}" -f $mapping.summary.safeItemsStillDisabled)
Write-Host ("Hold items enabled:    {0}" -f $mapping.summary.holdItemsAccidentallyEnabled)
Write-Host ''
Write-Host 'Known manual blockers:' -ForegroundColor Yellow
$manualBlockers | ForEach-Object { Write-Host ("- {0}" -f $_) }

if ($missingReports.Count -gt 0) {
    Write-Host ''
    Write-Host 'Missing reports:' -ForegroundColor Yellow
    $missingReports | ForEach-Object { Write-Host ("- {0}" -f $_) }
}

if ($Strict -and (-not $buildOk -or $missingReports.Count -gt 0)) {
    exit 1
}
