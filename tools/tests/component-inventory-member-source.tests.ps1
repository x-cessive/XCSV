<#
    component-inventory-member-source.tests.ps1 - member gitlink provenance regressions for issue #30.
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
    $root = Join-Path $env:TEMP ('xcsv-member-source-root-' + [guid]::NewGuid().ToString('N'))
    foreach ($dir in @(
        'registry',
        'wiki',
        'addons/mission/xcsv',
        'addons/xcsv_chatter',
        'catalogue/Addons',
        'catalogue/Scripts',
        'catalogue/LiveSource/mpmissions/Exile.Tanoa',
        'catalogue/LiveSource/server-addons/xcsv_chatter',
        'guard/src',
        'guard/tools'
    )) {
        New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null
    }

    Set-Content -LiteralPath (Join-Path $root 'addons/mission/xcsv/fn_member.sqf') -Value 'systemChat "member addon";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'addons/xcsv_chatter/config.cpp') -Value 'class CfgFunctions { class XCSV {}; };' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/Addons/schema.sql') -Value 'create table x(id int);' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/Scripts/script.sqf') -Value 'systemChat "script";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/LiveSource/mpmissions/Exile.Tanoa/init.sqf') -Value 'systemChat "init";' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'catalogue/LiveSource/server-addons/xcsv_chatter/config.cpp') -Value 'class CfgFunctions { class XCSV { class bootstrap { class postInit { postInit = 1; }; }; }; };' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'guard/src/main.rs') -Value 'fn main() {}' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root 'guard/tools/doctor.ps1') -Value 'Write-Output doctor' -Encoding UTF8

    Initialize-TestGitRepo (Join-Path $root 'addons') 'https://github.com/x-cessive/XCSV_ADDONS.git'
    $addonsSha = Commit-All (Join-Path $root 'addons') 'addons fixture'
    Initialize-TestGitRepo (Join-Path $root 'catalogue') 'https://github.com/x-cessive/Exile.git'
    $catalogueSha = Commit-All (Join-Path $root 'catalogue') 'catalogue fixture'
    Initialize-TestGitRepo (Join-Path $root 'guard') 'https://github.com/x-cessive/XCSV_GUARD.git'
    $guardSha = Commit-All (Join-Path $root 'guard') 'guard fixture'

    Initialize-TestGitRepo $root 'https://github.com/x-cessive/XCSV.git'
    git -C $root add . | Out-Null
    $xcsvSha = Commit-All $root 'xcsv fixture with member gitlinks'

    return [pscustomobject]@{
        Root = $root
        XcsvSha = $xcsvSha
        AddonsSha = $addonsSha
        CatalogueSha = $catalogueSha
        GuardSha = $guardSha
    }
}

function Invoke-InventoryProcess([string] $Root) {
    $args = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $Generator,
        '-Root', $Root,
        '-ObservedAtUtc', '2026-08-21T04:00:00Z'
    )
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

function Invoke-Inventory([string] $Root) {
    $result = Invoke-InventoryProcess $Root
    if ($result.ExitCode -ne 0) { throw $result.Output }
    return (Get-Content -Raw -LiteralPath (Join-Path $Root 'registry/components.json') | ConvertFrom-Json)
}

Write-Host ''
Write-Host 'XCSV component inventory member source provenance' -ForegroundColor Cyan

Test-Case 'clean member checkout at exact gitlink is verified at observation' {
    $fixture = New-XcsvFixture
    try {
        $registry = Invoke-Inventory $fixture.Root
        $notes = @($registry.notes) -join "`n"
        Assert-True $notes.Contains("XCSV_ADDONS member observation: x-cessive/XCSV_ADDONS@$($fixture.AddonsSha) (VERIFIED_AT_OBSERVATION); expected gitlink $($fixture.AddonsSha); clean=True.") 'addons member observation missing'
        Assert-True $notes.Contains("Exile member observation: x-cessive/Exile@$($fixture.CatalogueSha) (VERIFIED_AT_OBSERVATION); expected gitlink $($fixture.CatalogueSha); clean=True.") 'catalogue member observation missing'
        Assert-True $notes.Contains("XCSV_GUARD member observation: x-cessive/XCSV_GUARD@$($fixture.GuardSha) (VERIFIED_AT_OBSERVATION); expected gitlink $($fixture.GuardSha); clean=True.") 'guard member observation missing'
    }
    finally {
        if (Test-Path -LiteralPath $fixture.Root) { Remove-Item -LiteralPath $fixture.Root -Recurse -Force }
    }
}

