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
#>

[CmdletBinding()]
param(
    [string] $Root = (Split-Path $PSScriptRoot -Parent),
    [switch] $Install,
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'

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
    $script = Join-Path $PSScriptRoot 'sync-all.ps1'
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

& (Join-Path $PSScriptRoot 'build-docs.ps1') -Root $Root | ForEach-Object { Say "  $_" 'DarkGray' }

$pending = & git -C $Root status --porcelain 2>$null
if ($pending) {
    [void](Invoke-Git -C $Root add -A)
    [void](Invoke-Git -C $Root -c user.name='x-cessive' -c user.email='graygryphonooi@gmail.com' `
        commit --quiet -m "Sync: submodule pointers and generated docs ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))")
    if ((Invoke-Git -C $Root push --quiet origin main) -ne 0) {
        $status.ok = $false
        $status.notes += 'hub push failed'
        Say "  hub push FAILED" 'Red'
    } else {
        $status.changed = $true
        Say "  hub pushed - Pages will redeploy" 'Green'
    }
} else {
    Say "  hub already up to date" 'DarkGray'
}

# ------------------------------------------------------------------ wiki -----

try {
    & (Join-Path $PSScriptRoot 'push-wiki.ps1') -Root $Root | ForEach-Object { Say "  $_" 'DarkGray' }
}
catch {
    # A missing wiki is a known state, not a failure - it needs one manual click.
    $status.notes += "wiki: $($_.Exception.Message.Split("`n")[0])"
    Say "  wiki: $($_.Exception.Message.Split("`n")[0])" 'Yellow'
}

# ---------------------------------------------------------------- status -----

$statusPath = Join-Path $PSScriptRoot 'sync-status.json'
$json = $status | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($statusPath, $json, (New-Object System.Text.UTF8Encoding($false)))

Say "--- done ---" 'Cyan'

# Exit explicitly. Without this the script inherits $LASTEXITCODE from whatever
# native command ran last - and several git calls here return non-zero as a
# normal answer ("no differences"), which the scheduler would report as a
# failed task every hour.
if ($status.ok) { exit 0 } else { exit 1 }
