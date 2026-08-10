<#
    fps-report.ps1 - characterise server FPS against uptime, per boot.

    Why this exists
    ---------------
    The standing complaint was "FPS decays with uptime". The first time anyone
    actually plotted it (2026-08-10) that turned out to be the wrong shape: two
    four-hour boots sat flat at ~24 FPS for their entire life, and a separate
    boot sat flat at ~46. The server is bimodal, not decaying, and the useful
    question is "which regime is this boot in and when did it switch", not "how
    fast is it sliding".

    This is read-only. It parses RPTs that already exist; it starts nothing and
    changes nothing.

    Source series
    -------------
    infiSTAR's processReporter stamps uptime and FPS on one line:

        "[processReporter] Started @ 220.331 : [FPS: 46.7836|PLAYERS: 0|THREADS: 11]"

    The LOOTBOX summary supplies the live unit count:

        "... Units:81 ... FPS:41(av:46) Started:12.78min"

    Usage
    -----
        .\tools\fps-report.ps1                 summary table for every boot
        .\tools\fps-report.ps1 -Curve          per-boot FPS-vs-uptime profile
        .\tools\fps-report.ps1 -ProfilesDir X  read RPTs from somewhere else
#>

[CmdletBinding()]
param(
    [string]$ProfilesDir = 'E:\arma3server\profiles',
    [switch]$Curve,
    [int]$BinMinutes = 10
)

$ErrorActionPreference = 'Stop'

function Read-Locked([string]$path) {
    # The live RPT is held open by the running server, so a plain read throws.
    $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Open,
          [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try { (New-Object System.IO.StreamReader($fs)).ReadToEnd() } finally { $fs.Dispose() }
}

function Get-BootSamples([string]$text) {
    $out = New-Object System.Collections.ArrayList
    foreach ($m in [regex]::Matches($text, 'Started @ ([\d.]+) : \[FPS: ([\d.]+)\|PLAYERS: (\d+)\|THREADS: (\d+)\]')) {
        [void]$out.Add([pscustomobject]@{
            UpMin   = [double]$m.Groups[1].Value / 60.0
            Fps     = [double]$m.Groups[2].Value
            Players = [int]$m.Groups[3].Value
            Threads = [int]$m.Groups[4].Value
        })
    }
    , ($out | Sort-Object UpMin)
}

$files = Get-ChildItem $ProfilesDir -Filter 'arma3server*.rpt' -ErrorAction SilentlyContinue | Sort-Object Name
if (-not $files) { Write-Host "fps-report: no RPTs under $ProfilesDir"; return }

$rows = New-Object System.Collections.ArrayList
foreach ($f in $files) {
    $text = Read-Locked $f.FullName
    $s = Get-BootSamples $text
    if ($s.Count -lt 3) { continue }

    $boot = $f.Name -replace 'arma3server(_x64)?_|\.rpt', ''

    # Join evidence must come from the server's own log. The headless client's
    # RPT survives a server-only restart and would vouch for the previous boot.
    $hcJoined = ($text -match '\[A3XAI\] Headless client HC.*logged in successfully') -or
                ($text -match 'Starting transfer of.*Scripts to Headless Client')

    $units = @()
    foreach ($m in [regex]::Matches($text, 'Units:(\d+)')) { $units += [int]$m.Groups[1].Value }

    # First and last third, so a single noisy reading cannot drive the verdict.
    $k     = [Math]::Max(1, [int]($s.Count / 3))
    $early = ($s | Select-Object -First $k | Measure-Object Fps -Average).Average
    $late  = ($s | Select-Object -Last  $k | Measure-Object Fps -Average).Average

    # Least-squares slope, FPS per hour of uptime.
    $mx = ($s | Measure-Object UpMin -Average).Average
    $my = ($s | Measure-Object Fps   -Average).Average
    $num = 0.0; $den = 0.0
    foreach ($p in $s) { $num += ($p.UpMin - $mx) * ($p.Fps - $my); $den += ($p.UpMin - $mx) * ($p.UpMin - $mx) }
    $slope = if ($den -gt 0) { ($num / $den) * 60 } else { 0 }

    [void]$rows.Add([pscustomobject]@{
        Boot     = $boot
        UpMin    = [Math]::Round(($s | Select-Object -Last 1).UpMin, 0)
        N        = $s.Count
        HC       = if ($hcJoined) { 'joined' } else { 'no' }
        EarlyFps = [Math]::Round($early, 1)
        LateFps  = [Math]::Round($late, 1)
        SlopeHr  = [Math]::Round($slope, 2)
        Units    = if ($units.Count) { [Math]::Round(($units | Measure-Object -Average).Average, 0) } else { 0 }
        Samples  = $s
    })
}

if (-not $rows.Count) { Write-Host 'fps-report: no boot had enough samples to report'; return }

$rows | Select-Object Boot, UpMin, N, HC, EarlyFps, LateFps, SlopeHr, Units |
    Format-Table -AutoSize | Out-String -Width 200 | Write-Host

# Regime split. The observed modes are ~24 and ~46 FPS; 35 sits between them.
$hi = @($rows | Where-Object { $_.LateFps -ge 35 })
$lo = @($rows | Where-Object { $_.LateFps -lt 35 })
Write-Host ''
Write-Host ('regime  high (>=35 FPS): {0} boots   low (<35 FPS): {1} boots' -f $hi.Count, $lo.Count)
if ($hi.Count) { Write-Host ('  high mean {0:n1} FPS' -f ($hi | Measure-Object LateFps -Average).Average) }
if ($lo.Count) { Write-Host ('  low  mean {0:n1} FPS' -f ($lo | Measure-Object LateFps -Average).Average) }

$long = @($rows | Where-Object { $_.UpMin -ge 60 })
if ($long.Count) {
    Write-Host ''
    Write-Host 'boots over an hour, which are the only ones that could show decay:'
    foreach ($r in $long) {
        Write-Host ('  {0}  {1,4} min  {2,5:n1} -> {3,5:n1} FPS  ({4:n2} FPS/hr)' -f $r.Boot, $r.UpMin, $r.EarlyFps, $r.LateFps, $r.SlopeHr)
    }
}

if ($Curve) {
    foreach ($r in $rows) {
        Write-Host ''
        Write-Host ('=== {0}  ({1} samples, HC {2}) ===' -f $r.Boot, $r.N, $r.HC)
        $bins = $r.Samples | Group-Object { [int]([Math]::Floor($_.UpMin / $BinMinutes) * $BinMinutes) }
        foreach ($b in ($bins | Sort-Object { [int]$_.Name })) {
            $avg = ($b.Group | Measure-Object Fps -Average).Average
            Write-Host ('  {0,4}-{1,4} min  {2,5:n1}  {3}' -f [int]$b.Name, ([int]$b.Name + $BinMinutes), $avg, ('#' * [int]($avg / 2)))
        }
    }
}
