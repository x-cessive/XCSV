<#
    component-inventory-provenance.tests.ps1 - provenance and reproducibility regressions for issue #30.
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
    $root = Join-Path $env:TEMP ('xcsv-provenance-root-' + [guid]::NewGuid().ToString('N'))
    foreach ($dir in @(
        'registry',
        'wiki',
        'catalogue/Addons',
        'catalogue/Scripts',
        'catalogue/LiveSource/mpmissions/Exile.Tanoa',
        'catalogue/LiveSource/server-addons',
        'addons/mission/xcsv'
    )) {
        New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa/init.sqf') -Value 'systemChat "init";' -Encoding UTF8
    Initialize-TestGitRepo $root 'https://github.com/x-cessive/XCSV.git'
    [void](Commit-All $root 'xcsv fixture')
    return $root
}

function New-OrchFixture {
    $root = Join-Path $env:TEMP ('xcsv-provenance-orch-' + [guid]::NewGuid().ToString('N'))
    foreach ($dir in @('src', 'tools', 'tests')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $root 'src/xcsv-controller.ps1') -Value 'Write-Output controller' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'tools/deploy.ps1') -Value 'Write-Output deploy' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'tests/xcsv-regression.ps1') -Value 'Write-Output test' -Encoding UTF8
    Initialize-TestGitRepo $root 'https://github.com/x-cessive/XCSV_ORCH.git'
    [void](Commit-All $root 'orch fixture')
    return $root
}

function Invoke-Inventory([string] $Root, [string] $OrchRoot = $null) {
    $args = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $Generator,
        '-Root', $Root,
        '-ObservedAtUtc', '2026-08-21T03:30:00Z'
    )
    if (-not [string]::IsNullOrWhiteSpace($OrchRoot)) {
        $args += @('-OrchRoot', $OrchRoot)
    }
    powershell @args | Out-Null
    return (Get-Content -Raw -LiteralPath (Join-Path $Root 'registry/components.json') | ConvertFrom-Json)
}

Write-Host ''
Write-Host 'XCSV component inventory provenance/reproducibility' -ForegroundColor Cyan

Test-Case 'XCSV observation provenance follows the current fixture Git identity' {
    $root = New-XcsvFixture
    try {
        $firstSha = git -C $root rev-parse HEAD
        $first = Invoke-Inventory $root
        Assert-True ((@($first.notes) -join "`n").Contains($firstSha)) 'first generated registry must contain first observed XCSV SHA'

        Set-Content -LiteralPath (Join-Path $root 'catalogue/Addons/provenance-change.sqf') -Value 'systemChat "changed";' -Encoding UTF8
        git -C $root add catalogue/Addons/provenance-change.sqf | Out-Null
        git -C $root commit -m 'advance fixture source' | Out-Null
        $secondSha = git -C $root rev-parse HEAD
        $second = Invoke-Inventory $root
        $secondNotes = @($second.notes) -join "`n"

        Assert-True ($firstSha -ne $secondSha) 'fixture SHA must advance'
        Assert-True $secondNotes.Contains($secondSha) 'second generated registry must contain second observed XCSV SHA'
        Assert-True (-not $secondNotes.Contains($firstSha)) 'second generated registry must not retain old XCSV SHA'
        Assert-True (-not $secondNotes.Contains('38249878de2c03d6f5e2afd4884ee1b5beb9603d')) 'registry must not retain removed hard-coded XCSV SHA'
    }
    finally {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    }
}

Test-Case 'same verified ORCH identity at different paths emits equivalent canonical ORCH entries' {
    $root = New-XcsvFixture
    $orchA = New-OrchFixture
    $orchB = Join-Path $env:TEMP ('xcsv-provenance-orch-clone-' + [guid]::NewGuid().ToString('N'))
    try {
        git clone $orchA $orchB | Out-Null
        git -C $orchB remote set-url origin https://github.com/x-cessive/XCSV_ORCH.git | Out-Null

        $a = Invoke-Inventory $root $orchA
        $b = Invoke-Inventory $root $orchB
        $orchEntriesA = @($a.components | Where-Object { $_.repo -eq 'x-cessive/XCSV_ORCH' -and $_.component_id -ne 'XCSV-ORCH-OBSERVATION-NOT-VERIFIED' } | Sort-Object component_id)
        $orchEntriesB = @($b.components | Where-Object { $_.repo -eq 'x-cessive/XCSV_ORCH' -and $_.component_id -ne 'XCSV-ORCH-OBSERVATION-NOT-VERIFIED' } | Sort-Object component_id)

        Assert-Equal $orchEntriesA.Count $orchEntriesB.Count 'ORCH entry counts should match across paths'
        Assert-True ($orchEntriesA.Count -gt 0) 'ORCH source entries should be generated for verified ORCH source'
        for ($i = 0; $i -lt $orchEntriesA.Count; $i++) {
            Assert-Equal $orchEntriesA[$i].component_id $orchEntriesB[$i].component_id 'component_id should be path-independent'
            Assert-Equal $orchEntriesA[$i].canonical_path $orchEntriesB[$i].canonical_path 'canonical_path should be path-independent'
            Assert-True (-not $orchEntriesA[$i].canonical_path.Contains($orchA.Replace('\','/'))) 'canonical_path must not contain ORCH path A'
            Assert-True (-not $orchEntriesB[$i].canonical_path.Contains($orchB.Replace('\','/'))) 'canonical_path must not contain ORCH path B'
            Assert-True ($orchEntriesA[$i].canonical_path -match '^(src|tools|tests)/') 'canonical_path must be ORCH repository-relative'
        }
    }
    finally {
        foreach ($path in @($root, $orchA, $orchB)) {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
        }
    }
}

Test-Case 'absent unverified ORCH source is explicit and does not masquerade as complete inventory' {
    $root = New-XcsvFixture
    try {
        $registry = Invoke-Inventory $root
        $placeholder = @($registry.components | Where-Object { $_.component_id -eq 'XCSV-ORCH-OBSERVATION-NOT-VERIFIED' })
        $fileEntries = @($registry.components | Where-Object { $_.repo -eq 'x-cessive/XCSV_ORCH' -and $_.component_id -ne 'XCSV-ORCH-OBSERVATION-NOT-VERIFIED' })

        Assert-Equal 1 $placeholder.Count
        Assert-Equal 0 $fileEntries.Count
        Assert-Equal 'EXTERNAL_SOURCE_NOT_REVERIFIED' $placeholder[0].verdict
        Assert-True ((@($registry.notes) -join "`n").Contains('XCSV_ORCH external source observation: NOT_REVERIFIED')) 'registry notes must record ORCH not reverified'
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

Write-Host 'XCSV component inventory provenance/reproducibility: PASS' -ForegroundColor Green
exit 0
