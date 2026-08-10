# GUARD-RCON-001 - RCon credential actually repaired

Work ID: `GUARD-RCON-001`

Owning repo: `XCSV_GUARD` (config only; no code change)

Issue: `x-cessive/XCSV` #12

Date: 2026-08-10

Verdict: `PASS_RUNTIME_VERIFIED` (was `PARTIAL_REPAIRED_CONFIG`)

## Defect

GUARD's RCon stayed offline. Invoking Connect produced `bad RCon password` /
`login rejected`, so admin control (kick, ban, say, broadcast) was unavailable
from the console.

## What the 2026-08-08 pass got wrong

The earlier repair recorded:

```text
repaired GUARD decrypted secret hash:
  C37863F3F03B0DB0C4BE1BE1C1D5C46468319E04D751015CD3755FB925A7FA9F
```

The config file on disk is **byte-identical** to that pass - current SHA256
`44788C2F9F43B67AD8210C6AD15A421EC05B2A404BB6033482FF830A62F78856` matches the
recorded post-repair hash exactly, so nothing overwrote it since. But decrypting
the stored blob gives:

```text
GUARD decrypted : len=14  hash16=5EA3E8AFE8D52C8D
```

A **14-character** secret matching neither BattlEye config, and not the
pre-repair value either. The blob length corroborates it: the stored blob is 492
characters, while freshly encrypting the real 28-character password produces
556. The claimed repair was never actually written to disk - the verification
was of something other than the saved artifact.

GUARD's own crypto is not at fault. Its `protect`/`unprotect` pair
(`ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString`, then
`PtrToStringAuto(SecureStringToBSTR(...))`) round-trips the real 28-character
password byte-exactly, verified before any change was made.

## A wrong hypothesis, caught by measuring

The initial read of the evidence here was that BattlEye had fallen back to
`beserver.cfg`, because there is no `BEServer_x64.cfg` in `-bepath` and the
16-character configs are dated 2026-08-04 while the x64 *active* file is dated
2026-08-02. That reasoning was plausible and **wrong**.

Rather than "fix" GUARD on it, the credentials were tested directly:

```text
crc32 self-test: 0xCBF43926 (expected 0xCBF43926)
target: 127.0.0.1:2302

REJECTED   beserver.cfg (len 16, hash AFC097B80768B4A9)
REJECTED   beserver_active_134f.cfg (len 16, hash AFC097B80768B4A9)
LOGIN OK   BEServer_x64_active_274a.cfg (len 28, hash C37863F3F03B0DB0)
```

So the server does use the 28-character x64 credential. The 2026-08-08 pass
picked the right password and failed to store it; this pass nearly replaced a
correct choice with a wrong one on inference. Measuring settled it in seconds.

## Repair

Config only, `C:\Users\Architect\Desktop\xcsv_guard.json`:

- backup `xcsv_guard.json.20260810-034034.pre-rcon-reencrypt.bak`, hash-verified
  against the live file before proceeding
- GUARD stopped first, so it could not write stale in-memory config back over
  the patched file
- the new blob was decrypted and compared against the source **before** being
  written anywhere; a mismatch would have aborted
- only the `rcon_password_enc` value was substituted, by exact string
  replacement, leaving the rest of the JSON untouched
- written as UTF-8 **without** BOM, since serde_json rejects a BOM and GUARD
  would silently fall back to defaults

```text
pre  sha256 44788C2F9F43B67AD8210C6AD15A421EC05B2A404BB6033482FF830A62F78856
post sha256 AB8C399474C3E01138AA730D26B1828538869E95782BB42B3BB4C7E9867421F6

on-disk now decrypts: len=28 hash16=C37863F3F03B0DB0
plaintext rcon_password still empty: True
BOM present: False
```

## Runtime proof

GUARD relaunched (PID 432) and placed on the right half at `960x1032+960+0` per
the layout rule. RCon connected through the UI:

```text
rcon chip -> online

03:41:41  !  connecting to 127.0.0.1:2302 ...
03:41:41  !  RCon authenticated
03:41:41  *  RCon admin #2 (127.0.0.1:56069) logged in
```

The third line is server-originated - it arrived over the RCon channel - so this
is a genuine authenticated bidirectional session, not just a local claim of
success.

Not overclaimed: a `players` command was sent (`> players`, 03:42:26) and does
not echo a reply into the console. That is by design - `rcon.rs` routes player
responses into `players_raw` for the Players tab rather than the log pane - so
it is not evidence either way and is not counted as proof here.

GUARD doctor after the repair: **25 passed, 1 warned, 0 failed**, with
`credentials-at-rest` and `config-bom` both passing. The single warning remains
the known infiSTAR cloud 403.

## Tooling added

`tools/rcon-probe.ps1` - read-only BattlEye RCon login probe. Sends one login,
reads the ack, closes; issues no commands. Reports candidates by truncated
SHA-256 so two secrets can be told apart without printing either.

It **refuses to report** unless its CRC32 first reproduces
`crc32("123456789") = 0xCBF43926`. That guard is the point of the script: the
2026-08-08 attempt had to be discarded as `BAD_PROBE_IMPLEMENTATION` for an
invalid CRC32, and the self-test caught a real bug on the very first run here -
in PowerShell 5.1 the literal `0xFFFFFFFF` parses as Int32 `-1`, so the register
initialised wrong and every digest was garbage. Without the self-test that would
have produced confident, meaningless verdicts for a third time.

## Security follow-up - action recommended

During diagnosis a helper function named `H` collided with PowerShell's builtin
`h` alias for `Get-History`. The resulting parameter-binding errors **echoed
both RCon passwords in plaintext** into the session transcript.

The credential grants kick, ban and shutdown on a publicly listed server. It is
now present in an agent session log. Everything after that point in this receipt
deliberately uses hashes only, but that does not undo the exposure.

**Recommended: rotate the RCon password.** Change `RConPassword` in
`E:\arma3server\battleye\BEServer_x64_active_274a.cfg`, restart the server so
BattlEye reloads it, then re-point GUARD using the same procedure above and
confirm with `tools/rcon-probe.ps1`. This is the operator's call, not an
automatic action, because it drops any live RCon session.
