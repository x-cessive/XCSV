<#
    ai-commit.ps1 - create an XCSV commit with explicit AI provenance trailers.

    This helper does not stage files and does not modify git identity. Review and
    stage the intended changes first. Push is opt-in.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Message,

    [Parameter(Mandatory = $true)]
    [string] $Agent,

    [Parameter(Mandatory = $true)]
    [ValidateSet('orchestrator','primary','worker','critic','automation')]
    [string] $Role,

    [Parameter(Mandatory = $true)]
    [string] $WorkId,

    [string] $Contract = '1.0.0',

    [string] $Model,

    [switch] $Push
)

$ErrorActionPreference = 'Stop'

$root = (& git rev-parse --show-toplevel 2>$null)
if (-not $root) { throw 'Not inside a git working tree.' }

$staged = (& git diff --cached --name-only)
if (-not $staged) { throw 'No staged changes. Stage and review the intended files first.' }

if ($Agent -notmatch '^(claude-code|opencode|antigravity|codex|chatgpt|mixed|automation|local-llm:[A-Za-z0-9._-]+)$') {
    throw "Unsupported XCSV-Agent value: $Agent"
}

if ([string]::IsNullOrWhiteSpace($WorkId)) { throw 'WorkId cannot be empty.' }
if ([string]::IsNullOrWhiteSpace($Message)) { throw 'Message cannot be empty.' }

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add($Message.Trim())
$lines.Add('')
$lines.Add("XCSV-Agent: $Agent")
$lines.Add("XCSV-Agent-Role: $Role")
$lines.Add("XCSV-Work-ID: $WorkId")
$lines.Add("XCSV-Contract: $Contract")
if (-not [string]::IsNullOrWhiteSpace($Model)) {
    $lines.Add("XCSV-AI-Model: $($Model.Trim())")
}

$tmp = [System.IO.Path]::GetTempFileName()
try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($tmp, $lines, $utf8NoBom)
    & git commit -F $tmp
    if ($LASTEXITCODE -ne 0) { throw "git commit failed with exit code $LASTEXITCODE" }

    $sha = (& git rev-parse HEAD).Trim()
    Write-Host "XCSV AI commit created: $sha"

    if ($Push) {
        & git push
        if ($LASTEXITCODE -ne 0) { throw "git push failed with exit code $LASTEXITCODE" }
        Write-Host "XCSV AI commit pushed: $sha"
    }
}
finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}
