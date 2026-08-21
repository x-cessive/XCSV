param(
    [string] $Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string] $OrchRoot,
    [string] $ColdResponsePath,
    [ValidateSet('CI_SAFE_SOURCE_CHECK', 'LIVE_DEPLOY_VERIFY')]
    [string] $Mode = 'CI_SAFE_SOURCE_CHECK',
    [switch] $Json,
    [switch] $FailOnFindings,
    [switch] $RequireMemberSources
)

$ErrorActionPreference = 'Stop'

function Get-RepoSlugFromRemote([string] $RemoteUrl) {
    if ([string]::IsNullOrWhiteSpace($RemoteUrl)) { return $null }
    $remote = ($RemoteUrl -replace '\\', '/').Trim()
    if ($remote -match 'github\.com[:/]([^/]+)/([^/.]+)(?:\.git)?/?$') {
        return ('{0}/{1}' -f $Matches[1], $Matches[2])
    }
    return $null
}

function Get-RelPath([string] $Base, [string] $Path) {
    $baseFull = [IO.Path]::GetFullPath($Base).TrimEnd('\') + '\'
    $pathFull = [IO.Path]::GetFullPath($Path)
    return $pathFull.Substring($baseFull.Length).Replace('\', '/')
}

function New-XCSVGuardrailFinding(
    [string] $Check,
    [string] $Severity,
    [string] $Code,
    [string] $Detail,
    [string] $Path = '',
    [string] $Evidence = ''
) {
    [pscustomobject][ordered]@{
        check = $Check
        severity = $Severity
        code = $Code
        path = $Path
        detail = $Detail
        evidence = $Evidence
    }
}

function Remove-SqfComments([string] $Text) {
    $withoutBlocks = [regex]::Replace($Text, '(?s)/\*.*?\*/', '')
    return [regex]::Replace($withoutBlocks, '(?m)//.*$', '')
}

function Get-GitSourceObservation(
    [string] $Path,
    [string] $ExpectedRepo,
    [string] $ExpectedGitlinkSha = $null,
    [bool] $Required = $false
) {
    if ([string]::IsNullOrWhiteSpace($Path) -or !(Test-Path -LiteralPath $Path)) {
        if ($Required) { throw "REQUIRED_SOURCE_UNAVAILABLE: $ExpectedRepo at $Path" }
        return [pscustomobject][ordered]@{
            repository = $ExpectedRepo
            path = $Path
            result = 'NOT_REVERIFIED'
            sha = $null
            expected_gitlink_sha = $ExpectedGitlinkSha
            clean = $null
            detail = "$ExpectedRepo source is unavailable; source enumeration skipped."
        }
    }

    $top = (& git -C $Path rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($top)) {
        if ($Required) { throw "UNKNOWN_SOURCE: cannot resolve Git root for $ExpectedRepo at $Path" }
        return [pscustomobject][ordered]@{
            repository = $ExpectedRepo
            path = $Path
            result = 'UNKNOWN'
            sha = $null
            expected_gitlink_sha = $ExpectedGitlinkSha
            clean = $null
            detail = "$ExpectedRepo path exists, but Git identity could not be resolved."
        }
    }

    $remote = (& git -C $top remote get-url origin 2>$null)
    if ($LASTEXITCODE -ne 0) { $remote = $null }
    $actualRepo = Get-RepoSlugFromRemote $remote
    $sha = (& git -C $top rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($sha)) {
        if ($Required) { throw "UNKNOWN_SOURCE: cannot resolve HEAD for $ExpectedRepo at $top" }
        return [pscustomobject][ordered]@{
            repository = $ExpectedRepo
            path = $Path
            result = 'UNKNOWN'
            sha = $null
            expected_gitlink_sha = $ExpectedGitlinkSha
            clean = $null
            detail = "$ExpectedRepo HEAD could not be resolved."
        }
    }

    if ($actualRepo -ne $ExpectedRepo) {
        if ($Required) { throw "WRONG_SOURCE_IDENTITY: expected $ExpectedRepo but observed $actualRepo from $remote" }
        return [pscustomobject][ordered]@{
            repository = $ExpectedRepo
            path = $Path
            result = 'UNKNOWN'
            sha = $sha
            expected_gitlink_sha = $ExpectedGitlinkSha
            clean = $null
            detail = "Expected $ExpectedRepo but observed $actualRepo from $remote."
        }
    }

    if ($ExpectedGitlinkSha -and $sha -ne $ExpectedGitlinkSha) {
        return [pscustomobject][ordered]@{
            repository = $ExpectedRepo
            path = $Path
            result = 'STALE_MEMBER_SOURCE'
            sha = $sha
            expected_gitlink_sha = $ExpectedGitlinkSha
            clean = $null
            detail = "Observed $sha but XCSV gitlink expects $ExpectedGitlinkSha."
        }
    }

    $dirty = @(& git -C $top status --porcelain --untracked-files=all 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject][ordered]@{
            repository = $ExpectedRepo
            path = $Path
            result = 'UNKNOWN'
            sha = $sha
            expected_gitlink_sha = $ExpectedGitlinkSha
            clean = $null
            detail = "Could not inspect worktree cleanliness."
        }
    }
    if ($dirty.Count -gt 0) {
        return [pscustomobject][ordered]@{
            repository = $ExpectedRepo
            path = $Path
            result = 'DIRTY_SOURCE'
            sha = $sha
            expected_gitlink_sha = $ExpectedGitlinkSha
            clean = $false
            detail = "Source has $($dirty.Count) tracked/untracked changes; authoritative enumeration skipped."
        }
    }

    [pscustomobject][ordered]@{
        repository = $ExpectedRepo
        path = $Path
        result = 'VERIFIED_AT_OBSERVATION'
        sha = $sha
        expected_gitlink_sha = $ExpectedGitlinkSha
        clean = $true
        detail = "Repository identity, HEAD and cleanliness verified."
    }
}

function Get-ExpectedGitlinkSha([string] $Root, [string] $RelPath) {
    $entry = (& git -C $Root ls-tree HEAD -- $RelPath 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($entry)) { return $null }
    if ($entry -match '^160000\s+commit\s+([0-9a-f]{40})\s+') { return $Matches[1] }
    return $null
}

function Get-RegistryPathSet([string] $RegistryPath) {
    $set = @{}
    if (!(Test-Path -LiteralPath $RegistryPath)) { return $set }
    $registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
    foreach ($c in $registry.components) {
        if ($c.canonical_path) { $set[$c.canonical_path] = $true }
    }
    return $set
}

function Get-ChildDirectoryRelPaths([string] $Root, [string] $RelRoot) {
    $full = Join-Path $Root ($RelRoot -replace '/', '\')
    if (!(Test-Path -LiteralPath $full)) { return @() }
    @(Get-ChildItem -LiteralPath $full -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne '.git' } |
        ForEach-Object { "$RelRoot/$($_.Name)" })
}

function Get-GuardToolSurfacePaths([string] $Root) {
    $surfaces = @()
    foreach ($relRoot in @('guard/src', 'guard/tools')) {
        $full = Join-Path $Root ($relRoot -replace '/', '\')
        if (!(Test-Path -LiteralPath $full)) { continue }
        $surfaces += Get-ChildItem -LiteralPath $full -File -Recurse -Include *.rs,*.ps1,*.toml -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\target\\|\\\.git\\' } |
            ForEach-Object { Get-RelPath -Base $Root -Path $_.FullName }
    }
    return @($surfaces | Sort-Object -Unique)
}

function Get-OrchSurfacePaths([string] $OrchRoot) {
    if ([string]::IsNullOrWhiteSpace($OrchRoot) -or !(Test-Path -LiteralPath $OrchRoot)) { return @() }
    $surfaces = @()
    foreach ($relRoot in @('src', 'tools', 'tests')) {
        $full = Join-Path $OrchRoot $relRoot
        if (!(Test-Path -LiteralPath $full)) { continue }
        $surfaces += Get-ChildItem -LiteralPath $full -File -Recurse -Include *.rs,*.ps1,*.psm1,*.json,*.toml -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\target\\|\\\.git\\' } |
            ForEach-Object { Get-RelPath -Base $OrchRoot -Path $_.FullName }
    }
    return @($surfaces | Sort-Object -Unique)
}

function Test-RegistryCompleteness([string] $Root, [string] $OrchRoot = '') {
    $findings = @()
    $registryPaths = Get-RegistryPathSet (Join-Path $Root 'registry/components.json')
    $expected = @()
    $expected += Get-ChildDirectoryRelPaths $Root 'catalogue/Addons'
    $expected += Get-ChildDirectoryRelPaths $Root 'catalogue/Scripts'
    $expected += Get-ChildDirectoryRelPaths $Root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    $expected += Get-ChildDirectoryRelPaths $Root 'catalogue/LiveSource/server-addons'
    $expected += Get-ChildDirectoryRelPaths $Root 'addons/mission/xcsv'
    $expected += Get-ChildDirectoryRelPaths $Root 'addons/server'
    $expected += Get-GuardToolSurfacePaths $Root
    $expected += Get-OrchSurfacePaths $OrchRoot

    foreach ($rel in @($expected | Sort-Object -Unique)) {
        if (!$registryPaths.ContainsKey($rel)) {
            $findings += New-XCSVGuardrailFinding 'registry-completeness' 'FAIL' 'MISSING_COMPONENT_REGISTRY_ENTRY' "Source/module surface is not represented in registry/components.json." $rel 'source path enumerated from verified source tree'
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'registry-completeness' 'PASS' 'COMPONENT_REGISTRY_COMPLETE_FOR_ENUMERATED_SURFACES' 'All enumerated source/module surfaces have registry paths.' '' ''
    }
    return $findings
}

function Get-SqfFiles([string[]] $Roots) {
    $files = @()
    foreach ($root in $Roots) {
        if (Test-Path -LiteralPath $root) {
            $files += Get-ChildItem -LiteralPath $root -Recurse -File -Include *.sqf,*.cpp,*.hpp -ErrorAction SilentlyContinue
        }
    }
    return $files
}

function Test-CfgExileCustomCode([string] $MissionRoot) {
    $findings = @()
    $cfg = Join-Path $MissionRoot 'config.cpp'
    if (!(Test-Path -LiteralPath $cfg)) {
        return @(New-XCSVGuardrailFinding 'cfgexilecustomcode' 'UNKNOWN' 'MISSION_CONFIG_NOT_REVERIFIED' 'Mission config.cpp unavailable.' $cfg '')
    }
    $text = Remove-SqfComments (Get-Content -LiteralPath $cfg -Raw)
    $entries = @()
    foreach ($m in [regex]::Matches($text, '(?m)^\s*(Exile(?:Client|Server)_[A-Za-z0-9_]+)\s*=\s*"([^"]+)"\s*;')) {
        $entries += [pscustomobject]@{ function = $m.Groups[1].Value; replacement = $m.Groups[2].Value }
    }
    foreach ($g in ($entries | Group-Object function | Where-Object Count -gt 1)) {
        $findings += New-XCSVGuardrailFinding 'cfgexilecustomcode' 'FAIL' 'DUPLICATE_OVERRIDE_DECLARATION' "Duplicate override declaration for $($g.Name)." 'config.cpp' (($g.Group.replacement | Sort-Object -Unique) -join '; ')
    }
    foreach ($entry in $entries) {
        if ($entry.replacement -match '^\s*(?:[A-Za-z]:\\|\\\\|\.\.)') {
            $findings += New-XCSVGuardrailFinding 'cfgexilecustomcode' 'FAIL' 'OVERRIDE_OUTSIDE_EXPECTED_CUSTODY' "Override path is outside mission custody." $entry.replacement $entry.function
            continue
        }
        $target = Join-Path $MissionRoot ($entry.replacement -replace '/', '\')
        if (!(Test-Path -LiteralPath $target)) {
            $findings += New-XCSVGuardrailFinding 'cfgexilecustomcode' 'FAIL' 'MISSING_OVERRIDE_FILE' "Override replacement file is missing." $entry.replacement $entry.function
        }
    }
    $registered = @{}
    foreach ($entry in $entries) {
        $registered[($entry.replacement -replace '\\','/').ToLowerInvariant()] = $true
    }
    foreach ($f in Get-ChildItem -LiteralPath $MissionRoot -Recurse -File -Filter *.sqf -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^Exile(?:Client|Server)_.+\.sqf$' }) {
        $rel = (Get-RelPath -Base $MissionRoot -Path $f.FullName).ToLowerInvariant()
        if ($rel -match '^(?:overrides|customcode|xcsv)/' -and !$registered.ContainsKey($rel)) {
            $findings += New-XCSVGuardrailFinding 'cfgexilecustomcode' 'WARN' 'UNREGISTERED_OVERRIDE_CANDIDATE' 'Exile override-shaped source file is not registered in CfgExileCustomCode.' $rel ''
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'cfgexilecustomcode' 'PASS' 'CFGEXILECUSTOMCODE_NO_DETERMINISTIC_FINDINGS' 'No duplicate/missing/out-of-custody override findings detected.' '' ''
    }
    return $findings
}

function Test-NetworkMessages([string] $MissionRoot, [string] $ServerAddonsRoot) {
    $findings = @()
    $cfg = Join-Path $MissionRoot 'config.cpp'
    if (!(Test-Path -LiteralPath $cfg)) {
        return @(New-XCSVGuardrailFinding 'network-messages' 'UNKNOWN' 'MISSION_CONFIG_NOT_REVERIFIED' 'Mission config.cpp unavailable.' $cfg '')
    }
    $cfgText = Get-Content -LiteralPath $cfg -Raw
    $declared = @()
    foreach ($m in [regex]::Matches($cfgText, '(?m)^\s*class\s+(\w+)\s*\{\s*module\s*=\s*"([^"]+)"')) {
        $declared += [pscustomobject]@{ message = $m.Groups[1].Value; module = $m.Groups[2].Value }
    }
    foreach ($g in ($declared | Group-Object message | Where-Object Count -gt 1)) {
        $findings += New-XCSVGuardrailFinding 'network-messages' 'FAIL' 'DUPLICATE_CFGNETWORKMESSAGE' "Duplicate CfgNetworkMessages declaration for $($g.Name)." 'config.cpp' ''
    }
    $aliasText = ''
    foreach ($f in Get-SqfFiles @($MissionRoot, $ServerAddonsRoot)) { $aliasText += (Get-Content -LiteralPath $f.FullName -Raw) + "`n" }
    $ourModules = @{}
    foreach ($m in [regex]::Matches($aliasText, 'Exile(?:Server|Client)_(\w+?)_network_(\w+)\s*=')) { $ourModules[$m.Groups[1].Value] = $true }
    foreach ($d in $declared) {
        if (!$ourModules.ContainsKey($d.module)) { continue }
        $srv = "ExileServer_$($d.module)_network_$($d.message)"
        $cli = "ExileClient_$($d.module)_network_$($d.message)"
        if (($aliasText -notmatch [regex]::Escape($srv)) -and ($aliasText -notmatch [regex]::Escape($cli))) {
            $findings += New-XCSVGuardrailFinding 'network-messages' 'FAIL' 'MISSING_NETWORK_HANDLER' "Network message has no server/client handler alias." 'config.cpp' "$($d.module)/$($d.message)"
        }
    }
    $handlers = @{}
    foreach ($m in [regex]::Matches($aliasText, 'Exile(?:Server|Client)_(\w+?)_network_(\w+)\s*=')) {
        $handlers["$($m.Groups[1].Value)/$($m.Groups[2].Value)"] = $true
    }
    foreach ($key in $handlers.Keys) {
        $parts = $key -split '/', 2
        if (!@($declared | Where-Object { $_.module -eq $parts[0] -and $_.message -eq $parts[1] })) {
            $findings += New-XCSVGuardrailFinding 'network-messages' 'WARN' 'STALE_NETWORK_HANDLER_CANDIDATE' 'Handler alias has no matching CfgNetworkMessages declaration.' '' $key
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'network-messages' 'PASS' 'NETWORK_MESSAGES_NO_DETERMINISTIC_FINDINGS' 'No duplicate/missing/stale network message findings detected.' '' ''
    }
    return $findings
}

function Test-XM8Ui([string] $MissionRoot) {
    $findings = @()
    $cfg = Join-Path $MissionRoot 'config.cpp'
    if (!(Test-Path -LiteralPath $cfg)) {
        return @(New-XCSVGuardrailFinding 'xm8-ui' 'UNKNOWN' 'MISSION_CONFIG_NOT_REVERIFIED' 'Mission config.cpp unavailable.' $cfg '')
    }
    $text = Get-Content -LiteralPath $cfg -Raw
    $appIds = @()
    foreach ($m in [regex]::Matches($text, 'appID\s*=\s*"([^"]+)"')) { $appIds += $m.Groups[1].Value }
    foreach ($g in ($appIds | Group-Object | Where-Object Count -gt 1)) {
        $findings += New-XCSVGuardrailFinding 'xm8-ui' 'FAIL' 'DUPLICATE_XM8_APP_ID' "Duplicate XM8 appID $($g.Name)." 'config.cpp' ''
    }
    $idcs = @()
    foreach ($m in [regex]::Matches($text, '\bidc\s*=\s*(\d+)\s*;')) { $idcs += [int]$m.Groups[1].Value }
    foreach ($g in ($idcs | Where-Object { $_ -gt 0 } | Group-Object | Where-Object Count -gt 1)) {
        $findings += New-XCSVGuardrailFinding 'xm8-ui' 'FAIL' 'DUPLICATE_IDC' "Duplicate positive IDC $($g.Name)." 'config.cpp' ''
    }
    foreach ($idc in $idcs | Where-Object { $_ -gt 0 -and $_ -lt 1000 }) {
        $findings += New-XCSVGuardrailFinding 'xm8-ui' 'WARN' 'UNSAFE_LOW_IDC_CANDIDATE' "Positive IDC is in a low/shared-looking range." 'config.cpp' "$idc"
    }
    foreach ($app in $appIds | Sort-Object -Unique) {
        $candidate = Join-Path $MissionRoot ("xcsv\" + $app)
        if (!(Test-Path -LiteralPath $candidate)) {
            $findings += New-XCSVGuardrailFinding 'xm8-ui' 'WARN' 'XM8_REGISTERED_APP_SOURCE_NOT_PROVEN' 'Registered XM8 app has no same-name xcsv source directory; verify manually.' 'config.cpp' $app
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'xm8-ui' 'PASS' 'XM8_NO_DETERMINISTIC_FINDINGS' 'No duplicate appID/IDC findings detected.' '' ''
    }
    return $findings
}

function Test-InitEventScheduler([string] $MissionRoot, [string] $ServerAddonsRoot) {
    $findings = @()
    $patterns = [ordered]@{
        'execVM' = 'execVM\s+["'']([^"'']+)["'']'
        'preInit' = '\bpreInit\s*=\s*1\b'
        'postInit' = '\bpostInit\s*=\s*1\b'
        'thread' = 'ExileServer_system_thread_addTask|addMissionEventHandler|addEventHandler'
        'WeaponAssembled' = 'WeaponAssembled'
        'SoundPlayed' = 'SoundPlayed'
        'eachFrame' = 'EachFrame|onEachFrame|while\s*\{\s*true\s*\}'
    }
    foreach ($f in Get-SqfFiles @($MissionRoot, $ServerAddonsRoot)) {
        $text = Get-Content -LiteralPath $f.FullName -Raw
        foreach ($name in $patterns.Keys) {
            if ($text -match $patterns[$name]) {
                $findings += New-XCSVGuardrailFinding 'init-event-scheduler' 'WARN' 'INIT_EVENT_SCHEDULER_CANDIDATE' "Potential init/event/scheduler hook: $name." (Get-RelPath -Base (Split-Path $MissionRoot -Parent) -Path $f.FullName) ''
            }
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'init-event-scheduler' 'PASS' 'NO_INIT_EVENT_SCHEDULER_CANDIDATES' 'No deterministic init/event/scheduler candidates detected.' '' ''
    }
    return $findings
}

function Test-TraderEconomy([string] $MissionRoot) {
    $findings = @()
    $files = Get-SqfFiles @($MissionRoot)
    $classNames = @()
    foreach ($f in $files) {
        $text = Get-Content -LiteralPath $f.FullName -Raw
        if ($text -notmatch '(?i)trader|price|sellPrice|buyPrice|category') { continue }
        foreach ($m in [regex]::Matches($text, '(?m)^\s*class\s+([A-Za-z0-9_]+)')) {
            $classNames += [pscustomobject]@{ name = $m.Groups[1].Value; path = $f.FullName }
        }
        if ($text -match '(?i)buyPrice\s*=\s*(\d+).*?sellPrice\s*=\s*(\d+)') {
            foreach ($m in [regex]::Matches($text, '(?is)buyPrice\s*=\s*(\d+).*?sellPrice\s*=\s*(\d+)')) {
                if ([int]$m.Groups[2].Value -gt [int]$m.Groups[1].Value) {
                    $findings += New-XCSVGuardrailFinding 'trader-economy' 'WARN' 'BUY_SELL_INCONSISTENT_CANDIDATE' 'sellPrice exceeds buyPrice in a detectable block.' (Get-RelPath -Base $MissionRoot -Path $f.FullName) "$($m.Groups[1].Value)/$($m.Groups[2].Value)"
                }
            }
        }
    }
    foreach ($g in ($classNames | Group-Object name | Where-Object Count -gt 1)) {
        if ($g.Name -match '(?i)trader|category|vehicle|weapon|item') {
            $findings += New-XCSVGuardrailFinding 'trader-economy' 'WARN' 'DUPLICATE_TRADER_ECONOMY_CLASS_CANDIDATE' "Duplicate economy-looking class $($g.Name)." '' (($g.Group.path | Sort-Object -Unique) -join '; ')
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'trader-economy' 'PASS' 'TRADER_ECONOMY_NO_DETERMINISTIC_FINDINGS' 'No duplicate/inconsistent trader-economy candidates detected.' '' ''
    }
    return $findings
}

function Get-FileHashMap([string] $Root) {
    $map = @{}
    if (!(Test-Path -LiteralPath $Root)) { return $map }
    foreach ($f in Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue) {
        if ($f.FullName -match '\\\.git\\') { continue }
        $rel = (Get-RelPath -Base $Root -Path $f.FullName).ToLowerInvariant()
        $map[$rel] = (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash
    }
    return $map
}

function Test-XCSVAddonsMirrorDrift([string] $Root) {
    $findings = @()
    $pairs = @(
        @{ left = 'addons/mission/xcsv'; right = 'catalogue/LiveSource/mpmissions/Exile.Tanoa/xcsv' },
        @{ left = 'addons/server/xcsv_chatter'; right = 'catalogue/LiveSource/server-addons/xcsv_chatter' }
    )
    foreach ($pair in $pairs) {
        $leftRoot = Join-Path $Root ($pair.left -replace '/', '\')
        $rightRoot = Join-Path $Root ($pair.right -replace '/', '\')
        if (!(Test-Path -LiteralPath $leftRoot) -or !(Test-Path -LiteralPath $rightRoot)) {
            $findings += New-XCSVGuardrailFinding 'mirror-drift' 'UNKNOWN' 'MIRROR_PAIR_NOT_REVERIFIED' 'One side of a known mirror pair is unavailable.' "$($pair.left) <-> $($pair.right)" ''
            continue
        }
        $left = Get-FileHashMap $leftRoot
        $right = Get-FileHashMap $rightRoot
        foreach ($key in @($left.Keys + $right.Keys | Sort-Object -Unique)) {
            if (!$left.ContainsKey($key) -or !$right.ContainsKey($key)) {
                $findings += New-XCSVGuardrailFinding 'mirror-drift' 'WARN' 'MIRROR_FILE_PRESENCE_DRIFT' 'Mirror file exists on only one side.' "$($pair.left) <-> $($pair.right)" $key
            } elseif ($left[$key] -ne $right[$key]) {
                $findings += New-XCSVGuardrailFinding 'mirror-drift' 'WARN' 'MIRROR_FILE_CONTENT_DRIFT' 'Mirror file content differs.' "$($pair.left) <-> $($pair.right)" $key
            }
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'mirror-drift' 'PASS' 'KNOWN_MIRRORS_EQUIVALENT' 'Known source/mirror pairs are equivalent by SHA256.' '' ''
    }
    return $findings
}

function Test-StaleCurrentDocs([string] $Root) {
    $findings = @()
    $excluded = @(
        'wiki/Roadmap-History.md',
        'wiki/Lessons.md',
        'wiki/Memory.md',
        'wiki/Memory-Index.md'
    )
    $files = @('README.md', 'AI-START-HERE.md') + @(Get-ChildItem -LiteralPath (Join-Path $Root 'wiki') -File -Filter *.md | ForEach-Object { Get-RelPath -Base $Root -Path $_.FullName })
    foreach ($rel in $files | Sort-Object -Unique) {
        if ($excluded -contains $rel) { continue }
        $full = Join-Path $Root ($rel -replace '/', '\')
        if (!(Test-Path -LiteralPath $full)) { continue }
        $text = Get-Content -LiteralPath $full -Raw
        foreach ($m in [regex]::Matches($text, '[A-Z]:\\[A-Za-z0-9_.$()\\ /-]+')) {
            $findings += New-XCSVGuardrailFinding 'stale-path-version-docs' 'WARN' 'ABSOLUTE_PATH_IN_CURRENT_DOC_CANDIDATE' 'Current documentation contains a machine-local absolute path candidate.' $rel $m.Value.Trim()
        }
        foreach ($m in [regex]::Matches($text, '(?i)\b(?:pid|build id|build|run)\s*[:#]?\s*[0-9]{4,}\b')) {
            $findings += New-XCSVGuardrailFinding 'stale-path-version-docs' 'WARN' 'VOLATILE_RUNTIME_IDENTIFIER_CANDIDATE' 'Current documentation contains a volatile runtime/build identifier candidate.' $rel $m.Value.Trim()
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'stale-path-version-docs' 'PASS' 'NO_STALE_PATH_VERSION_CANDIDATES' 'No stale absolute path/runtime identifier candidates found in current docs.' '' ''
    }
    return $findings
}

function Test-ColdRehydrationResponse([string] $ResponseText) {
    $requirements = [ordered]@{
        identity = 'x-cessive/XCSV'
        ai_start = 'AI / AGENT START HERE|AI-START-HERE.md'
        ownership = 'canonical for|owns|repository ownership'
        not_own = 'NOT canonical|not canonical|does NOT own|not own'
        member_routing = 'XCSV_GUARD|XCSV_ADDONS|XCSV_ORCH|Exile'
        docs_authority = 'wiki/|docs/wiki|generated'
        freshness = 'UNKNOWN|NOT_REVERIFIED|freshness|current-state'
        system_components = 'System Components|registry/components.json'
        roadmap_boundary = 'Roadmap.*intent|intent.*Roadmap|Roadmap.*evidence'
        history_boundary = 'Roadmap-History|historical'
        completion = 'completion|DOC_IMPACT|COMPLETION_IMPACT'
        stop_condition = 'stop|refuse|do not proceed'
    }
    $findings = @()
    if ($ResponseText -match 'SOVRAN Command Deck|the-stack' -and $ResponseText -notmatch 'x-cessive/XCSV') {
        $findings += New-XCSVGuardrailFinding 'cold-rehydration-transcript-validator' 'FAIL' 'WRONG_REPOSITORY_CONTEXT' 'Cold worker response appears anchored to unrelated Command Deck/the-stack context.' '' ''
    }
    foreach ($key in $requirements.Keys) {
        if ($ResponseText -notmatch $requirements[$key]) {
            $findings += New-XCSVGuardrailFinding 'cold-rehydration-transcript-validator' 'FAIL' 'COLD_REHYDRATION_REQUIREMENT_MISSING' "Fresh worker response did not demonstrate $key." '' $requirements[$key]
        }
    }
    if ($findings.Count -eq 0) {
        $findings += New-XCSVGuardrailFinding 'cold-rehydration-transcript-validator' 'PASS' 'COLD_REHYDRATION_RESPONSE_ACCEPTED' 'Response demonstrates required XCSV bootstrap discoveries.' '' ''
    }
    return $findings
}

function Invoke-XCSVRepositoryGuardrails([string] $Root, [string] $OrchRoot = '', [string] $Mode = 'CI_SAFE_SOURCE_CHECK', [string] $ColdResponsePath = '', [bool] $RequireMemberSources = $false) {
    $rootObservation = Get-GitSourceObservation -Path $Root -ExpectedRepo 'x-cessive/XCSV' -Required $true
    $observations = [ordered]@{ xcsv = $rootObservation }

    $memberMap = [ordered]@{
        addons = 'x-cessive/XCSV_ADDONS'
        catalogue = 'x-cessive/Exile'
        guard = 'x-cessive/XCSV_GUARD'
    }
    foreach ($rel in $memberMap.Keys) {
        $expected = Get-ExpectedGitlinkSha $Root $rel
        $observations[$rel] = Get-GitSourceObservation -Path (Join-Path $Root $rel) -ExpectedRepo $memberMap[$rel] -ExpectedGitlinkSha $expected
    }
    if (![string]::IsNullOrWhiteSpace($OrchRoot)) {
        $observations['orch'] = Get-GitSourceObservation -Path $OrchRoot -ExpectedRepo 'x-cessive/XCSV_ORCH'
    } else {
        $observations['orch'] = [pscustomobject][ordered]@{
            repository = 'x-cessive/XCSV_ORCH'
            path = $null
            result = 'NOT_REVERIFIED'
            sha = $null
            expected_gitlink_sha = $null
            clean = $null
            detail = 'Explicit ORCH source was not supplied; ORCH completeness is not refreshed.'
        }
    }

    $findings = @()
    if ($rootObservation.result -ne 'VERIFIED_AT_OBSERVATION') {
        $findings += New-XCSVGuardrailFinding 'source-observation' 'FAIL' 'XCSV_SOURCE_NOT_VERIFIED' 'XCSV source preflight did not verify a clean source root.' $Root $rootObservation.detail
    }

    $sourceReady = ($rootObservation.result -eq 'VERIFIED_AT_OBSERVATION')
    foreach ($key in @('addons', 'catalogue', 'guard')) {
        if ($observations[$key].result -ne 'VERIFIED_AT_OBSERVATION') {
            $severity = $(if ($RequireMemberSources) { 'FAIL' } else { 'UNKNOWN' })
            $findings += New-XCSVGuardrailFinding 'source-observation' $severity 'MEMBER_SOURCE_NOT_VERIFIED' "Member source $key was not verified; member enumeration is not authoritative." $key $observations[$key].detail
            $sourceReady = $false
        }
    }

    if ($sourceReady) {
        $missionRoot = Join-Path $Root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
        $serverAddonsRoot = Join-Path $Root 'catalogue/LiveSource/server-addons'
        $findings += Test-RegistryCompleteness -Root $Root -OrchRoot ($(if ($observations['orch'].result -eq 'VERIFIED_AT_OBSERVATION') { $OrchRoot } else { '' }))
        $findings += Test-CfgExileCustomCode -MissionRoot $missionRoot
        $findings += Test-NetworkMessages -MissionRoot $missionRoot -ServerAddonsRoot $serverAddonsRoot
        $findings += Test-XM8Ui -MissionRoot $missionRoot
        $findings += Test-InitEventScheduler -MissionRoot $missionRoot -ServerAddonsRoot $serverAddonsRoot
        $findings += Test-TraderEconomy -MissionRoot $missionRoot
        $findings += Test-XCSVAddonsMirrorDrift -Root $Root
    }

    if ($Mode -eq 'LIVE_DEPLOY_VERIFY') {
        $findings += New-XCSVGuardrailFinding 'server-addon-artifact-manifest' 'UNKNOWN' 'LIVE_DEPLOY_VERIFY_NOT_IMPLEMENTED_WITHOUT_EXPLICIT_SOURCE' 'Live deployment/PBO verification requires an explicit live server artifact source and is not inferred from Git.' '' ''
    } else {
        $findings += New-XCSVGuardrailFinding 'server-addon-artifact-manifest' 'UNKNOWN' 'LIVE_DEPLOY_NOT_REVERIFIED' 'CI-safe source checks do not inspect deployed PBOs or live server artifacts.' '' ''
    }

    $findings += Test-StaleCurrentDocs -Root $Root

    if (![string]::IsNullOrWhiteSpace($ColdResponsePath) -and (Test-Path -LiteralPath $ColdResponsePath)) {
        $findings += Test-ColdRehydrationResponse -ResponseText (Get-Content -LiteralPath $ColdResponsePath -Raw)
        $findings += New-XCSVGuardrailFinding 'cold-rehydration-launcher' 'UNKNOWN' 'COLD_REHYDRATION_LAUNCHER_BLOCKED' 'A transcript was validated, but this run did not prove a repository-anchored fresh-worker launch.' '' 'TRANSCRIPT_VALIDATOR is separate from FRESH_WORKER_LAUNCHER.'
    } else {
        $findings += New-XCSVGuardrailFinding 'cold-rehydration-transcript-validator' 'UNKNOWN' 'TRANSCRIPT_NOT_SUPPLIED' 'No fresh-worker transcript was supplied; transcript validator was not exercised.' '' ''
        $findings += New-XCSVGuardrailFinding 'cold-rehydration-launcher' 'UNKNOWN' 'COLD_REHYDRATION_LAUNCHER_BLOCKED' 'No admitted deterministic fresh-worker launcher is available in this CI-safe path. Harness did not manufacture PASS.' '' 'effective instruction must be exactly: Read the repo.'
    }

    [pscustomobject][ordered]@{
        tool = 'xcsv-repository-guardrails'
        mode = $Mode
        sourceReady = $sourceReady
        member_sources_required = $RequireMemberSources
        member_dependent_audits_executed = @($findings | Where-Object { @('registry-completeness', 'cfgexilecustomcode', 'network-messages', 'xm8-ui', 'init-event-scheduler', 'trader-economy', 'mirror-drift') -contains $_.check } | Select-Object -ExpandProperty check -Unique)
        cold_rehydration = [pscustomobject][ordered]@{
            transcript_validator = $(if (![string]::IsNullOrWhiteSpace($ColdResponsePath) -and (Test-Path -LiteralPath $ColdResponsePath)) { 'VERIFIED_BY_SUPPLIED_TRANSCRIPT' } else { 'NOT_REVERIFIED' })
            fresh_worker_launcher = 'UNKNOWN_BLOCKED'
            end_to_end_pass = $false
        }
        observations = $observations
        findings = @($findings)
        summary = [pscustomobject][ordered]@{
            pass = @($findings | Where-Object severity -eq 'PASS').Count
            warn = @($findings | Where-Object severity -eq 'WARN').Count
            fail = @($findings | Where-Object severity -eq 'FAIL').Count
            unknown = @($findings | Where-Object severity -eq 'UNKNOWN').Count
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $report = Invoke-XCSVRepositoryGuardrails -Root $Root -OrchRoot $OrchRoot -Mode $Mode -ColdResponsePath $ColdResponsePath -RequireMemberSources:$RequireMemberSources
    if ($Json) {
        $report | ConvertTo-Json -Depth 12
    } else {
        Write-Output "XCSV repository guardrails: $($report.mode)"
        Write-Output ("PASS={0} WARN={1} FAIL={2} UNKNOWN={3}" -f $report.summary.pass, $report.summary.warn, $report.summary.fail, $report.summary.unknown)
        foreach ($f in $report.findings) {
            Write-Output ("{0,-7} {1,-28} {2} {3}" -f $f.severity, $f.check, $f.code, $f.path)
            if ($f.detail) { Write-Output ("        " + $f.detail) }
            if ($f.evidence) { Write-Output ("        evidence: " + $f.evidence) }
        }
    }
    if ($FailOnFindings -and @($report.findings | Where-Object severity -eq 'FAIL').Count -gt 0) { exit 1 }
    exit 0
}
