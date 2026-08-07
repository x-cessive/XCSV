<#
    sync-all.ps1 - keep the hub in step with every member repo

    Runs on this machine rather than in CI for one reason: the runner's
    GITHUB_TOKEN is scoped to the hub alone and cannot clone the private
    members, so it cannot bump their submodule pointers. This machine can.

    What it does:
      1. fetches every member repo and reports anything uncommitted or unpushed
         (it reports - it never commits your work for you)
      2. moves the hub's submodule pointers to each remote tip
      3. regenerates docs/wiki from wiki/ and stamps the landing page
      4. pushes the hub, which triggers the Pages deploy
      5. mirrors wiki/ to the GitHub wiki
      6. writes tools/sync-status.json so XCSV GUARD can show it at a glance

    Safe to run repeatedly. Does nothing and exits 0 when nothing has changed.
    Wired to the "XCSV Sync" scheduled task - see -Install.

    What it will NOT do (XCSV-AI-002)
    ---------------------------------
    It commits only what it produced itself: the submodule gitlinks it moves and
    the docs/wiki pages build-docs.ps1 writes. It used to stage the hub with
    `git add -A`, which swept up anything a human or an AI had left uncommitted
    and published it under a generic automation message with no provenance
    trailers - see commit 9a97709 and hub issue #1.

    Now a dirty tracked file that automation does not own produces
    BLOCKED_DIRTY_SOURCE: nothing is committed, nothing is pushed, the wiki
    mirror is skipped, and the paths are reported. The same care the member-repo
    loop has always taken now applies to the hub. tools/sync-policy.ps1 owns the
    rule; tools/tests/sync-policy.tests.ps1 proves it.
#>

