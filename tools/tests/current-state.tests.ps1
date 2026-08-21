<#
    current-state.tests.ps1 - deterministic regression for observation vs
    derived currentness.

    Plain PowerShell on purpose, matching the existing XCSV test style.
#>

[CmdletBinding()]
param([switch] $Quiet)

$ErrorActionPreference = 'Stop'

$ToolsDir = Split-Path -Parent $PSScriptRoot
. (Join-Path $ToolsDir 'current-state.ps1')

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

function Assert-Equal {
    param($Expected, $Actual, [string] $Because = '')
    if ($Expected -ne $Actual) {
        throw ("expected [{0}] but got [{1}] {2}" -f $Expected, $Actual, $Because)
    }
}

Write-Host ''
Write-Host 'XCSV current-state observation model' -ForegroundColor Cyan

Test-Case 'recorded identity A derives CURRENT when live identity is still A' {
    $r = Get-XcsvDerivedFreshness `
        -ObservationResult 'VERIFIED_AT_OBSERVATION' `
        -ObservedIdentity 'branch@A' `
        -LiveIdentity 'branch@A' `
        -LiveComparisonAvailable:$true
    Assert-Equal 'CURRENT' $r
}

Test-Case 'recorded identity A derives STALE after source advances to B' {
    $r = Get-XcsvDerivedFreshness `
        -ObservationResult 'VERIFIED_AT_OBSERVATION' `
        -ObservedIdentity 'branch@A' `
        -LiveIdentity 'branch@B' `
        -LiveComparisonAvailable:$true
    Assert-Equal 'STALE' $r
}

Test-Case 'unavailable live comparison does not inherit CURRENT' {
    $r = Get-XcsvDerivedFreshness `
        -ObservationResult 'VERIFIED_AT_OBSERVATION' `
        -ObservedIdentity 'branch@A' `
        -LiveIdentity $null `
        -LiveComparisonAvailable:$false
    Assert-Equal 'UNKNOWN' $r
}

Test-Case 'source never observed remains NOT_REVERIFIED' {
    $r = Get-XcsvDerivedFreshness `
        -ObservationResult 'NOT_REVERIFIED' `
        -ObservedIdentity $null `
        -LiveIdentity $null `
        -LiveComparisonAvailable:$false
    Assert-Equal 'NOT_REVERIFIED' $r
}

Test-Case 'report derives per-source freshness from supplied live identities' {
    $state = [pscustomobject]@{
        sources = [pscustomobject]@{
            branch = [pscustomobject]@{
                observation_result = 'VERIFIED_AT_OBSERVATION'
                observed_identity = 'branch@A'
                observed_at = '2026-08-21T00:00:00Z'
            }
            runtime = [pscustomobject]@{
                observation_result = 'NOT_REVERIFIED'
                observed_identity = $null
                observed_at = $null
            }
            wiki = [pscustomobject]@{
                observation_result = 'STALE_AT_OBSERVATION'
                observed_identity = 'wiki@old'
                observed_at = '2026-08-21T00:00:00Z'
            }
        }
    }
    $rows = Get-XcsvCurrentStateReport -State $state -LiveIdentities @{ branch = 'branch@B'; wiki = 'wiki@old' }
    Assert-Equal 'STALE' (@($rows | Where-Object SourceId -eq 'branch')[0].DerivedFreshness)
    Assert-Equal 'NOT_REVERIFIED' (@($rows | Where-Object SourceId -eq 'runtime')[0].DerivedFreshness)
    Assert-Equal 'STALE' (@($rows | Where-Object SourceId -eq 'wiki')[0].DerivedFreshness)
}

Write-Host ''
Write-Host ("Passed: {0}   Failed: {1}" -f $script:Passed, $script:Failed) -ForegroundColor $(if ($script:Failed) { 'Red' } else { 'Green' })
if ($script:Failed -gt 0) {
    Write-Host ''
    Write-Host 'Failures:' -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host ("  " + $f) -ForegroundColor Yellow }
    exit 1
}

Write-Host 'XCSV current-state observation model: PASS' -ForegroundColor Green
exit 0

