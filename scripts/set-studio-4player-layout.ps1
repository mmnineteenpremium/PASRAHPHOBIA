param(
    [ValidateSet("AutoSafe", "EditMode", "PlayF5", "ServerClient1", "ServerClient2", "PrimarySix", "RightFourClients")]
    [string]$Layout = "PrimarySix",
    [int]$TimeoutSeconds = 120,
    [int]$PollMs = 500,
    [int]$StablePolls = 2,
    [switch]$Watch,
    [switch]$ArrangeCode,
    [switch]$DryRun,
    [string]$OutDir = "artifacts\screenshots\studio-4player-layout"
)

$ErrorActionPreference = "Stop"

$dpiSignature = @'
using System;
using System.Runtime.InteropServices;

public static class StudioLayoutDpi {
    [DllImport("shcore.dll")]
    public static extern int SetProcessDpiAwareness(int value);

    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@

Add-Type -TypeDefinition $dpiSignature
try {
    [void][StudioLayoutDpi]::SetProcessDpiAwareness(2)
} catch {
    try { [void][StudioLayoutDpi]::SetProcessDPIAware() } catch {}
}

Add-Type -AssemblyName System.Windows.Forms

$signature = @'
using System;
using System.Runtime.InteropServices;

public struct StudioLayoutRect {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public static class LayoutWin32 {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out StudioLayoutRect rect);

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}

public struct StudioEnumRect {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public static class StudioEnumWin32 {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);

    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out StudioEnumRect rect);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
'@

Add-Type -TypeDefinition $signature

$SW_RESTORE = 9
$SW_MAXIMIZE = 3

function Get-VisibleWindows {
    Get-Process |
        Where-Object { $_.MainWindowHandle -ne 0 -and -not [string]::IsNullOrWhiteSpace($_.MainWindowTitle) } |
        ForEach-Object {
            $rect = New-Object StudioLayoutRect
            [LayoutWin32]::GetWindowRect($_.MainWindowHandle, [ref]$rect) | Out-Null
            [pscustomobject]@{
                Pid = $_.Id
                ProcessName = $_.ProcessName
                Title = $_.MainWindowTitle
                Handle = $_.MainWindowHandle
                Left = $rect.Left
                Top = $rect.Top
                Width = [Math]::Max(0, $rect.Right - $rect.Left)
                Height = [Math]::Max(0, $rect.Bottom - $rect.Top)
            }
        }
}

function Get-AllTopLevelWindows {
    $rows = New-Object System.Collections.Generic.List[object]
    $callback = {
        param([intptr]$handle, [intptr]$lParam)
        if (-not [StudioEnumWin32]::IsWindowVisible($handle)) { return $true }

        $length = [StudioEnumWin32]::GetWindowTextLength($handle)
        $builder = New-Object System.Text.StringBuilder ([Math]::Max(256, $length + 1))
        [void][StudioEnumWin32]::GetWindowText($handle, $builder, $builder.Capacity)
        $title = $builder.ToString()

        $processId = [uint32]0
        [void][StudioEnumWin32]::GetWindowThreadProcessId($handle, [ref]$processId)
        $process = Get-Process -Id ([int]$processId) -ErrorAction SilentlyContinue
        if (-not $process) { return $true }

        $rect = New-Object StudioEnumRect
        [void][StudioEnumWin32]::GetWindowRect($handle, [ref]$rect)
        $rows.Add([pscustomobject]@{
            Pid = [int]$processId
            ProcessName = $process.ProcessName
            Title = $title
            Handle = $handle
            Left = $rect.Left
            Top = $rect.Top
            Width = [Math]::Max(0, $rect.Right - $rect.Left)
            Height = [Math]::Max(0, $rect.Bottom - $rect.Top)
        }) | Out-Null
        return $true
    }
    [StudioEnumWin32]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null
    $rows
}

function Get-StudioViewportWindows {
    param(
        [int[]]$AllowedPids = @()
    )
    $primary = [System.Windows.Forms.Screen]::PrimaryScreen
    $right = @([System.Windows.Forms.Screen]::AllScreens |
        Where-Object { $_.Bounds.X -gt $primary.Bounds.X } |
        Sort-Object { $_.Bounds.X } |
        Select-Object -First 1)
    if ($right.Count -eq 0) { return @() }
    $rightBounds = $right[0].Bounds

    Get-AllTopLevelWindows |
        Where-Object {
            $_.ProcessName -eq "RobloxStudioBeta" -and
            $_.Title -eq "RobloxStudio" -and
            ($AllowedPids.Count -eq 0 -or $AllowedPids -contains $_.Pid) -and
            $_.Left -ge ($rightBounds.X - 20) -and
            $_.Left -lt ($rightBounds.X + $rightBounds.Width + 20) -and
            $_.Top -ge ($rightBounds.Y - 80) -and
            $_.Top -lt ($rightBounds.Y + $rightBounds.Height + 80)
        } |
        Sort-Object Top, Left |
        Select-Object -First 4
}

function Get-StudioViewportWindow {
    @(Get-StudioViewportWindows) | Select-Object -First 1
}

function Get-StudioSet {
    $windows = Get-VisibleWindows
    $studios = @($windows | Where-Object { $_.ProcessName -eq "RobloxStudioBeta" })
    $main = @($studios | Where-Object {
        $_.Title -match "PASRAHPHOBIA|\.rbxlx|\.rbxl| - Roblox Studio$" -and
        $_.Title -notmatch "^Server - Roblox Studio$|^Place\d+ - Roblox Studio$"
    } | Sort-Object Left, Top | Select-Object -First 1)
    $server = @($studios | Where-Object { $_.Title -match "^Server - Roblox Studio$" } | Sort-Object Left, Top | Select-Object -First 1)
    $clients = @($studios | Where-Object { $_.Title -match "^Place\d+ - Roblox Studio$" } | Sort-Object Left, Top, Pid | Select-Object -First 4)

    [pscustomobject]@{
        Main = if ($main.Count -gt 0) { $main[0] } else { $null }
        Server = if ($server.Count -gt 0) { $server[0] } else { $null }
        Clients = $clients
        Count = $studios.Count
    }
}

function Get-TopologySignature($set) {
    $mainPid = if ($set.Main) { $set.Main.Pid } else { 0 }
    $serverPid = if ($set.Server) { $set.Server.Pid } else { 0 }
    $clientPids = @($set.Clients | Sort-Object Pid | ForEach-Object { $_.Pid }) -join ","
    $clientPidsArray = @($set.Clients | ForEach-Object { [int]$_.Pid })
    $viewportHandles = @(Get-StudioViewportWindows -AllowedPids $clientPidsArray | ForEach-Object { $_.Handle.ToInt64() }) -join ","
    "main=$mainPid;server=$serverPid;clients=$($set.Clients.Count):$clientPids;viewports=$viewportHandles"
}

function Wait-StudioSet {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $set = Get-StudioSet
        if ($Layout -eq "AutoSafe" -and $set.Main) {
            return $set
        }
        if (($Layout -eq "EditMode" -or $Layout -eq "PlayF5") -and $set.Main) {
            return $set
        }
        if ($Layout -eq "ServerClient1" -and $set.Main -and $set.Server -and $set.Clients.Count -eq 1) {
            return $set
        }
        if ($Layout -eq "ServerClient2" -and $set.Main -and $set.Server -and $set.Clients.Count -eq 2) {
            return $set
        }
        if (($Layout -eq "PrimarySix" -or $Layout -eq "RightFourClients") -and $set.Main -and $set.Server -and $set.Clients.Count -ge 4) {
            return $set
        }
        Start-Sleep -Milliseconds $PollMs
    } while ((Get-Date) -lt $deadline)

