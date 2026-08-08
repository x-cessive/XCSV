<#
    continuity-state.tests.ps1 - read-only checks for the XCSV AI continuity lane.

    These checks prevent a stale worker policy or stale AI-Continuity page from
    claiming stronger Hermes/OpenClaw authority than the runtime has proven.
#>

[CmdletBinding()]
param([switch] $Quiet)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Read-Json {
    param([string] $Path)
    Assert-True (Test-Path -LiteralPath $Path) "missing JSON: $Path"
    [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json
}

Write-Host ''
Write-Host 'XCSV AI continuity state - read-only' -ForegroundColor Cyan

Test-Case 'worker policy keeps OpenClaw read-only and collision-sensitive' {
    $policy = Read-Json (Join-Path $Root 'continuity\worker-policy.json')
    $openclaw = @($policy.continuity_workers | Where-Object { $_.id -eq 'openclaw-xcsvcontinuity' })[0]
    Assert-True ($null -ne $openclaw) 'openclaw-xcsvcontinuity worker missing'
    Assert-True ($openclaw.authority -eq 'READ_ONLY') 'OpenClaw continuity worker must remain READ_ONLY'
    Assert-True (-not $openclaw.may_modify_code) 'OpenClaw continuity worker must not modify code'
    Assert-True ($openclaw.status -match 'collision_sensitive|collision-sensitive') 'OpenClaw status must retain collision-sensitive boundary'
}

Test-Case 'Hermes is not claimed runtime-ready without a CLI/API proof' {
    $policy = Read-Json (Join-Path $Root 'continuity\worker-policy.json')
    $hermes = @($policy.continuity_workers | Where-Object { $_.id -eq 'hermes-xcsvcontinuity' })[0]
    Assert-True ($null -ne $hermes) 'hermes-xcsvcontinuity worker missing'
    Assert-True ($hermes.authority -eq 'READ_ONLY') 'Hermes continuity worker must remain READ_ONLY'
    Assert-True ($hermes.status -match 'no_cli|no_api|profile_exists') 'Hermes status must not overclaim runtime readiness'
}

Test-Case 'local LLM fallback remains read-only' {
    $policy = Read-Json (Join-Path $Root 'continuity\worker-policy.json')
    $ollama = @($policy.local_fallback | Where-Object { $_.id -eq 'ollama-local' })[0]
    Assert-True ($null -ne $ollama) 'ollama-local fallback missing'
    Assert-True ($ollama.authority -eq 'READ_ONLY') 'local LLM fallback must remain READ_ONLY'
    Assert-True (-not $ollama.may_modify_code) 'local LLM fallback must not modify code'
}

Test-Case 'AI-Continuity page records the current partial boundary' {
    $page = [System.IO.File]::ReadAllText((Join-Path $Root 'wiki\AI-Continuity.md'))
    foreach ($needle in @(
        'PARTIAL',
        'OpenClaw',
        'Hermes',
        'collision-sensitive',
        'read-only'
    )) {
        Assert-True ($page.Contains($needle)) "missing AI-Continuity marker: $needle"
    }
}

Test-Case 'hub wrapper points at the governed runtime tool' {
    $wrapper = [System.IO.File]::ReadAllText((Join-Path $Root 'tools\xcsv-continuity.ps1'))
    Assert-True ($wrapper.Contains('D:\CAGE\xcsv-ai-continuity\tools\xcsv-continuity.ps1')) 'wrapper must delegate to governed runtime'
    Assert-True ($wrapper.Contains('Test-Path -LiteralPath $RuntimeTool')) 'wrapper must fail closed if runtime tool is missing'
}

Write-Host ''
Write-Host ("Passed: {0}   Failed: {1}" -f $script:Passed, $script:Failed) -ForegroundColor $(if ($script:Failed) { 'Red' } else { 'Green' })
if ($script:Failed -gt 0) {
    Write-Host ''
    Write-Host 'Failures:' -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host ("  " + $f) -ForegroundColor Yellow }
    exit 1
}

Write-Host 'XCSV AI continuity state: PASS' -ForegroundColor Green
exit 0
