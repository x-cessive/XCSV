<#
    check-docs-generated.ps1 - verify docs/wiki is generated from wiki/.

    This is a local documentation transaction check for XCSV-REFACTOR-DOCS-001.
    Permanent CI/audit expansion remains issue #37 scope.
#>

[CmdletBinding()]
param(
    [string] $Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

$before = & git -C $Root diff -- docs/wiki
if ($LASTEXITCODE -ne 0) {
    throw 'git diff failed before checking generated docs'
}

& (Join-Path $Root 'tools\build-docs.ps1') -Root $Root

$after = & git -C $Root diff -- docs/wiki
if ($LASTEXITCODE -ne 0) {
    throw 'git diff failed after checking generated docs'
}

if (($before -join "`n") -ne ($after -join "`n")) {
    $changed = & git -C $Root diff --name-only -- docs/wiki
    throw "build-docs.ps1 changed docs/wiki; regenerate and commit the projection: $($changed -join ', ')"
}

Write-Host 'check-docs-generated: PASS'
