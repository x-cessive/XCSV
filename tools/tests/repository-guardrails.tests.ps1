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
    $root = New-TestRoot 'docs'
    New-File (Join-Path $root 'README.md') 'Current doc mentions D:\Old\Runtime and build 12345.'
    New-File (Join-Path $root 'wiki/Roadmap-History.md') 'HISTORICAL EVIDENCE D:\Old\Runtime build 12345.'
    New-File (Join-Path $root 'wiki/Home.md') 'Current home without stale paths.'
    $findings = Test-StaleCurrentDocs -Root $root
    Assert-True (@($findings | Where-Object code -eq 'ABSOLUTE_PATH_IN_CURRENT_DOC_CANDIDATE' | Where-Object path -eq 'README.md').Count -eq 1) 'stale docs audit flags current absolute path'
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

if ($script:Failures.Count -gt 0) {
    Write-Output "repository-guardrails.tests: FAIL"
    foreach ($failure in $script:Failures) { Write-Output " - $failure" }
    exit 1
}

Write-Output "repository-guardrails.tests: PASS"
exit 0
