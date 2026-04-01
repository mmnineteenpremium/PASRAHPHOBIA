param(
    [string]$RobloxLogsDir = (Join-Path $env:LOCALAPPDATA "Roblox\logs"),
    [string]$OutDir = "",
    [string]$SessionName = (Get-Date -Format "yyyyMMdd_HHmmss"),
    [int]$PollMs = 300,
    [switch]$IncludeExisting,
    [string]$LineRegex = "",
    [bool]$AutoStopWhenStudioClosed = $true,
    [int]$IdleStopSeconds = 12
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $repoRoot "perbaikanmelayang\runtime-logs"
}

if (-not (Test-Path -LiteralPath $RobloxLogsDir)) {
    throw "Roblox log directory not found: $RobloxLogsDir"
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$outFile = Join-Path $OutDir ("studio_session_{0}.log" -f $SessionName)

function Get-CandidateLogFiles {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][datetime]$StartTime,
        [Parameter(Mandatory = $true)][bool]$TakeExisting
    )

    $files = Get-ChildItem -LiteralPath $Path -File -Filter "*Studio*_last.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 20 |
        Sort-Object LastWriteTime

    return $files
}

function Test-StudioRunning {
    $studioNames = @("RobloxStudioBeta", "RobloxStudio")
    $running = Get-Process -Name $studioNames -ErrorAction SilentlyContinue
    return $null -ne $running
}

$writer = [System.IO.StreamWriter]::new($outFile, $false, [System.Text.UTF8Encoding]::new($false))
$writer.AutoFlush = $true
$tracked = @{}
$startedAt = Get-Date
$lastActivityAt = $startedAt
$hasSeenStudioProcess = $false
$writer.WriteLine(("[{0}] START capture (pollMs={1}, includeExisting={2}, autoStop={3}, idleStopSeconds={4})" -f (Get-Date -Format "HH:mm:ss.fff"), $PollMs, $IncludeExisting.IsPresent, $AutoStopWhenStudioClosed, $IdleStopSeconds))

Write-Host "Capturing Roblox logs from: $RobloxLogsDir"
Write-Host "Merged session file: $outFile"
if ($AutoStopWhenStudioClosed) {
    Write-Host "Auto-stop: enabled (stops after Studio closed + idle ${IdleStopSeconds}s)."
} else {
    Write-Host "Auto-stop: disabled."
}
Write-Host "Press Ctrl+C to force stop."

try {
    while ($true) {
        $studioRunning = Test-StudioRunning
        if ($studioRunning) {
            $hasSeenStudioProcess = $true
            $lastActivityAt = Get-Date
        }

        $candidates = Get-CandidateLogFiles -Path $RobloxLogsDir -StartTime $startedAt -TakeExisting $IncludeExisting.IsPresent
        foreach ($file in $candidates) {
            if (-not $tracked.ContainsKey($file.FullName)) {
                $offset = if ($IncludeExisting.IsPresent) { [int64]0 } else { [int64]$file.Length }
                $tracked[$file.FullName] = @{
                    Offset = $offset
                    Remainder = ""
                    Name = $file.Name
                }
                $writer.WriteLine(("[{0}] TRACK {1} (offset={2})" -f (Get-Date -Format "HH:mm:ss.fff"), $file.Name, $offset))
                $lastActivityAt = Get-Date
            }
        }

        foreach ($path in @($tracked.Keys)) {
            if (-not (Test-Path -LiteralPath $path)) {
                continue
            }

            $entry = $tracked[$path]
            $length = (Get-Item -LiteralPath $path).Length

            if ($length -lt $entry.Offset) {
                $entry.Offset = 0
                $entry.Remainder = ""
                $writer.WriteLine(("[{0}] RESET {1} (truncated/rotated)" -f (Get-Date -Format "HH:mm:ss.fff"), $entry.Name))
                $lastActivityAt = Get-Date
            }

            if ($length -le $entry.Offset) {
                continue
            }

            $fs = $null
            $sr = $null
            $chunk = ""
            try {
                $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $null = $fs.Seek([int64]$entry.Offset, [System.IO.SeekOrigin]::Begin)
                $sr = [System.IO.StreamReader]::new($fs)
                $chunk = $sr.ReadToEnd()
                $entry.Offset = $length
            } catch {
                continue
            } finally {
                if ($sr) {
                    $sr.Dispose()
                } elseif ($fs) {
                    $fs.Dispose()
                }
            }

            if ([string]::IsNullOrEmpty($chunk)) {
                continue
            }

            $text = $entry.Remainder + $chunk
            $parts = $text -split "`r?`n", -1
            $trailingNewline = $text -match "(`r`n|`n)$"
            $completeCount = if ($trailingNewline) { $parts.Length - 1 } else { [Math]::Max(0, $parts.Length - 1) }
            $entry.Remainder = if ($trailingNewline) { "" } else { $parts[$parts.Length - 1] }

            for ($i = 0; $i -lt $completeCount; $i++) {
                $line = $parts[$i]
                if (-not [string]::IsNullOrEmpty($LineRegex) -and ($line -notmatch $LineRegex)) {
                    continue
                }
                $writer.WriteLine(("[{0}][{1}] {2}" -f (Get-Date -Format "HH:mm:ss.fff"), $entry.Name, $line))
                $lastActivityAt = Get-Date
            }
        }

        if ($AutoStopWhenStudioClosed -and $hasSeenStudioProcess -and -not $studioRunning) {
            $idleSeconds = ((Get-Date) - $lastActivityAt).TotalSeconds
            if ($idleSeconds -ge $IdleStopSeconds) {
                Write-Host ("Auto-stop triggered after Studio closed and idle for {0:N1}s." -f $idleSeconds)
                $writer.WriteLine(("[{0}] AUTOSTOP Studio closed; idle={1:N1}s" -f (Get-Date -Format "HH:mm:ss.fff"), $idleSeconds))
                break
            }
        }

        Start-Sleep -Milliseconds $PollMs
    }
} finally {
    foreach ($path in @($tracked.Keys)) {
        $entry = $tracked[$path]
        if (-not [string]::IsNullOrEmpty($entry.Remainder)) {
            if ([string]::IsNullOrEmpty($LineRegex) -or ($entry.Remainder -match $LineRegex)) {
                $writer.WriteLine(("[{0}][{1}] {2}" -f (Get-Date -Format "HH:mm:ss.fff"), $entry.Name, $entry.Remainder))
            }
        }
    }
    $writer.WriteLine(("[{0}] STOP capture" -f (Get-Date -Format "HH:mm:ss.fff")))
    $writer.Dispose()
}