Test-Case 'member checkout at wrong commit is stale and blocked' {
    $fixture = New-XcsvFixture
    try {
        Set-Content -LiteralPath (Join-Path $fixture.Root 'addons/mission/xcsv/fn_member_advanced.sqf') -Value 'systemChat "advanced";' -Encoding UTF8
        [void](Commit-All (Join-Path $fixture.Root 'addons') 'advance addons without superproject gitlink')
        $result = Invoke-InventoryProcess $fixture.Root
        Assert-True ($result.ExitCode -ne 0) 'generator must fail for stale member checkout'
        Assert-True ($result.Output.Contains('STALE_MEMBER_SOURCE')) 'stale member source must be explicit'
    }
    finally {
        if (Test-Path -LiteralPath $fixture.Root) { Remove-Item -LiteralPath $fixture.Root -Recurse -Force }
    }
}

Test-Case 'dirty member worktree is blocked and not represented as clean HEAD truth' {
    $fixture = New-XcsvFixture
    try {
        Add-Content -LiteralPath (Join-Path $fixture.Root 'catalogue/Scripts/script.sqf') -Value 'systemChat "dirty";'
        Set-Content -LiteralPath (Join-Path $fixture.Root 'catalogue/Scripts/untracked.sqf') -Value 'systemChat "untracked";' -Encoding UTF8
        $result = Invoke-InventoryProcess $fixture.Root
        Assert-True ($result.ExitCode -ne 0) 'generator must fail for dirty member checkout'
        Assert-True ($result.Output.Contains('DIRTY_MEMBER_SOURCE')) 'dirty member source must be explicit'
        Assert-True ($result.Output.Contains('dirty_fingerprint=')) 'dirty result must carry deterministic fingerprint evidence'
    }
    finally {
        if (Test-Path -LiteralPath $fixture.Root) { Remove-Item -LiteralPath $fixture.Root -Recurse -Force }
    }
}

Test-Case 'same verified member commits at different paths emit equivalent member entries' {
    $fixture = New-XcsvFixture
    $copy = Join-Path $env:TEMP ('xcsv-member-source-copy-' + [guid]::NewGuid().ToString('N'))
    try {
        Copy-Item -LiteralPath $fixture.Root -Destination $copy -Recurse -Force
        $a = Invoke-Inventory $fixture.Root
        $b = Invoke-Inventory $copy
        foreach ($repo in @('x-cessive/XCSV_ADDONS', 'x-cessive/Exile', 'x-cessive/XCSV_GUARD')) {
            $entriesA = @($a.components | Where-Object { $_.repo -eq $repo } | Sort-Object component_id)
            $entriesB = @($b.components | Where-Object { $_.repo -eq $repo } | Sort-Object component_id)
            Assert-Equal $entriesA.Count $entriesB.Count "$repo entry count should be path-independent"
            for ($i = 0; $i -lt $entriesA.Count; $i++) {
                Assert-Equal $entriesA[$i].component_id $entriesB[$i].component_id "$repo component_id should be path-independent"
                Assert-Equal $entriesA[$i].canonical_path $entriesB[$i].canonical_path "$repo canonical_path should be path-independent"
            }
        }
    }
    finally {
        foreach ($path in @($fixture.Root, $copy)) {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
        }
    }
}

Test-Case 'incorrect member repository origin identity fails closed' {
    $fixture = New-XcsvFixture
    try {
        git -C (Join-Path $fixture.Root 'guard') remote set-url origin https://github.com/x-cessive/not-guard.git | Out-Null
        $result = Invoke-InventoryProcess $fixture.Root
        Assert-True ($result.ExitCode -ne 0) 'generator must fail for incorrect member origin'
        Assert-True ($result.Output.Contains('Git source identity mismatch')) 'identity mismatch must be explicit'
    }
    finally {
        if (Test-Path -LiteralPath $fixture.Root) { Remove-Item -LiteralPath $fixture.Root -Recurse -Force }
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

Write-Host 'XCSV component inventory member source provenance: PASS' -ForegroundColor Green
exit 0