    $set = Get-StudioSet
    throw "Timed out waiting for layout $Layout. Found main=$([bool]$set.Main), server=$([bool]$set.Server), clients=$($set.Clients.Count), studios=$($set.Count)."
}

function New-Slot($name, $x, $y, $w, $h) {
    [pscustomobject]@{
        Name = $name
        X = [int]$x
        Y = [int]$y
        Width = [int]$w
        Height = [int]$h
    }
}

function New-ViewportGridSlots($screen) {
    if (-not $screen) { return @() }
    $area = $screen.WorkingArea
    $colW = [Math]::Floor($area.Width / 2)
    $rowH = [Math]::Floor($area.Height / 2)
    @(
        New-Slot "Viewport1" $area.X $area.Y $colW $rowH
        New-Slot "Viewport2" ($area.X + $colW) $area.Y ($area.Width - $colW) $rowH
        New-Slot "Viewport3" $area.X ($area.Y + $rowH) $colW ($area.Height - $rowH)
        New-Slot "Viewport4" ($area.X + $colW) ($area.Y + $rowH) ($area.Width - $colW) ($area.Height - $rowH)
    )
}

function Get-LayoutSlots {
    $screens = @([System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.X }, { $_.Bounds.Y })
    $primary = [System.Windows.Forms.Screen]::PrimaryScreen
    $right = @($screens | Where-Object { $_.Bounds.X -gt $primary.Bounds.X } | Sort-Object { $_.Bounds.X } | Select-Object -First 1)

    if ($Layout -eq "EditMode" -or $Layout -eq "PlayF5") {
        $area = $primary.WorkingArea
        $viewportArea = if ($right.Count -gt 0) { $right[0].WorkingArea } else { $null }
        return [pscustomobject]@{
            CodeArea = @($screens | Where-Object { $_.Bounds.X -lt $primary.Bounds.X } | Sort-Object { $_.Bounds.X } | Select-Object -Last 1)
            MaximizeMain = $true
            ViewportSlot = if ($viewportArea) { New-Slot "Viewport" $viewportArea.X $viewportArea.Y $viewportArea.Width $viewportArea.Height } else { $null }
            Slots = @(
                New-Slot "Main" $area.X $area.Y $area.Width $area.Height
            )
        }
    }

    if ($Layout -eq "ServerClient1") {
        $area = $primary.WorkingArea
        $leftW = [Math]::Floor($area.Width / 2)
        $rowH = [Math]::Floor($area.Height / 2)
        return [pscustomobject]@{
            CodeArea = @($screens | Where-Object { $_.Bounds.X -lt $primary.Bounds.X } | Sort-Object { $_.Bounds.X } | Select-Object -Last 1)
            ViewportSlot = if ($right.Count -gt 0) { New-Slot "Viewport" $right[0].WorkingArea.X $right[0].WorkingArea.Y $right[0].WorkingArea.Width $right[0].WorkingArea.Height } else { $null }
            Slots = @(
                New-Slot "Main" $area.X $area.Y $leftW $area.Height
                New-Slot "Server" ($area.X + $leftW) $area.Y ($area.Width - $leftW) $rowH
                New-Slot "Client1" ($area.X + $leftW) ($area.Y + $rowH) ($area.Width - $leftW) ($area.Height - $rowH)
            )
        }
    }

    if ($Layout -eq "ServerClient2") {
        $area = $primary.WorkingArea
        $leftW = [Math]::Floor($area.Width / 2)
        $rowH = [Math]::Floor($area.Height / 2)
        return [pscustomobject]@{
            CodeArea = @($screens | Where-Object { $_.Bounds.X -lt $primary.Bounds.X } | Sort-Object { $_.Bounds.X } | Select-Object -Last 1)
            ViewportSlot = if ($right.Count -gt 0) { New-Slot "Viewport" $right[0].WorkingArea.X $right[0].WorkingArea.Y $right[0].WorkingArea.Width $right[0].WorkingArea.Height } else { $null }
            Slots = @(
                New-Slot "Main" $area.X $area.Y $leftW $rowH
                New-Slot "Server" $area.X ($area.Y + $rowH) $leftW ($area.Height - $rowH)
                New-Slot "Client1" ($area.X + $leftW) $area.Y ($area.Width - $leftW) $rowH
                New-Slot "Client2" ($area.X + $leftW) ($area.Y + $rowH) ($area.Width - $leftW) ($area.Height - $rowH)
            )
        }
    }

    if ($Layout -eq "RightFourClients" -and $right.Count -gt 0) {
        $mainArea = $primary.WorkingArea
        $clientArea = $right[0].WorkingArea
        $leftW = [Math]::Floor($mainArea.Width / 3)
        $rowH = [Math]::Floor($mainArea.Height / 2)
        $clientW = [Math]::Floor($clientArea.Width / 2)
        $clientH = [Math]::Floor($clientArea.Height / 2)
        return [pscustomobject]@{
            CodeArea = @($screens | Where-Object { $_.Bounds.X -lt $primary.Bounds.X } | Sort-Object { $_.Bounds.X } | Select-Object -Last 1)
            Slots = @(
                New-Slot "Main" $mainArea.X $mainArea.Y $leftW $rowH
                New-Slot "Server" $mainArea.X ($mainArea.Y + $rowH) $leftW ($mainArea.Height - $rowH)
                New-Slot "Client1" $clientArea.X $clientArea.Y $clientW $clientH
                New-Slot "Client2" ($clientArea.X + $clientW) $clientArea.Y ($clientArea.Width - $clientW) $clientH
                New-Slot "Client3" $clientArea.X ($clientArea.Y + $clientH) $clientW ($clientArea.Height - $clientH)
                New-Slot "Client4" ($clientArea.X + $clientW) ($clientArea.Y + $clientH) ($clientArea.Width - $clientW) ($clientArea.Height - $clientH)
            )
        }
    }

    $area = $primary.WorkingArea
    $colW = [Math]::Floor($area.Width / 3)
    $rowH = [Math]::Floor($area.Height / 2)
    return [pscustomobject]@{
        CodeArea = @($screens | Where-Object { $_.Bounds.X -lt $primary.Bounds.X } | Sort-Object { $_.Bounds.X } | Select-Object -Last 1)
        ViewportSlots = if ($right.Count -gt 0) { New-ViewportGridSlots $right[0] } else { @() }
        Slots = @(
            New-Slot "Main" $area.X $area.Y $colW $rowH
            New-Slot "Server" $area.X ($area.Y + $rowH) $colW ($area.Height - $rowH)
            New-Slot "Client1" ($area.X + $colW) $area.Y $colW $rowH
            New-Slot "Client2" ($area.X + $colW) ($area.Y + $rowH) $colW ($area.Height - $rowH)
            New-Slot "Client3" ($area.X + ($colW * 2)) $area.Y ($area.Width - ($colW * 2)) $rowH
            New-Slot "Client4" ($area.X + ($colW * 2)) ($area.Y + $rowH) ($area.Width - ($colW * 2)) ($area.Height - $rowH)
        )
    }
}

