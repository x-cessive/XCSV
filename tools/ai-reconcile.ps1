<#
.SYNOPSIS
    Read-only XCSV AI bootstrap / reconciliation probe.

.DESCRIPTION
    Reports local-vs-remote repository state and required XCSV AI/bootstrap
    files without modifying git refs, working trees, the live server, or the
    desktop roadmap. Intended to be the first deterministic probe when an AI is
    told "read the GitHub" or "read the roadmap".

    This script deliberately uses git ls-remote instead of git fetch so remote
    comparison does not mutate local remote-tracking refs.

    PowerShell 5.1 safe: ASCII source only.
#>

[CmdletBinding()]
param(
    [string] $Hub = 'D:\XCSV',
    [string] $Guard = 'D:\XCSV_GUARD',
    [string] $Addons = 'E:\XCSV_ADDONS',
    [string] $Catalogue = 'E:\ExileRepo',
    [string] $Roadmap = 'C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX\ROADMAP.md',
    [switch] $Json
)

$ErrorActionPreference = 'Stop'

function Invoke-GitText {
    param(
        [string] $Repo,
        # Must not be named $Args: that collides with the PowerShell automatic
        # variable, arrives empty, and silently degrades every probe to a bare
        # "git -C <path>" usage error.
        [string[]] $GitArgs
    )

    $old = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        $out = & git -C $Repo @GitArgs 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        return (($out | Out-String).Trim())
    }
    finally {
        $ErrorActionPreference = $old
    }
}

function Get-RepoState {
    param(
        [string] $Name,
        [string] $Path
    )

    if (-not (Test-Path $Path)) {
        return [pscustomobject]@{
            name = $Name
            path = $Path
            exists = $false
            branch = $null
            local_sha = $null
            remote_sha = $null
            remote_match = 'UNKNOWN'
            working_tree = 'MISSING'
            upstream = $null
            origin = $null
        }
    }

    $inside = Invoke-GitText -Repo $Path -GitArgs @('rev-parse', '--is-inside-work-tree')
    if ($inside -ne 'true') {
        return [pscustomobject]@{
            name = $Name
            path = $Path
            exists = $true
            branch = $null
            local_sha = $null
            remote_sha = $null
            remote_match = 'UNKNOWN'
            working_tree = 'NOT_GIT'
            upstream = $null
            origin = $null
        }
    }

    $branch = Invoke-GitText -Repo $Path -GitArgs @('branch', '--show-current')
    $localSha = Invoke-GitText -Repo $Path -GitArgs @('rev-parse', 'HEAD')
    $status = Invoke-GitText -Repo $Path -GitArgs @('status', '--porcelain')
    $upstream = Invoke-GitText -Repo $Path -GitArgs @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}')
    $origin = Invoke-GitText -Repo $Path -GitArgs @('remote', 'get-url', 'origin')

    $remoteSha = $null
    if ($origin -and $branch) {
        $line = Invoke-GitText -Repo $Path -GitArgs @('ls-remote', '--heads', 'origin', "refs/heads/$branch")
        if ($line) {
            $remoteSha = ($line -split '\s+')[0]
        }
    }

    $match = 'UNKNOWN'
    if ($localSha -and $remoteSha) {
        if ($localSha -eq $remoteSha) { $match = 'MATCH' }
        else { $match = 'MISMATCH' }
    }

    [pscustomobject]@{
        name = $Name
        path = $Path
        exists = $true
        branch = $branch
        local_sha = $localSha
        remote_sha = $remoteSha
        remote_match = $match
        working_tree = $(if ([string]::IsNullOrWhiteSpace($status)) { 'CLEAN' } else { 'DIRTY' })
        upstream = $upstream
        origin = $origin
    }
}

$repos = @(
    Get-RepoState -Name 'XCSV' -Path $Hub
    Get-RepoState -Name 'XCSV_GUARD' -Path $Guard
    Get-RepoState -Name 'XCSV_ADDONS' -Path $Addons
    Get-RepoState -Name 'Exile' -Path $Catalogue
)

$contractPath = Join-Path $Hub 'wiki\AI-Start-Here.md'
$routerPath = Join-Path $Hub 'AI-START-HERE.md'
$claudePath = Join-Path $Hub 'CLAUDE.md'
$agentsPath = Join-Path $Hub 'AGENTS.md'
$openCodePath = Join-Path $Hub 'opencode.json'
$antigravityPath = Join-Path $Hub '.agents\rules\00-xcsv-ai-entrypoint.md'
$ragSearchPath = Join-Path $Hub 'tools\search-rag.ps1'
$buildDocsPath = Join-Path $Hub 'tools\build-docs.ps1'

$submodules = $null
if (Test-Path $Hub) {
    $submodules = Invoke-GitText -Repo $Hub -GitArgs @('submodule', 'status')
}

$result = [pscustomobject]@{
    contract_version = '1.0.0'
    mode = 'READ_ONLY_BOOTSTRAP'
    generated_at = (Get-Date).ToString('o')
    authoritative_roadmap = [pscustomobject]@{
        path = $Roadmap
        exists = (Test-Path $Roadmap)
        last_write = $(if (Test-Path $Roadmap) { (Get-Item $Roadmap).LastWriteTime.ToString('o') } else { $null })
    }
    bootstrap_files = [pscustomobject]@{
        canonical_contract = (Test-Path $contractPath)
        root_router = (Test-Path $routerPath)
        claude_adapter = (Test-Path $claudePath)
        agents_adapter = (Test-Path $agentsPath)
        opencode_config = (Test-Path $openCodePath)
        antigravity_rule = (Test-Path $antigravityPath)
        rag_search = (Test-Path $ragSearchPath)
        docs_builder = (Test-Path $buildDocsPath)
    }
    repositories = $repos
    hub_submodules = $submodules
    notes = @(
        'MISMATCH means local HEAD and remote branch tip differ; it does not say which side is correct.',
        'DIRTY means inspect local changes before pull, reset, checkout, merge, rebase, or replacement.',
        'GitHub absence is not proof that local/live implementation does not exist.',
        'Source presence is not proof of runtime verification.'
    )
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'XCSV AI RECONCILIATION'
Write-Host 'Contract: XCSV-AI-CONTRACT 1.0.0'
Write-Host 'Mode: READ_ONLY_BOOTSTRAP'
Write-Host ''
Write-Host ('Roadmap: {0} ({1})' -f $Roadmap, $(if ($result.authoritative_roadmap.exists) { 'FOUND' } else { 'MISSING' }))
Write-Host ''
Write-Host 'Repositories:'
foreach ($r in $repos) {
    Write-Host ('  {0,-12} {1,-9} remote={2,-8} branch={3} sha={4}' -f $r.name, $r.working_tree, $r.remote_match, $r.branch, $r.local_sha)
}
Write-Host ''
Write-Host 'Bootstrap files:'
$result.bootstrap_files.psobject.Properties | ForEach-Object {
    Write-Host ('  {0,-20} {1}' -f $_.Name, $(if ($_.Value) { 'FOUND' } else { 'MISSING' }))
}
Write-Host ''
Write-Host 'Hub submodules:'
if ($submodules) { Write-Host $submodules } else { Write-Host '  UNKNOWN' }
Write-Host ''
Write-Host 'No changes were made.'
