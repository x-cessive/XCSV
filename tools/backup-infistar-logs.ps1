<#
    backup-infistar-logs.ps1 - archive the infiSTAR admin logs off the game drive.

    Why this exists
    ---------------
    infiSTAR's hosted panel has been rejecting uploads with HTTP 403 since at
    least 2026-08-01 (6,612 occurrences and counting). The client is healthy -
    it loads config.vision successfully every boot - so the refusal is an
    authorisation decision on infiSTAR's side, not something fixable from this
    machine. See receipts/INFISTAR-AUDIT-001-20260810.md.

    The consequence is what matters: the local logs under
    @infiSTAR_A3_vision are the *only* record of admin actions, player joins,
    BattlEye events and Zeus usage. They sat on the same drive as the server,
    with no copy anywhere. One disk fault and the audit trail is gone.

    This takes a compressed, hash-manifested snapshot onto a different drive.

    Deliberately read-only with respect to the live logs
    ---------------------------------------------------
    It copies; it never truncates, rotates or deletes anything under
    @infiSTAR_A3_vision. infiSTAR holds those files open, and truncating a log a
    running process has a handle on is a good way to corrupt it or silently lose
    writes. E: has ample free space, so there is no reason to take that risk -
    growth is not the problem being solved here, absence of a copy is.

    The manifest exists so the archive is useful as evidence: an audit trail you
    cannot prove is unmodified is a weak audit trail.

    Usage
    -----
        .\tools\backup-infistar-logs.ps1
        .\tools\backup-infistar-logs.ps1 -Keep 60
        .\tools\backup-infistar-logs.ps1 -DestRoot D:\CAGE\xcsv-audit-archive
#>

[CmdletBinding()]
param(
    [string]$SourceDir = 'E:\arma3server\@infiSTAR_A3_vision',
    [string]$DestRoot  = 'D:\CAGE\xcsv-audit-archive',
    [int]$Keep         = 30
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $SourceDir)) { throw "source not found: $SourceDir" }
New-Item -ItemType Directory -Force -Path $DestRoot | Out-Null

# Staging goes on the destination drive, never C:. Filling the system drive with
# scratch data is a mistake this estate has already made once.
$stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$staging = Join-Path $DestRoot ".staging-$stamp"
New-Item -ItemType Directory -Force -Path $staging | Out-Null

function Copy-Locked([string]$src, [string]$dst) {
    # infiSTAR keeps these open; a plain Copy-Item throws on the busy ones.
    $in = New-Object System.IO.FileStream($src, [System.IO.FileMode]::Open,
          [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $out = New-Object System.IO.FileStream($dst, [System.IO.FileMode]::Create,
               [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try { $in.CopyTo($out) } finally { $out.Dispose() }
    } finally { $in.Dispose() }
}

$manifest = New-Object System.Collections.Generic.List[string]
$manifest.Add("XCSV infiSTAR audit archive")
$manifest.Add("taken     : $(Get-Date -Format o)")
$manifest.Add("source    : $SourceDir")
$manifest.Add("host      : $env:COMPUTERNAME")
$manifest.Add("")
$manifest.Add("sha256                                                            bytes        name")

# Logs only. config.vision is deliberately excluded: it is configuration rather
# than audit data, and it holds the infiSTAR licence material. It happens to be
# exclusively locked while the server runs, but relying on that would mean the
# archive quietly starts collecting credentials the first time a backup runs
# with the server stopped.
$files = @(Get-ChildItem $SourceDir -File -Filter *.log)
if (-not $files) { throw "no log files under $SourceDir" }

$copied = 0
$total  = 0
foreach ($f in $files) {
    $dst = Join-Path $staging $f.Name
    try {
        Copy-Locked $f.FullName $dst
    } catch {
        # config.vision is held with an exclusive lock by the running server.
        # Record the gap rather than failing the whole snapshot over it.
        $manifest.Add(("{0,-64} {1,12} {2}  [SKIPPED: {3}]" -f '-', 0, $f.Name, $_.Exception.Message.Split([char]10)[0]))
        continue
    }
    $h = (Get-FileHash $dst -Algorithm SHA256).Hash
    $len = (Get-Item $dst).Length
    $manifest.Add(("{0} {1,12} {2}" -f $h, $len, $f.Name))
    $copied++; $total += $len
}

$manifest.Add("")
$manifest.Add("files copied: $copied of $($files.Count), $([Math]::Round($total/1MB,2)) MB uncompressed")
$manifest | Set-Content (Join-Path $staging 'MANIFEST.txt') -Encoding utf8

$zip = Join-Path $DestRoot "infistar-$stamp.zip"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($staging, $zip,
    [System.IO.Compression.CompressionLevel]::Optimal, $false)

# Prove the archive opens and holds what we think, before deleting the staging
# copy. An unverified backup is a guess.
$entries = 0
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
try { $entries = $archive.Entries.Count } finally { $archive.Dispose() }
if ($entries -lt ($copied + 1)) { throw "archive verification failed: $entries entries, expected at least $($copied+1)" }

Remove-Item $staging -Recurse -Force

$zipMb = [Math]::Round((Get-Item $zip).Length / 1MB, 2)
Write-Host ("archived {0} file(s), {1} MB -> {2} MB  {3}" -f $copied, [Math]::Round($total/1MB,2), $zipMb, (Split-Path $zip -Leaf))
Write-Host ("verified {0} entries in the archive (including MANIFEST.txt)" -f $entries)

# Retention. Only ever touches this tool's own archives.
$old = @(Get-ChildItem $DestRoot -Filter 'infistar-*.zip' | Sort-Object Name -Descending | Select-Object -Skip $Keep)
foreach ($o in $old) { Remove-Item $o.FullName -Force; Write-Host ("pruned {0}" -f $o.Name) }
Write-Host ("retained {0} archive(s) in {1}" -f (@(Get-ChildItem $DestRoot -Filter 'infistar-*.zip')).Count, $DestRoot)
