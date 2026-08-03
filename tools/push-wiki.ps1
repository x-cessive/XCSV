<#
    push-wiki.ps1 - publish wiki/ to the GitHub wiki

    The GitHub wiki repository (XCSV.wiki.git) does not exist until the first
    page has been created in the web UI. There is no REST or GraphQL endpoint
    that creates it. So:

      1. open https://github.com/x-cessive/XCSV/wiki
      2. click "Create the first page", save anything at all
      3. run this script - it overwrites that placeholder with the real pages

    wiki/ is the source of truth. This script does not edit it; it clones the
    wiki repo, mirrors the files in, and pushes. Safe to re-run.
#>

[CmdletBinding()]
param(
    [string] $Root  = (Split-Path $PSScriptRoot -Parent),
    [string] $Wiki  = 'https://github.com/x-cessive/XCSV.wiki.git',
    [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'

# git writes ordinary progress and CRLF notices to stderr. Under
# $ErrorActionPreference = 'Stop' PowerShell 5.1 turns any native stderr write
# into a terminating error, so a harmless "LF will be replaced by CRLF" warning
# aborted a wiki push that had otherwise worked. Run git with stderr demoted and
# judge it on its exit code, which is the only thing that actually means failure.
# No param() block on purpose: an advanced function binds leading-dash tokens to
# its own parameters, so a trailing `-A` prefix-matches and the call fails.
function Invoke-Git {
    $rest = $args
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try   { & git @rest 2>&1 | Out-String | Write-Verbose }
    finally { $ErrorActionPreference = $old }
    return $LASTEXITCODE
}

$src = Join-Path $Root 'wiki'
if (-not (Test-Path $src)) { throw "no wiki source at $src" }

$tmp = Join-Path $env:TEMP ("xcsv_wiki_" + [guid]::NewGuid().ToString('N').Substring(0, 8))

Write-Host "cloning $Wiki"
if ((Invoke-Git clone --quiet $Wiki $tmp) -ne 0) {
    throw @"
could not clone the wiki.

The wiki repository does not exist yet. GitHub only creates it once the first
page is saved in the web UI, and there is no API for it:

    https://github.com/x-cessive/XCSV/wiki  ->  "Create the first page"

Save anything, then run this script again - it will overwrite the placeholder.
"@
}

try {
    # Mirror: remove pages that no longer exist in source, then copy.
    Get-ChildItem $tmp -Filter *.md | Remove-Item -Force
    Copy-Item (Join-Path $src '*.md') $tmp -Force

    $count = (Get-ChildItem $tmp -Filter *.md).Count
    Write-Host "staged $count pages"

    if ($WhatIf) {
        Write-Host "-WhatIf: not committing"
        Get-ChildItem $tmp -Filter *.md | ForEach-Object { "  $($_.Name)" }
        return
    }

    [void](Invoke-Git -C $tmp add -A)

    # Exit code 0 from `diff --cached --quiet` means no staged differences.
    if ((Invoke-Git -C $tmp diff --cached --quiet) -eq 0) {
        Write-Host "wiki already up to date"
        return
    }

    [void](Invoke-Git -C $tmp -c user.name='x-cessive' -c user.email='graygryphonooi@gmail.com' `
        commit --quiet -m "Sync wiki from XCSV/wiki ($(Get-Date -Format 'yyyy-MM-dd'))")
    if ((Invoke-Git -C $tmp push --quiet) -ne 0) { throw 'push failed' }

    Write-Host "wiki published: https://github.com/x-cessive/XCSV/wiki"
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
