# xcsv-coldpaths.ps1 - which of our code has NEVER run?
#
# Keep this file pure ASCII. PowerShell 5.1 reads .ps1 as ANSI without a BOM.
#
# WHY THIS EXISTS
# ===============
# Twice on 2026-08-10 the decisive evidence in an investigation was an ABSENCE.
#
# The Player Inspector was reported as "renders its frame but the content area
# is empty". `grep XCSV_INS` across every RPT on the box returned zero lines.
# Both the success path and the refusal path in that handler end in a diag_log,
# so a single request - authorised or not - would have left a trace. The app had
# never been exercised past opening it, and that single fact reframed the whole
# investigation.
#
# Hours later the same technique found something worse: zero occurrences of
# "bought a policy", zero refusals, and every "loaded N charge(s)" reading zero
# across twenty server RPTs. The Insurance feature had never completed a
# purchase in the server's entire history, because its network handler was
# aliased under a name the dispatcher would never look up.
#
# Both times that grep was typed by hand. A feature that has never once logged
# is either unreachable, unused, or broken, and all three are worth knowing
# BEFORE a player finds out. So: extract every log tag our source can emit, and
# report which have never appeared in any log we keep.
#
# WHAT IT IS NOT
# ==============
# It is not a test. A cold path is a QUESTION, not a defect - a seasonal feature
# or an admin-only tool can be legitimately cold. The output is a list to be
# looked at, and its value is that the list is short.
#
#   .\tools\xcsv-coldpaths.ps1
#   .\tools\xcsv-coldpaths.ps1 -Json
#
# Exit code is always 0. This reports, it does not gate.

[CmdletBinding()]
param(
    [switch]$Json,
    [string[]]$SourceRoots = @(
        'E:\ExileRepo\LiveSource\mpmissions\Exile.Tanoa',
        'E:\ExileRepo\LiveSource\server-addons'
    ),
    [string[]]$LogRoots = @(
        'E:\arma3server\profiles',
        "$env:LOCALAPPDATA\Arma 3"
    )
)

$ErrorActionPreference = 'Continue'

# --- 1. every tag our source can emit --------------------------------------
# Our convention is diag_log "[XCSV_THING] ...". The tag is the bracketed prefix,
# which is stable even when the rest of the message is a format string.
$tags = @{}
foreach ($root in $SourceRoots) {
    if (-not (Test-Path $root)) { continue }
    foreach ($f in Get-ChildItem $root -Recurse -Include *.sqf -ErrorAction SilentlyContinue) {
        $text = Get-Content $f.FullName -Raw
        foreach ($m in [regex]::Matches($text, 'diag_log\s+(?:format\s*\[\s*)?"\s*(\[[A-Z0-9_]+\])')) {
            $tag = $m.Groups[1].Value
            if (-not $tags.ContainsKey($tag)) { $tags[$tag] = @() }
            $rel = $f.FullName.Replace($root, '').TrimStart('\')
            if ($tags[$tag] -notcontains $rel) { $tags[$tag] += $rel }
        }
    }
}

if ($tags.Count -eq 0) {
    Write-Output 'No XCSV log tags found in source. Check -SourceRoots.'
    exit 0
}

# --- 2. every tag any log has actually seen --------------------------------
# Read once per file and test every tag against it. The naive shape - loop the
# tags, grep the logs - re-reads hundreds of megabytes per tag.
$seen = @{}
$logFiles = @()
foreach ($root in $LogRoots) {
    if (-not (Test-Path $root)) { continue }
    $logFiles += Get-ChildItem $root -Recurse -Include *.rpt, *.log -ErrorAction SilentlyContinue
}

$tagList = @($tags.Keys)
foreach ($lf in $logFiles) {
    $content = ''
    try { $content = [IO.File]::ReadAllText($lf.FullName) } catch { continue }
    if ($content -eq '') { continue }
    foreach ($tag in $tagList) {
        if ($seen.ContainsKey($tag)) { continue }
        if ($content.Contains($tag)) { $seen[$tag] = $lf.Name }
    }
}

# --- 3. report --------------------------------------------------------------
$rows = @()
foreach ($tag in ($tagList | Sort-Object)) {
    $isCold = -not $seen.ContainsKey($tag)
    $where = ''
    if (-not $isCold) { $where = $seen[$tag] }
    $rows += [pscustomobject]@{
        tag     = $tag
        state   = $(if ($isCold) { 'COLD' } else { 'seen' })
        evidence = $where
        sources = ($tags[$tag] -join '; ')
    }
}

if ($Json) {
    $rows | ConvertTo-Json -Depth 4
    exit 0
}

$cold = @($rows | Where-Object { $_.state -eq 'COLD' })
$warm = @($rows | Where-Object { $_.state -eq 'seen' })

Write-Output ''
Write-Output ("  Scanned {0} log file(s) for {1} tag(s) our source can emit." -f $logFiles.Count, $tagList.Count)
Write-Output ''

if ($cold.Count -eq 0) {
    Write-Output '  No cold paths. Every tag our code can emit has appeared in a log at least once.'
} else {
    Write-Output ("  COLD - never logged, not once ({0}):" -f $cold.Count)
    Write-Output ''
    foreach ($r in $cold) {
        Write-Output ("    {0,-22} {1}" -f $r.tag, $r.sources)
    }
    Write-Output ''
    Write-Output '  A cold path is a question, not a verdict. Ask of each: can it be reached at all,'
    Write-Output '  has anyone had reason to use it, and would it work if they did? The Insurance'
    Write-Output '  purchase path was cold for the whole life of the server because its handler was'
    Write-Output '  aliased under a name the dispatcher never looked up.'
}

Write-Output ''
Write-Output ("  seen at least once ({0}):" -f $warm.Count)
foreach ($r in $warm) {
    Write-Output ("    {0,-22} {1}" -f $r.tag, $r.evidence)
}
Write-Output ''
exit 0
