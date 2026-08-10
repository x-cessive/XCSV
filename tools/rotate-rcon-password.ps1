<#
    rotate-rcon-password.ps1 - rotate the BattlEye RCon credential everywhere it
    is stored, and re-point GUARD at it.

    Why this exists
    ---------------
    Written during GUARD-RCON-002, after the live RCon password was exposed in
    plaintext in an agent session transcript. Rotation touches four artifacts
    that must agree or admin control breaks, and doing it by hand is how the
    credential drifted in the first place (GUARD-RCON-001: the right password
    was chosen and a *different* value ended up encrypted in GUARD's config,
    unnoticed for two days because nothing verified the saved artifact).

    What it does
    ------------
      1. generates a fresh alphanumeric secret
      2. rewrites RConPassword in every BattlEye cfg that has one, byte-level so
         encoding and line endings cannot shift
      3. stops GUARD, re-encrypts the new secret into xcsv_guard.json, restarts
         GUARD placed on the right per the layout rule
      4. redacts its own pre-rotation backups, because a readable copy of a
         compromised secret defeats the rotation

    The secret is never printed. Everything is reported as a truncated SHA-256
    so two candidates can be told apart safely.

    AFTER RUNNING: restart the server, then verify with tools/rcon-probe.ps1.
    BattlEye only loads its config at boot, so until the server restarts the old
    credential is still the live one.

    Usage
    -----
        .\tools\rotate-rcon-password.ps1              rotate and re-point GUARD
        .\tools\rotate-rcon-password.ps1 -WhatIfOnly  report what would change
#>

[CmdletBinding()]
param(
    [string]$BePath     = 'E:\arma3server\battleye',
    [string]$GuardCfg   = "$env:USERPROFILE\Desktop\xcsv_guard.json",
    [string]$GuardExe   = "$env:USERPROFILE\Desktop\XCSV_GUARD.exe",
    [int]$Length        = 32,
    [switch]$WhatIfOnly
)

$ErrorActionPreference = 'Stop'

function Get-SecretHash([string]$s) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    (-join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s)) | ForEach-Object { $_.ToString('X2') })).Substring(0,16)
}

# Alphanumeric only. BattlEye splits the cfg line on whitespace, so a space or
# quote in the value yields a password nothing can actually use.
function New-Password([int]$len) {
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
    $bytes = New-Object 'byte[]' ($len * 4)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $len; $i++) {
        [void]$sb.Append($chars[[int]([BitConverter]::ToUInt32($bytes, $i*4) % [uint32]$chars.Length)])
    }
    $sb.ToString()
}

function Set-CfgPassword([string]$file, [string]$old, [string]$new) {
    # Byte-level substitution: a line rewrite would risk re-encoding the file.
    $bytes    = [IO.File]::ReadAllBytes($file)
    $oldBytes = [Text.Encoding]::ASCII.GetBytes($old)
    $newBytes = [Text.Encoding]::ASCII.GetBytes($new)
    $idx = -1
    for ($i = 0; $i -le $bytes.Length - $oldBytes.Length; $i++) {
        $m = $true
        for ($k = 0; $k -lt $oldBytes.Length; $k++) { if ($bytes[$i+$k] -ne $oldBytes[$k]) { $m = $false; break } }
        if ($m) { $idx = $i; break }
    }
    if ($idx -lt 0) { throw "old credential not found verbatim in $file" }
    $tail    = $idx + $oldBytes.Length
    $tailLen = $bytes.Length - $tail
    # PowerShell array slices are Object[], so copy explicitly into a byte[].
    $out = New-Object 'byte[]' ($idx + $newBytes.Length + $tailLen)
    [Array]::Copy($bytes,    0,     $out, 0,                       $idx)
    [Array]::Copy($newBytes, 0,     $out, $idx,                    $newBytes.Length)
    [Array]::Copy($bytes,    $tail, $out, $idx + $newBytes.Length, $tailLen)
    [IO.File]::WriteAllBytes($file, $out)
}

function Get-CfgPassword([string]$file) {
    foreach ($l in [IO.File]::ReadAllLines($file)) {
        if ($l -match '^\s*RConPassword\s+(\S+)') { return $Matches[1] }
    }
    $null
}

$cfgs = @(Get-ChildItem $BePath -Filter '*.cfg' -ErrorAction SilentlyContinue |
          Where-Object { Get-CfgPassword $_.FullName })
if (-not $cfgs) { throw "no BattlEye cfg with an RConPassword under $BePath" }

