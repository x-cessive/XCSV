<#
    component-inventory.tests.ps1 - focused regressions for issue #30 inventory evidence precision.
#>

[CmdletBinding()]
param([switch] $Quiet)

$ErrorActionPreference = 'Stop'

$ToolsDir = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent $ToolsDir
$Generator = Join-Path $ToolsDir 'build-component-inventory.ps1'

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

function Assert-True {
    param([bool] $Condition, [string] $Because = '')
    if (-not $Condition) { throw ("assertion failed {0}" -f $Because) }
}

function Assert-Equal {
    param($Expected, $Actual, [string] $Because = '')
    if ($Expected -ne $Actual) {
        throw ("expected [{0}] but got [{1}] {2}" -f $Expected, $Actual, $Because)
    }
}

function New-Fixture {
    $root = Join-Path $env:TEMP ('xcsv-component-inventory-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    foreach ($dir in @(
        'registry',
        'wiki',
        'catalogue/Addons',
        'catalogue/Scripts',
        'catalogue/LiveSource/mpmissions/Exile.Tanoa/custom',
        'catalogue/LiveSource/mpmissions/Exile.Tanoa/unusedPresence',
        'catalogue/LiveSource/server-addons/xcsv_chatter',
        'addons/.agents',
        'addons/mission/xcsv',
        'addons/xcsv_chatter/bootstrap'
    )) {
        New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null
    }

    Set-Content -LiteralPath (Join-Path $root 'catalogue/Addons/findBuildings.sqf') -Value 'not database' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/Scripts/deadBodies.sqf') -Value 'not database' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/Addons/schema.sql') -Value 'create table x(id int);' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa/init.sqf') -Value '[] execVM "custom\wired.sqf";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa/custom/wired.sqf') -Value 'systemChat "wired";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa/unusedPresence/unused.sqf') -Value 'systemChat "present only";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/LiveSource/server-addons/xcsv_chatter/config.cpp') -Value 'class CfgFunctions { class XCSV { class bootstrap { class postInit { postInit = 1; }; }; }; };' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'addons/README.md') -Value '# docs only' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'addons/AGENTS.md') -Value '# governance' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'addons/AI-START-HERE.md') -Value '# bootstrap' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'addons/CLAUDE.md') -Value '# adapter' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'addons/xcsv_chatter/config.cpp') -Value 'class CfgFunctions { class XCSV {}; };' -Encoding UTF8

    git -C $root init | Out-Null
    git -C $root config user.email test@example.invalid | Out-Null
    git -C $root config user.name 'XCSV Test' | Out-Null
    git -C $root remote add origin https://github.com/x-cessive/XCSV.git | Out-Null
    git -C $root add . | Out-Null
    git -C $root commit -m 'fixture source' | Out-Null
    return $root
}

Write-Host ''
Write-Host 'XCSV component inventory generator' -ForegroundColor Cyan

$fixture = New-Fixture
try {
    powershell -NoProfile -ExecutionPolicy Bypass -File $Generator -Root $fixture -ObservedAtUtc '2026-08-21T03:00:00Z' | Out-Null
    $registry = Get-Content -Raw -LiteralPath (Join-Path $fixture 'registry/components.json') | ConvertFrom-Json

    Test-Case 'unrelated names containing db letter sequence are not DATABASE' {
        $falseDb = @($registry.components | Where-Object {
            $_.kind -eq 'DATABASE' -and (
                $_.canonical_path -like '*findBuildings.sqf' -or
                $_.canonical_path -like '*deadBodies.sqf'
            )
        })
        Assert-Equal 0 $falseDb.Count
        $realDb = @($registry.components | Where-Object { $_.kind -eq 'DATABASE' -and $_.canonical_path -like '*schema.sql' })
        Assert-Equal 1 $realDb.Count
    }

    Test-Case 'XCSV_ADDONS governance and docs are not SERVER_ADDON entries' {
        $pollution = @($registry.components | Where-Object {
            $_.kind -eq 'SERVER_ADDON' -and $_.repo -eq 'x-cessive/XCSV_ADDONS' -and (
                $_.canonical_path -like 'addons/README.md' -or
                $_.canonical_path -like 'addons/AGENTS.md' -or
                $_.canonical_path -like 'addons/AI-START-HERE.md' -or
                $_.canonical_path -like 'addons/CLAUDE.md' -or
                $_.canonical_path -like 'addons/.agents*'
            )
        })
        Assert-Equal 0 $pollution.Count
        $runtime = @($registry.components | Where-Object { $_.kind -eq 'SERVER_ADDON' -and $_.canonical_path -eq 'addons/xcsv_chatter' })
        Assert-Equal 1 $runtime.Count
    }

    Test-Case 'presence alone does not imply SOURCE_WIRED' {
        $unused = @($registry.components | Where-Object { $_.canonical_path -eq 'catalogue/LiveSource/mpmissions/Exile.Tanoa/unusedPresence' })[0]
        Assert-True ($null -ne $unused) 'unusedPresence component missing'
        Assert-True ($unused.evidence.source_wired -ne $true) 'presence-only directory must not be SOURCE_WIRED'
    }

    Test-Case 'known concrete wiring promotes SOURCE_WIRED' {
        $init = @($registry.components | Where-Object { $_.canonical_path -eq 'catalogue/LiveSource/mpmissions/Exile.Tanoa/init.sqf' })[0]
        Assert-True ($null -ne $init) 'init.sqf component missing'
        Assert-Equal $true $init.evidence.source_wired
    }
}
finally {
    if (Test-Path -LiteralPath $fixture) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}

Write-Host ''
Write-Host ("Passed: {0}   Failed: {1}" -f $script:Passed, $script:Failed) -ForegroundColor $(if ($script:Failed) { 'Red' } else { 'Green' })
if ($script:Failed -gt 0) {
    Write-Host ''
    Write-Host 'Failures:' -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host ("  " + $f) -ForegroundColor Yellow }
    exit 1
}

Write-Host 'XCSV component inventory generator: PASS' -ForegroundColor Green
exit 0
