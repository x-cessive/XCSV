<#
    check-doc-links.ps1 - validate local README/wiki/docs links.

    This check is intentionally repository-local and deterministic. It does not
    crawl external URLs; network/link health policy belongs to the broader #37
    guardrail lane.
#>

[CmdletBinding()]
param(
    [string] $Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

function Test-External([string] $Target) {
    return $Target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:' -or $Target.StartsWith('//')
}

function Resolve-DocTarget([string] $SourcePath, [string] $Target) {
    $clean = ($Target -split '#')[0]
    if ([string]::IsNullOrWhiteSpace($clean)) { return @() }
    if (Test-External $clean) { return @() }

    $base = Split-Path -Parent $SourcePath
    $candidates = New-Object System.Collections.Generic.List[string]

    if ($SourcePath -match '(^|[\\/])wiki[\\/]' -and $clean -notmatch '[\\/]|\.(md|html)$') {
        $candidates.Add((Join-Path $Root ("wiki\$clean.md")))
    }

    if ($SourcePath -match '(^|[\\/])docs[\\/]wiki[\\/]' -and $clean -notmatch '[\\/]|\.(md|html)$') {
        $candidates.Add((Join-Path $Root ("docs\wiki\$clean.md")))
    }

    if ($clean.EndsWith('.html') -and $SourcePath -match '(^|[\\/])docs[\\/]wiki[\\/]') {
        $candidates.Add((Join-Path $Root ("docs\wiki\" + ($clean -replace '\.html$', '.md'))))
    }

    $candidates.Add((Join-Path $base $clean))
    return $candidates
}

$files = @(
    Join-Path $Root 'README.md'
    Join-Path $Root 'AI-START-HERE.md'
)
$files += Get-ChildItem -LiteralPath (Join-Path $Root 'wiki') -Filter '*.md' -File | Select-Object -ExpandProperty FullName
$files += Get-ChildItem -LiteralPath (Join-Path $Root 'docs\wiki') -Filter '*.md' -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

$missing = New-Object System.Collections.Generic.List[string]
foreach ($file in $files) {
    $text = [System.IO.File]::ReadAllText($file)
    foreach ($match in [regex]::Matches($text, '(?<!\!)\[[^\]]+\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim()
        $target = $target.Trim('"')
        if ([string]::IsNullOrWhiteSpace($target) -or $target.StartsWith('#') -or (Test-External $target)) {
            continue
        }

        $candidates = @(Resolve-DocTarget -SourcePath $file -Target $target)
        if ($candidates.Count -eq 0) { continue }
        $exists = $false
        foreach ($candidate in $candidates) {
            if (Test-Path -LiteralPath $candidate) {
                $exists = $true
                break
            }
        }
        if (-not $exists) {
            $rel = [IO.Path]::GetRelativePath($Root, $file)
            $missing.Add("$rel -> $target")
        }
    }
}

if ($missing.Count -gt 0) {
    throw "Broken local documentation links:`n$($missing -join "`n")"
}

Write-Host "check-doc-links: PASS ($($files.Count) files)"
