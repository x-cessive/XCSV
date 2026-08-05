# Builds a local read-only RAG index for XCSV operations.
# Output is intentionally outside the repo by default because it contains
# source/log snippets that are useful locally but not always publishable.

[CmdletBinding()]
param(
    [string]$OutDir = 'D:\CAGE\xcsv-rag',
    [string]$VaultDir = 'C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX',
    [string]$XcsvDir = 'D:\XCSV',
    [string]$ExileRepo = 'E:\ExileRepo',
    [string]$GuardRepo = 'D:\XCSV_GUARD',
    [string]$AddonsRepo = 'E:\XCSV_ADDONS',
    [string]$LiveServerDir = 'E:\arma3server',
    [int]$MaxFileBytes = 524288,
    [int]$ChunkLines = 80,
    [int]$RecentLogCount = 5
)

$ErrorActionPreference = 'Stop'

$secretNamePattern = '(?i)(secret|token|password|credential|private|apikey|api_key|xcsv_guard\.json|\.env|extdb.*conf|basic\.cfg|config\.cfg)'
$allowedExtensions = @(
    '.md', '.sqf', '.cpp', '.hpp', '.h', '.ps1', '.cmd', '.bat',
    '.sql', '.ini', '.ext', '.sqm', '.toml', '.json', '.rpt', '.log'
)
$skipDirPattern = '(?i)\\(\.git|\.obsidian|target|node_modules|docs\\assets|original-addons|editor-tools)\\'

function Resolve-OrNull([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return $null }
    (Resolve-Path -LiteralPath $Path).Path
}

function Relative-Path([string]$Root, [string]$Path) {
    $rootUri = [Uri]((Resolve-Path -LiteralPath $Root).Path.TrimEnd('\') + '\')
    $pathUri = [Uri]((Resolve-Path -LiteralPath $Path).Path)
    [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

function Git-Sha([string]$Repo) {
    if (-not (Test-Path -LiteralPath (Join-Path $Repo '.git'))) { return '' }
    try {
        (& git -C $Repo rev-parse HEAD 2>$null).Trim()
    } catch {
        ''
    }
}

function Read-LinesShared([string]$Path) {
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8, $true)
        try {
            $content = $reader.ReadToEnd()
        } finally {
            $reader.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
    $content -split "\r?\n"
}

function Sanitize-Text([string]$Text) {
    $redacted = $Text -replace '(?i)(password|token|secret|api[_-]?key|steamApiKey|rconPassword)\s*[:=]\s*["'']?[^"''\s,;]+', '$1=<REDACTED>'
    $redacted -replace '\b[A-Za-z0-9_/\+=-]{32,}\b', '<REDACTED_LONG_TOKEN>'
}

function New-ChunkId([string]$Tier, [string]$RelPath, [int]$StartLine) {
    $raw = "$Tier|$RelPath|$StartLine"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 16)
}

function Add-Chunk(
    [System.Collections.Generic.List[object]]$Chunks,
    [string]$Tier,
    [string]$RepoName,
    [string]$RepoSha,
    [string]$Root,
    [System.IO.FileInfo]$File,
    [string]$Heading,
    [int]$StartLine,
    [int]$EndLine,
    [string]$Text
) {
    $clean = (Sanitize-Text $Text).Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) { return }
    $rel = Relative-Path -Root $Root -Path $File.FullName
    $Chunks.Add([pscustomobject]@{
        id         = New-ChunkId -Tier $Tier -RelPath $rel -StartLine $StartLine
        tier       = $Tier
        repo       = $RepoName
        commit     = $RepoSha
        root       = $Root
        path       = $File.FullName
        rel_path   = $rel
        heading    = $Heading
        line_start = $StartLine
        line_end   = $EndLine
        ext        = $File.Extension.ToLowerInvariant()
        text       = $clean
    })
}

function Add-MarkdownChunks(
    [System.Collections.Generic.List[object]]$Chunks,
    [string]$Tier,
    [string]$RepoName,
    [string]$RepoSha,
    [string]$Root,
    [System.IO.FileInfo]$File
) {
    $lines = Read-LinesShared $File.FullName
    $heading = ''
    $buffer = New-Object System.Collections.Generic.List[string]
    $start = 1
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match '^(#{1,3})\s+(.+)$' -and $buffer.Count -gt 0) {
            Add-Chunk $Chunks $Tier $RepoName $RepoSha $Root $File $heading $start $i ($buffer -join [Environment]::NewLine)
            $buffer.Clear()
            $start = $i + 1
            $heading = $Matches[2]
        } elseif ($lines[$i] -match '^(#{1,3})\s+(.+)$') {
            $start = $i + 1
            $heading = $Matches[2]
        }
        $buffer.Add($lines[$i])
    }
    if ($buffer.Count -gt 0) {
        Add-Chunk $Chunks $Tier $RepoName $RepoSha $Root $File $heading $start $lines.Length ($buffer -join [Environment]::NewLine)
    }
}