function Get-EffectiveLayout($set) {
    if ($Layout -ne "AutoSafe") { return $Layout }
    if ($set.Server -and $set.Clients.Count -eq 2) { return "ServerClient2" }
    if ($set.Server -and $set.Clients.Count -ge 2) { return "PrimarySix" }
    if ($set.Server -and $set.Clients.Count -eq 1) { return "ServerClient1" }
    return "EditMode"
}

function Test-BoundsNear($window, $slot, [int]$Tolerance = 12) {
    if (-not $window -or -not $slot) { return $false }
    return (
        [Math]::Abs($window.Left - $slot.X) -le $Tolerance -and
        [Math]::Abs($window.Top - $slot.Y) -le $Tolerance -and
        [Math]::Abs($window.Width - $slot.Width) -le ($Tolerance * 2) -and
        [Math]::Abs($window.Height - $slot.Height) -le ($Tolerance * 3)
    )
}

function Test-MaximizedOnSlot($window, $slot, [int]$Tolerance = 24) {
    if (-not $window -or -not $slot) { return $false }
    $expectedX = $slot.X - 8
    $expectedY = $slot.Y - 8
    $expectedW = $slot.Width + 16
    $expectedH = $slot.Height + 16
    return (
        [Math]::Abs($window.Left - $expectedX) -le $Tolerance -and
        [Math]::Abs($window.Top - $expectedY) -le $Tolerance -and
        [Math]::Abs($window.Width - $expectedW) -le ($Tolerance * 2) -and
        [Math]::Abs($window.Height - $expectedH) -le ($Tolerance * 2)
    )
}

