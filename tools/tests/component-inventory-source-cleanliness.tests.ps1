<#
    component-inventory-source-cleanliness.tests.ps1 - root and external source cleanliness regressions for issue #30.
#>

[CmdletBinding()]
param([switch] $Quiet)

$ErrorActionPreference = 'Stop'

$ToolsDir = Split-Path -Parent $PSScriptRoot
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

function Initialize-TestGitRepo([string] $Path, [string] $Origin) {
    git -C $Path init | Out-Null
    git -C $Path config user.email test@example.invalid | Out-Null
    git -C $Path config user.name 'XCSV Test' | Out-Null
    git -C $Path remote add origin $Origin | Out-Null
}

function Commit-All([string] $Path, [string] $Message) {
    git -C $Path add . | Out-Null
    git -C $Path commit -m $Message | Out-Null
    return (git -C $Path rev-parse HEAD)
}

function New-XcsvFixture {
    $root = Join-Path $env:TEMP ('xcsv-source-clean-root-' + [guid]::NewGuid().ToString('N'))
    foreach ($dir in @(
        'registry',
        'wiki',
        'tools',
        'addons/mission/xcsv',
        'catalogue/Addons',
        'catalogue/Scripts',
        'catalogue/LiveSource/mpmissions/Exile.Tanoa',
        'catalogue/LiveSource/server-addons',
        'guard/src',
        'guard/tools'
    )) {
        New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null
    }

    Set-Content -LiteralPath (Join-Path $root 'tools/fixture-tool.ps1') -Value 'Write-Output clean' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'addons/mission/xcsv/fn_fixture.sqf') -Value 'systemChat "addon";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/Addons/schema.sql') -Value 'create table x(id int);' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/Scripts/script.sqf') -Value 'systemChat "script";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa/init.sqf') -Value 'systemChat "init";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'guard/src/main.rs') -Value 'fn main() {}' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'guard/tools/doctor.ps1') -Value 'Write-Output doctor' -Encoding UTF8

    Initialize-TestGitRepo (Join-Path $root 'addons') 'https://github.com/x-cessive/XCSV_ADDONS.git'
    [void](Commit-All (Join-Path $root 'addons') 'addons fixture')
    Initialize-TestGitRepo (Join-Path $root 'catalogue') 'https://github.com/x-cessive/Exile.git'
    [void](Commit-All (Join-Path $root 'catalogue') 'catalogue fixture')
    Initialize-TestGitRepo (Join-Path $root 'guard') 'https://github.com/x-cessive/XCSV_GUARD.git'
    [void](Commit-All (Join-Path $root 'guard') 'guard fixture')

    Initialize-TestGitRepo $root 'https://github.com/x-cessive/XCSV.git'
    [void](Commit-All $root 'xcsv fixture')
    return $root
}

function New-OrchFixture {
    $root = Join-Path $env:TEMP ('xcsv-source-clean-orch-' + [guid]::NewGuid().ToString('N'))
    foreach ($dir in @('src', 'tools', 'tests')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $root 'src/xcsv-controller.ps1') -Value 'Write-Output controller' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'tools/deploy.ps1') -Value 'Write-Output deploy' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'tests/xcsv-regression.ps1') -Value 'Write-Output regression' -Encoding UTF8
    Initialize-TestGitRepo $root 'https://github.com/x-cessive/XCSV_ORCH.git'
    [void](Commit-All $root 'orch fixture')
    return $root
}

function Invoke-InventoryProcess([string] $Root, [string] $OrchRoot = $null) {
    $args = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $Generator,
        '-Root', $Root,
        '-ObservedAtUtc', '2026-08-21T04:20:00Z'
    )
    if (-not [string]::IsNullOrWhiteSpace($OrchRoot)) {
        $args += @('-OrchRoot', $OrchRoot)
    }
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & powershell @args 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output | Out-String)
    }
}

function Invoke-Inventory([string] $Root, [string] $OrchRoot = $null) {
    $result = Invoke-InventoryProcess -Root $Root -OrchRoot $OrchRoot
    if ($result.ExitCode -ne 0) { throw $result.Output }
    return (Get-Content -Raw -LiteralPath (Join-Path $Root 'registry/components.json') | ConvertFrom-Json)
}

Write-Host ''
Write-Host 'XCSV component inventory source cleanliness' -ForegroundColor Cyan

Test-Case 'clean XCSV source is accepted' {
    $root = New-XcsvFixture
    try {
        $registry = Invoke-Inventory $root
        $notes = @($registry.notes) -join "`n"
        $sha = git -C $root rev-parse HEAD
        Assert-True $notes.Contains("XCSV source observation: x-cessive/XCSV@$sha (VERIFIED_AT_OBSERVATION); clean=True") 'clean XCSV source observation missing'
    }
    finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
}

Test-Case 'dirty XCSV source that can affect inventory is blocked' {
    $root = New-XcsvFixture
    try {
        Set-Content -LiteralPath (Join-Path $root 'tools/dirty-source.ps1') -Value 'Write-Output dirty' -Encoding UTF8
        $result = Invoke-InventoryProcess $root
        Assert-True ($result.ExitCode -ne 0) 'dirty XCSV source must fail closed'
        Assert-True ($result.Output.Contains('DIRTY_XCSV_SOURCE')) 'dirty XCSV source must be explicit'
        Assert-True ($result.Output.Contains('dirty_fingerprint=')) 'dirty XCSV source must include fingerprint evidence'
    }
    finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
}

Test-Case 'clean explicit ORCH source is accepted' {
    $root = New-XcsvFixture
    $orch = New-OrchFixture
    try {
        $registry = Invoke-Inventory $root $orch
        $notes = @($registry.notes) -join "`n"
        $sha = git -C $orch rev-parse HEAD
        Assert-True $notes.Contains("XCSV_ORCH external source observation: x-cessive/XCSV_ORCH@$sha (VERIFIED_AT_OBSERVATION); clean=True") 'clean ORCH source observation missing'
    }
    finally {
        foreach ($path in @($root, $orch)) {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
        }
    }
}

Test-Case 'dirty explicit ORCH source is blocked' {
    $root = New-XcsvFixture
    $orch = New-OrchFixture
    try {
        Set-Content -LiteralPath (Join-Path $orch 'src/dirty-orch.ps1') -Value 'Write-Output dirty' -Encoding UTF8
        $result = Invoke-InventoryProcess $root $orch
        Assert-True ($result.ExitCode -ne 0) 'dirty ORCH source must fail closed'
        Assert-True ($result.Output.Contains('DIRTY_EXTERNAL_SOURCE')) 'dirty ORCH source must be explicit'
        Assert-True ($result.Output.Contains('dirty_fingerprint=')) 'dirty ORCH source must include fingerprint evidence'
    }
    finally {
        foreach ($path in @($root, $orch)) {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
        }
    }
}

Test-Case 'generation may update expected generated outputs after successful preflight' {
    $root = New-XcsvFixture
    try {
        [void](Invoke-Inventory $root)
        Add-Content -LiteralPath (Join-Path $root 'registry/components.json') -Value ''
        Add-Content -LiteralPath (Join-Path $root 'wiki/System-Components.md') -Value ''
        $registry = Invoke-Inventory $root
        $notes = @($registry.notes) -join "`n"
        Assert-True $notes.Contains('permitted_generated_dirty=2') 'only generated-output dirtiness should be permitted between runs'
    }
    finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
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

Write-Host 'XCSV component inventory source cleanliness: PASS' -ForegroundColor Green
exit 0
