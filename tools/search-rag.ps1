# Queries the local XCSV RAG JSONL index and prints cited snippets.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    [string]$IndexFile = 'D:\CAGE\xcsv-rag\xcsv-rag.jsonl',
    [int]$Top = 8
)

$ErrorActionPreference = 'Stop'

function Tokenize([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    [regex]::Matches($Text.ToLowerInvariant(), '[a-z0-9_]{3,}') |
        ForEach-Object { $_.Value } |
        Where-Object { $_ -notin @('the','and','for','with','this','that','from','into','then','than','was','were','are','you','your','our') }
}

function Snippet([string]$Text, [string[]]$Terms) {
    $flat = ($Text -replace '\s+', ' ').Trim()
    if ($flat.Length -le 320) { return $flat }
    $firstHit = 0
    foreach ($term in $Terms) {
        $idx = $flat.ToLowerInvariant().IndexOf($term)
        if ($idx -ge 0) { $firstHit = [Math]::Max(0, $idx - 120); break }
    }
    $len = [Math]::Min(320, $flat.Length - $firstHit)
    $prefix = if ($firstHit -gt 0) { '...' } else { '' }
    $suffix = if (($firstHit + $len) -lt $flat.Length) { '...' } else { '' }
    $prefix + $flat.Substring($firstHit, $len) + $suffix
}

if (-not (Test-Path -LiteralPath $IndexFile)) {
    throw "index not found: $IndexFile. Run D:\XCSV\tools\build-rag-index.ps1 first."
}

$terms = @(Tokenize $Query | Select-Object -Unique)
if ($terms.Count -eq 0) { throw 'query has no searchable terms' }

$tierBoost = @{
    'live' = 8
    'committed-source' = 6
    'vault' = 4
    'wiki' = 3
    'generated-wiki' = 1
    'log' = 5
}

$results = Get-Content -LiteralPath $IndexFile |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object {
        $doc = $_ | ConvertFrom-Json
        $haystack = "$($doc.repo) $($doc.rel_path) $($doc.heading) $($doc.text)".ToLowerInvariant()
        $score = 0
        $matchedTerms = 0
        foreach ($term in $terms) {
            $matches = [regex]::Matches($haystack, [regex]::Escape($term)).Count
            if ($matches -gt 0) {
                $matchedTerms++
                $score += [Math]::Min($matches, 3)
            }
            if (($doc.heading + '').ToLowerInvariant().Contains($term)) { $score += 6 }
            if (($doc.rel_path + '').ToLowerInvariant().Contains($term)) { $score += 4 }
        }
        if ($tierBoost.ContainsKey($doc.tier)) { $score += $tierBoost[$doc.tier] }
        $minimumTerms = if ($terms.Count -gt 1) { 2 } else { 1 }
        if ($score -gt 0 -and $matchedTerms -ge $minimumTerms) {
            [pscustomobject]@{
                Score = $score
                Tier = $doc.tier
                Repo = $doc.repo
                Path = $doc.rel_path
                Lines = "$($doc.line_start)-$($doc.line_end)"
                Heading = $doc.heading
                Commit = if ($doc.commit) { $doc.commit.Substring(0, [Math]::Min(8, $doc.commit.Length)) } else { '' }
                Snippet = Snippet $doc.text $terms
            }
        }
    } |
    Sort-Object Score -Descending |
    Select-Object -First $Top

if (-not $results) {
    Write-Host "No matches for: $Query"
    exit 2
}

$results | Format-Table -Wrap -AutoSize
