param(
    [string]$FrameZip = "ezgif-1f207771deb23970-png-split.zip",
    [string]$OutputDir = ".codex/asset-imports/20260510-loading-sprite-atlas",
    [int]$Columns = 4,
    [int]$Rows = 4,
    [int]$FrameWidth = 256,
    [int]$FrameHeight = 144,
    [int]$FramesPerSecond = 30
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$resolvedZip = Resolve-Path -LiteralPath $FrameZip
$resolvedOutput = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
$atlasDir = Join-Path $resolvedOutput "atlases"
New-Item -ItemType Directory -Force -Path $atlasDir | Out-Null

$framesPerAtlas = $Columns * $Rows
$atlasWidth = $Columns * $FrameWidth
$atlasHeight = $Rows * $FrameHeight

if ($framesPerAtlas -le 0) {
    throw "Columns and Rows must produce at least one frame per atlas."
}

if ($atlasWidth -gt 1024 -or $atlasHeight -gt 1024) {
    throw "Atlas size ${atlasWidth}x${atlasHeight} exceeds 1024x1024. Reduce columns, rows, or frame size."
}

$zip = [System.IO.Compression.ZipFile]::OpenRead($resolvedZip)
try {
    $entries = @($zip.Entries | Where-Object { $_.FullName -match "\.png$" } | Sort-Object FullName)
    if ($entries.Count -eq 0) {
        throw "No PNG frames found in $resolvedZip."
    }

    $atlasCount = [Math]::Ceiling($entries.Count / $framesPerAtlas)
    $atlases = New-Object System.Collections.Generic.List[object]
    $frames = New-Object System.Collections.Generic.List[object]

    for ($atlasIndex = 0; $atlasIndex -lt $atlasCount; $atlasIndex++) {
        $bitmap = New-Object System.Drawing.Bitmap($atlasWidth, $atlasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([System.Drawing.Color]::FromArgb(255, 0, 0, 0))
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        $firstFrame = ($atlasIndex * $framesPerAtlas) + 1
        $lastFrame = [Math]::Min(($atlasIndex + 1) * $framesPerAtlas, $entries.Count)

        try {
            for ($slot = 0; $slot -lt $framesPerAtlas; $slot++) {
                $frameIndex = ($atlasIndex * $framesPerAtlas) + $slot
                if ($frameIndex -ge $entries.Count) {
                    continue
                }

                $entry = $entries[$frameIndex]
                $stream = $entry.Open()
                try {
                    $source = [System.Drawing.Image]::FromStream($stream)
                    try {
                        $column = $slot % $Columns
                        $row = [Math]::Floor($slot / $Columns)
                        $offsetX = $column * $FrameWidth
                        $offsetY = $row * $FrameHeight
                        $destination = New-Object System.Drawing.Rectangle($offsetX, $offsetY, $FrameWidth, $FrameHeight)
                        $sourceRect = New-Object System.Drawing.Rectangle(0, 0, $source.Width, $source.Height)
                        $graphics.DrawImage($source, $destination, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)

                        $frames.Add([ordered]@{
                            frame = $frameIndex + 1
                            atlas = $atlasIndex + 1
                            slot = $slot
                            offsetX = $offsetX
                            offsetY = $offsetY
                        })
                    } finally {
                        $source.Dispose()
                    }
                } finally {
                    $stream.Dispose()
                }
            }
        } finally {
            $graphics.Dispose()
        }

        $fileName = "pasrah_loading_atlas_{0:D3}.png" -f ($atlasIndex + 1)
        $filePath = Join-Path $atlasDir $fileName
        $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bitmap.Dispose()

        $atlases.Add([ordered]@{
            index = $atlasIndex + 1
            file = "atlases/$fileName"
            width = $atlasWidth
            height = $atlasHeight
            firstFrame = $firstFrame
            lastFrame = $lastFrame
        })
    }

    $manifest = [ordered]@{
        sourceZip = [string]$resolvedZip
        generatedAt = (Get-Date).ToString("o")
        frameSourceCount = $entries.Count
        totalFrames = $entries.Count
        columns = $Columns
        rows = $Rows
        framesPerAtlas = $framesPerAtlas
        frameWidth = $FrameWidth
        frameHeight = $FrameHeight
        atlasWidth = $atlasWidth
        atlasHeight = $atlasHeight
        framesPerSecond = $FramesPerSecond
        maxTextureSize = 1024
        atlases = $atlases
        frames = $frames
    }

    $manifestPath = Join-Path $resolvedOutput "manifest.json"
    $manifest | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    $uploadPlan = New-Object System.Collections.Generic.List[object]
    foreach ($atlas in $atlases) {
        $uploadPlan.Add([ordered]@{
            key = "loading_atlas_{0:D3}" -f [int]$atlas.index
            displayName = "PASRAHPHOBIA Loading Atlas {0:D3}" -f [int]$atlas.index
            file = $atlas.file
            assetType = "Image"
            source = "pasrahphobia_loading_10s_1920x1080 sprite frames"
            description = "PASRAHPHOBIA loading sprite atlas $($atlas.index)/$atlasCount. Frames $($atlas.firstFrame)-$($atlas.lastFrame), $FrameWidth x $FrameHeight cells, $Columns x $Rows layout."
            firstFrame = $atlas.firstFrame
            lastFrame = $atlas.lastFrame
        })
    }

    $uploadPlanPath = Join-Path $resolvedOutput "roblox-upload-plan.json"
    $uploadPlan | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $uploadPlanPath -Encoding UTF8

    [pscustomobject]@{
        OutputDir = $resolvedOutput
        AtlasCount = $atlasCount
        TotalFrames = $entries.Count
        AtlasSize = "${atlasWidth}x${atlasHeight}"
        FrameSize = "${FrameWidth}x${FrameHeight}"
        Manifest = $manifestPath
        UploadPlan = $uploadPlanPath
    }
} finally {
    $zip.Dispose()
}