[CmdletBinding()]
param(
    [string] $Root,
    [switch] $Install,
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'

# Resolve paths in the body, not in a param() default. Under the scheduled
# task's `powershell.exe -File ...` invocation $PSScriptRoot came back empty,
# so `Split-Path $PSScriptRoot -Parent` threw before the script had run a single
# line - and the task reported failure every hour while a hand-run of the same
# script worked perfectly.
$ToolsDir = $PSScriptRoot
if (-not $ToolsDir) { $ToolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ToolsDir) { $ToolsDir = 'D:\XCSV\tools' }
if (-not $Root)     { $Root = Split-Path -Parent $ToolsDir }

# Which paths this automation is allowed to commit, and the decision function
# that classifies a dirty tree. Kept in its own file so the rule is testable
# without git, a network or the scheduled task - see tools/tests/.
. (Join-Path $ToolsDir 'sync-policy.ps1')

function Say($msg, $colour = 'Gray') {
    if (-not $Quiet) { Write-Host $msg -ForegroundColor $colour }
}

# git writes progress and CRLF notices to stderr, and under
# $ErrorActionPreference = 'Stop' PowerShell 5.1 turns any native stderr write
# into a terminating error. Capture output, judge on the exit code.
# Deliberately a simple function with no param() block. An advanced function
# tries to bind leading-dash tokens to its own parameters, so `Invoke-Git -C
# <path> add -A` failed with "missing an argument for parameter 'Args'" - the
# trailing -A prefix-matched the parameter name. With no param() block every
# token lands in $args untouched.
function Invoke-Git {
    $rest = $args
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try   { $script:GitOut = (& git @rest 2>&1 | Out-String) }
    finally { $ErrorActionPreference = $old }
    return $LASTEXITCODE
}

# ---------------------------------------------------------------- install ----

if ($Install) {
    $script = Join-Path $ToolsDir 'sync-all.ps1'
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`" -Quiet"

    # Hourly, plus once shortly after logon so a machine that was off overnight
    # catches up without waiting for the next slot.
    $daily = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(7) `
        -RepetitionInterval (New-TimeSpan -Hours 1)
    $logon = New-ScheduledTaskTrigger -AtLogOn
    $logon.Delay = 'PT5M'

    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable `
        -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries `
        -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

    Register-ScheduledTask -TaskName 'XCSV Sync' -Force `
        -Action $action -Trigger @($daily, $logon) -Settings $settings `
        -Description 'Bump XCSV hub submodules, regenerate the docs site, mirror the wiki.' | Out-Null

    Write-Host "installed scheduled task 'XCSV Sync' (hourly, hidden)" -ForegroundColor Green
    return
}

# ------------------------------------------------------------------ repos ----

$members = @(
    @{ Name = 'XCSV_GUARD';  Path = 'D:\XCSV_GUARD';  Sub = 'guard'     }
    @{ Name = 'XCSV_ADDONS'; Path = 'E:\XCSV_ADDONS'; Sub = 'addons'    }
    @{ Name = 'Exile';       Path = 'E:\ExileRepo';   Sub = 'catalogue' }
)

$status = [ordered]@{
    ranAt   = (Get-Date).ToUniversalTime().ToString('o')
    ok      = $true
    changed = $false
    action  = 'UNKNOWN'   # NOOP | COMMIT | BLOCKED_DIRTY_SOURCE
    blocked = @()         # non-automation-owned paths that stopped the sync
    repos   = @()
    notes   = @()
}

Say "--- member repos ---" 'Cyan'
foreach ($m in $members) {
    $r = [ordered]@{ name = $m.Name; path = $m.Path; dirty = $false; ahead = 0; reachable = $true }

    if (-not (Test-Path $m.Path)) {
        $r.reachable = $false
        $status.notes += "$($m.Name): working copy not found at $($m.Path)"
        Say "  $($m.Name): MISSING $($m.Path)" 'Yellow'
        $status.repos += $r
        continue
    }

    [void](Invoke-Git -C $m.Path fetch --quiet origin)

    $dirty = & git -C $m.Path status --porcelain 2>$null
    if ($dirty) {
        $r.dirty = $true
        $n = @($dirty).Count
        $status.notes += "$($m.Name): $n uncommitted file(s)"
        Say "  $($m.Name): $n uncommitted file(s) - not touched" 'Yellow'
    }

    $branch = (& git -C $m.Path rev-parse --abbrev-ref HEAD 2>$null).Trim()
    $ahead  = (& git -C $m.Path rev-list --count "origin/$branch..$branch" 2>$null)
    if ($ahead -and [int]$ahead -gt 0) {
        $r.ahead = [int]$ahead
        $status.notes += "$($m.Name): $ahead commit(s) not pushed"
        Say "  $($m.Name): $ahead local commit(s) not pushed - not pushed for you" 'Yellow'
    }

    if (-not $r.dirty -and $r.ahead -eq 0) { Say "  $($m.Name): clean" 'DarkGray' }
    $status.repos += $r
}

# ------------------------------------------------------------- submodules ----

Say "--- hub ---" 'Cyan'
$before = & git -C $Root submodule status 2>$null
[void](Invoke-Git -C $Root submodule update --remote --merge --quiet)
$after = & git -C $Root submodule status 2>$null
if (($before -join "`n") -ne ($after -join "`n")) {
    Say "  submodule pointers moved" 'Green'
    $status.changed = $true
}

# ------------------------------------------------------------------ docs -----

& (Join-Path $ToolsDir 'build-docs.ps1') -Root $Root | ForEach-Object { Say "  $_" 'DarkGray' }

$pending = & git -C $Root status --porcelain 2>$null
$plan = Get-XcsvSyncPlan -PorcelainLines @($pending)
$status.action = $plan.Action

foreach ($u in $plan.Untracked) {
    # Scoped staging cannot pick these up, so they are not at risk of being
    # absorbed. Report and leave them, exactly as the member-repo loop does.
    $status.notes += "untracked, not touched: $u"
    Say "  untracked, not touched: $u" 'DarkGray'
}

switch ($plan.Action) {

    'BLOCKED_DIRTY_SOURCE' {
        # Someone is mid-edit on a file this automation does not own. Commit
        # nothing - not even the automation-owned subset. build-docs.ps1 has
        # already regenerated docs/wiki from wiki/, so committing the generated
        # half while its source is still moving would publish a page built from
        # work in progress. Both halves land together, authored by whoever is
        # actually writing them.
        $status.ok = $false
        $status.blocked = @($plan.Blocked)
        $status.notes += "BLOCKED_DIRTY_SOURCE: $($plan.Blocked.Count) non-automation-owned file(s) dirty"
        foreach ($b in $plan.Blocked) { $status.notes += "  dirty, preserved: $b" }

        Say "  BLOCKED_DIRTY_SOURCE - committing nothing, your work is untouched" 'Red'
        foreach ($b in $plan.Blocked) { Say "    dirty, preserved: $b" 'Yellow' }
        Say "  commit or stash these yourself, with real authorship, then sync again" 'Yellow'
    }

    'COMMIT' {
        # Stage the automation-owned paths explicitly. Never `add -A`: that is
        # the defect XCSV-AI-002 exists to remove. The pathspec keeps --all
        # scoped, so deletions inside docs/wiki are still handled.
        $contractVersion = Get-XcsvContractVersion -Root $Root
        if (-not $contractVersion) {
            $status.ok = $false
            $status.notes += 'cannot read contract version from wiki/AI-Start-Here.md - refusing to stamp provenance'
            Say "  contract version unreadable - refusing to commit" 'Red'
            break
        }

        [void](Invoke-Git -C $Root add --all -- $XcsvOwnedGitlinks[0] $XcsvOwnedGitlinks[1] $XcsvOwnedGitlinks[2] 'docs/wiki')

        # Prove the staged set matches the plan before committing. If anything
        # else reached the index - a stray `git add` from another process, a
        # pathspec doing more than expected - abandon rather than commit it
        # under an automation trailer.
        $stagedRaw = & git -C $Root diff --cached --name-only 2>$null
        $staged = @($stagedRaw | ForEach-Object { ($_ -replace '\\', '/').Trim() } | Where-Object { $_ })
        $unexpected = @($staged | Where-Object { -not (Test-XcsvAutomationOwnedPath -Path $_) })

        if ($unexpected.Count -gt 0) {
            $status.ok = $false
            $status.notes += "refused to commit: non-owned path reached the index: $($unexpected -join ', ')"
            Say "  REFUSED - non-owned path staged: $($unexpected -join ', ')" 'Red'
            [void](Invoke-Git -C $Root reset --quiet)
            break
        }

        if ($staged.Count -eq 0) {
            Say "  hub already up to date" 'DarkGray'
            break
        }

        $summary = "Sync: submodule pointers and generated docs ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
        $message = New-XcsvAutomationCommitMessage -Summary $summary -ContractVersion $contractVersion

        $msgFile = [System.IO.Path]::GetTempFileName()
        try {
            [System.IO.File]::WriteAllText($msgFile, $message, (New-Object System.Text.UTF8Encoding($false)))
            [void](Invoke-Git -C $Root -c user.name='x-cessive' -c user.email='graygryphonooi@gmail.com' `
                commit --quiet -F $msgFile)
        }
        finally {
            Remove-Item $msgFile -Force -ErrorAction SilentlyContinue
        }

        if ((Invoke-Git -C $Root push --quiet origin main) -ne 0) {
            $status.ok = $false
            $status.notes += 'hub push failed'
            Say "  hub push FAILED" 'Red'
        } else {
            $status.changed = $true
            Say "  hub pushed - Pages will redeploy" 'Green'
        }
    }

    default {
        Say "  hub already up to date" 'DarkGray'
    }
}

# ------------------------------------------------------------------ wiki -----

if ($plan.Action -eq 'BLOCKED_DIRTY_SOURCE') {
    # push-wiki.ps1 mirrors the wiki/ working tree, not the committed tree, so
    # running it here would publish the very uncommitted work the block exists
    # to protect.
    $status.notes += 'wiki mirror skipped while BLOCKED_DIRTY_SOURCE'
    Say "  wiki mirror skipped - would publish uncommitted work" 'Yellow'
}
else {
    try {
        & (Join-Path $ToolsDir 'push-wiki.ps1') -Root $Root | ForEach-Object { Say "  $_" 'DarkGray' }
    }
    catch {
        # A missing wiki is a known state, not a failure - it needs one manual click.
        $status.notes += "wiki: $($_.Exception.Message.Split("`n")[0])"
        Say "  wiki: $($_.Exception.Message.Split("`n")[0])" 'Yellow'
    }
}

# ---------------------------------------------------------------- status -----

$statusPath = Join-Path $ToolsDir 'sync-status.json'
$json = $status | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($statusPath, $json, (New-Object System.Text.UTF8Encoding($false)))

Say "--- done ---" 'Cyan'

# Exit explicitly. Without this the script inherits $LASTEXITCODE from whatever
# native command ran last - and several git calls here return non-zero as a
# normal answer ("no differences"), which the scheduler would report as a
# failed task every hour.
if ($status.ok) { exit 0 } else { exit 1 }
