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

$src = Join-Path $Root 'wiki'
if (-not (Test-Path $src)) { throw "no wiki source at $src" }

$tmp = Join-Path $env:TEMP ("xcsv_wiki_" + [guid]::NewGuid().ToString('N').Substring(0, 8))

Write-Host "cloning $Wiki"
& git clone --quiet $Wiki $tmp 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
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

    & git -C $tmp add -A
    & git -C $tmp diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "wiki already up to date"
        return
    }

    & git -C $tmp -c user.name='x-cessive' -c user.email='graygryphonooi@gmail.com' `
        commit --quiet -m "Sync wiki from XCSV/wiki ($(Get-Date -Format 'yyyy-MM-dd'))"
    & git -C $tmp push --quiet
    if ($LASTEXITCODE -ne 0) { throw "push failed" }

    Write-Host "wiki published: https://github.com/x-cessive/XCSV/wiki"
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
