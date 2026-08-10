# xcsv-wiring-audit.ps1 - static cross-checks for wiring that fails SILENTLY.
#
# Keep this file pure ASCII. PowerShell 5.1 reads .ps1 as ANSI without a BOM.
#
# WHY THIS EXISTS
# ===============
# On 2026-08-10 a forensic pass over the six custom XM8 apps found twelve
# defects. NINE of them were invisible rather than hard: nothing crashed, the
# server booted clean, doctor passed 26 checks, and the features simply did not
# work.
#
# The worst was one missing word. Exile's dispatcher derives its handler name
# mechanically:
#
#     _functionName = format ["ExileServer_%1_network_%2", _module, _message];
#
# CfgNetworkMessages declared `xcsvPolicyBuyRequest` in module `system_xcsv`, so
# the only name it would ever look up was
# ExileServer_system_xcsv_network_xcsvPolicyBuyRequest. The addon aliased
# ExileServer_system_xcsv_network_policyBuyRequest - the message name without its
# own prefix. Every purchase threw inside the dispatcher, which caught it and
# logged server-side only. The Insurance feature was decoration from the day it
# shipped, and twenty server RPTs contain zero purchases and zero refusals.
#
# A machine can check that in a second. A human reading the line agrees with it,
# because the line looks exactly like what it is supposed to be.
#
# WHAT IT CHECKS
# ==============
#   network-aliases   every CfgNetworkMessages class has a matching handler
#   xm8-controlids    CfgXM8 controlID agrees with the slide class idc
#   extdb-output      DATETIME/text columns are tagged -STRING in sql_custom
#   idc-collisions    no two controls in the mission share an idc
#   text-escaping     player-controlled text reaching parseText is escaped
#
# Each check exists because the corresponding bug actually happened here.
#
#   .\tools\xcsv-wiring-audit.ps1
#   .\tools\xcsv-wiring-audit.ps1 -Json
#
# Exit code: 0 = clean, 1 = at least one FAIL, 2 = only WARNs.

[CmdletBinding()]
param(
    [switch]$Json,
    [string]$MissionSrc = 'E:\ExileRepo\LiveSource\mpmissions\Exile.Tanoa',
    [string]$AddonSrc   = 'E:\ExileRepo\LiveSource\server-addons',
    [string]$SqlCustom  = 'E:\arma3server\@ExileServer\sql_custom\exile.ini',
    [string]$SqlSchema  = 'E:\arma3server\sql\exile.sql'
)

$ErrorActionPreference = 'Continue'
$results = @()

function Add-Result([string]$Name, [string]$Status, [string]$Detail, [string]$Why) {
    $script:results += [pscustomobject]@{
        check = $Name; status = $Status; detail = $Detail; why = $Why
    }
}
function Pass($n, $d)     { Add-Result $n 'PASS' $d '' }
function Fail($n, $d, $w) { Add-Result $n 'FAIL' $d $w }
function Warn($n, $d, $w) { Add-Result $n 'WARN' $d $w }

$missionCfg = Join-Path $MissionSrc 'config.cpp'
if (-not (Test-Path $missionCfg)) {
    Fail 'mission-config' "no config.cpp at $missionCfg" 'Nothing can be checked without it.'
    $results | Format-Table -Auto
    exit 1
}
$cfgText = Get-Content $missionCfg -Raw

# --- 1. network message handlers ------------------------------------------
# The check that would have caught the Insurance bug.
#
# Only OUR modules are checked. Exile's own messages are handled inside
# exile_server.pbo, which is compressed and not readable here, so asserting on
# them would produce confident nonsense. A module is ours if any of our addon
# sources aliases anything for it.
$declared = @()
foreach ($m in [regex]::Matches($cfgText, '(?m)^\s*class\s+(\w+)\s*\{\s*module\s*=\s*"([^"]+)"')) {
    $declared += [pscustomobject]@{
        message = $m.Groups[1].Value
        module  = $m.Groups[2].Value
    }
}

# BOTH sides are scanned, because a message travels one way or the other and the
# handler lives at the far end. xcsvInspectResponse is declared in the same
# CfgNetworkMessages block as xcsvInspectRequest, but the request is handled by
# ExileServer_... and the response by ExileClient_.... An earlier version of this
# check only looked for server handlers and duly reported the response as a
# missing handler - a false positive, and the fastest way to make a checker
# worthless is to have it cry wolf.
$aliasText = ''
foreach ($root in @($AddonSrc, $MissionSrc)) {
    if (-not (Test-Path $root)) { continue }
    foreach ($f in Get-ChildItem $root -Recurse -Include *.sqf -ErrorAction SilentlyContinue) {
        $aliasText += (Get-Content $f.FullName -Raw)
        $aliasText += "`n"
    }
}

