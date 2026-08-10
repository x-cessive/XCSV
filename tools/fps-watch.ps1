<#
    fps-watch.ps1 - sample server FPS next to host CPU, so the next regime
    change names its own cause.

    Why this exists
    ---------------
    2026-08-10 analysis (see fps-report.ps1) showed the server does not decay
    with uptime. It sits in one of two regimes, ~23 FPS or ~46 FPS, and steps
    between them on *wall-clock* time with nothing in-game changing:

        08-06 10:06  46.2 -> 25.7 FPS, players unchanged at 2
        08-10 01:12  22.8 -> 46.4 FPS, players unchanged at 1

    A clean 2:1 ratio that appears and disappears on wall-clock time, with the
    same mods, mission, world and thread counts either side, points at
    something else on the host taking CPU - not at Arma. The RPT cannot name
    that, because it only sees inside the server process.

    So: sample FPS and per-process CPU together. When the next transition
    happens, the row before and after it identifies the culprit by name.

    Read-only with respect to the game. It starts nothing and kills nothing.

    Usage
    -----
        .\tools\fps-watch.ps1                    sample forever, 60s apart
        .\tools\fps-watch.ps1 -IntervalSec 30
        .\tools\fps-watch.ps1 -Once              single row, for testing
#>

[CmdletBinding()]
param(
    [string]$ProfilesDir = 'E:\arma3server\profiles',
    [string]$OutCsv      = 'D:\CAGE\xcsv-fps-watch.csv',
    [int]$IntervalSec    = 60,
    [int]$TopN           = 6,
    [switch]$Once
)

$ErrorActionPreference = 'Continue'

function Read-Locked([string]$path) {
    $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Open,
          [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try { (New-Object System.IO.StreamReader($fs)).ReadToEnd() } finally { $fs.Dispose() }
}

# Newest server FPS reading, from infiSTAR's processReporter line.
function Get-LatestFps {
    $rpt = Get-ChildItem $ProfilesDir -Filter 'arma3server*.rpt' -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $rpt) { return $null }
    $text = Read-Locked $rpt.FullName
    $ms = [regex]::Matches($text, 'Started @ ([\d.]+) : \[FPS: ([\d.]+)\|PLAYERS: (\d+)\|THREADS: (\d+)\]')
    if ($ms.Count -eq 0) { return $null }
    $m = $ms[$ms.Count - 1]
    [pscustomobject]@{
        Rpt     = $rpt.Name
        UpMin   = [Math]::Round([double]$m.Groups[1].Value / 60.0, 1)
        Fps     = [Math]::Round([double]$m.Groups[2].Value, 1)
        Players = [int]$m.Groups[3].Value
        Threads = [int]$m.Groups[4].Value
    }
}

# CPU percent per process across one interval, from total-processor-time deltas.
# Get-Process CPU is cumulative, so a delta over a known window is the only way
# to get "busy right now" without the cost of a full perf-counter query.
$prev = @{}
function Get-TopCpu([double]$windowSec) {
    $now = @{}
    foreach ($p in Get-Process -ErrorAction SilentlyContinue) {
        try { $now[$p.Id] = @{ Cpu = $p.TotalProcessorTime.TotalSeconds; Name = $p.ProcessName } } catch { }
    }
    $rows = @()
    foreach ($id in $now.Keys) {
        if ($prev.ContainsKey($id)) {
            $d = $now[$id].Cpu - $prev[$id].Cpu
            if ($d -gt 0) {
                $rows += [pscustomobject]@{
                    Name = $now[$id].Name
                    Pid  = $id
                    Pct  = [Math]::Round(100.0 * $d / ($windowSec * [Environment]::ProcessorCount), 1)
                }
            }
        }
    }
    $script:prev = $now
    $rows | Sort-Object Pct -Descending | Select-Object -First $TopN
}

if (-not (Test-Path (Split-Path $OutCsv -Parent))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $OutCsv -Parent) | Out-Null
}
if (-not (Test-Path $OutCsv)) {
    'Time,Rpt,UpMin,Fps,Players,Threads,TotalCpuPct,TopProcs' |
        Out-File -FilePath $OutCsv -Encoding utf8
}

Get-TopCpu 1 | Out-Null       # prime the deltas
$last = Get-Date

while ($true) {
    Start-Sleep -Seconds $IntervalSec
    $window = ((Get-Date) - $last).TotalSeconds
    $last = Get-Date

    $f   = Get-LatestFps
    $top = Get-TopCpu $window
    $tot = if ($top) { [Math]::Round(($top | Measure-Object Pct -Sum).Sum, 1) } else { 0 }
    $txt = ($top | ForEach-Object { '{0}({1}) {2}%' -f $_.Name, $_.Pid, $_.Pct }) -join ' | '

    $row = '{0},{1},{2},{3},{4},{5},{6},"{7}"' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),
           $(if ($f) { $f.Rpt } else { '' }),
           $(if ($f) { $f.UpMin } else { '' }),
           $(if ($f) { $f.Fps } else { '' }),
           $(if ($f) { $f.Players } else { '' }),
           $(if ($f) { $f.Threads } else { '' }),
           $tot, $txt

    Add-Content -Path $OutCsv -Value $row -Encoding utf8
    if ($Once) { Write-Output $row; break }
}
