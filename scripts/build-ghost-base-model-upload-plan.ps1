param(
    [string]$SourceRoot = "C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\skinned-base",
    [string]$OutputPath = ".codex/asset-imports/20260513-ghost-base-reexport/roblox-base-model-upload-plan.json"
)

$ErrorActionPreference = "Stop"

$items = @(
    @{
        ghost = "Genderuwo"
        file = "..\normalized-base\Genderuwo\Genderuwo_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx"
        displayName = "Genderuwo_RIG_BASE_REEXPORT_SKINNED_NORMALIZED"
    },
    @{
        ghost = "HantuTanah"
        file = "..\normalized-base\HantuTanah\HantuTanah_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx"
        displayName = "HantuTanah_RIG_BASE_REEXPORT_SKINNED_NORMALIZED"
    },
    @{
        ghost = "Kuntilanak"
        file = "..\normalized-base\Kuntilanak\Kuntilanak_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx"
        displayName = "Kuntilanak_RIG_BASE_REEXPORT_SKINNED_NORMALIZED"
    },
    @{
        ghost = "Leak"
        file = "..\normalized-base\Leak\Leak_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx"
        displayName = "Leak_RIG_BASE_REEXPORT_SKINNED_NORMALIZED"
    },
    @{
        ghost = "Palasik"
        file = "..\normalized-base\Palasik\Palasik_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx"
        displayName = "Palasik_RIG_BASE_REEXPORT_SKINNED_NORMALIZED"
    },
    @{
        ghost = "Pocong"
        file = "..\normalized-base\Pocong\Pocong_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx"
        displayName = "Pocong_RIG_BASE_REEXPORT_SKINNED_NORMALIZED"
    },
    @{
        ghost = "Tuyul"
        file = "..\normalized-base\Tuyul\Tuyul_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx"
        displayName = "Tuyul_RIG_BASE_REEXPORT_SKINNED_NORMALIZED"
    },
    @{
        ghost = "WeweGombel"
        file = "..\normalized-base\WeweGombel\WeweGombel_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx"
        displayName = "WeweGombel_RIG_BASE_REEXPORT_SKINNED_NORMALIZED"
    }
)

$fullSourceRoot = [System.IO.Path]::GetFullPath($SourceRoot)
$plan = foreach ($item in $items) {
    $filePath = Join-Path $fullSourceRoot $item.file
    [ordered]@{
        key = $item.ghost
        ghost = $item.ghost
        displayName = $item.displayName
        description = "PASRAHPHOBIA ghost skinned base rig reexport candidate. Created from Manifest blend on 2026-05-13."
        file = $item.file
        filePath = $filePath
        assetType = "Model"
    }
}

$outputDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($OutputPath))
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$plan | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Ghost base model upload plan written: $OutputPath"
