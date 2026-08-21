<#
    build-docs.ps1 - generate the site's documentation pages from wiki/

    wiki/*.md is the single source of truth. It is written in GitHub-wiki
    flavour (bare [Page](Page) links, no front matter) so the same files can be
    pushed straight to XCSV.wiki.git when the wiki is initialised.

    This script produces docs/wiki/*.md: the same content plus Jekyll front
    matter, with wiki links rewritten to .html so they resolve on Pages.

    Run it after editing anything in wiki/. Nothing here is hand-maintained.

    Note on encoding: the files are written with UTF8Encoding($false) rather
    than Out-File -Encoding utf8, because PowerShell 5.1 writes a BOM and a BOM
    ahead of the opening '---' stops Jekyll recognising front matter at all.
    A BOM in a config file has already cost this project a silent failure once.
#>

[CmdletBinding()]
param(
    [string] $Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

$src = Join-Path $Root 'wiki'
$dst = Join-Path $Root 'docs\wiki'

# Order and blurb per page. A page absent from here is not published, which is
# how _Sidebar.md stays out of the site.
$pages = [ordered]@{
    'AI-Start-Here'                    = @{ Order = 1;  Title = 'AI Start Here'; Blurb = 'Mandatory reconciliation and navigation contract for AI-assisted XCSV work.' }
    'AI-Provenance-and-Doc-Sync'       = @{ Order = 2;  Title = 'AI Provenance & Doc Sync'; Blurb = 'AI commit attribution and safe desktop/GitHub documentation reconciliation.' }
    'AI-Tooling'                       = @{ Order = 3;  Title = 'AI / Development Tooling'; Blurb = 'Selected, optional and rejected workflow tools, with the reason for each decision.' }
    'AI-Continuity'                    = @{ Order = 4;  Title = 'AI Continuity'; Blurb = 'Isolated Hermes/OpenClaw baton and failover workflow for XCSV.' }
    'Home'                             = @{ Order = 5;  Title = 'Overview'; Blurb = 'What XCSV EXILE is, and where to start.' }
    'Architecture'                     = @{ Order = 6;  Title = 'Architecture'; Blurb = 'Processes, threading, content layers, and the override seam.' }
    'Repository-Identity-and-Freshness'= @{ Order = 7;  Title = 'Repository Identity & Freshness'; Blurb = 'Machine-readable repository identity, per-source freshness and cold-rehydration semantics.' }
    'Runbook'                          = @{ Order = 8;  Title = 'Deployment & Operations'; Blurb = 'Recovery and operating procedures, with currentness boundaries called out.' }
    'Repositories'                     = @{ Order = 9;  Title = 'Repositories'; Blurb = 'Five repositories, one XCSV project: what lives where, and why.' }
    'XM8-Apps'                         = @{ Order = 10; Title = 'XM8 Apps'; Blurb = 'How XM8 apps register, what is shipped, what is next.' }
    'Custom-Map-Editing'               = @{ Order = 11; Title = 'Custom Map Editing'; Blurb = 'Map-authoring custody, Eden/static-object pipeline and deployment evidence boundaries.' }
    'Drone-and-Counter-UAS'            = @{ Order = 12; Title = 'Drone & Counter-UAS'; Blurb = 'Drone system and counterplay source/evidence boundaries.' }
    'Roadmap'                          = @{ Order = 13; Title = 'Roadmap'; Blurb = 'Durable planning direction and issue routing, not execution/runtime proof.' }
    'Roadmap-History'                  = @{ Order = 14; Title = 'Roadmap History'; Blurb = 'Historical roadmap/status evidence retained with currentness warnings.' }
    'XCSV-GUARD-Development-Plan'      = @{ Order = 15; Title = 'GUARD Development'; Blurb = 'Gauntlet, reliability, UX, evidence, deployment and player-system programme.' }
    'Memory'                           = @{ Order = 16; Title = 'Memory'; Blurb = 'Where project truth is recorded, and the RAG plan.' }
    'Memory-Index'                     = @{ Order = 17; Title = 'Memory Index'; Blurb = 'Heading-level map of vault and wiki memory.' }
    'Lessons'                          = @{ Order = 18; Title = 'Lessons'; Blurb = 'Mistakes actually made here, and the rule each one produced.' }
    'System-Components'                = @{ Order = 19; Title = 'System Components'; Blurb = 'Evidence-backed registry contract for addons, scripts, mods, live wiring and refactor status.' }
}

if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$names = @($pages.Keys)
$written = 0

foreach ($name in $names) {
    $inFile = Join-Path $src "$name.md"
    if (-not (Test-Path $inFile)) { throw "missing source page: $inFile" }

    $meta = $pages[$name]
    $body = [System.IO.File]::ReadAllText($inFile)

    # Drop the source page's own H1 - the layout renders the title itself.
    $body = [regex]::Replace($body, '\A\s*#\s+[^\r\n]*\r?\n', '')

    # Rewrite bare wiki links to their generated .html siblings. Only names we
    # actually publish are touched, so external links and anchors are untouched.
    foreach ($n in $names) {
        $body = $body -replace "\]\($([regex]::Escape($n))\)", "]($n.html)"
    }

    $front = @(
        '---'
        'layout: wiki'
        'section: docs'
        "title: $($meta.Title)"
        "heading: $($meta.Title)"
        "blurb: $($meta.Blurb)"
        "order: $($meta.Order)"
        "source: $name.md"
        'generated: true'
        "source_authority: wiki/$name.md"
        '---'
        ''
        "<!-- GENERATED FROM wiki/$name.md BY tools/build-docs.ps1. DO NOT EDIT docs/wiki BY HAND. -->"
        ''
    ) -join "`n"

    [System.IO.File]::WriteAllText((Join-Path $dst "$name.md"), $front + $body, $utf8NoBom)
    $written++
}

Write-Host "build-docs: wrote $written pages to $dst"

# The "last updated" date is no longer stamped here. Every page now runs
# through the shared base layout, whose footer uses Jekyll's own {{ site.time }}
# - so the date comes from the build itself and cannot go stale in the repo.

# Cheap guard against the failure this script is most likely to have: a page
# that renders as raw markdown because the front matter was not recognised.
Get-ChildItem $dst -Filter *.md | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "BOM written to $($_.Name) - Jekyll will not parse the front matter"
    }
    if ($bytes[0] -ne 0x2D) {
        throw "$($_.Name) does not begin with front matter"
    }
}
Write-Host "build-docs: front matter verified on all pages"
