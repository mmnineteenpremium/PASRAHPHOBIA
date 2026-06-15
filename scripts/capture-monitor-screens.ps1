param(
    [string]$OutDir = "artifacts\screenshots\monitor-baseline",
    [switch]$OpenFolder
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$targetDir = [System.IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$captures = @()
$screens = [System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.X }, { $_.Bounds.Y }
$index = 0

foreach ($screen in $screens) {
    $index += 1
    $bounds = $screen.Bounds
    $name = "display{0}_{1}x{2}_at_{3}_{4}" -f $index, $bounds.Width, $bounds.Height, $bounds.X, $bounds.Y
    $safeName = $name -replace "-", "neg"
    $pngPath = Join-Path $targetDir "$safeName.png"
    $jsonPath = Join-Path $targetDir "$safeName.json"

    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bitmap.Size)
    $bitmap.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()

    $metadata = [pscustomobject]@{
        DeviceName = $screen.DeviceName
        Primary = $screen.Primary
        ImagePath = $pngPath
        Bounds = [pscustomobject]@{
            X = $bounds.X
            Y = $bounds.Y
            Width = $bounds.Width
            Height = $bounds.Height
        }
        WorkingArea = [pscustomobject]@{
            X = $screen.WorkingArea.X
            Y = $screen.WorkingArea.Y
            Width = $screen.WorkingArea.Width
            Height = $screen.WorkingArea.Height
        }
        CapturedAt = (Get-Date).ToString("o")
    }
    $metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath
    $captures += $metadata
}

$manifestPath = Join-Path $targetDir "manifest.json"
[pscustomobject]@{
    CapturedAt = (Get-Date).ToString("o")
    Count = $captures.Count
    Captures = $captures
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath

if ($OpenFolder) {
    Start-Process -FilePath $targetDir
}

[pscustomobject]@{
    OutDir = $targetDir
    ManifestPath = $manifestPath
    Count = $captures.Count
} | ConvertTo-Json -Compress
