<#
    rcon-probe.ps1 - answer "does this RCon credential actually work?" without
    guessing and without touching GUARD's config.

    Why this exists
    ---------------
    GUARD-RCON-001 was diagnosed twice from inference and got the wrong answer
    both times. A hand-written probe was attempted during the first pass and had
    to be discarded as BAD_PROBE_IMPLEMENTATION because its CRC32 was invalid -
    so it produced confident, meaningless verdicts.

    The fix is not "be careful", it is a self-test. This script refuses to
    report anything until its CRC32 reproduces the standard check vector
    crc32("123456789") = 0xCBF43926. That check immediately caught a real bug on
    the first run here: in PowerShell 5.1 the literal 0xFFFFFFFF parses as Int32
    -1, so the register initialised wrong and every digest was garbage.

    Protocol (BERConProtocol)
    ------------------------
        packet  = 'B' 'E' <crc32 LE of payload> <payload>
        payload = 0xFF <type> [data]
        login   = type 0x00, data = password bytes
        reply   = 0xFF 0x00 <0x01 success | 0x00 failure>

    The CRC32 is the reflected IEEE one (init 0xFFFFFFFF, final XOR 0xFFFFFFFF)
    over the payload only - not over the 'BE' magic.

    Read-only: sends one login, reads the ack, closes. It issues no commands and
    changes nothing. Secrets are never printed; passwords are reported by a
    truncated SHA-256 so two candidates can be told apart safely.

    Usage
    -----
        .\tools\rcon-probe.ps1                       test every BE cfg found
        .\tools\rcon-probe.ps1 -BePath E:\...\battleye
        .\tools\rcon-probe.ps1 -Password '<secret>'  test one value explicitly
#>

[CmdletBinding()]
param(
    [string]$BePath   = 'E:\arma3server\battleye',
    [string]$ServerIp = '127.0.0.1',
    [int]$Port        = 2302,
    [string]$Password
)

$ErrorActionPreference = 'Stop'

$script:crcTable = $null
function Get-Crc32([byte[]]$bytes) {
    if (-not $script:crcTable) {
        $t = New-Object 'System.UInt32[]' 256
        for ($i = 0; $i -lt 256; $i++) {
            $c = [uint32]$i
            for ($k = 0; $k -lt 8; $k++) {
                if ($c -band 1) { $c = [uint32](0xEDB88320 -bxor [uint32]($c -shr 1)) }
                else            { $c = [uint32]($c -shr 1) }
            }
            $t[$i] = $c
        }
        $script:crcTable = $t
    }
    # 0xFFFFFFFF is Int32 -1 in PS 5.1; the explicit constant avoids that trap.
    $mask = [uint32]4294967295
    $crc = $mask
    foreach ($b in $bytes) {
        $idx = [int](([uint32]$crc -bxor [uint32]$b) -band 0xFF)
        $crc = [uint32](([uint32]$script:crcTable[$idx] -bxor ([uint32]$crc -shr 8)) -band $mask)
    }
    [uint32](([uint32]$crc -bxor $mask) -band $mask)
}

function Get-SecretHash([string]$s) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    (-join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s)) | ForEach-Object { $_.ToString('X2') })).Substring(0, 16)
}

function New-BePacket([byte]$type, [byte[]]$data) {
    $payload = New-Object System.Collections.Generic.List[byte]
    $payload.Add(0xFF); $payload.Add($type)
    if ($data) { $payload.AddRange($data) }
    $crc = Get-Crc32 $payload.ToArray()
    $out = New-Object System.Collections.Generic.List[byte]
    $out.Add(0x42); $out.Add(0x45)
    $out.AddRange([BitConverter]::GetBytes($crc))
    $out.AddRange($payload)
    $out.ToArray()
}

function Test-RconPassword([string]$password, [string]$label) {
    $client = New-Object System.Net.Sockets.UdpClient
    try {
        $client.Client.ReceiveTimeout = 4000
        $client.Connect($ServerIp, $Port)
        $pkt = New-BePacket 0x00 ([Text.Encoding]::ASCII.GetBytes($password))
        [void]$client.Send($pkt, $pkt.Length)
        $ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $resp = $client.Receive([ref]$ep)
        if ($resp.Length -ge 9 -and $resp[7] -eq 0x00) {
            if ($resp[8] -eq 1) { return "LOGIN OK   $label" }
            return "REJECTED   $label  (server refused the password)"
        }
        return ("UNEXPECTED $label  {0} bytes" -f $resp.Length)
    } catch {
        return "NO REPLY   $label  ($($_.Exception.Message))"
    } finally { $client.Close() }
}

# Refuse to report anything on an unverified digest.
$check = '{0:X8}' -f (Get-Crc32 ([Text.Encoding]::ASCII.GetBytes('123456789')))
Write-Host ("crc32 self-test: 0x{0} (expected 0xCBF43926)" -f $check)
if ($check -ne 'CBF43926') {
    Write-Host 'CRC32 SELF-TEST FAILED - refusing to report, any verdict would be meaningless'
    exit 1
}

Write-Host ("target: {0}:{1}" -f $ServerIp, $Port)
Write-Host ''

if ($Password) {
    Write-Host (Test-RconPassword $Password ("supplied value (hash {0})" -f (Get-SecretHash $Password)))
    return
}

$any = $false
foreach ($f in (Get-ChildItem $BePath -Filter '*.cfg' -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $pw = $null
    foreach ($l in [IO.File]::ReadAllLines($f.FullName)) {
        if ($l -match '^\s*RConPassword\s+(\S+)') { $pw = $Matches[1] }
    }
    if (-not $pw) { continue }
    $any = $true
    $label = "{0} (len {1}, hash {2})" -f $f.Name, $pw.Length, (Get-SecretHash $pw)
    Write-Host (Test-RconPassword $pw $label)
    Start-Sleep -Milliseconds 800
}
if (-not $any) { Write-Host "no RConPassword found in any cfg under $BePath" }
