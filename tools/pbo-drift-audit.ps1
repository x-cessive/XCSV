# pbo-drift-audit - compare every deployed PBO against the source we hold for it.
#
# Keep this file pure ASCII. PowerShell 5.1 reads .ps1 as ANSI without a BOM.
#
# WHY THIS EXISTS
#
# On 2026-08-10 xcsv_chatter.pbo was found to contain a complete network
# handler - ExileServer_xcsv_chatter_network_inspectRequest and its wiring -
# that did not exist anywhere in E:\ExileRepo\LiveSource\server-addons\
# xcsv_chatter. The code had been written straight into the deployed PBO and
# never written back to the tree it was supposed to come from.
#
# That is a live time bomb rather than an untidiness. The moment anyone edits
# a comment in the source tree and repacks - which is the documented, correct
# way to change an addon - the packer walks the SOURCE directory, so the file
# that only exists inside the PBO is simply not in the list. It does not
# conflict, it does not warn, it does not fail a checksum. The feature stops
# existing and the PBO that lost it verifies clean.
#
# doctor.ps1's mission-drift check does not catch this. It compares timestamps,
# and it only compares them in one direction: source newer than PBO. A file
# that exists ONLY in the PBO has no source timestamp to be newer than, so the
# check has nothing to look at and passes.
#
# So this tool asks the question the other way round, per file, on content:
#
#   (a) in the PBO, NOT in source   - deployed work a repack would DESTROY.
#                                     This is the xcsv_chatter failure. It is
#                                     the only category that exits non-zero.
#   (b) in source, NOT in the PBO   - work written but never deployed. Often
#                                     deliberate (staged fixes waiting for a
#                                     restart window), so it is reported, not
#                                     failed.
#   (c) in both, content differs    - one side was edited without the other.
#                                     Direction is unknowable from content
#                                     alone, so a human reads the excerpt.
#
# LINE ENDINGS ARE NOT DRIFT
#
# The first manual pass over these pairs produced six differing files. Four of
# them were byte-for-byte identical once CR characters were dropped - a source
# tree checked out with git's autocrlf against a PBO packed from LF, or the
# reverse. Reporting those as findings buries the two that mattered under
# noise nobody will read twice. Every comparison here is therefore made three
# ways, in order: raw bytes equal (identical), equal after normalising CRLF to
# LF (reported as line-endings-only, NOT a finding), otherwise a real content
# difference. Raw-first matters because collapsing CR in a genuinely binary
# file could in principle make two different files compare equal; checking raw
# equality first means normalisation can only ever downgrade a difference that
# was already there, never invent a match.
#
# WHAT COUNTS AS "IN SOURCE"
#
# The source-side file list is exactly the list E:\ArmaTools\pbo.ps1 Pack
# would walk: everything under the tree except its own metadata files
# ($PBOPREFIX$, $PREFIX$, $PBOPROPS$.txt, pbo.properties), Thumbs.db,
# desktop.ini and anything under .git. That is deliberate. The question this
# tool answers is "what would happen if someone repacked this right now", so
# the definition of the source set has to be the packer's definition and not a
# tidier one of our own. A README in a vendored addon tree shows up under (b)
# because a repack really would put it in the PBO.
#
#   .\tools\pbo-drift-audit.ps1              readable report
#   .\tools\pbo-drift-audit.ps1 -Json        machine-readable
#   .\tools\pbo-drift-audit.ps1 -Only chat   audit only pairs matching a substring
#
# Exit code: 0 = no category (a) findings, 1 = at least one.
#
# This tool is READ ONLY. It unpacks to a scratch directory and never writes to
# a PBO, a source tree, or the server.

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Quiet,
    [string]$Only = '',
    [string]$ServerDir = 'E:\arma3server',
    [string]$RepoDir   = 'E:\ExileRepo',
    [string]$PboTool   = 'E:\ArmaTools\pbo.ps1',
    # Scratch space. On D: on purpose - a temp_dir under C:\Users once filled
    # the system drive to zero bytes with orphaned projections.
    [string]$TempRoot  = 'D:\CAGE\tmp\pbo-drift-audit',
    # Lines of unified diff shown per differing file. Enough to judge whether a
    # difference is a tuned constant or a missing function, not enough to turn
    # the report into the diff itself.
    [int]$DiffLines    = 15
)

