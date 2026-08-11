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

function Invoke-GitResult {
    param(
        [string] $Repo,
        # Must not be named $Args: that collides with the PowerShell automatic
        # variable, arrives empty, and silently degrades every probe to a bare
        # "git -C <path>" usage error.
        [string[]] $GitArgs
    )

    $errFile = [System.IO.Path]::GetTempFileName()
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & git -C $Repo @GitArgs 2>$errFile
        $exitCode = $LASTEXITCODE
        $err = ''
        if (Test-Path $errFile) {
            $err = ((Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue) | Out-String).Trim()
        }

        return [pscustomobject]@{
            exit_code = $exitCode
            stdout = (($out | Out-String).Trim())
            stderr = $err
        }
    }
    finally {
        $ErrorActionPreference = $old
        Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-GitText {
    param(
        [string] $Repo,
        [string[]] $GitArgs
    )

    $result = Invoke-GitResult -Repo $Repo -GitArgs $GitArgs
    if ($result.exit_code -ne 0) { return $null }
    return $result.stdout
}

function Get-GhAuthState {
    <#
        Detect a GH_TOKEN environment variable shadowing the credential gh has
        stored, without ever reading, printing or returning either secret.

        XCSV-AI-001 lost most of a session to this. gh prefers GH_TOKEN over its
        stored credential, so a fine-grained PAT in the environment silently
        became the active account while a keyring OAuth token with the scopes
        the work needed sat inactive. Every Projects and issue write failed with
        "Resource not accessible by personal access token", and the obvious
        remedy is a dead end: gh refuses to refresh a token supplied through the
        environment. The fix was to stop using the env var, not to grant a scope
        - but nothing in the tooling said so.

        Only presence, account names, source and scope names are inspected. The
        token values themselves are never touched.
    #>

    $state = [pscustomobject]@{
        gh_present       = $false
        env_token_set    = [bool]$env:GH_TOKEN
        active_account   = $null
        active_source    = $null
        stored_accounts  = @()
        active_scopes    = @()
        stored_scopes    = @()
        shadowing        = 'UNKNOWN'
        detail           = $null
    }

    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        $state.shadowing = 'UNKNOWN'
        $state.detail = 'gh CLI not found on PATH'
        return $state
    }
    $state.gh_present = $true

    $old = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { $raw = (& gh auth status 2>&1 | Out-String) }
    finally { $ErrorActionPreference = $old }

    if (-not $raw) {
        $state.detail = 'gh auth status returned nothing'
        return $state
    }

    # Walk the per-account blocks. gh prints one "Logged in to <host> account
    # <name> (<source>)" header followed by indented properties.
    $current = $null
    $accounts = New-Object System.Collections.Generic.List[object]

    foreach ($line in ($raw -split "`r?`n")) {
        if ($line -match 'Logged in to\s+\S+\s+account\s+(\S+)\s+\(([^)]+)\)') {
            $current = [pscustomobject]@{
                name   = $Matches[1]
                source = $Matches[2]
                active = $false
                scopes = @()
            }
            $accounts.Add($current)
            continue
        }
        if (-not $current) { continue }

        if ($line -match 'Active account:\s*true') { $current.active = $true }

        if ($line -match "Token scopes:\s*(.+)$") {
            # Scope NAMES only. The token value is on a different line and is
            # never parsed.
            $current.scopes = @(
                ($Matches[1] -split ',') |
                    ForEach-Object { $_.Trim().Trim("'").Trim('"') } |
                    Where-Object { $_ }
            )
        }
    }

    if ($accounts.Count -eq 0) {
        $state.detail = 'no authenticated gh account detected'
        return $state
    }

    $active = $accounts | Where-Object { $_.active } | Select-Object -First 1
    if (-not $active) { $active = $accounts[0] }

    $state.active_account  = $active.name
    $state.active_source   = $active.source
    $state.active_scopes   = @($active.scopes)
    $state.stored_accounts = @($accounts | Where-Object { -not $_.active } | ForEach-Object { $_.name })
    $state.stored_scopes   = @($accounts | Where-Object { -not $_.active } | ForEach-Object { $_.scopes } | Sort-Object -Unique)

    $envSourced = ($active.source -match 'GH_TOKEN|GITHUB_TOKEN')
    $inactiveWithScopes = @($accounts | Where-Object { -not $_.active -and $_.scopes.Count -gt 0 })

    if ($envSourced -and $inactiveWithScopes.Count -gt 0) {
        # The active credential comes from the environment while a stored one
        # carries explicit scopes. Whether the stored one is strictly better
        # cannot always be known - an env token reports no scopes at all - so
        # report the shadowing and let the operator compare.
        $state.shadowing = 'GH_TOKEN_SHADOWING_STORED_CREDENTIAL'
        $state.detail = ('active credential comes from the environment; a stored credential offers scopes: {0}' -f (($state.stored_scopes) -join ', '))
    }
    elseif ($envSourced) {
        $state.shadowing = 'ENV_TOKEN_ACTIVE_NO_STORED_ALTERNATIVE'
        $state.detail = 'active credential comes from the environment; no scoped stored credential detected'
    }
    else {
        $state.shadowing = 'NONE'
        $state.detail = 'active credential is the stored one'
    }

    return $state
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
            git_detail = $null
        }
    }

    $inside = Invoke-GitResult -Repo $Path -GitArgs @('rev-parse', '--is-inside-work-tree')
    if ($inside.exit_code -ne 0 -or $inside.stdout -ne 'true') {
        $state = 'NOT_GIT'
        $detail = $inside.stderr
        if ($inside.stderr -match 'dubious ownership') {
            $state = 'GIT_UNSAFE_OWNERSHIP'
            $fatal = [regex]::Match($inside.stderr, 'fatal: detected dubious ownership[^\r\n]*')
            $hint = [regex]::Match($inside.stderr, 'git config --global --add safe\.directory\s+\S+')
            $detail = (@($fatal.Value, $hint.Value) | Where-Object { $_ }) -join '; '
        }

        return [pscustomobject]@{
            name = $Name
            path = $Path
            exists = $true
            branch = $null
            local_sha = $null
            remote_sha = $null
            remote_match = 'UNKNOWN'
            working_tree = $state
            upstream = $null
            origin = $null
            git_detail = $detail
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
        git_detail = $null
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

$ghAuth = Get-GhAuthState

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
    github_auth = $ghAuth
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
    if ($r.git_detail) {
        $detail = ($r.git_detail -split "`r?`n" | Select-Object -First 1)
        Write-Host ('    detail: {0}' -f $detail)
    }
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
Write-Host 'GitHub auth:'
Write-Host ('  active account   {0} (source: {1})' -f $ghAuth.active_account, $ghAuth.active_source)
Write-Host ('  GH_TOKEN set     {0}' -f $ghAuth.env_token_set)
Write-Host ('  shadowing        {0}' -f $ghAuth.shadowing)
if ($ghAuth.shadowing -eq 'GH_TOKEN_SHADOWING_STORED_CREDENTIAL') {
    Write-Host '  WARNING: GH_TOKEN is overriding the credential gh has stored.'
    Write-Host ('  stored credential scopes: {0}' -f (($ghAuth.stored_scopes) -join ', '))
    Write-Host '  If a Projects/Issues write fails as "not accessible by personal access token",'
    Write-Host '  clear GH_TOKEN for the process and retry before requesting any new scope.'
    Write-Host '  gh cannot refresh a token supplied through the environment.'
}
Write-Host ''
Write-Host 'No token values were read or displayed.'
Write-Host 'No changes were made.'
