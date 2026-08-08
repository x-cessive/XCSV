<#
    ai-desktop-capture.ps1 - live XCSV desktop layout + evidence capture

    Agent workflow:
      D:\XCSV\tools\ai-desktop-capture.ps1 -Layout -Shot
      D:\XCSV\tools\ai-desktop-capture.ps1 -GuardTab RCon -Shot

    This is for live debugging, not website/product screenshots. It pins Orca
    to the left half of the primary screen and XCSV GUARD to the right half,
    then captures the whole desktop plus a JSON/text manifest. The manifest is
    the accessibility-friendly record for agents that cannot read images.

    Output defaults to D:\CAGE\xcsv-desktop-shots and must not be committed.
#>

[CmdletBinding()]
param(
    [string] $OutDir = 'D:\CAGE\xcsv-desktop-shots',
    [switch] $Layout,
    [switch] $Shot,
    [ValidateSet('Overview','Integrity','AI','Metrics','Players','Database','RCon','InfiSTAR','ServerLog','Consoles','Restarts','Docs','Settings')]
    [string] $GuardTab,
    [switch] $WideGuardForShot,
    [switch] $NoOrcaState
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

if (-not ('XcsvDeskWin' -as [type])) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public class XcsvDeskWin {
    public delegate bool EnumWindowsProc(IntPtr h, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out int pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder text, int count);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextLength(IntPtr h);

    [StructLayout(LayoutKind.Sequential)] public struct RECT {
        public int Left; public int Top; public int Right; public int Bottom;
    }
}
'@
}

$SW_RESTORE = 9
$SWP_NOZORDER = 0x0004
$SWP_SHOWWINDOW = 0x0040
$MOUSEEVENTF_LEFTDOWN = 0x0002
$MOUSEEVENTF_LEFTUP = 0x0004

function Get-WindowTitle([IntPtr] $Handle) {
    $len = [XcsvDeskWin]::GetWindowTextLength($Handle)
    if ($len -le 0) { return '' }
    $sb = [Text.StringBuilder]::new($len + 1)
    [void][XcsvDeskWin]::GetWindowText($Handle, $sb, $sb.Capacity)
    $sb.ToString()
}

function Get-ProcessMainWindow([string] $ProcessName, [string] $TitleContains = '') {
    $candidates = New-Object System.Collections.Generic.List[object]
    [XcsvDeskWin+EnumWindowsProc] $cb = {
        param([IntPtr] $h, [IntPtr] $l)
        if (-not [XcsvDeskWin]::IsWindowVisible($h)) { return $true }
        $winPid = 0
        [void][XcsvDeskWin]::GetWindowThreadProcessId($h, [ref]$winPid)
        $p = Get-Process -Id $winPid -ErrorAction SilentlyContinue
        if (-not $p -or $p.ProcessName -ne $ProcessName) { return $true }
        $title = Get-WindowTitle $h
        if ($TitleContains -and $title -notlike "*$TitleContains*") { return $true }
        $r = New-Object XcsvDeskWin+RECT
        if (-not [XcsvDeskWin]::GetWindowRect($h, [ref]$r)) { return $true }
        $w = [Math]::Max(0, $r.Right - $r.Left)
        $hgt = [Math]::Max(0, $r.Bottom - $r.Top)
        $candidates.Add([pscustomobject]@{
            process = $ProcessName
            pid = $winPid
            handle = $h
            title = $title
            left = $r.Left
            top = $r.Top
            width = $w
            height = $hgt
            area = $w * $hgt
        })
        return $true
    }
    [void][XcsvDeskWin]::EnumWindows($cb, [IntPtr]::Zero)
    $candidates | Sort-Object area -Descending | Select-Object -First 1
}