# Which modules do we actually implement? Derived, not listed - a hardcoded list
# is the very failure mode this whole file is about.
$ourModules = @{}
foreach ($m in [regex]::Matches($aliasText, 'Exile(?:Server|Client)_(\w+?)_network_(\w+)\s*=')) {
    $ourModules[$m.Groups[1].Value] = $true
}

$missing = @()
$checked = 0
foreach ($d in $declared) {
    if (-not $ourModules.ContainsKey($d.module)) { continue }
    $checked++
    $srv = "ExileServer_$($d.module)_network_$($d.message)"
    $cli = "ExileClient_$($d.module)_network_$($d.message)"
    $hasSrv = ($aliasText -match [regex]::Escape($srv))
    $hasCli = ($aliasText -match [regex]::Escape($cli))
    if ((-not $hasSrv) -and (-not $hasCli)) {
        $missing += ("{0} (no server or client handler)" -f $d.message)
    }
}

if ($checked -eq 0) {
    Warn 'network-aliases' 'no messages in modules we implement' 'Nothing to check, or the addon source moved.'
} elseif ($missing.Count -gt 0) {
    Fail 'network-aliases' ("no handler for: " + ($missing -join ', ')) `
         ('The dispatcher builds the name as ExileServer_<module>_network_<message> and looks it up in missionNamespace. ' +
          'A name that does not match exactly throws "Invalid function call!" inside the dispatcher, which catches and logs it server-side - ' +
          'so the feature is silently dead and the player sees nothing at all. This is exactly how the Insurance app shipped broken.')
} else {
    Pass 'network-aliases' "$checked message(s) in our modules all have handlers"
}

# --- 2. CfgXM8 controlID vs the slide class idc ----------------------------
# Two sources of truth for the same number. Drift is silent: the app title
# changes and the page stays blank, with no error anywhere.
$xm8 = @()
$xm8Block = [regex]::Match($cfgText, '(?s)class\s+CfgXM8\s*\{(.+?)\n\};')
if ($xm8Block.Success) {
    foreach ($m in [regex]::Matches($xm8Block.Groups[1].Value,
        '(?s)class\s+(\w+)\s*\{(.*?)\}')) {
        # The slide class name is NOT in the CfgXM8 entry - it lives on the App
        # button class that the entry names through appID, and that class is
        # called XM8_<appID>_Button rather than <appID>. So the join is
        #   CfgXM8 >> <app> >> appID  ->  class XM8_<appID>_Button >> resource
        #   ->  class <resource> >> idc
        # and it has to be walked in that order. An earlier version looked for
        # `resource` directly inside the CfgXM8 entry, found none, and reported
        # "no entries" - a checker silently checking nothing, which is worse than
        # no checker at all because it reads as a pass.
        $body = $m.Groups[2].Value
        $cid  = [regex]::Match($body, 'controlID\s*=\s*(\d+)')
        $app  = [regex]::Match($body, 'appID\s*=\s*"([^"]+)"')
        if ($cid.Success -and $app.Success) {
            $btnCls = "XM8_" + $app.Groups[1].Value + "_Button"
            $appCls = [regex]::Match($cfgText, ('(?s)class\s+' + [regex]::Escape($btnCls) + '\s*:[^\{]*\{(.*?)\n\s*\};'))
            if ($appCls.Success) {
                $res = [regex]::Match($appCls.Groups[1].Value, 'resource\s*=\s*"([^"]+)"')
                if ($res.Success) {
                    $xm8 += [pscustomobject]@{
                        name      = $m.Groups[1].Value
                        controlID = [int]$cid.Groups[1].Value
                        resource  = $res.Groups[1].Value
                    }
                }
            }
        }
    }
}

$mismatch = @()
foreach ($a in $xm8) {
    $slide = [regex]::Match($cfgText, ('(?s)class\s+' + [regex]::Escape($a.resource) + '\s*:[^\{]*\{(.*?)\n\};'))
    if (-not $slide.Success) { continue }
    $idc = [regex]::Match($slide.Groups[1].Value, 'idc\s*=\s*(\d+)')
    if ($idc.Success -and ([int]$idc.Groups[1].Value) -ne $a.controlID) {
        $mismatch += ("{0}: CfgXM8 says {1}, {2} has idc {3}" -f $a.name, $a.controlID, $a.resource, $idc.Groups[1].Value)
    }
}
if ($xm8.Count -eq 0) {
    Warn 'xm8-controlids' 'no CfgXM8 entries with a resource found' 'Parser may need updating, or the block moved.'
} elseif ($mismatch.Count -gt 0) {
    Fail 'xm8-controlids' ($mismatch -join '; ') `
         'ExileClient_gui_xm8_slide resolves the slide through CfgXM8 >> controlID. If that does not match the slide class idc, displayCtrl returns null, the switch silently does nothing, and the app opens as a titled blank page.'
} else {
    Pass 'xm8-controlids' "$($xm8.Count) app(s), controlID matches slide idc"
}

