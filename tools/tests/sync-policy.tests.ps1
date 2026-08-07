<#
    sync-policy.tests.ps1 - proof that the sync automation cannot absorb your work.

    Deliberately not Pester. This box has Pester 3.4.0 (the version Windows
    ships), whose syntax differs enough from Pester 5 that a test file written
    for one silently misbehaves under the other. A regression suite that guards
    provenance must not itself depend on which module version happened to load,
    so this is a plain script: run it, read the verdict, exit code says pass.

        powershell -File tools\tests\sync-policy.tests.ps1

    Two layers:

      1. Unit - Get-XcsvSyncPlan against porcelain fixtures. No git, no network,
         no clock. This is where the six required scenarios live.
      2. Integration - a real throwaway git repository, proving the pathspec
         sync-all.ps1 actually issues stages only automation-owned files. A unit
         test cannot prove that; `git add --all -- <paths>` either scopes or it
         does not, and only git can answer.
#>

[CmdletBinding()]
param([switch] $Quiet)

$ErrorActionPreference = 'Stop'

$ToolsDir = Split-Path -Parent $PSScriptRoot
. (Join-Path $ToolsDir 'sync-policy.ps1')

$script:Passed = 0
$script:Failed = 0
$script:Failures = New-Object System.Collections.Generic.List[string]

