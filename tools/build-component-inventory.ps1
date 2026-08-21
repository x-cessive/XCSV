param(
    [string] $Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string] $OrchRoot = 'D:\XCSV_ORCH'
)

$ErrorActionPreference = 'Stop'

function Get-Rel([string] $Base, [string] $Path) {
    $baseFull = [IO.Path]::GetFullPath($Base).TrimEnd('\') + '\'
    $pathFull = [IO.Path]::GetFullPath($Path)
    return $pathFull.Substring($baseFull.Length).Replace('\', '/')
}

function Get-Slug([string] $Text) {
    $slug = ($Text -replace '[^A-Za-z0-9]+', '-').Trim('-').ToUpperInvariant()
    if ([string]::IsNullOrWhiteSpace($slug)) { return 'ROOT' }
    return $slug
}

function New-Evidence(
    [Nullable[bool]] $CataloguePresent,
    [Nullable[bool]] $SourceWired,
    [Nullable[bool]] $PackedArtifactPresent,
    [Nullable[bool]] $DeployedPresent,
    [Nullable[bool]] $BootEvidence,
    [Nullable[bool]] $PlayerRuntimeEvidence,
    [string[]] $Detail
) {
    [pscustomobject][ordered]@{
        catalogue_present = $CataloguePresent
        source_wired = $SourceWired
        packed_artifact_present = $PackedArtifactPresent
        deployed_present = $DeployedPresent
        boot_evidence = $BootEvidence
        player_runtime_evidence = $PlayerRuntimeEvidence
        detail = @($Detail)
    }
}

function New-Component(
    [string] $Id,
    [string] $Name,
    [string] $Family,
    [string] $Kind,
    [string] $Repo,
    [string] $Path,
    [string] $Ownership,
    [string] $Authority,
    [object] $Evidence,
    [string] $Action,
    [string] $Status = 'UNKNOWN',
    [string[]] $LiveWiring = @(),
    [string[]] $Startup = @(),
    [string[]] $CustomCode = @(),
    [string[]] $Network = @(),
    [string[]] $Xm8 = @(),
    [string[]] $Economy = @(),
    [string[]] $Db = @(),
    [string[]] $Be = @(),
    [string[]] $Persistence = @(),
    [string[]] $Safezone = @(),
    [string[]] $Schedulers = @(),
    [string[]] $Performance = @(),
    [string[]] $Overlap = @(),
    [string[]] $Tests = @(),
    [string[]] $Docs = @(),
    [string] $Confidence = 'LOW',
    [string] $Staleness = 'UNKNOWN',
    [string] $Verdict = $Action,
    [string[]] $Notes = @()
) {
    [pscustomobject][ordered]@{
        component_id = $Id
        name = $Name
        family = $Family
        kind = $Kind
        repo = $Repo
        canonical_path = $Path
        upstream_origin = $null
        license = $null
        ownership = $Ownership
        status = $Status
        runtime_authority = $Authority
        live_wiring = @($LiveWiring)
        packed_artifact = $null
        startup_hook = @($Startup)
        custom_code_hooks = @($CustomCode)
        network_messages = @($Network)
        xm8_registration = @($Xm8)
        trader_economy_hooks = @($Economy)
        database_schema_queries = @($Db)
        battleye_requirements = @($Be)
        persistence_impact = @($Persistence)
        security_safezone_impact = @($Safezone)
        background_loops_schedulers = @($Schedulers)
        performance_risks = @($Performance)
        overlap_conflicts = @($Overlap)
        tests_evidence = @($Tests)
        docs = @($Docs)
        evidence = $Evidence
        confidence = $Confidence
        staleness = $Staleness
        refactor_action = $Action
        rollback = @()
        last_verified = '2026-08-21'
        verdict = $Verdict
        notes = @($Notes)
    }
}

function Get-Family([string] $Name, [string] $Path) {
    $s = ($Name + ' ' + $Path).ToLowerInvariant()
    if ($s -match 'a3xai|dms|occupation|fums|vcom|sarge|vemf|zcp|zombie|ai') { return 'AI / missions / HC' }
    if ($s -match 'vehicle|avs|vps|garage|claim|paint|salvage|drone|uav|crash') { return 'Vehicles' }
    if ($s -match 'territory|flag|build|lockpick|base|floor|floating|construction') { return 'Territory / building / raiding' }
    if ($s -match 'market|scratch|trader|safex|loadout|bounty|economy|policy') { return 'Economy / traders / storage' }
    if ($s -match 'xm8|hud|status|spawn|ui|census|scoreboard|standing|notes|welcome|teleport|owner') { return 'XM8 / UI / HUD' }
    if ($s -match 'cruise|holster|moaning|reload|safezone|scavenge|fishing|missile|warning') { return 'QoL / player events' }
    if ($s -match 'loot|shipwreck|helicrash|trick|blowout|anomaly|survival|farming|plant') { return 'Loot / survival / events' }
    if ($s -match 'mission\.sqm|object|eden|cmap|buildingreplace|r3f|prison|map') { return 'Map / Eden / static objects' }
    if ($s -match 'server|network|database|extdb|sql|battleye|config|chatter') { return 'Server addons / network / database' }
    if ($s -match 'guard|rcon|metrics|console|restart|doctor|deploy') { return 'GUARD / operations' }
    if ($s -match 'orch|gauntlet|worker|hermes|integrity|controller') { return 'ORCH / AI workforce' }
    return 'Unclassified inventory'
}

function Test-SourceReference([string] $Name) {
    $mission = Join-Path $Root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    if (!(Test-Path $mission)) { return $false }
    $needle = [regex]::Escape($Name)
    $hits = @(rg -i -n $needle $mission 2>$null)
    return ($hits.Count -gt 0)
}

function Test-DatabaseSurface([string] $Path) {
    $rel = $Path.Replace('\', '/')
    $file = [IO.Path]::GetFileName($rel)
    if ($file -match '(?i)\.sql$') { return $true }
    if ($rel -match '(?i)(^|/)(extdb|extdb2|extdb3)(/|$)') { return $true }
    if ($rel -match '(?i)(^|/)(database|databases|sql_custom|sql_custom_v2)(/|$)') { return $true }
    if ($file -match '(?i)(exile|avs|safex|scratchie|playermarket|virtualgarage|publicvg|barter|lockpick|vehiclecustoms|zombiekill|mostwanted).*\.ini$') { return $true }
    if ($file -match '(?i)^Exile(Server|Client)_.*_database_.*\.sqf$') { return $true }
    if ($file -match '(?i)^.*_system_database_.*\.sqf$') { return $true }
    return $false
}

function Test-XcsvAddonsRuntimeSurface([IO.FileSystemInfo] $Item) {
    if (-not $Item.PSIsContainer) { return $false }
    if ($Item.Name -in @('.git', '.agents', 'mission')) { return $false }
    if (Test-Path -LiteralPath (Join-Path $Item.FullName 'config.cpp')) { return $true }
    if (Test-Path -LiteralPath (Join-Path $Item.FullName '$PBOPREFIX$')) { return $true }
    return $false
}

function Get-ConcreteWiringEvidence([string] $RelPath, [string] $Kind) {
    $rel = $RelPath.Replace('/', '\')
    $missionRoot = Join-Path $Root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    $entryNames = @('config.cpp', 'description.ext', 'mission.sqm', 'init.sqf', 'initServer.sqf', 'initPlayerLocal.sqf')
    $fileName = [IO.Path]::GetFileName($rel)
    if ($RelPath -like 'catalogue/LiveSource/mpmissions/Exile.Tanoa/*' -and $entryNames -contains $fileName) {
        return @("Concrete mission entrypoint/config file: $RelPath.")
    }

    if ($RelPath -like 'catalogue/LiveSource/server-addons/*') {
        $abs = Join-Path $Root $RelPath
        $config = Join-Path $abs 'config.cpp'
        if (Test-Path -LiteralPath $config) {
            $text = Get-Content -Raw -LiteralPath $config
            if ($text -match '(?i)(preInit|postInit|CfgFunctions|CfgPatches)') {
                return @("Server addon config.cpp contains CfgPatches/CfgFunctions/preInit/postInit evidence.")
            }
        }
    }

    if ($RelPath -like 'addons/mission/xcsv/*.sqf') {
        $liveRel = 'xcsv\' + [IO.Path]::GetFileName($RelPath)
        $init = Join-Path $missionRoot 'initPlayerLocal.sqf'
        if (Test-Path -LiteralPath $init) {
            $escaped = [regex]::Escape($liveRel)
            if ((Get-Content -Raw -LiteralPath $init) -match $escaped) {
                return @("LiveSource initPlayerLocal.sqf explicitly loads $liveRel.")
            }
        }
    }

    if ($RelPath -like 'catalogue/LiveSource/mpmissions/Exile.Tanoa/*') {
        $target = $RelPath.Substring('catalogue/LiveSource/mpmissions/Exile.Tanoa/'.Length).Replace('/', '\')
        foreach ($entry in @('config.cpp', 'description.ext', 'init.sqf', 'initServer.sqf', 'initPlayerLocal.sqf')) {
            $entryPath = Join-Path $missionRoot $entry
            if (Test-Path -LiteralPath $entryPath) {
                $escaped = [regex]::Escape($target)
                if ((Get-Content -Raw -LiteralPath $entryPath) -match $escaped) {
                    return @("$entry explicitly references $target.")
                }
            }
        }
    }

    return @()
}

$components = New-Object System.Collections.Generic.List[object]

function Add-TopLevel([string] $BaseRel, [string] $Repo, [string] $Prefix, [string] $Kind, [string] $Ownership, [string] $Authority, [bool] $LiveSource) {
    $base = Join-Path $Root $BaseRel
    if (!(Test-Path $base)) { return }
    Get-ChildItem -LiteralPath $base -Force | Where-Object { $_.Name -notin @('.git','.gitignore') } | Sort-Object Name | ForEach-Object {
        $rel = Get-Rel $Root $_.FullName
        $wiringEvidence = Get-ConcreteWiringEvidence -RelPath $rel -Kind $Kind
        $wired = ($wiringEvidence.Count -gt 0)
        $referenceCandidate = if ($wired) { $false } elseif ($LiveSource) { $true } else { Test-SourceReference $_.Name }
        $action = if ($LiveSource -or $wired -or $referenceCandidate) { 'REFACTOR_ACTIVE' } else { 'KEEP_VENDOR_REFERENCE' }
        $status = if ($LiveSource) { 'UNKNOWN' } else { 'REFERENCE_ONLY' }
        $detail = @("Enumerated from $BaseRel at hub commit 38249878de2c03d6f5e2afd4884ee1b5beb9603d.")
        if ($wired) {
            $detail += $wiringEvidence
        } elseif ($LiveSource) {
            $detail += 'This is current LiveSource Git content. Deployment/runtime state was not inspected.'
        } elseif ($referenceCandidate) {
            $detail += 'SOURCE_REFERENCE_CANDIDATE: name/reference appears in current LiveSource source, but concrete include/config/init/module/handler wiring was not proven.'
        } else {
            $detail += 'No current LiveSource name/reference was found by the inventory scan.'
        }
        $components.Add((New-Component `
            -Id "$Prefix-$(Get-Slug $_.Name)" `
            -Name $_.Name `
            -Family (Get-Family $_.Name $rel) `
            -Kind $Kind `
            -Repo $Repo `
            -Path $rel `
            -Ownership $Ownership `
            -Authority $Authority `
            -Evidence (New-Evidence $true $wired $null $null $null $null $detail) `
            -Action $action `
            -Status $status `
            -Confidence ($(if ($wired) { 'HIGH' } elseif ($LiveSource -or $referenceCandidate) { 'MEDIUM' } else { 'LOW' })) `
            -Staleness 'CURRENT' `
            -Verdict ($(if ($wired) { 'SOURCE_WIRED_RUNTIME_UNKNOWN' } elseif ($LiveSource) { 'LIVESOURCE_PRESENT_RUNTIME_UNKNOWN' } elseif ($referenceCandidate) { 'SOURCE_REFERENCE_CANDIDATE_RUNTIME_UNKNOWN' } else { 'CATALOGUE_ONLY_REFERENCE' })) `
            -Notes @('No deployed/boot/player-runtime evidence was inspected in this lane.')))
    }
}

Add-TopLevel 'catalogue/Addons' 'x-cessive/Exile' 'EXILE-ADDON' 'ADDON' 'THIRD_PARTY' 'MIXED' $false
Add-TopLevel 'catalogue/Scripts' 'x-cessive/Exile' 'EXILE-SCRIPT' 'SCRIPT' 'THIRD_PARTY' 'CLIENT' $false
Add-TopLevel 'catalogue/LiveSource/mpmissions/Exile.Tanoa' 'x-cessive/Exile' 'EXILE-LIVE-MISSION' 'MISSION_MODULE' 'MIXED' 'MIXED' $true
Add-TopLevel 'catalogue/LiveSource/server-addons' 'x-cessive/Exile' 'EXILE-LIVE-SERVERADDON' 'SERVER_ADDON' 'MIXED' 'SERVER' $true
Add-TopLevel 'addons/mission/xcsv' 'x-cessive/XCSV_ADDONS' 'XCSV-ADDONS-MISSION' 'MISSION_MODULE' 'XCSV' 'CLIENT' $false

$addonRoot = Join-Path $Root 'addons'
if (Test-Path $addonRoot) {
    Get-ChildItem -LiteralPath $addonRoot -Force | Where-Object { Test-XcsvAddonsRuntimeSurface $_ } | Sort-Object Name | ForEach-Object {
        $rel = Get-Rel $Root $_.FullName
        $livePeer = Join-Path $Root ("catalogue/LiveSource/server-addons/" + $_.Name)
        $wiringEvidence = Get-ConcreteWiringEvidence -RelPath ("catalogue/LiveSource/server-addons/" + $_.Name) -Kind 'SERVER_ADDON'
        $wired = ($wiringEvidence.Count -gt 0)
        $components.Add((New-Component `
            -Id "XCSV-ADDONS-SERVER-$(Get-Slug $_.Name)" `
            -Name $_.Name `
            -Family (Get-Family $_.Name $rel) `
            -Kind 'SERVER_ADDON' `
            -Repo 'x-cessive/XCSV_ADDONS' `
            -Path $rel `
            -Ownership 'XCSV' `
            -Authority 'SERVER' `
            -Evidence (New-Evidence $true $wired $null $null $null $null @("Enumerated from XCSV_ADDONS runtime top-level source.", $(if (Test-Path $livePeer) { "Matching LiveSource server-addon path exists: catalogue/LiveSource/server-addons/$($_.Name)." } else { 'No matching LiveSource server-addon path found.' }), $wiringEvidence)) `
            -Action ($(if ($wired) { 'CONSOLIDATE_DUPLICATE' } else { 'UNKNOWN' })) `
            -Confidence 'MEDIUM' `
            -Staleness 'CURRENT' `
            -Verdict ($(if ($wired) { 'DUAL_SOURCE_SURFACE_REQUIRES_CUSTODY_RECONCILIATION' } else { 'XCSV_SOURCE_PRESENT_RUNTIME_UNKNOWN' })) `
            -Overlap @($(if ($wired) { "Dual XCSV_ADDONS/Exile LiveSource surface for $($_.Name)." } else { $null })) `
            -Notes @('Member repository inspected read-only at the hub gitlink.')))
    }
}

function Add-FileGroup([string] $BaseRel, [string] $Repo, [string] $Prefix, [string] $Family, [string] $Kind, [string] $Ownership, [string] $Authority) {
    $base = if ([IO.Path]::IsPathRooted($BaseRel)) { $BaseRel } else { Join-Path $Root $BaseRel }
    if (!(Test-Path $base)) { return }
    rg --files $base | Sort-Object | ForEach-Object {
        $path = $_
        $name = [IO.Path]::GetFileNameWithoutExtension($path)
        $rel = if ($path.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) { Get-Rel $Root $path } else { $path }
        $components.Add((New-Component `
            -Id "$Prefix-$(Get-Slug (($rel -replace '^[A-Za-z]:','') -replace '/', '-'))" `
            -Name $name `
            -Family $Family `
            -Kind $Kind `
            -Repo $Repo `
            -Path ($rel.Replace('\','/')) `
            -Ownership $Ownership `
            -Authority $Authority `
            -Evidence (New-Evidence $true $false $null $null $null $null @("Enumerated source file during issue #30 inventory expansion. Source presence does not prove SOURCE_WIRED.")) `
            -Action 'REFACTOR_ACTIVE' `
            -Confidence 'MEDIUM' `
            -Staleness 'CURRENT' `
            -Verdict 'SOURCE_PRESENT_RUNTIME_UNKNOWN' `
            -Notes @('Major module/tool inventory entry; runtime/deployment evidence not inspected.')))
    }
}

Add-FileGroup 'guard/src' 'x-cessive/XCSV_GUARD' 'XCSV-GUARD-SRC' 'GUARD / operations' 'TOOL' 'XCSV' 'SERVER'
Add-FileGroup 'guard/tools' 'x-cessive/XCSV_GUARD' 'XCSV-GUARD-TOOL' 'GUARD / operations' 'TOOL' 'XCSV' 'SERVER'
Add-FileGroup 'tools' 'x-cessive/XCSV' 'XCSV-HUB-TOOL' 'Hub build/sync/audit tooling' 'TOOL' 'XCSV' 'NONE'
if (Test-Path $OrchRoot) {
    Add-FileGroup (Join-Path $OrchRoot 'src') 'x-cessive/XCSV_ORCH' 'XCSV-ORCH-SRC' 'ORCH / AI workforce' 'TOOL' 'XCSV' 'NONE'
    Add-FileGroup (Join-Path $OrchRoot 'tools') 'x-cessive/XCSV_ORCH' 'XCSV-ORCH-TOOL' 'ORCH / AI workforce' 'TOOL' 'XCSV' 'NONE'
    Add-FileGroup (Join-Path $OrchRoot 'tests') 'x-cessive/XCSV_ORCH' 'XCSV-ORCH-TEST' 'ORCH / AI workforce' 'TOOL' 'XCSV' 'NONE'
}

rg --files (Join-Path $Root 'catalogue') (Join-Path $Root 'addons') | Where-Object { Test-DatabaseSurface $_ } | Sort-Object | ForEach-Object {
    $rel = Get-Rel $Root $_
    $components.Add((New-Component `
        -Id "XCSV-DB-$(Get-Slug ($rel -replace '/', '-'))" `
        -Name ([IO.Path]::GetFileName($_)) `
        -Family 'Server addons / network / database' `
        -Kind 'DATABASE' `
        -Repo ($(if ($rel -like 'addons/*') { 'x-cessive/XCSV_ADDONS' } else { 'x-cessive/Exile' })) `
        -Path $rel `
        -Ownership 'MIXED' `
        -Authority 'DATABASE' `
        -Evidence (New-Evidence $true $null $null $null $null $null @('Database/extDB/schema/query file exists in Git source. Live DB schema was not inspected.')) `
        -Action 'UNKNOWN' `
        -Confidence 'LOW' `
        -Staleness 'UNKNOWN' `
        -Verdict 'DB_SOURCE_PRESENT_LIVE_DB_UNKNOWN' `
        -Db @($rel)))
}

rg --files (Join-Path $Root 'catalogue') | Where-Object { $_ -match '(?i)(battleye|scripts\.txt|remoteexec\.txt|publicvariable\.txt|createvehicle\.txt|setvariable\.txt|attachto\.txt)' } | Sort-Object | ForEach-Object {
    $rel = Get-Rel $Root $_
    $components.Add((New-Component `
        -Id "XCSV-BE-$(Get-Slug ($rel -replace '/', '-'))" `
        -Name ([IO.Path]::GetFileName($_)) `
        -Family 'Server addons / network / database' `
        -Kind 'OTHER' `
        -Repo 'x-cessive/Exile' `
        -Path $rel `
        -Ownership 'MIXED' `
        -Authority 'SERVER' `
        -Evidence (New-Evidence $true $null $null $null $null $null @('BattlEye filter/exception material exists in Git source. Live BattlEye filters were not inspected.')) `
        -Action 'UNKNOWN' `
        -Confidence 'LOW' `
        -Staleness 'UNKNOWN' `
        -Verdict 'BATTLEYE_SOURCE_PRESENT_LIVE_FILTER_UNKNOWN' `
        -Be @($rel)))
}

$missionConfig = Join-Path $Root 'catalogue/LiveSource/mpmissions/Exile.Tanoa/config.cpp'
$overrideRows = @()
$networkRows = @()
if (Test-Path $missionConfig) {
    $lines = Get-Content -LiteralPath $missionConfig
    foreach ($line in $lines) {
        if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*"([^"]+\.sqf)"\s*;') {
            $overrideRows += [pscustomobject]@{ Function = $Matches[1]; Path = $Matches[2] }
        }
        if ($line -match '^\s*class\s+([A-Za-z0-9_]+)\s*\{.*module\s*=\s*"([^"]+)"') {
            $networkRows += [pscustomobject]@{ Message = $Matches[1]; Module = $Matches[2] }
        }
    }
}

$registry = [ordered]@{
    registry_version = '0.2.0'
    classification = 'PARTIAL_SOURCE_VERIFIED'
    notes = @(
        'Expanded by XCSV-REFACTOR-INV-001 (#30) from Git source enumeration on 2026-08-21.',
        'This is not PASS_INVENTORY_VERIFIED because deployed server, boot logs, live DB, live BattlEye and player-runtime evidence were not inspected.',
        'Catalogue/source presence is not runtime truth; source_wired is recorded only where current LiveSource contains or references the component.'
    )
    components = @($components | Sort-Object component_id)
}

$registryPath = Join-Path $Root 'registry/components.json'
$registry | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $registryPath -Encoding UTF8

$byRepo = $components | Group-Object repo | Sort-Object Name
$byKind = $components | Group-Object kind | Sort-Object Name
$byAction = $components | Group-Object refactor_action | Sort-Object Name
$sourceWiredCount = @($components | Where-Object { $_.evidence.source_wired -eq $true }).Count
$packedCount = @($components | Where-Object { $_.evidence.packed_artifact_present -eq $true }).Count
$deployedCount = @($components | Where-Object { $_.evidence.deployed_present -eq $true }).Count
$bootCount = @($components | Where-Object { $_.evidence.boot_evidence -eq $true }).Count
$playerCount = @($components | Where-Object { $_.evidence.player_runtime_evidence -eq $true }).Count

$wiki = New-Object System.Collections.Generic.List[string]
[void]($wiki.Add('# System Components'))
[void]($wiki.Add(''))
[void]($wiki.Add('This page is generated from `registry/components.json` by `tools/build-component-inventory.ps1` for XCSV-REFACTOR-INV-001 / issue #30.'))
[void]($wiki.Add(''))
[void]($wiki.Add('> Catalogue/source presence is not proof of live deployment. Runtime, deployment, boot and player evidence remain `UNKNOWN` unless explicitly recorded.'))
[void]($wiki.Add(''))
[void]($wiki.Add('## Inventory State'))
[void]($wiki.Add(''))
[void]($wiki.Add(('- Registry classification: `{0}`' -f $registry.classification)))
[void]($wiki.Add(('- Component entries: {0}' -f $components.Count)))
[void]($wiki.Add(('- Source-wired/current LiveSource references: {0}' -f $sourceWiredCount)))
[void]($wiki.Add(('- Packed artifact evidence: {0}' -f $packedCount)))
[void]($wiki.Add(('- Deployed evidence: {0}' -f $deployedCount)))
[void]($wiki.Add(('- Boot evidence: {0}' -f $bootCount)))
[void]($wiki.Add(('- Player runtime evidence: {0}' -f $playerCount)))
[void]($wiki.Add(''))
[void]($wiki.Add('### By Repository'))
[void]($wiki.Add(''))
[void]($wiki.Add('| Repository | Count |'))
[void]($wiki.Add('| --- | ---: |'))
foreach ($g in $byRepo) { [void]($wiki.Add(('| `{0}` | {1} |' -f $g.Name, $g.Count))) }
[void]($wiki.Add(''))
[void]($wiki.Add('### By Kind'))
[void]($wiki.Add(''))
[void]($wiki.Add('| Kind | Count |'))
[void]($wiki.Add('| --- | ---: |'))
foreach ($g in $byKind) { [void]($wiki.Add(('| `{0}` | {1} |' -f $g.Name, $g.Count))) }
[void]($wiki.Add(''))
[void]($wiki.Add('### By Working Verdict'))
[void]($wiki.Add(''))
[void]($wiki.Add('| Verdict | Count |'))
[void]($wiki.Add('| --- | ---: |'))
foreach ($g in $byAction) { [void]($wiki.Add(('| `{0}` | {1} |' -f $g.Name, $g.Count))) }
[void]($wiki.Add(''))
[void]($wiki.Add('## Duplicate / Overlap Matrix Draft'))
[void]($wiki.Add(''))
[void]($wiki.Add('| Surface | Evidence | Working verdict | Next lane |'))
[void]($wiki.Add('| --- | --- | --- | --- |'))
[void]($wiki.Add('| Scratchie residue | `catalogue/LiveSource/mpmissions/Exile.Tanoa/Scratchie` exists and `config.cpp` still contains Scratchie app/comment material; no live runtime verified. | `REFACTOR_ACTIVE` source-residue audit required | #30/#31 then gameplay lanes only after evidence |'))
[void]($wiki.Add('| MarketByCyunide residue | `catalogue/LiveSource/mpmissions/Exile.Tanoa/MarketByCyunide` exists and player-market network messages remain in `config.cpp`; no live runtime verified. | `REFACTOR_ACTIVE` source-residue audit required | #30/#31 |'))
[void]($wiki.Add('| Multiple revive implementations | `catalogue/Addons/ExileRevive`, `catalogue/Scripts/Enigma_Exile_Revive`, and `ReviveRequest` in current `config.cpp` all exist. | `CONSOLIDATE_DUPLICATE` candidate, no deletion authority | #34/#35 after authority decision |'))
[void]($wiki.Add('| AI engines | A3XAI, DMS, Occupation, FuMS, VcomAI, Sarge and VEMF catalogue entries exist; GUARD source references A3XAI/FuMS as operational concerns. | `KEEP_VENDOR_REFERENCE` or `UNKNOWN` until live process/mod evidence | #35 |'))
[void]($wiki.Add('| Vehicle lifecycle | AVS, VPS, persistent vehicles, claim, salvage, crash loot, paint, virtual garage and drones are all present across catalogue/LiveSource/XCSV_ADDONS. | `REFACTOR_ACTIVE` / `CONSOLIDATE_DUPLICATE` high risk | #34 |'))
[void]($wiki.Add('| XCSV_ADDONS mirrors | `addons/mission/xcsv` and `catalogue/LiveSource/mpmissions/Exile.Tanoa/xcsv` both exist; `xcsv_chatter` exists in XCSV_ADDONS and LiveSource server-addons. | `CONSOLIDATE_DUPLICATE` custody decision required | #33 |'))
[void]($wiki.Add(''))
[void]($wiki.Add('## Override Registry Draft'))
[void]($wiki.Add(''))
[void]($wiki.Add('| Exile function | Replacement path |'))
[void]($wiki.Add('| --- | --- |'))
foreach ($row in ($overrideRows | Sort-Object Function)) { [void]($wiki.Add(('| `{0}` | `{1}` |' -f $row.Function, $row.Path))) }
[void]($wiki.Add(''))
[void]($wiki.Add('## Network Message Registry Draft'))
[void]($wiki.Add(''))
[void]($wiki.Add('| Message | Module |'))
[void]($wiki.Add('| --- | --- |'))
foreach ($row in ($networkRows | Sort-Object Message)) { [void]($wiki.Add(('| `{0}` | `{1}` |' -f $row.Message, $row.Module))) }
[void]($wiki.Add(''))
[void]($wiki.Add('## Init / Scheduler Map Draft'))
[void]($wiki.Add(''))
[void]($wiki.Add('| Source | Evidence |'))
[void]($wiki.Add('| --- | --- |'))
[void]($wiki.Add('| mission init | `init.sqf`, `initPlayerLocal.sqf`, `initServer.sqf` exist in current LiveSource and contain execVM/preprocess/bootstrap wiring. |'))
[void]($wiki.Add('| xcsv_chatter | `config.cpp` defines preInit/postInit and `bootstrap/fn_postInit.sqf` registers Exile server thread tasks. |'))
[void]($wiki.Add('| XCSV mission modules | `fn_droneControl.sqf` registers an Exile client thread; several UI modules spawn scheduled client work. |'))
[void]($wiki.Add('| GUARD | Rust modules include stack/server/db/rcon/live/metrics/docs/ai and UI tabs; runtime state not reverified in this lane. |'))
[void]($wiki.Add('| ORCH | Local read-only `D:\XCSV_ORCH` exposes controller, gauntlet, Hermes, workers, integrity, deploy/release and tests. |'))
[void]($wiki.Add(''))
[void]($wiki.Add('## Prioritized Refactor Queue Draft'))
[void]($wiki.Add(''))
[void]($wiki.Add('1. Vehicle lifecycle and persistence overrides: AVS/VPS/persistent vehicles/claim/salvage/crash loot/paint/garage/drone overlap.'))
[void]($wiki.Add('2. `CfgExileCustomCode` override registry hardening and duplicate-collision tests.'))
[void]($wiki.Add('3. `CfgNetworkMessages` handler resolution and XCSV_ADDONS/LiveSource network custody.'))
[void]($wiki.Add('4. XCSV_ADDONS to LiveSource mirror ownership and drift testing, especially `xcsv_chatter`.'))
[void]($wiki.Add('5. Scratchie and MarketByCyunide residue classification without deleting source.'))
[void]($wiki.Add('6. AI engine runtime authority split: A3XAI/DMS/Occupation/FuMS/VcomAI/Sarge/VEMF.'))
[void]($wiki.Add('7. Init/event/scheduler ownership map and duplicate scheduler guardrails.'))
[void]($wiki.Add('8. DB/extDB query group custody and BattlEye filter exception mapping.'))
[void]($wiki.Add(''))
[void]($wiki.Add('## Remaining UNKNOWN Areas'))
[void]($wiki.Add(''))
[void]($wiki.Add('- Live server deployment, loaded mods/servermods, packed PBO hashes, boot logs, live DB schema, live BattlEye filters and player-runtime behavior were not inspected.'))
[void]($wiki.Add('- `REMOVE_CANDIDATE` is not used as deletion authority in this tranche.'))
[void]($wiki.Add('- Issue #31 should use this registry as evidence input but should not claim global modernization completion.'))
[void]($wiki.Add(''))
[void]($wiki.Add('## Component Registry'))
[void]($wiki.Add(''))
[void]($wiki.Add('| Component | Family | Kind | Repo | Path | Evidence | Verdict |'))
[void]($wiki.Add('| --- | --- | --- | --- | --- | --- | --- |'))
foreach ($c in ($components | Sort-Object family, component_id)) {
    $ev = @()
    if ($c.evidence.catalogue_present -eq $true) { $ev += 'CATALOGUE_PRESENT' }
    if ($c.evidence.source_wired -eq $true) { $ev += 'SOURCE_WIRED' }
    if ($c.evidence.packed_artifact_present -eq $true) { $ev += 'PACKED_ARTIFACT_PRESENT' }
    if ($c.evidence.deployed_present -eq $true) { $ev += 'DEPLOYED_PRESENT' }
    if ($c.evidence.boot_evidence -eq $true) { $ev += 'BOOT_EVIDENCE' }
    if ($c.evidence.player_runtime_evidence -eq $true) { $ev += 'PLAYER_RUNTIME_EVIDENCE' }
    if ($ev.Count -eq 0) { $ev += 'UNKNOWN' }
    [void]($wiki.Add(('| `{0}` | {1} | `{2}` | `{3}` | `{4}` | {5} | `{6}` |' -f $c.component_id, $c.family, $c.kind, $c.repo, $c.canonical_path, ($ev -join ', '), $c.refactor_action)))
}

Set-Content -LiteralPath (Join-Path $Root 'wiki/System-Components.md') -Value $wiki -Encoding UTF8
Write-Output "component-inventory: wrote $($components.Count) components"
Write-Output "component-inventory: source-wired=$sourceWiredCount packed=$packedCount deployed=$deployedCount boot=$bootCount player=$playerCount"


