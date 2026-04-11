param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('list', 'describe', 'focus', 'capture', 'click', 'keypress', 'text', 'move')]
    [string]$Action,
    [int]$WindowPid,
    [string]$TitlePattern,
    [string]$OutPath,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [string]$Key,
    [string]$Text,
    [ValidateSet('client', 'window')]
    [string]$CaptureArea = 'client',
    [int]$DelayMs = 250,
    [switch]$Maximize
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$signature = @'
using System;
using System.Runtime.InteropServices;

public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public struct POINT {
    public int X;
    public int Y;
}

public static class Win32 {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
}
'@

Add-Type -TypeDefinition $signature

$SW_RESTORE = 9
$SW_MAXIMIZE = 3
$MOUSEEVENTF_LEFTDOWN = 0x0002
$MOUSEEVENTF_LEFTUP = 0x0004

function Get-WindowCandidates {
    Get-Process |
        Where-Object { $_.MainWindowHandle -ne 0 -and [string]::IsNullOrWhiteSpace($_.MainWindowTitle) -eq $false } |
        ForEach-Object {
            $rect = New-Object RECT
            [Win32]::GetWindowRect($_.MainWindowHandle, [ref]$rect) | Out-Null
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

function Resolve-Window {
    $candidates = Get-WindowCandidates
    if ($WindowPid) {
        $match = $candidates | Where-Object { $_.Pid -eq $WindowPid } | Select-Object -First 1
        if ($match) { return $match }
        throw "Window PID not found: $WindowPid"
    }
    if (-not [string]::IsNullOrWhiteSpace($TitlePattern)) {
        $match = $candidates | Where-Object { $_.Title -match $TitlePattern } | Select-Object -First 1
        if ($match) { return $match }
        throw "Window title pattern not found: $TitlePattern"
    }
    throw 'Provide -WindowPid or -TitlePattern.'
}

function Focus-Window([object]$window) {
    $shell = New-Object -ComObject WScript.Shell
    $null = $shell.AppActivate($window.Pid)
    if ($Maximize) {
        [Win32]::ShowWindowAsync([intptr]$window.Handle, $SW_MAXIMIZE) | Out-Null
    } else {
        [Win32]::ShowWindowAsync([intptr]$window.Handle, $SW_RESTORE) | Out-Null
    }
    Start-Sleep -Milliseconds 120
    [Win32]::SetForegroundWindow([intptr]$window.Handle) | Out-Null
    Start-Sleep -Milliseconds $DelayMs
}

function Get-ClientOrigin([object]$window) {
    $clientRect = New-Object RECT
    [Win32]::GetClientRect([intptr]$window.Handle, [ref]$clientRect) | Out-Null
    $point = New-Object POINT
    $point.X = 0
    $point.Y = 0
    [Win32]::ClientToScreen([intptr]$window.Handle, [ref]$point) | Out-Null
    [pscustomobject]@{
        Left = $point.X
        Top = $point.Y
        Width = [Math]::Max(0, $clientRect.Right - $clientRect.Left)
        Height = [Math]::Max(0, $clientRect.Bottom - $clientRect.Top)
    }
}

function Get-WindowBounds([object]$window) {
    $rect = New-Object RECT
    [Win32]::GetWindowRect([intptr]$window.Handle, [ref]$rect) | Out-Null
    [pscustomobject]@{
        Left = $rect.Left
        Top = $rect.Top
        Width = [Math]::Max(0, $rect.Right - $rect.Left)
        Height = [Math]::Max(0, $rect.Bottom - $rect.Top)
    }
}

function Get-CaptureBounds([object]$window, [string]$area) {
    if ($area -eq 'window') {
        return Get-WindowBounds $window
    }
    return Get-ClientOrigin $window
}

function Get-WindowSnapshotMetadata([object]$window, [string]$area, [string]$targetPath) {
    $windowBounds = Get-WindowBounds $window
    $clientBounds = Get-ClientOrigin $window
    $captureBounds = Get-CaptureBounds $window $area
    [pscustomobject]@{
        Pid = $window.Pid
        Title = $window.Title
        CaptureArea = $area
        ImagePath = $targetPath
        WindowBounds = [pscustomobject]@{
            Left = $windowBounds.Left
            Top = $windowBounds.Top
            Width = $windowBounds.Width
            Height = $windowBounds.Height
        }
        ClientBounds = [pscustomobject]@{
            Left = $clientBounds.Left
            Top = $clientBounds.Top
            Width = $clientBounds.Width
            Height = $clientBounds.Height
        }
        CaptureBounds = [pscustomobject]@{
            Left = $captureBounds.Left
            Top = $captureBounds.Top
            Width = $captureBounds.Width
            Height = $captureBounds.Height
        }
        CapturedAt = (Get-Date).ToString('o')
    }
}

switch ($Action) {
    'list' {
        Get-WindowCandidates |
            Sort-Object ProcessName, Title, Pid |
            Format-Table Pid, ProcessName, Title, Left, Top, Width, Height -AutoSize
        break
    }
    'describe' {
        $window = Resolve-Window
        $metadata = Get-WindowSnapshotMetadata $window $CaptureArea $null
        $metadata | ConvertTo-Json -Depth 6 -Compress
        break
    }
    'focus' {
        $window = Resolve-Window
        Focus-Window $window
        [pscustomobject]@{
            Pid = $window.Pid
            Title = $window.Title
            Status = 'focused'
        } | ConvertTo-Json -Compress
        break
    }
    'capture' {
        if ([string]::IsNullOrWhiteSpace($OutPath)) {
            throw 'capture requires -OutPath'
        }
        $window = Resolve-Window
        Focus-Window $window
        $bounds = Get-CaptureBounds $window $CaptureArea
        $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.CopyFromScreen($bounds.Left, $bounds.Top, 0, 0, $bmp.Size)
        $targetPath = [System.IO.Path]::GetFullPath($OutPath)
        $dir = Split-Path -Parent $targetPath
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }
        $bmp.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bmp.Dispose()
        $metadata = Get-WindowSnapshotMetadata $window $CaptureArea $targetPath
        $metadataPath = [System.IO.Path]::ChangeExtension($targetPath, '.json')
        $metadata | ConvertTo-Json -Depth 6 | Set-Content -Path $metadataPath
        [pscustomobject]@{
            Pid = $window.Pid
            Title = $window.Title
            Path = $targetPath
            MetadataPath = $metadataPath
            CaptureArea = $CaptureArea
            Width = $bounds.Width
            Height = $bounds.Height
        } | ConvertTo-Json -Compress
        break
    }
    'click' {
        $window = Resolve-Window
        Focus-Window $window
        $bounds = Get-ClientOrigin $window
        $targetX = $bounds.Left + $X
        $targetY = $bounds.Top + $Y
        [Win32]::SetCursorPos($targetX, $targetY) | Out-Null
        Start-Sleep -Milliseconds 80
        [Win32]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 40
        [Win32]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
        [pscustomobject]@{
            Pid = $window.Pid
            Title = $window.Title
            ClickedX = $X
            ClickedY = $Y
        } | ConvertTo-Json -Compress
        break
    }
    'move' {
        $window = Resolve-Window
        if ($Width -le 0 -or $Height -le 0) {
            throw 'move requires positive -Width and -Height'
        }
        [Win32]::MoveWindow([intptr]$window.Handle, $X, $Y, $Width, $Height, $true) | Out-Null
        Start-Sleep -Milliseconds $DelayMs
        [pscustomobject]@{
            Pid = $window.Pid
            Title = $window.Title
            X = $X
            Y = $Y
            Width = $Width
            Height = $Height
        } | ConvertTo-Json -Compress
        break
    }
    'keypress' {
        if ([string]::IsNullOrWhiteSpace($Key)) {
            throw 'keypress requires -Key'
        }
        $window = Resolve-Window
        Focus-Window $window
        [System.Windows.Forms.SendKeys]::SendWait($Key)
        Start-Sleep -Milliseconds $DelayMs
        [pscustomobject]@{
            Pid = $window.Pid
            Title = $window.Title
            Key = $Key
        } | ConvertTo-Json -Compress
        break
    }
    'text' {
        if ([string]::IsNullOrWhiteSpace($Text)) {
            throw 'text requires -Text'
        }
        $window = Resolve-Window
        Focus-Window $window
        [System.Windows.Forms.SendKeys]::SendWait($Text)
        Start-Sleep -Milliseconds $DelayMs
        [pscustomobject]@{
            Pid = $window.Pid
            Title = $window.Title
            Text = $Text
        } | ConvertTo-Json -Compress
        break
    }
}