function Move-WindowToSlot($window, $slot) {
    if ($DryRun) { return }
    if (Test-BoundsNear $window $slot) { return }
    [LayoutWin32]::ShowWindowAsync([intptr]$window.Handle, $SW_RESTORE) | Out-Null
    Start-Sleep -Milliseconds 80
    [LayoutWin32]::MoveWindow([intptr]$window.Handle, $slot.X, $slot.Y, $slot.Width, $slot.Height, $true) | Out-Null
}

function Move-HandleToSlot($window, $slot, [switch]$MaximizeAfterMove) {
    if (-not $window -or -not $slot -or $DryRun) { return }
    if ($MaximizeAfterMove -and (Test-MaximizedOnSlot $window $slot)) { return }
    if (-not $MaximizeAfterMove -and (Test-BoundsNear $window $slot)) { return }
    [LayoutWin32]::ShowWindowAsync([intptr]$window.Handle, $SW_RESTORE) | Out-Null
    Start-Sleep -Milliseconds 80
    [LayoutWin32]::MoveWindow([intptr]$window.Handle, $slot.X, $slot.Y, $slot.Width, $slot.Height, $true) | Out-Null
    Start-Sleep -Milliseconds 120
    if ($MaximizeAfterMove) {
        [LayoutWin32]::ShowWindowAsync([intptr]$window.Handle, $SW_MAXIMIZE) | Out-Null
    }
}