Write-Host ("configs holding a credential: {0}" -f $cfgs.Count)
foreach ($c in $cfgs) {
    Write-Host ("  {0,-32} current hash {1}" -f $c.Name, (Get-SecretHash (Get-CfgPassword $c.FullName)))
}
if ($WhatIfOnly) { Write-Host 'WhatIfOnly: nothing changed'; return }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$new   = New-Password $Length
Write-Host ''
Write-Host ("new credential: len={0} hash={1}" -f $new.Length, (Get-SecretHash $new))

$backups = @()
foreach ($c in $cfgs) {
    $old = Get-CfgPassword $c.FullName
    $bak = "$($c.FullName).$stamp.pre-rotate.bak"
    Copy-Item $c.FullName $bak
    if ((Get-FileHash $c.FullName -Algorithm SHA256).Hash -ne (Get-FileHash $bak -Algorithm SHA256).Hash) {
        throw "backup hash mismatch for $($c.Name)"
    }
    $backups += $bak
    Set-CfgPassword $c.FullName $old $new
    if ((Get-CfgPassword $c.FullName) -cne $new) { throw "verification failed for $($c.Name)" }
    Write-Host ("  rotated {0,-32} {1} -> {2}" -f $c.Name, (Get-SecretHash $old), (Get-SecretHash $new))
}

# GUARD must be down first, or it writes stale in-memory config back over this.
$g = Get-Process XCSV_GUARD -ErrorAction SilentlyContinue
if ($g) {
    $null = $g.CloseMainWindow(); Start-Sleep -Seconds 4
    $g = Get-Process -Id $g.Id -ErrorAction SilentlyContinue
    if ($g) { Stop-Process -Id $g.Id -Force }
    Start-Sleep -Seconds 2
    Write-Host 'GUARD stopped'
}

$bak = "$GuardCfg.$stamp.pre-rotate.bak"
Copy-Item $GuardCfg $bak
$blob = ConvertTo-SecureString $new -AsPlainText -Force | ConvertFrom-SecureString
# Prove the blob decrypts to the intended value BEFORE it is written anywhere.
$chk = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR(($blob | ConvertTo-SecureString)))
if ($chk -cne $new) { throw 'new blob does not round-trip - refusing to write' }

$raw = [IO.File]::ReadAllText($GuardCfg)
$oldBlob = ($raw | ConvertFrom-Json).rcon_password_enc
if (-not $raw.Contains($oldBlob)) { throw 'old blob not found verbatim in GUARD config' }
# UTF-8 without BOM: serde_json rejects a BOM and GUARD silently falls back to
# defaults - no paths, no credentials, no indication why.
[IO.File]::WriteAllText($GuardCfg, $raw.Replace($oldBlob, $blob), (New-Object System.Text.UTF8Encoding($false)))

$after = Get-Content $GuardCfg -Raw | ConvertFrom-Json
$back  = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
          [Runtime.InteropServices.Marshal]::SecureStringToBSTR(($after.rcon_password_enc | ConvertTo-SecureString)))
Write-Host ("GUARD config now decrypts to hash {0}  matches={1}  plaintextEmpty={2}" -f `
    (Get-SecretHash $back), ($back -ceq $new), [string]::IsNullOrEmpty($after.rcon_password))
if ($back -cne $new) { throw 'GUARD config did not take the new credential' }

# A readable copy of a compromised secret defeats the rotation.
$note = "REDACTED $stamp - rotate-rcon-password.ps1. This pre-rotation backup held a`r`n" +
        "superseded RCon credential. The only thing it could restore is the old`r`n" +
        "secret, so its contents were overwritten. Live configs carry the rotated`r`n" +
        "value; verify with tools/rcon-probe.ps1 after restarting the server.`r`n"
foreach ($b in $backups) { [IO.File]::WriteAllText($b, $note, (New-Object System.Text.UTF8Encoding($false))) }
Write-Host ("redacted {0} pre-rotation cfg backup(s)" -f $backups.Count)

if (Test-Path $GuardExe) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type @"
using System;using System.Runtime.InteropServices;
public class RotWin { [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f); }
"@ -ErrorAction SilentlyContinue
    $p = Start-Process $GuardExe -WorkingDirectory (Split-Path $GuardExe -Parent) -PassThru
    for ($i = 0; $i -lt 40 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 500; $p.Refresh() }
    $a = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $x = $a.Left + [int][Math]::Floor($a.Width / 2)
    [void][RotWin]::SetWindowPos($p.MainWindowHandle, [IntPtr]::Zero, $x, $a.Top, ($a.Right - $x), $a.Height, 0x0040)
    Write-Host ("GUARD relaunched (pid {0}) and placed right" -f $p.Id)
}

Write-Host ''
Write-Host 'NEXT: restart the Arma server so BattlEye reloads the config, then run'
Write-Host '      tools\rcon-probe.ps1 and expect LOGIN OK.'