$ErrorActionPreference = 'Continue'

<#
    The pair table.

    Discovered by unpacking every PBO under @ExileServer\addons and mpmissions
    and matching its entry paths against every directory in E:\ExileRepo. Only
    trees where EVERY PBO entry has a same-named source file are listed; a
    partial match means the directory is a different addon that happens to
    contain a config.cpp, and pairing against it would generate pure fiction.

    'origin' is not decoration. It changes how a category (c) finding should be
    read:

      ours   - written for this server. Source and PBO disagreeing means one of
               them is wrong and somebody has to decide which.
      vendor - a third-party tree cloned into Addons\. These are EXPECTED to
               differ where we have tuned them, because the clone is upstream's
               code and the PBO is upstream's code plus our edits. A (c)
               finding here is only interesting if the edit is one nobody
               remembers making. A category (a) finding here is just as
               dangerous as anywhere else.
#>
$Pairs = @(
    @{ pbo = "$ServerDir\mpmissions\Exile.Tanoa.pbo";                  src = "$RepoDir\LiveSource\mpmissions\Exile.Tanoa";                                origin = 'ours'   }
    @{ pbo = "$ServerDir\@ExileServer\addons\xcsv_chatter.pbo";        src = "$RepoDir\LiveSource\server-addons\xcsv_chatter";                            origin = 'ours'   }
    # Captured on 2026-08-11 (commit 1b524c6). It had NO source anywhere and the
    # deployed PBO was the only copy of the loot tables and CfgSettings in
    # existence. It stayed in the "no source held" list for a day after being
    # captured, which is the worst state for an audit to be in: quietly telling
    # you a gap is still open after it has been closed. Paired now so a future
    # divergence is actually reported.
    @{ pbo = "$ServerDir\@ExileServer\addons\exile_server_config.pbo"; src = "$RepoDir\LiveSource\server-addons\exile_server_config";                     origin = 'ours'   }
    @{ pbo = "$ServerDir\@ExileServer\addons\sovran_zeus.pbo";         src = "$RepoDir\original-addons\sovran_zeus";                                      origin = 'ours'   }
    @{ pbo = "$ServerDir\@ExileServer\addons\a3_exile_lootbox.pbo";    src = "$RepoDir\Addons\a3_exile_lootbox";                                          origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\a3_exile_occupation.pbo"; src = "$RepoDir\Addons\a3_exile_occupation-development\source\a3_exile_occupation"; origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\a3_dms.pbo";              src = "$RepoDir\Addons\DMS_Exile\@ExileServer\addons\a3_dms";                      origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\A3XAI.pbo";               src = "$RepoDir\Addons\A3XAI\4. SQF\Addons\A3XAI";                                 origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\a3_travellingTrader.pbo"; src = "$RepoDir\Addons\ExileTravellingTrader\source\a3_travellingTrader";          origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\BigfootsShipwrecks_Server.pbo"; src = "$RepoDir\Addons\bigfoots-shipwrecks\src\BigfootsShipwrecks_Server";   origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\ClaimVehicles_Server.pbo"; src = "$RepoDir\Addons\Claim-Vehicles\ClaimVehicles_Server";                      origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\DMD_BuildingReplace.pbo"; src = "$RepoDir\Addons\DMD_BuildingReplace\DMD_BuildingReplace";                   origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\ExileHalvPaintshop_Server.pbo"; src = "$RepoDir\Addons\HalvPaintshop-Exile\Server\ExileHalvPaintshop_Server"; origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\exile_abandon.pbo";       src = "$RepoDir\Addons\Exile_Abandon_Territory\Server\exile_abandon";              origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\FlagHack_server.pbo";     src = "$RepoDir\Addons\ExileFlagHacking\Server\FlagHack_server";                   origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\helicrash_server.pbo";    src = "$RepoDir\Addons\ExileHelicrashes\Server\helicrash_server";                  origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\PlayerMarketByCyunide.pbo"; src = "$RepoDir\Addons\PlayerMarketByCyunide\@ExileServer\addons\PlayerMarketByCyunide"; origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\revive_server.pbo";       src = "$RepoDir\Addons\ExileRevive\Server\revive_server";                          origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\safex_server.pbo";        src = "$RepoDir\Addons\ExileSafeX\Server\safex_server";                            origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\Server.pbo";              src = "$RepoDir\Addons\ExileLoadouts\Server\loadout_server";                       origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\vehicles.pbo";            src = "$RepoDir\Addons\ExilePersistentVehicles\Server\vehicles";                   origin = 'vendor' }
    @{ pbo = "$ServerDir\@ExileServer\addons\w4_lockpick.pbo";         src = "$RepoDir\Scripts\w4_lockpick\2 - Server\w4_lockpick";                       origin = 'vendor' }
)