function Maximize-Window($window) {
    if ($DryRun) { return }
    $primary = [System.Windows.Forms.Screen]::PrimaryScreen
    $slot = New-Slot "Main" $primary.WorkingArea.X $primary.WorkingArea.Y $primary.WorkingArea.Width $primary.WorkingArea.Height
    if (Test-MaximizedOnSlot $window $slot) { return }
    [LayoutWin32]::ShowWindowAsync([intptr]$window.Handle, $SW_MAXIMIZE) | Out-Null
}

function Arrange-Code($screen) {
    if (-not $ArrangeCode -or -not $screen) { return $null }
    $code = Get-VisibleWindows | Where-Object { $_.ProcessName -eq "Code" } | Sort-Object Left, Top | Select-Object -First 1
    if (-not $code) { return $null }
    if (-not $DryRun) {
        $area = $screen.WorkingArea
        $slot = New-Slot "Code" $area.X $area.Y $area.Width $area.Height
        if (Test-MaximizedOnSlot $code $slot) { return $code }
        [LayoutWin32]::ShowWindowAsync([intptr]$code.Handle, $SW_RESTORE) | Out-Null
        Start-Sleep -Milliseconds 80
        [LayoutWin32]::MoveWindow([intptr]$code.Handle, $area.X, $area.Y, $area.Width, $area.Height, $true) | Out-Null
        Start-Sleep -Milliseconds 120
        [LayoutWin32]::ShowWindowAsync([intptr]$code.Handle, $SW_MAXIMIZE) | Out-Null
    }
    return $code
}

