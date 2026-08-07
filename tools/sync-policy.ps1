<#
    sync-policy.ps1 - what the XCSV sync automation is allowed to commit.

    Dot-source this. It defines functions and constants only; loading it has no
    side effects, which is what makes the decision testable without a git
    repository, a network or the scheduled task.

    Why this file exists
    --------------------
    sync-all.ps1 used to stage the hub with `git add -A`. That stages everything
    dirty in the working tree - tracked or not, whoever wrote it - so any file a
    human or an AI left uncommitted was swept into the next hourly automation
    commit under a generic message with no provenance trailers. Commit 9a97709
    absorbed an AI-authored wiki edit exactly that way (XCSV-AI-001, hub issue
    #1); XCSV-AI-002 is the repair.

    The rule
    --------
    Automation owns exactly what sync-all.ps1 itself produces:

      - the submodule gitlinks it moves:      addons, catalogue, guard
      - the site pages build-docs.ps1 writes: docs/wiki/*.md

    Everything else is someone's work. That includes wiki/*.md source and
    wiki/Memory-Index.md - generated, but by build-memory-index.ps1, which this
    automation does not run. If automation did not produce it, automation does
    not commit it.

    Three outcomes, and the reasoning behind each:

      NOOP                  nothing dirty. Do nothing, exit clean.

      COMMIT                only automation-owned paths are dirty. Stage those
                            paths explicitly - never `-A` - and commit with
                            automation provenance trailers.

      BLOCKED_DIRTY_SOURCE  a tracked, non-owned file is dirty. Commit nothing
                            at all, preserve the work, report loudly.

    BLOCKED_DIRTY_SOURCE deliberately blocks the *whole* sync rather than
    committing the owned subset and skipping the rest. Consider a half-finished
    edit to wiki/Home.md: build-docs.ps1 has already regenerated
    docs/wiki/Home.md from it, so committing the generated half alone would
    publish a page built from source that is still moving. The two must land
    together, authored by whoever is actually writing them. Submodule pointers
    stop advancing while a tree is dirty; that is a visible, loudly reported,
    self-correcting cost, and it is cheaper than silently misattributing or
    publishing someone's unfinished work.

    Untracked non-owned files are a softer case: scoped staging cannot pick them
    up, so they are not at risk of being absorbed. They are reported and
    otherwise ignored, matching how the member-repo loop already treats dirty
    members - report, never touch.
#>

# Submodule gitlinks this automation moves, exactly as they appear in
# `git status --porcelain`.
$XcsvOwnedGitlinks = @('addons', 'catalogue', 'guard')

# Generated site pages. build-docs.ps1 writes docs/wiki/<Page>.md and nothing
# else under docs/ - the layouts, includes and _config.yml there are
# hand-maintained, so the pattern is deliberately narrow.
$XcsvOwnedPathPattern = '^docs/wiki/[^/]+\.md$'


function Get-XcsvPorcelainEntry {
    <#
        Parse one `git status --porcelain=v1` line into its status code and the
        path(s) it touches.

        Format is `XY <path>`, where XY is two status characters. Renames and
        copies arrive as `R  old -> new` and touch both sides, so both are
        returned - classifying only the destination would let a file be renamed
        out of a protected path unnoticed. Paths containing unusual bytes are
        C-quoted by git; unquote them so matching sees the real path.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Line)

    if ([string]::IsNullOrWhiteSpace($Line)) { return $null }
    if ($Line.Length -lt 4) { return $null }

    $code = $Line.Substring(0, 2)
    $rest = $Line.Substring(3)

    $parts = if ($rest -match ' -> ') { $rest -split ' -> ', 2 } else { , $rest }

    $paths = foreach ($p in $parts) {
        $t = $p.Trim()
        if ($t.StartsWith('"') -and $t.EndsWith('"') -and $t.Length -ge 2) {
            $t = $t.Substring(1, $t.Length - 2)
            # git C-quotes backslashes and quotes; undo the two that matter.
            $t = $t -replace '\\"', '"' -replace '\\\\', '\'
        }
        $t -replace '\\', '/'
    }

    [pscustomobject]@{
        Code      = $code
        Paths     = @($paths | Where-Object { $_ })
        Untracked = ($code -eq '??')
    }
}


function Test-XcsvAutomationOwnedPath {
    <#
        True when this exact path is something sync-all.ps1 produces itself.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }

    $p = ($Path -replace '\\', '/').Trim().TrimEnd('/')

    if ($XcsvOwnedGitlinks -contains $p) { return $true }
    if ($p -match $XcsvOwnedPathPattern) { return $true }

    return $false
}


function Get-XcsvSyncPlan {
    <#
        Decide what the automation may do, from porcelain output alone.

        Returns Action = NOOP | COMMIT | BLOCKED_DIRTY_SOURCE, plus the paths
        behind the decision so the caller can stage precisely and report
        precisely.
    #>
    [CmdletBinding()]
    param([string[]] $PorcelainLines)

    $owned     = New-Object System.Collections.Generic.List[string]
    $blocked   = New-Object System.Collections.Generic.List[string]
    $untracked = New-Object System.Collections.Generic.List[string]

    foreach ($line in @($PorcelainLines)) {
        $entry = Get-XcsvPorcelainEntry -Line $line
        if (-not $entry) { continue }

        foreach ($path in $entry.Paths) {
            if (Test-XcsvAutomationOwnedPath -Path $path) {
                if (-not $owned.Contains($path)) { $owned.Add($path) }
            }
            elseif ($entry.Untracked) {
                if (-not $untracked.Contains($path)) { $untracked.Add($path) }
            }
            else {
                if (-not $blocked.Contains($path)) { $blocked.Add($path) }
            }
        }
    }

    $action =
        if ($blocked.Count -gt 0)  { 'BLOCKED_DIRTY_SOURCE' }
        elseif ($owned.Count -gt 0) { 'COMMIT' }
        else                        { 'NOOP' }

    [pscustomobject]@{
        Action    = $action
        Owned     = @($owned)
        Blocked   = @($blocked)
        Untracked = @($untracked)
    }
}


function Get-XcsvContractVersion {
    <#
        Read the contract version from the canonical contract rather than
        hardcoding it, so an automation trailer cannot quietly outlive the
        version it claims. Returns $null when it cannot be established - callers
        must not guess a version.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string] $Root)

    $contract = Join-Path $Root 'wiki\AI-Start-Here.md'
    if (-not (Test-Path -LiteralPath $contract)) { return $null }

    $match = Select-String -LiteralPath $contract -Pattern 'XCSV-AI-CONTRACT:\s*([0-9]+\.[0-9]+\.[0-9]+)' |
        Select-Object -First 1
    if (-not $match) { return $null }

    return $match.Matches[0].Groups[1].Value
}


function New-XcsvAutomationCommitMessage {
    <#
        Automation provenance, and only for automation-authored content. The
        caller must have established that every staged path is
        automation-owned before calling this - stamping `XCSV-Agent: automation`
        onto a human or AI edit is the exact misattribution XCSV-AI-002 exists
        to prevent.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Summary,
        [Parameter(Mandatory = $true)][string] $ContractVersion
    )

    if ([string]::IsNullOrWhiteSpace($ContractVersion)) {
        throw 'Refusing to build an automation commit message without a contract version.'
    }

    @(
        $Summary.Trim()
        ''
        'XCSV-Agent: automation'
        'XCSV-Agent-Role: automation'
        'XCSV-Work-ID: XCSV-AI-002'
        "XCSV-Contract: $ContractVersion"
    ) -join "`n"
}
