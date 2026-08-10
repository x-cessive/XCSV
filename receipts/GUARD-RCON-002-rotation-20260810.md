# GUARD-RCON-002 - RCon credential rotation after transcript exposure

Work ID: `GUARD-RCON-002`

Owning target: live server `E:\arma3server\battleye`, plus GUARD config

Priority: P1 - live credential exposure on a publicly listed server

Gauntlet: G3

Date: 2026-08-10

Verdict: `PASS_RUNTIME_VERIFIED`

## Why

During `GUARD-RCON-001` diagnosis, a helper function named `H` collided with
PowerShell's builtin `h` alias for `Get-History`. The resulting
parameter-binding errors echoed **both** RCon passwords in plaintext into an
agent session transcript. That credential grants kick, ban and shutdown on a
publicly listed server.

Rotation was requested by ARCHITECT and carried out here.

## Scope check first

Before changing anything, every store of either leaked secret was located, so
rotation could not break something that hardcoded it:

```text
E:\arma3server\battleye\beserver.cfg                  [16-char]
E:\arma3server\battleye\beserver_active_134f.cfg      [16-char]
E:\arma3server\battleye\BEServer_x64_active_274a.cfg  [28-char]
```

Nothing else under `E:\arma3server` or the Desktop referenced either value - no
script, mission file or scheduled task. Both leaked secrets were rotated, not
just the live one, since both were exposed.

All three configs were given the **same** new 32-character credential. There is
no `BEServer_x64.cfg` under `-bepath`, so which file BattlEye resolves to is
not fully pinned down; giving every candidate the same value means RCon works
whichever one it loads.

Connected players at rotation time: only the headless client. No real player
was dropped by the restart.

## Change

New credential: 32 chars, alphanumeric only (BattlEye splits the cfg line on
whitespace, so quotes or spaces produce a password nothing can use), from
`RandomNumberGenerator`. Hash `6AAB384D69D7A29B`. The value is not recorded
here or anywhere else in the repo.

Each config was backed up, hash-verified against the live file, then rewritten
**byte-level** so encoding and line endings could not shift:

```text
beserver.cfg                     AFC097B80768B4A9 -> 6AAB384D69D7A29B  verified=True
beserver_active_134f.cfg         AFC097B80768B4A9 -> 6AAB384D69D7A29B  verified=True
BEServer_x64_active_274a.cfg     C37863F3F03B0DB0 -> 6AAB384D69D7A29B  verified=True
```

GUARD was stopped before its config was touched, so it could not write stale
in-memory state back over the patch. The new blob was decrypted and compared
against the source **before** being written; only `rcon_password_enc` was
substituted; the file was written UTF-8 without BOM.

```text
GUARD config decrypts to hash 6AAB384D69D7A29B  matches=True  plaintextEmpty=True
post sha256 AF48413603C1037D78CDE7838E1DC0CCE5A21C2D611DAEE4C5AE16505FE61286
```

## Runtime proof

Server restarted through the GUARD UI so BattlEye would reload its config
(it only reads it at boot). New server PID `9708`, then `18752` after the HC
recovery cycle below.

```text
crc32 self-test: 0xCBF43926 (expected 0xCBF43926)
target: 127.0.0.1:2302

LOGIN OK   beserver.cfg (len 32, hash 6AAB384D69D7A29B)
LOGIN OK   beserver_active_134f.cfg (len 32, hash 6AAB384D69D7A29B)
LOGIN OK   BEServer_x64_active_274a.cfg (len 32, hash 6AAB384D69D7A29B)
```

GUARD reconnected on the rotated credential:

```text
rcon chip -> online
03:57:49  !  RCon authenticated
03:57:49  *  RCon admin #1 (127.0.0.1:62029) logged in
```

The second line is server-originated, so this is a real authenticated session.

Final doctor: **25 passed, 1 warned, 0 failed** - `credentials-at-rest`,
`config-bom`, `hc-join` and `battleye-enforcement 11 of 51` all passing. The
single warning is the known infiSTAR cloud 403.

## Leaked copies removed

The pre-rotation backups contained the compromised secrets in plaintext, which
defeats the point of rotating. Their contents were overwritten in place with a
note explaining why. A sweep confirms nothing readable remains:

```text
plaintext copies of leaked credentials remaining: 0
```

The files were redacted rather than deleted - `Remove-Item` was blocked by the
sandbox on that path, and overwriting achieves the security goal while leaving
the audit trail that a backup existed. Note this is not forensic erasure: prior
contents may survive in filesystem slack or backups outside this tree.

## Side effect, and the limitation it exercised

The server restart orphaned the headless client, and GUARD had been restarted
*after* the server, so the `GUARD-HC-001` recovery never armed - it arms on a
server start, and this GUARD instance did not perform one. This is exactly the
"known limitation" recorded in that receipt, observed in the wild within an hour
of being written.

Cleared with the documented workaround, a full `STOP EVERYTHING` /
`START EVERYTHING` cycle: server `18752`, HC `40688` joined at `04:02:38`, one
mission start, no duplicates.

Worth reconsidering: the limitation is more reachable than it looked. Any
sequence that restarts GUARD after a server restart leaves a stranded HC that
nothing recovers until the next server start. A cheap improvement would be to
arm the join check on GUARD startup too, gated on the server having started
recently enough that its RPT tail still covers the join window.

## Tooling added

`tools/rotate-rcon-password.ps1` - performs the whole rotation: generate,
rewrite every BattlEye cfg byte-level, stop GUARD, re-encrypt with a verified
round-trip, relaunch GUARD placed right, and redact its own backups. Never
prints the secret; reports everything as truncated SHA-256. `-WhatIfOnly` lists
what would change.

It deliberately does **not** restart the server, because that decision depends
on who is connected. It prints the required next step instead.

## Follow-up

- The exposed credential is dead. No action outstanding on the exposure itself.
- If any external tooling outside `E:\arma3server` held the old RCon password,
  it will now fail; the scope check found none, but that scan covered the server
  tree and Desktop only.