function Add-LineChunks(
    [System.Collections.Generic.List[object]]$Chunks,
    [string]$Tier,
    [string]$RepoName,
    [string]$RepoSha,
    [string]$Root,
    [System.IO.FileInfo]$File,
    [int]$ChunkLines
) {
    $lines = Read-LinesShared $File.FullName
    for ($start = 0; $start -lt $lines.Length; $start += $ChunkLines) {
        $end = [Math]::Min($start + $ChunkLines - 1, $lines.Length - 1)
        Add-Chunk $Chunks $Tier $RepoName $RepoSha $Root $File '' ($start + 1) ($end + 1) (($lines[$start..$end]) -join [Environment]::NewLine)
    }
}

function Get-RecentLogs([string]$ServerDir, [int]$Count) {
    if (-not (Test-Path -LiteralPath $ServerDir)) { return @() }
    $patterns = @(
        (Join-Path $ServerDir 'profiles\*.rpt'),
        (Join-Path $ServerDir 'profiles_hc2\*.rpt'),
        (Join-Path $ServerDir '@ExileServer\logs\*\*\*\*.log')
    )
    $logs = foreach ($pattern in $patterns) {
        Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First $Count
    }
    @($logs | Sort-Object LastWriteTime -Descending | Select-Object -First ($Count * $patterns.Count))
}

$roots = @(
    @{ Path = Resolve-OrNull $VaultDir; Tier = 'vault'; Repo = 'ARMA3_EXILE_CODEX'; Sha = '' },
    @{ Path = Resolve-OrNull (Join-Path $XcsvDir 'wiki'); Tier = 'wiki'; Repo = 'XCSV'; Sha = Git-Sha $XcsvDir },
    @{ Path = Resolve-OrNull (Join-Path $XcsvDir 'tools'); Tier = 'committed-source'; Repo = 'XCSV'; Sha = Git-Sha $XcsvDir },
    @{ Path = Resolve-OrNull (Join-Path $ExileRepo 'LiveSource'); Tier = 'committed-source'; Repo = 'Exile'; Sha = Git-Sha $ExileRepo },
    @{ Path = Resolve-OrNull (Join-Path $ExileRepo 'tools'); Tier = 'committed-source'; Repo = 'Exile'; Sha = Git-Sha $ExileRepo },
    @{ Path = Resolve-OrNull (Join-Path $GuardRepo 'src'); Tier = 'committed-source'; Repo = 'XCSV_GUARD'; Sha = Git-Sha $GuardRepo },
    @{ Path = Resolve-OrNull (Join-Path $GuardRepo 'tools'); Tier = 'committed-source'; Repo = 'XCSV_GUARD'; Sha = Git-Sha $GuardRepo },
    @{ Path = Resolve-OrNull $AddonsRepo; Tier = 'committed-source'; Repo = 'XCSV_ADDONS'; Sha = Git-Sha $AddonsRepo }
) | Where-Object { $_.Path }

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$chunks = New-Object System.Collections.Generic.List[object]
foreach ($root in $roots) {
    Get-ChildItem -LiteralPath $root.Path -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $allowedExtensions -contains $_.Extension.ToLowerInvariant() -and
            $_.Length -le $MaxFileBytes -and
            $_.Name -ne 'Memory-Index.md' -and
            $_.FullName -notmatch $skipDirPattern -and
            $_.Name -notmatch $secretNamePattern
        } |
        Sort-Object FullName |
        ForEach-Object {
            if ($_.Extension.ToLowerInvariant() -eq '.md') {
                Add-MarkdownChunks $chunks $root.Tier $root.Repo $root.Sha $root.Path $_
            } else {
                Add-LineChunks $chunks $root.Tier $root.Repo $root.Sha $root.Path $_ $ChunkLines
            }
        }
}

$liveRoot = Resolve-OrNull $LiveServerDir
if ($liveRoot) {
    Get-RecentLogs -ServerDir $liveRoot -Count $RecentLogCount |
        Where-Object {
            $_.Length -le $MaxFileBytes -and
            $_.FullName -notmatch $skipDirPattern -and
            $_.Name -notmatch $secretNamePattern
        } |
        ForEach-Object {
            Add-LineChunks $chunks 'log' 'live-server' '' $liveRoot $_ $ChunkLines
        }
}

$indexFile = Join-Path $OutDir 'xcsv-rag.jsonl'
$manifestFile = Join-Path $OutDir 'manifest.json'
$encoding = New-Object System.Text.UTF8Encoding($false)
$jsonl = ($chunks | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 6 }) -join [Environment]::NewLine
[System.IO.File]::WriteAllText($indexFile, $jsonl + [Environment]::NewLine, $encoding)

$manifest = [pscustomobject]@{
    generated_at = (Get-Date).ToString('s')
    index_file   = $indexFile
    chunk_count  = $chunks.Count
    roots        = $roots
    max_file_bytes = $MaxFileBytes
    chunk_lines  = $ChunkLines
    recent_log_count = $RecentLogCount
    secret_name_pattern = $secretNamePattern
}
[System.IO.File]::WriteAllText($manifestFile, ($manifest | ConvertTo-Json -Depth 6), $encoding)

[pscustomobject]@{
    IndexFile = $indexFile
    Manifest  = $manifestFile
    Chunks    = $chunks.Count
}