function Move-Window([object] $Window, [int] $X, [int] $Y, [int] $W, [int] $H) {
    if (-not $Window) { return $null }
    [void][XcsvDeskWin]::ShowWindow($Window.handle, $SW_RESTORE)
    Start-Sleep -Milliseconds 150
    [void][XcsvDeskWin]::SetWindowPos($Window.handle, [IntPtr]::Zero, $X, $Y, $W, $H, ($SWP_NOZORDER -bor $SWP_SHOWWINDOW))
    Start-Sleep -Milliseconds 150
    Get-WindowRectObject $Window.handle $Window.process $Window.pid
}

function Get-WindowRectObject([IntPtr] $Handle, [string] $ProcessName, [int] $ProcessId) {
    $r = New-Object XcsvDeskWin+RECT
    [void][XcsvDeskWin]::GetWindowRect($Handle, [ref]$r)
    [pscustomobject]@{
        process = $ProcessName
        pid = $ProcessId
        handle = $Handle.ToInt64()
        title = Get-WindowTitle $Handle
        left = $r.Left
        top = $r.Top
        width = $r.Right - $r.Left
        height = $r.Bottom - $r.Top
    }
}

function Invoke-Click([int] $X, [int] $Y) {
    [void][XcsvDeskWin]::SetCursorPos($X, $Y)
    Start-Sleep -Milliseconds 80
    [XcsvDeskWin]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 50
    [XcsvDeskWin]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [IntPtr]::Zero)
}

function Set-GuardTab([object] $GuardWindow, [string] $TabName) {
    if (-not $GuardWindow) { throw 'XCSV_GUARD window not found' }
    $tabY = @{
        Overview = 76
        Integrity = 102
        AI = 129
        Metrics = 156
        Players = 183
        Database = 210
        RCon = 237
        InfiSTAR = 263
        ServerLog = 290
        Consoles = 317
        Restarts = 344
        Docs = 370
        Settings = 397
    }
    [void][XcsvDeskWin]::SetForegroundWindow($GuardWindow.handle)
    Start-Sleep -Milliseconds 200
    Invoke-Click ($GuardWindow.left + 64) ($GuardWindow.top + [int]$tabY[$TabName])
    Start-Sleep -Milliseconds 500
}

function Save-DesktopShot([string] $Path) {
    $bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $bmp = [Drawing.Bitmap]::new($bounds.Width, $bounds.Height)
    $g = [Drawing.Graphics]::FromImage($bmp)
    try {
        $g.CopyFromScreen($bounds.Left, $bounds.Top, 0, 0, $bounds.Size)
        $bmp.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $g.Dispose()
        $bmp.Dispose()
    }
    [pscustomobject]@{
        path = $Path
        left = $bounds.Left
        top = $bounds.Top
        width = $bounds.Width
        height = $bounds.Height
    }
}

