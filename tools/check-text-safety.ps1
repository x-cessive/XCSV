<#
    check-text-safety.ps1 - refuse PowerShell that silently re-encodes protected text.

    The incident this exists to prevent (XCSV-AI-001, 2026-08-07)
    ------------------------------------------------------------
    A one-line fix to the desktop ROADMAP.md was made with:

        (Get-Content $p) -replace 'a','b' | Set-Content $p -Encoding utf8

    In PowerShell 5.1 that is not a targeted edit. `Get-Content` decodes with
    the ANSI codepage, and `Set-Content -Encoding utf8` writes a BOM. The
    round-trip re-encoded every non-ASCII byte in a 147 KB authoritative
    document: pre-existing double-encoded UTF-8 became triple-encoded and a BOM
    appeared at the top. 154,439 bytes of unreviewed rewrite across
    evidence-bearing text, from a command that looked like a one-character
    change.

    It was recoverable only because the transform happened to be invertible. The
    next one might not be.

    What this checks
    ----------------
    Scans PowerShell under -Root for a same-file read/write round-trip: a
    `Get-Content` whose output is piped or assigned into a `Set-Content` /
    `Out-File` targeting the same variable or path. That is the shape of the
    bug, independent of whether -Encoding was passed on any given day.

    Targeted line edits, byte-level rewrites via [System.IO.File], and writes to
    a *different* file are all left alone - they are not this failure.

    Exit 0 clean, 1 on any finding. Wired into the AI contract drift workflow.
#>

[CmdletBinding()]
param(
    [string] $Root,
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'

# Resolve in the body, not in a param() default. Under `powershell.exe -File`
# $PSScriptRoot comes back empty and a default of `Split-Path $PSScriptRoot`
# throws before the script runs a line - the same trap that made the XCSV Sync
# scheduled task fail hourly while a hand-run worked. sync-all.ps1 carries the
# same note; this script repeated the mistake anyway, which is why it is now
# written the same way in both places.
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ScriptDir) { $ScriptDir = 'D:\XCSV\tools' }
if (-not $Root)      { $Root = Split-Path -Parent $ScriptDir }

# Normalise before any path arithmetic. $Root may arrive as a short 8.3 path
# (C:\Users\ARCHIT~1\...) while Get-ChildItem returns the long form, and a
# naive Substring against the raw string then produces garbage relative paths
# that match no protected pattern - the check would pass by accident, which is
# the worst way for a safety check to fail. Get-Item expands 8.3 to the real
# name; Resolve-Path does NOT, so do not substitute it here.
$Root = (Get-Item -LiteralPath $Root).FullName.TrimEnd([char]92, [char]47)

# Paths whose text is authoritative: contracts, generated-doc sources, CI and
# the tooling that maintains them. A silent re-encode here destroys evidence or
# breaks a parser (a BOM before Jekyll front matter has already cost this
# project one silent failure - see build-docs.ps1).
$protectedPatterns = @(
    '^tools/.*\.ps1$'
    '^wiki/.*\.md$'
    '^docs/.*$'
    '^\.github/.*$'
    '^(CLAUDE|AGENTS|README|AI-START-HERE|AI-PROVENANCE)\.md$'
    '^opencode\.json$'
    '^\.agents/.*$'
)

$findings = New-Object System.Collections.Generic.List[object]

function Get-RelativePath {
    <#
        Repo-relative, forward-slashed. Throws rather than guessing if the file
        is not under $Root: a silently wrong relative path is how this check
        previously reported "clean" on a file that was not clean.
    #>
    param([string] $FullName)

    if (-not $FullName.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) {
        throw "path is not under root: $FullName (root: $Root)"
    }
    ($FullName.Substring($Root.Length).TrimStart([char]92, [char]47)) -replace '\\', '/'
}

$scripts = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.ps1' -ErrorAction SilentlyContinue |
    Where-Object {
        $r = Get-RelativePath $_.FullName
        # Member repos are vendored in as submodules and own their own tooling.
        if ($r -match '^(guard|addons|catalogue)/') { return $false }
        # Test fixtures plant the offending pattern on purpose - that is how the
        # detector is proven to work. Reporting them would force the suite to
        # choose between testing the check and passing it.
        if ($r -match '^tools/tests/')              { return $false }
        return $true
    }

foreach ($file in $scripts) {
    $rel = Get-RelativePath $file.FullName
    $lines = [System.IO.File]::ReadAllLines($file.FullName)

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]

        # Only the round-trip shape matters: a read and a write of the same
        # target on one statement.
        if ($line -notmatch 'Get-Content')                  { continue }
        if ($line -notmatch '(Set-Content|Out-File)')        { continue }

        # This file documents the pattern in prose; do not report the examples.
        if ($rel -eq 'tools/check-text-safety.ps1')          { continue }
        if ($line.TrimStart().StartsWith('#'))               { continue }

        # Pull the target of the read and the target of the write and compare.
        # Same target on both sides == destructive same-file round-trip.
        $readTarget  = if ($line -match 'Get-Content\s+(?:-(?:LiteralPath|Path)\s+)?(\$[\w:.\[\]]+|[''"][^''"]+[''"])') { $Matches[1] } else { $null }
        $writeTarget = if ($line -match '(?:Set-Content|Out-File)\s+(?:-(?:LiteralPath|Path|FilePath)\s+)?(\$[\w:.\[\]]+|[''"][^''"]+[''"])') { $Matches[1] } else { $null }

        if ($readTarget -and $writeTarget -and $readTarget -eq $writeTarget) {
            $findings.Add([pscustomobject]@{
                File   = $rel
                Line   = $i + 1
                Target = $readTarget
                Text   = $line.Trim()
                Why    = 'same-file Get-Content/Set-Content round-trip re-encodes the whole file'
            })
        }
    }
}

$protected = @($findings | Where-Object {
    $f = $_.File
    ($protectedPatterns | Where-Object { $f -match $_ }).Count -gt 0
})

if (-not $Quiet) {
    Write-Host "check-text-safety: scanned $($scripts.Count) script(s) under $Root"
}

if ($protected.Count -eq 0) {
    if (-not $Quiet) { Write-Host 'check-text-safety: no unsafe same-file rewrites on protected paths' }
    exit 0
}

Write-Host ''
Write-Host 'UNSAFE TEXT REWRITE on a protected path:' -ForegroundColor Red
foreach ($f in $protected) {
    Write-Host ("  {0}:{1}  {2}" -f $f.File, $f.Line, $f.Text) -ForegroundColor Yellow
    Write-Host ("      {0}" -f $f.Why) -ForegroundColor DarkGray
}
Write-Host ''
Write-Host 'In PowerShell 5.1 this re-encodes every non-ASCII byte in the file:' -ForegroundColor Gray
Write-Host 'Get-Content decodes with the ANSI codepage and Set-Content -Encoding utf8 adds a BOM.' -ForegroundColor Gray
Write-Host 'Edit the specific lines, or read and write bytes with [System.IO.File].' -ForegroundColor Gray

exit 1
