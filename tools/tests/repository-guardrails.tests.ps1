$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\xcsv-repository-guardrails.ps1')

$script:Failures = New-Object System.Collections.Generic.List[string]

function Assert-True([bool] $Condition, [string] $Message) {
    if (!$Condition) { $script:Failures.Add($Message) }
}

function New-TestRoot([string] $Name) {
    $root = Join-Path ([IO.Path]::GetTempPath()) ("xcsv-guardrails-" + $Name + "-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $root | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'registry') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'wiki') | Out-Null
    return $root
}

function Write-Registry([string] $Root, [string[]] $Paths) {
    $components = @()
    $i = 0
    foreach ($path in $Paths) {
        $i++
        $components += [pscustomobject][ordered]@{
            component_id = "TEST-$i"
            name = "test-$i"
            family = "test"
            kind = "OTHER"
            repo = "x-cessive/XCSV"
            canonical_path = $path
            ownership = "XCSV"
            status = "UNKNOWN"
            runtime_authority = "UNKNOWN"
            evidence = [pscustomobject][ordered]@{
                catalogue_present = $true
                source_wired = $false
                packed_artifact_present = $null
                deployed_present = $null
                boot_evidence = $null
                player_runtime_evidence = $null
                detail = @("fixture")
            }
            refactor_action = "UNKNOWN"
            verdict = "fixture"
        }
    }
    [pscustomobject][ordered]@{
        registry_version = 'fixture'
        classification = 'PARTIAL_SOURCE_VERIFIED'
        components = $components
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $Root 'registry/components.json') -Encoding UTF8
}

function New-File([string] $Path, [string] $Text = '') {
    $dir = Split-Path -Parent $Path
    if (!(Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -LiteralPath $Path -Value $Text -Encoding UTF8
}

function Invoke-GuardrailProcess([string[]] $ProcessArgs) {
    $scriptPath = (Resolve-Path (Join-Path $PSScriptRoot '..\xcsv-repository-guardrails.ps1')).Path
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @ProcessArgs 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    [pscustomobject]@{
        exit_code = $exitCode
        output = @($output)
    }
}

function Invoke-RepoScriptProcess([string] $Root, [string] $ScriptRel, [string[]] $ProcessArgs = @()) {
    $scriptPath = Join-Path $Root ($ScriptRel -replace '/', '\')
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @ProcessArgs 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    [pscustomobject]@{
        exit_code = $exitCode
        output = @($output)
    }
}

function New-DocsFixtureRoot([string] $Name) {
    $sourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $root = New-TestRoot $Name
    foreach ($dir in @('.github', 'registry', 'wiki', 'docs\wiki', 'tools')) {
        $target = Join-Path $root $dir
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        Copy-Item -LiteralPath (Join-Path $sourceRoot $dir) -Destination $target -Recurse -Force
    }
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'README.md') -Destination (Join-Path $root 'README.md') -Force
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'AI-START-HERE.md') -Destination (Join-Path $root 'AI-START-HERE.md') -Force
    & git -C $root init | Out-Null
    & git -C $root add README.md AI-START-HERE.md .github registry wiki docs tools | Out-Null
    & git -C $root -c user.name=test -c user.email=test@example.com commit -m docs-fixture | Out-Null
    return $root
}

try {
    $root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $workflowPath = Join-Path $root '.github/workflows/ai-contract-drift.yml'
    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    $requiredPaths = @(
        '.gitmodules',
        'addons',
        'addons/**',
        'catalogue',
        'catalogue/**',
        'guard',
        'guard/**',
        'README.md',
        'wiki/**',
        'tools/build-component-inventory.ps1',
        'tools/build-docs.ps1',
        'tools/check-doc-links.ps1',
        'tools/check-docs-generated.ps1',
        'tools/xcsv-repository-guardrails.ps1',
        'registry/components.json',
        'tools/tests/**',
        '.github/workflows/ai-contract-drift.yml'
    )
    foreach ($path in $requiredPaths) {
        $quoted = "'" + $path + "'"
        Assert-True (([regex]::Matches($workflow, [regex]::Escape($quoted))).Count -ge 2) "workflow trigger paths include $path for push/main and pull_request"
    }
    foreach ($path in @('AI-START-HERE.md', 'AI-PROVENANCE.md', 'CLAUDE.md', 'AGENTS.md', 'opencode.json', '.agents/rules/**', 'wiki/AI-Start-Here.md', 'wiki/AI-Provenance-and-Doc-Sync.md', 'wiki/AI-Tooling.md')) {
        $quoted = "'" + $path + "'"
        Assert-True (([regex]::Matches($workflow, [regex]::Escape($quoted))).Count -ge 2) "workflow preserves AI-contract trigger path $path"
    }
    Assert-True ($workflow.Contains('git config --global --unset-all $rewriteKey')) 'workflow scrubs credential-bearing Git URL rewrite after member checkout'
    Assert-True ($workflow.Contains("Verify member checkout credential scrubbed")) 'workflow verifies credential scrub before repository-controlled scripts run'
    Assert-True ($workflow.IndexOf('Verify member checkout credential scrubbed') -lt $workflow.IndexOf('Repository guardrail regression suite')) 'credential scrub verification runs before repository-controlled guardrail tests'
    Assert-True ($workflow.Contains('x-access-token') -and $workflow.Contains('Credential-bearing Git URL rewrite')) 'workflow asserts no credential-bearing x-access-token rewrite remains'
    Assert-True ($workflow.Contains('tools/build-docs.ps1') -and $workflow.Contains('tools\check-docs-generated.ps1') -and $workflow.Contains('tools\check-doc-links.ps1')) 'workflow wires existing documentation guardrail tools'
    Assert-True ($workflow.IndexOf('CI-safe repository guardrail audit') -lt $workflow.IndexOf('Documentation generation and link guardrails')) 'source audit runs before generated-doc checks can dirty docs/wiki'
    Assert-True (!$workflow.Contains('.\tools\build-docs.ps1 -Root $PWD')) 'workflow does not pre-dirty docs/wiki before check-docs-generated.ps1'
}
finally {
}

try {
    $root = New-DocsFixtureRoot 'docs-pass'
    $generated = Invoke-RepoScriptProcess -Root $root -ScriptRel 'tools/check-docs-generated.ps1' -ProcessArgs @('-Root', $root)
    $links = Invoke-RepoScriptProcess -Root $root -ScriptRel 'tools/check-doc-links.ps1' -ProcessArgs @('-Root', $root)
    Assert-True ($generated.exit_code -eq 0) 'synchronized generated docs pass check-docs-generated.ps1'
    Assert-True ($links.exit_code -eq 0) 'synchronized documentation links pass check-doc-links.ps1'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-DocsFixtureRoot 'docs-drift'
    Add-Content -LiteralPath (Join-Path $root 'docs/wiki/Home.md') -Value "`nmanual generated-doc drift" -Encoding UTF8
    $generated = Invoke-RepoScriptProcess -Root $root -ScriptRel 'tools/check-docs-generated.ps1' -ProcessArgs @('-Root', $root)
    Assert-True ($generated.exit_code -ne 0) 'generated-doc drift fails check-docs-generated.ps1'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-DocsFixtureRoot 'docs-link'
    Add-Content -LiteralPath (Join-Path $root 'README.md') -Value "`n[broken](wiki/Definitely-Missing.md)" -Encoding UTF8
    $links = Invoke-RepoScriptProcess -Root $root -ScriptRel 'tools/check-doc-links.ps1' -ProcessArgs @('-Root', $root)
    Assert-True ($links.exit_code -ne 0) 'broken internal documentation link fails check-doc-links.ps1'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-DocsFixtureRoot 'docs-marker'
    $homePath = Join-Path $root 'docs/wiki/Home.md'
    $text = Get-Content -LiteralPath $homePath -Raw
    $text = $text -replace '<!-- GENERATED FROM wiki/Home.md BY tools/build-docs.ps1\. DO NOT EDIT docs/wiki BY HAND\. -->', '<!-- marker removed -->'
    Set-Content -LiteralPath $homePath -Value $text -Encoding UTF8
    $generated = Invoke-RepoScriptProcess -Root $root -ScriptRel 'tools/check-docs-generated.ps1' -ProcessArgs @('-Root', $root)
    Assert-True ($generated.exit_code -ne 0) 'missing generated-doc marker fails generated-doc equivalence check'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-TestRoot 'completeness'
    New-Item -ItemType Directory -Path (Join-Path $root 'catalogue/Addons/FooAddon') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'catalogue/Scripts/FooScript') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'addons/mission/xcsv/FooMission') -Force | Out-Null
    Write-Registry $root @('catalogue/Addons/FooAddon', 'catalogue/Scripts/FooScript')
    $findings = Test-RegistryCompleteness -Root $root
    Assert-True (@($findings | Where-Object code -eq 'MISSING_COMPONENT_REGISTRY_ENTRY' | Where-Object path -eq 'addons/mission/xcsv/FooMission').Count -eq 1) 'registry completeness reports missing XCSV_ADDONS mission surface'
    Write-Registry $root @('catalogue/Addons/FooAddon', 'catalogue/Scripts/FooScript', 'addons/mission/xcsv/FooMission')
    $findings = Test-RegistryCompleteness -Root $root
    Assert-True (@($findings | Where-Object severity -eq 'FAIL').Count -eq 0) 'registry completeness passes once all enumerated surfaces are represented'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-TestRoot 'override'
    $mission = Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    New-File (Join-Path $mission 'config.cpp') @'
class CfgExileCustomCode
{
    ExileClient_object_player_event_onInventoryOpened = "overrides\one.sqf";
    ExileClient_object_player_event_onInventoryOpened = "overrides\two.sqf";
    ExileServer_system_process_preInit = "..\outside.sqf";
    ExileServer_system_process_postInit = "overrides\missing.sqf";
};
'@
    New-File (Join-Path $mission 'overrides/one.sqf') ''
    New-File (Join-Path $mission 'overrides/ExileClient_unregistered.sqf') ''
    $findings = Test-CfgExileCustomCode -MissionRoot $mission
    Assert-True (@($findings | Where-Object code -eq 'DUPLICATE_OVERRIDE_DECLARATION').Count -eq 1) 'CfgExileCustomCode detects duplicate override declarations'
    Assert-True (@($findings | Where-Object code -eq 'OVERRIDE_OUTSIDE_EXPECTED_CUSTODY').Count -eq 1) 'CfgExileCustomCode detects out-of-custody replacement paths'
    Assert-True (@($findings | Where-Object code -eq 'MISSING_OVERRIDE_FILE').Count -ge 1) 'CfgExileCustomCode detects missing replacement files'
    Assert-True (@($findings | Where-Object code -eq 'UNREGISTERED_OVERRIDE_CANDIDATE').Count -eq 1) 'CfgExileCustomCode detects unregistered override candidates'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-TestRoot 'network'
    $mission = Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    $server = Join-Path $root 'catalogue/LiveSource/server-addons'
    New-File (Join-Path $mission 'config.cpp') @'
class CfgNetworkMessages
{
    class xcsvFooRequest { module = "system_xcsv"; };
    class xcsvFooRequest { module = "system_xcsv"; };
};
'@
    New-File (Join-Path $server 'xcsv_test/fn.sqf') 'ExileServer_system_xcsv_network_staleHandler = {};'
    $findings = Test-NetworkMessages -MissionRoot $mission -ServerAddonsRoot $server
    Assert-True (@($findings | Where-Object code -eq 'DUPLICATE_CFGNETWORKMESSAGE').Count -eq 1) 'network audit detects duplicate message declarations'
    Assert-True (@($findings | Where-Object code -eq 'MISSING_NETWORK_HANDLER').Count -ge 1) 'network audit detects missing handlers for implemented modules'
    Assert-True (@($findings | Where-Object code -eq 'STALE_NETWORK_HANDLER_CANDIDATE').Count -ge 1) 'network audit detects stale handler candidates'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-TestRoot 'xm8'
    $mission = Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    New-File (Join-Path $mission 'config.cpp') @'
class CfgXM8
{
    class A { appID = "dup"; controlID = 101; };
    class B { appID = "dup"; controlID = 101; };
};
class SomeControl { idc = 101; };
class OtherControl { idc = 101; };
'@
    $findings = Test-XM8Ui -MissionRoot $mission
    Assert-True (@($findings | Where-Object code -eq 'DUPLICATE_XM8_APP_ID').Count -eq 1) 'XM8 audit detects duplicate app IDs'
    Assert-True (@($findings | Where-Object code -eq 'DUPLICATE_IDC').Count -ge 1) 'XM8 audit detects duplicate positive IDCs'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-TestRoot 'xm8-mapping'
    $mission = Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    New-File (Join-Path $mission 'config.cpp') @'
class CfgXM8
{
    class A { appID = "App01"; controlID = 9001; };
    class B { appID = "xcsvMissing"; controlID = 9002; };
};
class XM8_App01_Button { resource = "RscApp01"; };
'@
    $findings = Test-XM8Ui -MissionRoot $mission
    Assert-True (@($findings | Where-Object { $_.code -match 'SOURCE|MAPPING' -and $_.evidence -eq 'App01' }).Count -eq 0) 'XM8 audit does not warn solely because AppXX lacks a same-name source directory'
    Assert-True (@($findings | Where-Object code -eq 'XM8_REGISTERED_APP_MAPPING_NOT_PROVEN' | Where-Object evidence -eq 'xcsvMissing').Count -eq 1) 'XM8 audit warns when XCSV app mapping cannot be proven from config/source evidence'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-TestRoot 'init-precision'
    $mission = Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    New-File (Join-Path $mission 'R3F_LOG/addons_config/logistics_config_maker_tool/readme.txt') 'Example text says execVM "tool.sqf"; but this is documentation.'
    New-File (Join-Path $mission 'init.sqf') '[] execVM "real_hook.sqf";'
    $findings = Test-InitEventScheduler -MissionRoot $mission -ServerAddonsRoot (Join-Path $root 'catalogue/LiveSource/server-addons')
    Assert-True (@($findings | Where-Object path -match 'readme\.txt').Count -eq 0) 'init/event audit ignores README text mentioning execVM'
    Assert-True (@($findings | Where-Object { $_.path -match 'init\.sqf' -and $_.code -eq 'INIT_EVENT_SCHEDULER_CANDIDATE' }).Count -eq 1) 'init/event audit detects executable SQF hook'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-TestRoot 'trader-precision'
    $mission = Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa'
    $sqm = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt 67; $i++) {
        [void]$sqm.AppendLine("class Item$i {};")
        [void]$sqm.AppendLine("class Item$i {};")
    }
    New-File (Join-Path $mission 'mission.sqm') $sqm.ToString()
    New-File (Join-Path $mission 'config.cpp') @'