function Invoke-OrcaState([string] $App) {
    $orca = if ($env:ORCA_CLI_COMMAND) { $env:ORCA_CLI_COMMAND } else { 'orca' }
    try {
        $raw = & $orca computer get-app-state --app $App --no-screenshot --json 2>$null
        if ($LASTEXITCODE -eq 0 -and $raw) { return ($raw | ConvertFrom-Json) }
    } catch {}
    $null
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$rightX = $screen.Left + [int]($screen.Width / 2)
$rightW = [int]($screen.Width / 2)
$leftW = [int]($screen.Width / 2)
$restoreRightLayout = $false
$orcaWindow = Get-ProcessMainWindow 'Orca'
$guardWindow = Get-ProcessMainWindow 'XCSV_GUARD' 'XCSV GUARD'
$layoutResult = @()

if ($Layout) {
    if ($orcaWindow) {
        $layoutResult += Move-Window $orcaWindow $screen.Left $screen.Top $leftW $screen.Height
    }
    if ($guardWindow) {
        $layoutResult += Move-Window $guardWindow $rightX $screen.Top $rightW $screen.Height
        $guardWindow = Get-ProcessMainWindow 'XCSV_GUARD' 'XCSV GUARD'
    }
}

if ($WideGuardForShot) {
    if (-not $guardWindow) { $guardWindow = Get-ProcessMainWindow 'XCSV_GUARD' 'XCSV GUARD' }
    if ($guardWindow) {
        $targetW = [Math]::Min($screen.Width, [Math]::Max(1280, $rightW))
        $targetX = $screen.Left + $screen.Width - $targetW
        $layoutResult += Move-Window $guardWindow $targetX $screen.Top $targetW $screen.Height
        $guardWindow = Get-ProcessMainWindow 'XCSV_GUARD' 'XCSV GUARD'
        $restoreRightLayout = $true
    }
}

if ($GuardTab) {
    if (-not $guardWindow) { $guardWindow = Get-ProcessMainWindow 'XCSV_GUARD' 'XCSV GUARD' }
    Set-GuardTab $guardWindow $GuardTab
    $guardWindow = Get-ProcessMainWindow 'XCSV_GUARD' 'XCSV GUARD'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$shotInfo = $null
if ($Shot) {
    $shotInfo = Save-DesktopShot (Join-Path $OutDir "desktop-$stamp.png")
}

if ($restoreRightLayout) {
    $orcaWindow = Get-ProcessMainWindow 'Orca'
    $guardWindow = Get-ProcessMainWindow 'XCSV_GUARD' 'XCSV GUARD'
    if ($orcaWindow) {
        $layoutResult += Move-Window $orcaWindow $screen.Left $screen.Top $leftW $screen.Height
    }
    if ($guardWindow) {
        $layoutResult += Move-Window $guardWindow $rightX $screen.Top $rightW $screen.Height
        $guardWindow = Get-ProcessMainWindow 'XCSV_GUARD' 'XCSV GUARD'
    }
}

$stateDir = Join-Path $OutDir "state-$stamp"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$guardState = if ($NoOrcaState) { $null } else { Invoke-OrcaState 'XCSV_GUARD' }
$orcaState = if ($NoOrcaState) { $null } else { Invoke-OrcaState 'Orca' }

if ($guardState -and $guardState.result.snapshot.treeText) {
    [IO.File]::WriteAllText((Join-Path $stateDir 'guard-tree.txt'), $guardState.result.snapshot.treeText, [Text.UTF8Encoding]::new($false))
}
if ($orcaState -and $orcaState.result.snapshot.treeText) {
    [IO.File]::WriteAllText((Join-Path $stateDir 'orca-tree.txt'), $orcaState.result.snapshot.treeText, [Text.UTF8Encoding]::new($false))
}

$manifest = [pscustomobject]@{
    captured_at = (Get-Date).ToString('o')
    output_dir = $OutDir
    layout_rule = 'Orca left, XCSV GUARD right. Do not minimize GUARD or Orca for routine AI debugging.'
    requested_tab = $GuardTab
    wide_guard_for_shot = [bool]$WideGuardForShot
    restored_right_layout_after_shot = [bool]$restoreRightLayout
    screenshot = $shotInfo
    windows = @{
        orca = if ($orcaWindow) { Get-WindowRectObject $orcaWindow.handle 'Orca' $orcaWindow.pid } else { $null }
        guard = if ($guardWindow) { Get-WindowRectObject $guardWindow.handle 'XCSV_GUARD' $guardWindow.pid } else { $null }
    }
    layout_applied = $layoutResult
    text_state = @{
        directory = $stateDir
        guard_tree = if (Test-Path (Join-Path $stateDir 'guard-tree.txt')) { Join-Path $stateDir 'guard-tree.txt' } else { $null }
        orca_tree = if (Test-Path (Join-Path $stateDir 'orca-tree.txt')) { Join-Path $stateDir 'orca-tree.txt' } else { $null }
        note = 'Use text_state files when an agent cannot read screenshots.'
    }
}

$manifestPath = Join-Path $OutDir "desktop-$stamp.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding ascii
$manifest | ConvertTo-Json -Depth 8