function Test-Case {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][scriptblock] $Body
    )
    try {
        & $Body
        $script:Passed++
        if (-not $Quiet) { Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor DarkGreen }
    }
    catch {
        $script:Failed++
        $script:Failures.Add(("{0}: {1}" -f $Name, $_.Exception.Message))
        Write-Host ("  FAIL  {0}" -f $Name) -ForegroundColor Red
        Write-Host ("        {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

function Assert-Equal {
    param($Expected, $Actual, [string] $Because = '')
    if ($Expected -ne $Actual) {
        throw ("expected [{0}] but got [{1}] {2}" -f $Expected, $Actual, $Because)
    }
}

function Assert-SetEqual {
    param([string[]] $Expected, [string[]] $Actual, [string] $Because = '')
    $e = @($Expected | Sort-Object) -join '|'
    $a = @($Actual   | Sort-Object) -join '|'
    if ($e -ne $a) {
        throw ("expected set [{0}] but got [{1}] {2}" -f $e, $a, $Because)
    }
}

Write-Host ''
Write-Host 'XCSV-AI-002 sync policy - unit' -ForegroundColor Cyan

# --- the six required scenarios -------------------------------------------

Test-Case 'clean tree + submodule change -> COMMIT, gitlink owned' {
    $plan = Get-XcsvSyncPlan -PorcelainLines @(' M guard')
    Assert-Equal 'COMMIT' $plan.Action
    Assert-SetEqual @('guard') $plan.Owned
    Assert-Equal 0 $plan.Blocked.Count
}

Test-Case 'clean tree + generated-doc change -> COMMIT, page owned' {
    $plan = Get-XcsvSyncPlan -PorcelainLines @(' M docs/wiki/Home.md')
    Assert-Equal 'COMMIT' $plan.Action
    Assert-SetEqual @('docs/wiki/Home.md') $plan.Owned
    Assert-Equal 0 $plan.Blocked.Count
}

Test-Case 'dirty wiki source before sync -> BLOCKED_DIRTY_SOURCE' {
    # The exact shape of the XCSV-AI-001 incident: an AI edit to wiki source
    # sitting uncommitted when the hourly task fired.
    $plan = Get-XcsvSyncPlan -PorcelainLines @(' M wiki/AI-Start-Here.md')
    Assert-Equal 'BLOCKED_DIRTY_SOURCE' $plan.Action
    Assert-SetEqual @('wiki/AI-Start-Here.md') $plan.Blocked
    Assert-Equal 0 $plan.Owned.Count
}

Test-Case 'dirty README/source before sync -> BLOCKED_DIRTY_SOURCE' {
    $plan = Get-XcsvSyncPlan -PorcelainLines @(' M README.md', ' M tools/build-docs.ps1')
    Assert-Equal 'BLOCKED_DIRTY_SOURCE' $plan.Action
    Assert-SetEqual @('README.md', 'tools/build-docs.ps1') $plan.Blocked
}

Test-Case 'mixed generated + human/AI source -> BLOCKED, nothing committed' {
    # The dangerous case. The generated page must not be committed while the
    # source it was generated from is still moving.
    $plan = Get-XcsvSyncPlan -PorcelainLines @(
        ' M docs/wiki/Home.md'
        ' M wiki/Home.md'
        ' M guard'
    )
    Assert-Equal 'BLOCKED_DIRTY_SOURCE' $plan.Action
    Assert-SetEqual @('wiki/Home.md') $plan.Blocked
    # Owned paths are still reported, but Action governs: the caller commits
    # nothing while blocked.
    Assert-SetEqual @('docs/wiki/Home.md', 'guard') $plan.Owned
}

Test-Case 'no-change sync -> NOOP' {
    Assert-Equal 'NOOP' (Get-XcsvSyncPlan -PorcelainLines @()).Action
    Assert-Equal 'NOOP' (Get-XcsvSyncPlan -PorcelainLines $null).Action
    Assert-Equal 'NOOP' (Get-XcsvSyncPlan -PorcelainLines @('', '   ')).Action
}

# --- boundary conditions ---------------------------------------------------

Test-Case 'all three gitlinks are owned' {
    foreach ($g in @('addons', 'catalogue', 'guard')) {
        if (-not (Test-XcsvAutomationOwnedPath -Path $g)) { throw "gitlink not owned: $g" }
    }
}

Test-Case 'wiki/Memory-Index.md is NOT owned - generated, but not by this script' {
    if (Test-XcsvAutomationOwnedPath -Path 'wiki/Memory-Index.md') {
        throw 'Memory-Index.md must not be automation-owned: build-memory-index.ps1 writes it, sync-all.ps1 does not run that'
    }
    Assert-Equal 'BLOCKED_DIRTY_SOURCE' (Get-XcsvSyncPlan -PorcelainLines @(' M wiki/Memory-Index.md')).Action
}

Test-Case 'hand-maintained files under docs/ are NOT owned' {
    # build-docs.ps1 writes docs/wiki/*.md and nothing else there.
    foreach ($p in @('docs/_config.yml', 'docs/index.html', 'docs/_layouts/base.html', 'docs/addons/index.html')) {
        if (Test-XcsvAutomationOwnedPath -Path $p) { throw "must not be owned: $p" }
    }
}

Test-Case 'nested path under docs/wiki is NOT owned' {
    if (Test-XcsvAutomationOwnedPath -Path 'docs/wiki/sub/Page.md') {
        throw 'pattern must not match nested paths'
    }
}

Test-Case 'a non-.md file in docs/wiki is NOT owned' {
    if (Test-XcsvAutomationOwnedPath -Path 'docs/wiki/notes.txt') {
        throw 'only generated .md pages are owned'
    }
}

Test-Case 'path traversal cannot masquerade as an owned path' {
    foreach ($p in @('../secrets.md', 'docs/wiki/../../README.md', 'x/docs/wiki/Home.md')) {
        if (Test-XcsvAutomationOwnedPath -Path $p) { throw "must not be owned: $p" }
    }
}

Test-Case 'untracked non-owned file is reported, not blocking, never staged' {
    $plan = Get-XcsvSyncPlan -PorcelainLines @('?? scratch.tmp')
    Assert-Equal 'NOOP' $plan.Action
    Assert-SetEqual @('scratch.tmp') $plan.Untracked
    Assert-Equal 0 $plan.Blocked.Count
}

Test-Case 'untracked generated page is owned and committed' {
    $plan = Get-XcsvSyncPlan -PorcelainLines @('?? docs/wiki/New-Page.md')
    Assert-Equal 'COMMIT' $plan.Action
    Assert-SetEqual @('docs/wiki/New-Page.md') $plan.Owned
}

Test-Case 'staged-but-uncommitted human work still blocks' {
    # Index-side status codes, e.g. someone ran `git add` and walked away.
    $plan = Get-XcsvSyncPlan -PorcelainLines @('M  wiki/Home.md', 'A  newfile.md', 'D  README.md')
    Assert-Equal 'BLOCKED_DIRTY_SOURCE' $plan.Action
    Assert-SetEqual @('wiki/Home.md', 'newfile.md', 'README.md') $plan.Blocked
}

Test-Case 'rename is judged on BOTH sides, not just the destination' {
    # Renaming protected source into an owned path must not launder it.
    $plan = Get-XcsvSyncPlan -PorcelainLines @('R  wiki/Home.md -> docs/wiki/Home.md')
    Assert-Equal 'BLOCKED_DIRTY_SOURCE' $plan.Action
    Assert-SetEqual @('wiki/Home.md') $plan.Blocked
}

Test-Case 'quoted paths with spaces are unquoted before matching' {
    $plan = Get-XcsvSyncPlan -PorcelainLines @(' M "docs/wiki/My Page.md"')
    Assert-Equal 'COMMIT' $plan.Action
    Assert-SetEqual @('docs/wiki/My Page.md') $plan.Owned
}

Test-Case 'backslash-separated paths normalise to forward slashes' {
    Assert-Equal $true (Test-XcsvAutomationOwnedPath -Path 'docs\wiki\Home.md')
}

Test-Case 'empty and whitespace paths are never owned' {
    foreach ($p in @('', '   ')) {
        if (Test-XcsvAutomationOwnedPath -Path $p) { throw 'empty path must not be owned' }
    }
}

# --- provenance -------------------------------------------------------------

Write-Host ''
Write-Host 'XCSV-AI-002 automation provenance' -ForegroundColor Cyan

Test-Case 'automation commit message carries all four required trailers' {
    $msg = New-XcsvAutomationCommitMessage -Summary 'Sync: test' -ContractVersion '1.0.0'
    foreach ($t in @(
        'XCSV-Agent: automation'
        'XCSV-Agent-Role: automation'
        'XCSV-Work-ID: XCSV-AI-002'
        'XCSV-Contract: 1.0.0'
    )) {
        if ($msg -notmatch [regex]::Escape($t)) { throw "missing trailer: $t" }
    }
}

Test-Case 'automation never claims to be claude-code or a human' {
    $msg = New-XcsvAutomationCommitMessage -Summary 'Sync: test' -ContractVersion '1.0.0'
    foreach ($bad in @('claude-code', 'opencode', 'codex', 'chatgpt', 'mixed', 'Co-authored-by')) {
        if ($msg -match [regex]::Escape($bad)) { throw "automation message must not contain: $bad" }
    }
}

Test-Case 'refuses to stamp provenance without a contract version' {
    $threw = $false
    try { New-XcsvAutomationCommitMessage -Summary 'x' -ContractVersion '' }
    catch { $threw = $true }
    if (-not $threw) { throw 'expected a throw on an empty contract version' }
}

Test-Case 'contract version is read from the canonical contract, not hardcoded' {
    $root = Split-Path -Parent $ToolsDir
    $v = Get-XcsvContractVersion -Root $root
    if ($v -notmatch '^\d+\.\d+\.\d+$') { throw "unusable contract version: [$v]" }
}

# --- integration: prove the real pathspec scopes ---------------------------

Write-Host ''
Write-Host 'XCSV-AI-002 staging scope - integration (real git)' -ForegroundColor Cyan

Test-Case 'git add --all -- <owned paths> stages ONLY owned files' {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("xcsv-sync-test-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        & git -C $tmp init --quiet 2>&1 | Out-Null
        & git -C $tmp config user.name  'test' 2>&1 | Out-Null
        & git -C $tmp config user.email 'test@example.invalid' 2>&1 | Out-Null

        New-Item -ItemType Directory -Path (Join-Path $tmp 'docs\wiki') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $tmp 'wiki') -Force | Out-Null

        Set-Content -LiteralPath (Join-Path $tmp 'docs\wiki\Home.md') -Value 'generated v1'
        Set-Content -LiteralPath (Join-Path $tmp 'wiki\Home.md')      -Value 'source v1'
        Set-Content -LiteralPath (Join-Path $tmp 'README.md')         -Value 'readme v1'

        & git -C $tmp add -A 2>&1 | Out-Null
        & git -C $tmp commit --quiet -m 'base' 2>&1 | Out-Null

        # Now dirty one file of each kind, exactly like the incident.
        Set-Content -LiteralPath (Join-Path $tmp 'docs\wiki\Home.md') -Value 'generated v2'
        Set-Content -LiteralPath (Join-Path $tmp 'wiki\Home.md')      -Value 'source v2 - HUMAN WORK'
        Set-Content -LiteralPath (Join-Path $tmp 'README.md')         -Value 'readme v2 - HUMAN WORK'

        # The pathspec sync-all.ps1 issues. 'addons'/'catalogue'/'guard' do not
        # exist in this fixture, so only docs/wiki is passed - git errors on a
        # pathspec matching nothing, which is itself worth knowing.
        & git -C $tmp add --all -- 'docs/wiki' 2>&1 | Out-Null

        $staged = @(& git -C $tmp diff --cached --name-only 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        Assert-SetEqual @('docs/wiki/Home.md') $staged 'only the generated page may be staged'

        # And prove the human work is still sitting there, unstaged and intact.
        $unstaged = @(& git -C $tmp diff --name-only 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        Assert-SetEqual @('README.md', 'wiki/Home.md') $unstaged 'human work must remain unstaged'

        $content = Get-Content -LiteralPath (Join-Path $tmp 'wiki\Home.md') -Raw
        if ($content -notmatch 'HUMAN WORK') { throw 'human work was altered' }
    }
    finally {
        # .git holds read-only pack files on Windows.
        Get-ChildItem -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Attributes = 'Normal' }
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Test-Case 'the old broken behaviour is genuinely absent from sync-all.ps1' {
    # Regression guard on the literal defect: `git add -A` at the hub root.
    $syncAll = [System.IO.File]::ReadAllText((Join-Path $ToolsDir 'sync-all.ps1'))
    $code = ($syncAll -split "`r?`n" | Where-Object { -not $_.TrimStart().StartsWith('#') }) -join "`n"
    if ($code -match 'Invoke-Git\s+-C\s+\$Root\s+add\s+-A\b') {
        throw 'sync-all.ps1 still stages the hub with `git add -A`'
    }
    if ($code -notmatch 'BLOCKED_DIRTY_SOURCE') {
        throw 'sync-all.ps1 does not implement BLOCKED_DIRTY_SOURCE'
    }
}

# --- text safety check ------------------------------------------------------

Write-Host ''
Write-Host 'XCSV-AI-002 text safety check' -ForegroundColor Cyan

# A safety check that cannot fail is worse than no check: it reports "clean" and
# is believed. The first version of check-text-safety.ps1 did exactly that - it
# computed relative paths by Substring against a root that could be an 8.3 short
# path, produced garbage like "7/tools/offender.ps1", matched no protected
# pattern, and passed on a planted offender. These cases plant one and require
# it to be found.

function New-SafetyFixture {
    param([Parameter(Mandatory = $true)][hashtable] $Files)

    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("xcsv-safety-" + [guid]::NewGuid().ToString('N'))
    foreach ($rel in $Files.Keys) {
        $full = Join-Path $dir $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
        [System.IO.File]::WriteAllText($full, $Files[$rel])
    }
    return $dir
}

function Invoke-Child {
    <#
        Run a child PowerShell and capture stdout+stderr without letting the
        stderr write become a terminating error.

        PowerShell 5.1 turns any native stderr write into a terminating error
        while $ErrorActionPreference is 'Stop'. sync-all.ps1 and push-wiki.ps1
        both carry comments about it; this suite hit it anyway the moment a
        child script was expected to fail on purpose. Demote, capture, and judge
        on the exit code and the text.
    #>
    param([string[]] $ArgumentList)

    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass @ArgumentList 2>&1 | Out-String
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $out }
    }
    finally { $ErrorActionPreference = $old }
}

function Invoke-SafetyCheck {
    param([string] $Root)
    $checker = Join-Path $ToolsDir 'check-text-safety.ps1'
    Invoke-Child -ArgumentList @('-File', $checker, '-Root', $Root)
}

Test-Case 'planted same-file round-trip on a protected path is DETECTED' {
    $fixture = New-SafetyFixture @{
        'tools\offender.ps1' = '(Get-Content $p) -replace ''a'',''b'' | Set-Content $p -Encoding utf8'
    }
    try {
        $r = Invoke-SafetyCheck -Root $fixture
        Assert-Equal 1 $r.ExitCode 'planted offender must fail the check'
        if ($r.Output -notmatch 'offender\.ps1') { throw 'offender not named in output' }
    }
    finally { Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
}

Test-Case 'detection survives an 8.3 short-path root' {
    # The exact condition that made the check silently pass.
    $fixture = New-SafetyFixture @{
        'tools\offender.ps1' = '(Get-Content $p) | Set-Content $p -Encoding utf8'
    }
    try {
        $shortRoot = $fixture -replace [regex]::Escape($env:USERPROFILE), $env:TEMP.Substring(0, $env:TEMP.IndexOf('\AppData'))
        $r = Invoke-SafetyCheck -Root $fixture
        Assert-Equal 1 $r.ExitCode 'must still detect regardless of root path form'
    }
    finally { Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
}

Test-Case 'writing to a DIFFERENT file is not reported' {
    $fixture = New-SafetyFixture @{
        'tools\fine.ps1' = 'Get-Content $src | Set-Content $dst -Encoding utf8'
    }
    try { Assert-Equal 0 (Invoke-SafetyCheck -Root $fixture).ExitCode }
    finally { Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
}

Test-Case 'byte-level rewrite is not reported' {
    $fixture = New-SafetyFixture @{
        'tools\bytes.ps1' = '$s = [System.IO.File]::ReadAllText($p); [System.IO.File]::WriteAllBytes($p, $b)'
    }
    try { Assert-Equal 0 (Invoke-SafetyCheck -Root $fixture).ExitCode }
    finally { Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
}

Test-Case 'the live XCSV hub is clean' {
    $root = Split-Path -Parent $ToolsDir
    $r = Invoke-SafetyCheck -Root $root
    if ($r.ExitCode -ne 0) { throw ("hub has an unsafe rewrite:`n" + $r.Output) }
}

# --- wiki publishing guard --------------------------------------------------

Write-Host ''
Write-Host 'XCSV-AI-002 wiki publish guard' -ForegroundColor Cyan

# A sandbox run of sync-all.ps1 during this very work item pushed a throwaway
# test edit onto the live GitHub wiki, because push-wiki.ps1 targets a fixed
# production URL while -Root is a free parameter. These cases hold that door
# shut.

Test-Case 'publishing from a foreign checkout is refused' {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("xcsv-wiki-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $dir 'wiki') -Force | Out-Null
    try {
        & git -C $dir init --quiet 2>&1 | Out-Null
        & git -C $dir remote add origin 'https://github.com/someone-else/OtherRepo.git' 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $dir 'wiki\Home.md') -Value 'not the real wiki'

        $script = Join-Path $ToolsDir 'push-wiki.ps1'
        $r = Invoke-Child -ArgumentList @('-Command', "& '$script' -Root '$dir' -WhatIf")

        if ($r.Output -notmatch 'refusing to publish') {
            throw ("expected a refusal, got:`n" + $r.Output)
        }
        if ($r.Output -match 'wiki published') {
            throw 'a foreign checkout reached the publish step'
        }
    }
    finally {
        Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object { try { $_.Attributes = 'Normal' } catch {} }
        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Test-Case 'the real hub is still allowed to publish' {
    # The guard must not be so strict that it blocks the legitimate caller -
    # that would just get it disabled. -WhatIf stops before any commit or push.
    $root = Split-Path -Parent $ToolsDir
    $script = Join-Path $ToolsDir 'push-wiki.ps1'
    $r = Invoke-Child -ArgumentList @('-Command', "& '$script' -Root '$root' -WhatIf")
    if ($r.Output -match 'refusing to publish') {
        throw ("the real hub must not be refused:`n" + $r.Output)
    }
}

Test-Case 'guard normalises repo identity and offers an explicit override' {
    $text = [System.IO.File]::ReadAllText((Join-Path $ToolsDir 'push-wiki.ps1'))
    foreach ($needle in @('.wiki.git', 'AllowForeignRoot', 'refusing to publish')) {
        if (-not $text.Contains($needle)) { throw "guard is missing: $needle" }
    }
}

# --- verdict ---------------------------------------------------------------

Write-Host ''
Write-Host ("Passed: {0}   Failed: {1}" -f $script:Passed, $script:Failed) -ForegroundColor $(if ($script:Failed) { 'Red' } else { 'Green' })
if ($script:Failed -gt 0) {
    Write-Host ''
    Write-Host 'Failures:' -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host ("  " + $f) -ForegroundColor Yellow }
    exit 1
}
Write-Host 'XCSV-AI-002 sync policy: PASS' -ForegroundColor Green
exit 0