class CfgTraderCategories
{
    class VehicleTrader {};
    class VehicleTrader {};
};
'@
    $findings = Test-TraderEconomy -MissionRoot $mission
    Assert-True (@($findings | Where-Object { $_.code -eq 'DUPLICATE_TRADER_ECONOMY_CLASS_CANDIDATE' -and $_.detail -match 'Item\d+' }).Count -eq 0) 'trader/economy audit ignores generic mission.sqm Item classes'
    Assert-True (@($findings | Where-Object { $_.code -eq 'DUPLICATE_TRADER_ECONOMY_CLASS_CANDIDATE' -and $_.detail -match 'VehicleTrader' }).Count -eq 1) 'trader/economy audit detects actual duplicate economy authority class'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

try {
    $root = New-TestRoot 'docs'
    New-File (Join-Path $root 'README.md') 'Current doc mentions D:\XCSV, E:\arma3server, D:\Old\Runtime and build 12345.'
    New-File (Join-Path $root 'wiki/Roadmap-History.md') 'HISTORICAL EVIDENCE D:\Old\Runtime build 12345.'
    New-File (Join-Path $root 'wiki/Home.md') 'Current home without stale paths.'
    $findings = Test-StaleCurrentDocs -Root $root
    Assert-True (@($findings | Where-Object code -eq 'OBSOLETE_ABSOLUTE_PATH_CANDIDATE' | Where-Object path -eq 'README.md').Count -eq 1) 'stale docs audit flags known-obsolete absolute path'
    Assert-True (@($findings | Where-Object { $_.evidence -eq 'D:\XCSV' -or $_.evidence -eq 'E:\arma3server' }).Count -eq 0) 'stale docs audit does not warn solely for known-valid absolute paths'
    Assert-True (@($findings | Where-Object path -eq 'wiki/Roadmap-History.md').Count -eq 0) 'stale docs audit excludes historical Roadmap History'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

$badCold = Test-ColdRehydrationResponse -ResponseText 'SOVRAN Command Deck should read the-stack CONTROL.md.'
Assert-True (@($badCold | Where-Object code -eq 'WRONG_REPOSITORY_CONTEXT').Count -eq 1) 'cold harness rejects unrelated Command Deck context'

$goodCold = Test-ColdRehydrationResponse -ResponseText @'
x-cessive/XCSV. AI / AGENT START HERE is AI-START-HERE.md. XCSV is canonical for hub routing and wiki/docs, and not canonical for runtime.
Members route to XCSV_GUARD, XCSV_ADDONS, XCSV_ORCH and Exile. Canonical docs are wiki/ and docs/wiki is generated.
registry/current-state.json preserves freshness and UNKNOWN / NOT_REVERIFIED. System Components lives in registry/components.json.
Roadmap is planning intent, not runtime evidence. Roadmap-History is historical. Completion requires DOC_IMPACT and COMPLETION_IMPACT. Stop if identity is wrong.
'@
Assert-True (@($goodCold | Where-Object severity -eq 'FAIL').Count -eq 0) 'cold harness accepts response that demonstrates XCSV bootstrap discoveries'

try {
    $badTranscript = Join-Path ([IO.Path]::GetTempPath()) ("xcsv-cold-bad-" + [guid]::NewGuid().ToString('N') + ".txt")
    Set-Content -LiteralPath $badTranscript -Value 'SOVRAN Command Deck should read the-stack CONTROL.md.' -Encoding UTF8
    $process = Invoke-GuardrailProcess @('-Root', (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path, '-ColdResponsePath', $badTranscript, '-FailOnFindings')
    Assert-True ($process.exit_code -ne 0) 'process enforcement exits non-zero for a deterministic FAIL finding'
}
finally {
    if ($badTranscript -and (Test-Path -LiteralPath $badTranscript)) { Remove-Item -LiteralPath $badTranscript -Force }
}

$process = Invoke-GuardrailProcess @('-Root', (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path, '-FailOnFindings')
Assert-True ($process.exit_code -eq 0) 'process enforcement remains successful for WARN and UNKNOWN-only current findings'
Assert-True (($process.output -join "`n") -match 'LIVE_DEPLOY_NOT_REVERIFIED') 'UNKNOWN live deployment evidence is reported but non-fatal in CI_SAFE_SOURCE_CHECK'

try {
    $root = New-TestRoot 'missing-member-process'
    & git -C $root init | Out-Null
    & git -C $root remote add origin https://github.com/x-cessive/XCSV.git
    New-File (Join-Path $root 'registry/components.json') '{"registry_version":"fixture","classification":"PARTIAL_SOURCE_VERIFIED","components":[]}'
    New-File (Join-Path $root 'README.md') 'fixture'
    & git -C $root add registry/components.json README.md | Out-Null
    & git -C $root -c user.name=test -c user.email=test@example.com commit -m init | Out-Null
    $process = Invoke-GuardrailProcess @('-Root', $root, '-RequireMemberSources', '-FailOnFindings')
    Assert-True ($process.exit_code -ne 0) 'missing/unverified member source fails enforcement when CI requires members'
    Assert-True (($process.output -join "`n") -match 'MEMBER_SOURCE_NOT_VERIFIED') 'missing member source does not produce a false healthy audit'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

$report = Invoke-XCSVRepositoryGuardrails -Root (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path -RequireMemberSources $true
$requiredAudits = @('registry-completeness', 'cfgexilecustomcode', 'network-messages', 'xm8-ui', 'init-event-scheduler', 'trader-economy', 'mirror-drift')
foreach ($audit in $requiredAudits) {
    Assert-True (@($report.member_dependent_audits_executed | Where-Object { $_ -eq $audit }).Count -eq 1) "verified exact gitlink members execute $audit"
}

try {
    $root = New-TestRoot 'wrong-member'
    & git -C $root init | Out-Null
    & git -C $root remote add origin https://github.com/x-cessive/XCSV.git
    New-File (Join-Path $root 'registry/components.json') '{"registry_version":"fixture","classification":"PARTIAL_SOURCE_VERIFIED","components":[]}'
    New-File (Join-Path $root 'README.md') 'fixture'
    & git -C $root add registry/components.json README.md | Out-Null
    & git -C $root -c user.name=test -c user.email=test@example.com commit -m init | Out-Null
    foreach ($member in @('addons', 'catalogue', 'guard')) {
        $memberRoot = Join-Path $root $member
        New-Item -ItemType Directory -Path $memberRoot | Out-Null
        & git -C $memberRoot init | Out-Null
        & git -C $memberRoot remote add origin https://github.com/wrong/example.git
        New-File (Join-Path $memberRoot 'README.md') 'wrong origin fixture'
        & git -C $memberRoot add README.md | Out-Null
        & git -C $memberRoot -c user.name=test -c user.email=test@example.com commit -m init | Out-Null
    }
    $report = Invoke-XCSVRepositoryGuardrails -Root $root -RequireMemberSources $true
    Assert-True (@($report.findings | Where-Object { $_.code -eq 'MEMBER_SOURCE_NOT_VERIFIED' -and $_.severity -eq 'FAIL' }).Count -eq 3) 'wrong member origins fail closed under required-member enforcement'
    Assert-True ($report.sourceReady -eq $false) 'wrong member origins block authoritative member-dependent audit execution'
}
finally {
    if ($root -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
}

if ($script:Failures.Count -gt 0) {
    Write-Output "repository-guardrails.tests: FAIL"
    foreach ($failure in $script:Failures) { Write-Output " - $failure" }
    exit 1
}

Write-Output "repository-guardrails.tests: PASS"
exit 0