function Apply-Layout {
    $set = Wait-StudioSet
    $requestedLayout = $Layout
    $effectiveLayout = Get-EffectiveLayout $set
    if ($Layout -eq "AutoSafe") {
        $script:Layout = $effectiveLayout
    }
    $layoutInfo = Get-LayoutSlots
    $slotsByName = @{}
    foreach ($slot in $layoutInfo.Slots) { $slotsByName[$slot.Name] = $slot }

    if ($layoutInfo.MaximizeMain) {
        Maximize-Window $set.Main
    } else {
        Move-WindowToSlot $set.Main $slotsByName.Main
    }

    if ($effectiveLayout -eq "ServerClient1") {
        Move-WindowToSlot $set.Server $slotsByName.Server
        Move-WindowToSlot $set.Clients[0] $slotsByName.Client1
    }

    if ($effectiveLayout -eq "ServerClient2") {
        Move-WindowToSlot $set.Server $slotsByName.Server
        Move-WindowToSlot $set.Clients[0] $slotsByName.Client1
        Move-WindowToSlot $set.Clients[1] $slotsByName.Client2
    }

    if ($effectiveLayout -eq "PrimarySix" -or $effectiveLayout -eq "RightFourClients") {
        Move-WindowToSlot $set.Server $slotsByName.Server
        $clientCount = [Math]::Min(4, $set.Clients.Count)
        for ($i = 0; $i -lt $clientCount; $i++) {
            Move-WindowToSlot $set.Clients[$i] $slotsByName["Client$($i + 1)"]
        }
    }
    if ($layoutInfo.ViewportSlots -and $layoutInfo.ViewportSlots.Count -gt 0) {
        $clientViewportPids = @($set.Clients | ForEach-Object { [int]$_.Pid })
        $viewportWindows = @(Get-StudioViewportWindows -AllowedPids $clientViewportPids)
        $viewportCount = [Math]::Min($layoutInfo.ViewportSlots.Count, $viewportWindows.Count)
        for ($i = 0; $i -lt $viewportCount; $i++) {
            Move-HandleToSlot $viewportWindows[$i] $layoutInfo.ViewportSlots[$i]
        }
    } elseif ($layoutInfo.ViewportSlot) {
        Move-HandleToSlot (Get-StudioViewportWindow) $layoutInfo.ViewportSlot
    }
    $script:Layout = $requestedLayout
    $codeWindow = Arrange-Code $layoutInfo.CodeArea
    Start-Sleep -Milliseconds 600

    $targetDir = [System.IO.Path]::GetFullPath($OutDir)
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    $manifestPath = Join-Path $targetDir "last-applied-layout.json"
    $fresh = Get-StudioSet
    $manifest = [pscustomobject]@{
        AppliedAt = (Get-Date).ToString("o")
        Layout = $requestedLayout
        EffectiveLayout = $effectiveLayout
        DryRun = [bool]$DryRun
        Slots = $layoutInfo.Slots
        Main = $fresh.Main
        Server = $fresh.Server
        Clients = $fresh.Clients
        Viewports = @(Get-StudioViewportWindows -AllowedPids @($fresh.Clients | ForEach-Object { [int]$_.Pid }))
        Code = $codeWindow
    }
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath
    $manifest
}

if ($Watch) {
    $lastSignature = $null
    $candidateSignature = $null
    $stableCount = 0
    $applied = $false
    while ($true) {
        try {
            $set = Get-StudioSet
            if ($set.Main -and -not $applied) {
                $signature = Get-TopologySignature $set
                if ($signature -eq $candidateSignature) {
                    $stableCount += 1
                } else {
                    $candidateSignature = $signature
                    $stableCount = 1
                }

                if ($stableCount -ge $StablePolls -and $signature -ne $lastSignature) {
                    Apply-Layout | ConvertTo-Json -Depth 8 -Compress
                    $lastSignature = $signature
                    $applied = $true
                    break
                }
            }
        } catch {
            Write-Host $_.Exception.Message
        }
        Start-Sleep -Milliseconds $PollMs
    }
} else {
    Apply-Layout | ConvertTo-Json -Depth 8 -Compress
}