<#
    Deployed PBOs with no source tree anywhere in E:\ExileRepo.

    Listed rather than silently skipped. "Not audited" and "audited, clean" are
    different states, and a reader who cannot tell them apart will assume the
    reassuring one. Each of these is one bad afternoon away from being the next
    xcsv_chatter, because there is nothing to compare them against at all - the
    PBO IS the only copy.
#>
$NoSource = @(
    @{ pbo = 'exile_server.pbo';              note = 'Exile 1.0.4a stock server addon. The only trees carrying these paths are copies bundled inside third-party mods (ExileReborn zombies), not our source.' }
    # exile_server_config.pbo was here until 2026-08-11. It is now captured at
    # LiveSource\server-addons\exile_server_config and is audited above.
    @{ pbo = 'GADD_TrickOrTreat_Server.pbo';  note = 'The repo holds the shipped .pbo (Addons\Trick-Or-Treat\Server), not unpacked source.' }
    @{ pbo = 'Exile.Altis.pbo';               note = 'Stock mission, not the one this server runs.' }
    @{ pbo = 'Exile.Malden.pbo';              note = 'Stock mission, not the one this server runs.' }
    @{ pbo = 'Exile.Namalsk.pbo';             note = 'Stock mission, not the one this server runs.' }
    @{ pbo = 'ExileEscape.Altis.pbo';         note = 'Stock Escape mission, not the one this server runs.' }
    @{ pbo = 'ExileEscape.Tanoa.pbo';         note = 'Stock Escape mission, not the one this server runs.' }
)

# Exactly what pbo.ps1 Pack skips. See the header note on why this list is
# copied from the packer rather than chosen independently.
$MetaFiles = @('$PBOPREFIX$', '$PREFIX$', '$PBOPROPS$.txt', 'pbo.properties', 'Thumbs.db', 'desktop.ini')