# --- 3. extDB sql_custom OUTPUT typing -------------------------------------
# A DATETIME renders with a space in it. Untyped, and therefore unquoted, it
# cannot survive being read back as an SQF array - the row arrives malformed and
# the app shows nothing for a player who plainly exists.
#
# Exile's own loadTerritory tags last_paid_at as 12-STRING. That is the house
# rule, written down in the file being checked.
if ((Test-Path $SqlCustom) -and (Test-Path $SqlSchema)) {
    $schema = Get-Content $SqlSchema -Raw
    # Column names whose declared type carries a space in its rendered value.
    $textish = @{}
    foreach ($m in [regex]::Matches($schema, '(?im)^\s*`?(\w+)`?\s+(datetime|timestamp|date|char|varchar|text|tinytext|mediumtext|longtext)')) {
        $textish[$m.Groups[1].Value.ToLower()] = $m.Groups[2].Value
    }

    # SCOPE: our own queries only, and the reason is not modesty.
    #
    # The first run of this check reported 20 "failures", every one of them in a
    # STOCK Exile query - loadVehicle, loadTerritory, loadContainer - that
    # demonstrably works in production every day. The heuristic was wrong, and
    # instructively so.
    #
    # Columns like `hitpoints`, `cargo_items`, `positionArr`, `build_rights` and
    # `moderators` are TEXT columns whose contents are a serialised SQF array,
    # e.g. [["HitBody",0.5],...]. Leaving those untyped is not an oversight, it
    # is the entire point: extDB emits them raw and the engine parses them back
    # into real arrays. Tagging them -STRING would BREAK them.
    #
    # And the `deleted_at` DATETIME columns are safe because every one of those
    # queries carries `deleted_at IS NULL` in its WHERE clause, so the value is
    # always NULL and never renders a space.
    #
    # The rule "a DATETIME needs -STRING" therefore holds only when the value can
    # actually be non-null AND is consumed as text - which is the case for our
    # xcsvInspectorLookup first_connect_at/last_connect_at, and was a real bug.
    # A checker that cannot tell those apart is a checker nobody runs.
    $iniLines = Get-Content $SqlCustom
    $bad = @()
    $skippedStock = 0
    $section = ''
    $selectCols = @()
    for ($i = 0; $i -lt $iniLines.Count; $i++) {
        $line = $iniLines[$i]
        $s = [regex]::Match($line, '^\s*\[(\w+)\]')
        if ($s.Success) { $section = $s.Groups[1].Value; $selectCols = @(); continue }

        $q = [regex]::Match($line, '(?i)^\s*SQL\d+_\d+\s*=\s*SELECT\s+(.+?)\s+FROM\s')
        if ($q.Success) {
            $selectCols = @()
            foreach ($c in ($q.Groups[1].Value -split ',')) {
                $c = $c.Trim()
                # Strip an alias and any function wrapper; we only want a bare column.
                $c = ($c -replace '\s+AS\s+\w+$', '')
                if ($c -match '^\(?\s*(\w+)\s*\)?$') { $selectCols += $Matches[1] } else { $selectCols += '' }
            }
            continue
        }

        $o = [regex]::Match($line, '(?i)^\s*OUTPUT\s*=\s*(.+)$')
        if ($o.Success -and $selectCols.Count -gt 0) {
            if ($section -notmatch '^xcsv') { $skippedStock++; continue }
            $specs = ($o.Groups[1].Value -split ',')
            for ($k = 0; $k -lt $specs.Count; $k++) {
                if ($k -ge $selectCols.Count) { break }
                $col = $selectCols[$k]
                if ($col -eq '') { continue }
                if (-not $textish.ContainsKey($col.ToLower())) { continue }
                if ($specs[$k] -notmatch 'STRING') {
                    $bad += ("[{0}] column {1} ({2}) at OUTPUT position {3} is not -STRING" -f `
                             $section, $col, $textish[$col.ToLower()], ($k + 1))
                }
            }
        }
    }

    if ($bad.Count -gt 0) {
        Fail 'extdb-output' ($bad -join '; ') `
             'The value contains a space, so unquoted it cannot be parsed back as an SQF array. The row arrives malformed and the app renders nothing, with no error naming the cause. Exile tags last_paid_at as 12-STRING in this same file.'
    } else {
        Pass 'extdb-output' "our queries type their text/datetime columns correctly ($skippedStock stock quer(ies) not audited - see comment)"
    }
} else {
    Warn 'extdb-output' 'sql_custom ini or schema not found' 'Cannot check OUTPUT typing.'
}

# --- 4. idc collisions ------------------------------------------------------
# Two apps once shared 71820 and both wrote control 71821.
$idcs = @{}
foreach ($m in [regex]::Matches($cfgText, 'idc\s*=\s*(\d+)\s*;')) {
    $v = [int]$m.Groups[1].Value
    if ($v -le 0) { continue }
    if ($idcs.ContainsKey($v)) { $idcs[$v] = $idcs[$v] + 1 } else { $idcs[$v] = 1 }
}
$dupes = @()
foreach ($k in $idcs.Keys) { if ($idcs[$k] -gt 1) { $dupes += $k } }
if ($dupes.Count -gt 0) {
    Fail 'idc-collisions' ("shared idc: " + (($dupes | Sort-Object) -join ', ')) `
         'Two controls with one id means displayCtrl finds whichever the engine reached first. Prices and Standing both claimed 71820 and both wrote 71821.'
} else {
    Pass 'idc-collisions' "$($idcs.Count) distinct idc(s), no collisions"
}

# --- 5. unescaped player text in structured text ---------------------------
# Structured text is XML-ish. One player with "&" in their Steam name corrupted
# the entire scoreboard for everyone who opened it.
$xcsvDir = Join-Path $MissionSrc 'xcsv'
if (Test-Path $xcsvDir) {
    $suspect = @()
    foreach ($f in Get-ChildItem $xcsvDir -Filter *.sqf) {
        $t = Get-Content $f.FullName -Raw
        if ($t -notmatch 'parseText') { continue }
        # A file that formats a _name/_playerName into markup should escape it.
        $usesName = ($t -match '_name|_playerName|_shown')
        $escapes  = ($t -match 'XCSV_fnc_esc')
        if ($usesName -and (-not $escapes)) { $suspect += $f.Name }
    }
    if ($suspect.Count -gt 0) {
        Warn 'text-escaping' ("parseText with a name and no escape: " + ($suspect -join ', ')) `
             'Verify by hand. A player name reaching parseText unescaped lets one Steam name containing "&" or "<" corrupt the markup of the whole control, for every player who opens it.'
    } else {
        Pass 'text-escaping' 'every app rendering a name calls XCSV_fnc_esc'
    }
} else {
    Warn 'text-escaping' "no xcsv directory at $xcsvDir" 'Cannot check.'
}

# --- report -----------------------------------------------------------------
if ($Json) {
    $results | ConvertTo-Json -Depth 4
} else {
    Write-Output ''
    foreach ($r in $results) {
        Write-Output ("  {0,-5} {1,-18} {2}" -f $r.status, $r.check, $r.detail)
        if ($r.why -ne '') { Write-Output ("        -> " + $r.why) }
    }
    $p = @($results | Where-Object { $_.status -eq 'PASS' }).Count
    $w = @($results | Where-Object { $_.status -eq 'WARN' }).Count
    $f = @($results | Where-Object { $_.status -eq 'FAIL' }).Count
    Write-Output ''
    Write-Output ("  {0} passed, {1} warned, {2} failed" -f $p, $w, $f)
    Write-Output ''
}

$failCount = @($results | Where-Object { $_.status -eq 'FAIL' }).Count
$warnCount = @($results | Where-Object { $_.status -eq 'WARN' }).Count
if ($failCount -gt 0) { exit 1 }
if ($warnCount -gt 0) { exit 2 }
exit 0
