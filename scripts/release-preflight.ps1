param(
    [switch]$Strict,
    [switch]$Json,
    [string]$BuildOutput = '_tmp_release_preflight_build.rbxlx',
    [string]$CanonicalPlaceOutput = 'PASRAHPHOBIA.rbxlx'
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

$persistenceReportPath = Join-Path $repoRoot 'DOCUMENTATION\SOURCE OF TRUTH\reports\PERSISTENCE_RESULT_2026-04-11_REAL_DATASTORE.md'
$persistenceValidated = $false
if (Test-Path $persistenceReportPath) {
    $persistenceReportText = Get-Content -Path $persistenceReportPath -Raw
    if ($persistenceReportText -match 'status:\s*`PASS`') {
        $persistenceValidated = $true
    }
}

$legalReviewPath = Join-Path $repoRoot 'DOCUMENTATION\SOURCE OF TRUTH\reports\LEGAL_RUNTIME_REVIEW_2026-04-11.md'
$legalReviewValidated = $false
if (Test-Path $legalReviewPath) {
    $legalReviewText = Get-Content -Path $legalReviewPath -Raw
    if ($legalReviewText -match 'status:\s*`PASS`') {
        $legalReviewValidated = $true
    }
}

$buildOk = $false
$buildError = $null
$canonicalMirrorPath = $null
$canonicalMirrorOk = $false
$canonicalMirrorError = $null
try {
    & $invokeRojo 'build' 'default.project.json' '--output' $BuildOutput
    if ($LASTEXITCODE -eq 0) {
        $buildOk = $true
        if (-not [string]::IsNullOrWhiteSpace($CanonicalPlaceOutput)) {
            $canonicalMirrorPath = $CanonicalPlaceOutput
            try {
                if (([System.IO.Path]::GetFullPath($BuildOutput)) -eq ([System.IO.Path]::GetFullPath($CanonicalPlaceOutput))) {
                    $canonicalMirrorOk = $true
                } else {
                    Copy-Item -LiteralPath $BuildOutput -Destination $CanonicalPlaceOutput -Force
                    $canonicalMirrorOk = $true
                }
            } catch {
                $canonicalMirrorError = $_.Exception.Message
            }
        }
    } else {
        $buildError = "rojo_build_exit_$LASTEXITCODE"
    }
} catch {
    $buildError = $_.Exception.Message
}

$mappingRaw = & pwsh $auditScript -Json
$mapping = $mappingRaw | ConvertFrom-Json

$manualBlockers = New-Object System.Collections.Generic.List[string]

if (($mapping.summary.safeItemsMissingMarketplaceId -gt 0) -or ($mapping.summary.safeItemsStillDisabled -gt 0) -or ($mapping.summary.holdItemsAccidentallyEnabled -gt 0) -or ($mapping.summary.unclassifiedItems -gt 0)) {
    $manualBlockers.Add('Creator Hub marketplace mapping belum final (cek missing/disabled/hold/unclassified).')
}

$manualBlockers.Add('smoke test 2 client nyata: owner task manual (eksekusi user)')
if (-not $persistenceValidated) {
    $manualBlockers.Add('persistence non-mock belum divalidasi')
}
if (-not $legalReviewValidated) {
    $manualBlockers.Add('legal/licensing final review belum dikonfirmasi')
}

$summary = [pscustomobject]@{
    buildOk = $buildOk
    buildOutput = $BuildOutput
    buildError = $buildError
    canonicalMirrorPath = $canonicalMirrorPath
    canonicalMirrorOk = $canonicalMirrorOk
    canonicalMirrorError = $canonicalMirrorError
    missingReports = @($missingReports)
    mapping = $mapping.summary
    manualBlockers = @($manualBlockers.ToArray())
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
if ($canonicalMirrorPath) {
    Write-Host ("Canonical mirror:      {0}" -f $canonicalMirrorPath)
    Write-Host ("Canonical mirror ok:   {0}" -f $canonicalMirrorOk)
    if ($canonicalMirrorError) {
        Write-Host ("Canonical mirror err:  {0}" -f $canonicalMirrorError) -ForegroundColor Yellow
    }
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