function Get-RelativeFileMap([string]$Root) {
    $map = @{}
    $r = (Get-Item -LiteralPath $Root).FullName.TrimEnd('\')
    foreach ($f in (Get-ChildItem -LiteralPath $r -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        if ($f.FullName -match '\\\.git\\') { continue }
        if ($MetaFiles -contains $f.Name)   { continue }
        $rel = $f.FullName.Substring($r.Length).TrimStart('\', '/').Replace('/', '\')
        $map[$rel.ToLower()] = $f.FullName
    }
    return $map
}

# Raw first, then CRLF-normalised. Returns 'same', 'eol' or 'differ'.
function Compare-FileContent([string]$A, [string]$B) {
    $ba = [IO.File]::ReadAllBytes($A)
    $bb = [IO.File]::ReadAllBytes($B)
    if ($ba.Length -eq $bb.Length) {
        $same = $true
        for ($i = 0; $i -lt $ba.Length; $i++) {
            if ($ba[$i] -ne $bb[$i]) { $same = $false; break }
        }
        if ($same) { return 'same' }
    }
    $na = Get-NormalisedBytes $ba
    $nb = Get-NormalisedBytes $bb
    if ($na.Length -ne $nb.Length) { return 'differ' }
    for ($i = 0; $i -lt $na.Length; $i++) {
        if ($na[$i] -ne $nb[$i]) { return 'differ' }
    }
    return 'eol'
}

# Drop CR that is immediately followed by LF, then drop trailing LF.
#
# A lone CR is left alone: in a binary file it is data, and in a text file it is
# a Mac-classic line ending that really is a difference.
#
# The trailing-newline trim is here because of a concrete false positive.
# ExileServer_BigfootsShipwrecks_addMoneyToCrateCommand.sqf is 701 bytes in the
# repo and 699 in the PBO, and the entire difference is that the source file
# ends "};\r\n" and the packed one ends "};". That is a text editor's habit,
# not an edit, and it was landing in category (c) next to a real finding in the
# same addon - which is exactly the burying-the-signal problem this tool exists
# to avoid. SQF does not care whether its last line is terminated.
function Get-NormalisedBytes($Bytes) {
    $outB = New-Object 'System.Collections.Generic.List[byte]'
    $n = $Bytes.Length
    for ($i = 0; $i -lt $n; $i++) {
        if ($Bytes[$i] -eq 13 -and ($i + 1) -lt $n -and $Bytes[$i + 1] -eq 10) { continue }
        $outB.Add($Bytes[$i])
    }
    while ($outB.Count -gt 0 -and $outB[$outB.Count - 1] -eq 10) { $outB.RemoveAt($outB.Count - 1) }
    return $outB.ToArray()
}

# git is used purely as a diff engine here. --no-index keeps it away from any
# repository, and --ignore-cr-at-eol means the excerpt shows the same thing the
# byte comparison above decided rather than a wall of ^M.
#
# Note --ignore-cr-at-eol, NOT --strip-trailing-cr: the latter is GNU diff's
# spelling and git rejects it with "unknown option", which git reports on
# STDERR while exiting 129 and printing nothing to STDOUT. The first version of
# this function swallowed that and reported "no diff available - likely a
# binary file" for every single differing file, which is a plausible-looking
# answer and completely wrong.
#
# --text forces a diff even where git's heuristic calls a file binary. Exile
# SQF is text, but a stray NUL or a non-UTF8 byte in a config makes git give up
# and print "Binary files differ", which is exactly the case a human most needs
# to see the content of.
function Get-DiffExcerpt([string]$PboFile, [string]$SrcFile, [int]$Max) {
    $lines = @()
    try {
        # 2>&1 rather than 2>$null: if git ever refuses again, the refusal
        # should end up in the report instead of masquerading as "no changes".
        $raw = & git diff --no-index --no-color --ignore-cr-at-eol --text -U2 -- $SrcFile $PboFile 2>&1
        if ($null -ne $raw) {
            foreach ($l in $raw) {
                # git's core.autocrlf warning fires once per file per side and
                # says nothing about the diff. Dropping it here rather than
                # setting -c core.autocrlf=false so the tool never changes git
                # config, even transiently, on a machine it does not own.
                if ($l -match '^warning: .*(LF will be replaced by CRLF|CRLF will be replaced by LF)') { continue }
                if ($l -match '^(diff --git|index |--- |\+\+\+ )') { continue }
                $lines += $l
                if ($lines.Count -ge $Max) { $lines += '    ... (truncated)'; break }
            }
        }
    } catch { }
    if (-not $lines.Count) { $lines = @('    (git produced no output for this pair - inspect the two files by hand)') }
    return $lines
}

# --- run ------------------------------------------------------------------
if (-not (Test-Path $PboTool)) {
    Write-Host "pbo tool not found at $PboTool" -ForegroundColor Red
    exit 1
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$work  = Join-Path $TempRoot $stamp
New-Item -ItemType Directory -Path $work -Force | Out-Null

$report = @()

foreach ($pair in $Pairs) {
    $name = Split-Path $pair.pbo -Leaf
    if ($Only -and ($name -notlike "*$Only*")) { continue }

    $entry = [ordered]@{
        pbo = $pair.pbo; source = $pair.src; origin = $pair.origin
        state = 'ok'; note = ''
        only_in_pbo = @(); only_in_source = @(); differing = @()
        eol_only = 0; identical = 0
    }

    if (-not (Test-Path $pair.pbo)) {
        $entry.state = 'missing-pbo'; $entry.note = 'PBO not found'
        $report += [pscustomobject]$entry; continue
    }
    if (-not (Test-Path $pair.src)) {
        $entry.state = 'missing-source'; $entry.note = 'source tree not found'
        $report += [pscustomobject]$entry; continue
    }

    $dest = Join-Path $work ($name -replace '[^A-Za-z0-9_.-]', '_')
    # pbo.ps1 sets $ErrorActionPreference = 'Stop' internally and THROWS on a
    # compressed entry, so the failure arrives as a terminating error rather
    # than an exit code. Catch it; a script's $LASTEXITCODE is not the signal.
    $unpackOut = ''
    $unpackErr = ''
    try {
        $unpackOut = & $PboTool Unpack $pair.pbo -Out $dest 2>&1
    } catch {
        $unpackErr = $_.Exception.Message
    }
    if ($unpackErr -or -not (Test-Path $dest)) {
        $txt = $unpackErr + "`n" + ($unpackOut | Out-String)
        if ($txt -match 'LZSS-compressed') {
            $entry.state = 'compressed'
            $entry.note  = 'LZSS-compressed; pbo.ps1 refuses to extract rather than emit unverified output. Not audited.'
        } else {
            $entry.state = 'unpack-failed'
            $entry.note  = ($txt -split "`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
        }
        $report += [pscustomobject]$entry; continue
    }

    $pboMap = Get-RelativeFileMap $dest
    $srcMap = Get-RelativeFileMap $pair.src

    foreach ($k in $pboMap.Keys) {
        if (-not $srcMap.ContainsKey($k)) {
            $entry.only_in_pbo += $k
        }
    }
    foreach ($k in $srcMap.Keys) {
        if (-not $pboMap.ContainsKey($k)) { $entry.only_in_source += $k }
    }
    foreach ($k in $pboMap.Keys) {
        if (-not $srcMap.ContainsKey($k)) { continue }
        $verdict = Compare-FileContent $pboMap[$k] $srcMap[$k]
        if ($verdict -eq 'same') {
            $entry.identical = $entry.identical + 1
        } elseif ($verdict -eq 'eol') {
            $entry.eol_only = $entry.eol_only + 1
        } else {
            $entry.differing += [pscustomobject]@{
                path = $k
                pbo_bytes = (Get-Item $pboMap[$k]).Length
                source_bytes = (Get-Item $srcMap[$k]).Length
                diff = (Get-DiffExcerpt $pboMap[$k] $srcMap[$k] $DiffLines)
            }
        }
    }

    $entry.only_in_pbo    = @($entry.only_in_pbo    | Sort-Object)
    $entry.only_in_source = @($entry.only_in_source | Sort-Object)
    if ($entry.only_in_pbo.Count) { $entry.state = 'LOST-WORK-RISK' }
    elseif ($entry.differing.Count) { $entry.state = 'differs' }
    elseif ($entry.only_in_source.Count) { $entry.state = 'undeployed' }

    $report += [pscustomobject]$entry
}

$catA = @($report | Where-Object { $_.only_in_pbo.Count -gt 0 })
$catC = @($report | Where-Object { $_.differing.Count -gt 0 })

if ($Json) {
    [pscustomobject]@{
        generated = (Get-Date -Format 's')
        workdir   = $work
        pairs     = $report
        no_source = $NoSource
    } | ConvertTo-Json -Depth 8
} else {
    Write-Host ""
    Write-Host "  PBO DRIFT AUDIT   $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Cyan
    Write-Host "  scratch: $work"
    Write-Host ""

    foreach ($r in $report) {
        $nm = Split-Path $r.pbo -Leaf
        $col = 'Green'
        if ($r.state -eq 'LOST-WORK-RISK') { $col = 'Red' }
        elseif ($r.state -eq 'differs')    { $col = 'Yellow' }
        elseif ($r.state -eq 'undeployed') { $col = 'Yellow' }
        elseif ($r.state -ne 'ok')         { $col = 'DarkGray' }

        if ($Quiet -and ($r.state -eq 'ok')) { continue }

        Write-Host ("  {0,-34} {1,-16} [{2}]" -f $nm, $r.state, $r.origin) -ForegroundColor $col
        if ($r.note) { Write-Host ("        " + $r.note) -ForegroundColor DarkGray }
        if ($r.state -eq 'compressed' -or $r.state -eq 'unpack-failed' -or $r.state -like 'missing*') { continue }

        Write-Host ("        source: " + $r.source) -ForegroundColor DarkGray
        Write-Host ("        {0} identical, {1} line-endings-only (ignored)" -f $r.identical, $r.eol_only) -ForegroundColor DarkGray

        if ($r.only_in_pbo.Count) {
            Write-Host ("    (a) IN PBO, NOT IN SOURCE - a repack would DELETE these:") -ForegroundColor Red
            foreach ($f in $r.only_in_pbo) { Write-Host ("          " + $f) -ForegroundColor Red }
        }
        if ($r.only_in_source.Count) {
            Write-Host ("    (b) in source, not deployed ({0}):" -f $r.only_in_source.Count) -ForegroundColor Yellow
            foreach ($f in $r.only_in_source) { Write-Host ("          " + $f) -ForegroundColor DarkYellow }
        }
        if ($r.differing.Count) {
            Write-Host ("    (c) content differs ({0}):" -f $r.differing.Count) -ForegroundColor Yellow
            foreach ($d in $r.differing) {
                Write-Host ("          {0}   pbo {1} bytes / source {2} bytes" -f $d.path, $d.pbo_bytes, $d.source_bytes) -ForegroundColor Yellow
                foreach ($l in $d.diff) { Write-Host ("            " + $l) -ForegroundColor DarkGray }
            }
        }
        Write-Host ""
    }

    Write-Host "  --- not audited: no source held ---" -ForegroundColor DarkGray
    foreach ($n in $NoSource) {
        Write-Host ("  {0,-34} {1}" -f $n.pbo, $n.note) -ForegroundColor DarkGray
    }
    Write-Host ""
    if ($catA.Count) {
        Write-Host ("  {0} PBO(s) contain deployed files with no source. A repack destroys them." -f $catA.Count) -ForegroundColor Red
    } else {
        Write-Host "  No category (a) findings: every deployed FILE has a source counterpart." -ForegroundColor Green
    }

    # Say nothing reassuring while category (c) is unjudged.
    #
    # This block exists because the first run of this tool ended on a green
    # "no category (a) findings" and very nearly closed the investigation there.
    # It was true, and it was the wrong headline.
    #
    # Category (a) is a FILE present in the PBO and missing from source - the
    # exact shape of the xcsv_chatter case this tool was built for. But
    # file-level presence is not the risk. The risk is a REGRESSION ON DEPLOY,
    # and that happens just as completely when the file exists on both sides and
    # the deployed copy is the one carrying the fix.
    #
    # That is not hypothetical. The same run listed five vendor addons under
    # category (c) whose deployed PBO held changes their source tree did not:
    # sovran_zeus (the admin whitelist is populated in the PBO and commented out
    # in source, so a repack grants Zeus to nobody), BigfootsShipwrecks (a dated
    # XCSV fix for Tanoa, with source still holding stock Altis coordinates),
    # vehicles (spawn counts tuned down by two thirds), a3_travellingTrader and
    # exile_abandon. All five were reported without judgement, under a green
    # summary line.
    #
    # Until this tool determines direction per file, the honest summary is that
    # content differences are unjudged and someone has to look at them.
    if ($catC.Count) {
        Write-Host ""
        Write-Host ("  {0} PBO(s) differ in CONTENT and this tool has not judged which side is ahead." -f $catC.Count) -ForegroundColor Yellow
        Write-Host "  Read every one before repacking any of them. Where the DEPLOYED copy is the" -ForegroundColor Yellow
        Write-Host "  one carrying a fix, a repack from source reverts it silently - which is the" -ForegroundColor Yellow
        Write-Host "  same outcome as category (a) and is not covered by the line above." -ForegroundColor Yellow
        Write-Host "  See D:\XCSV\receipts\PBO-DRIFT-001-20260810.md for five real instances." -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($catA.Count) { exit 1 } else { exit 0 }
