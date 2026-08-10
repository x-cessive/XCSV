# Deploy runbook - taking the staged XM8 work live

Written 2026-08-10. Everything below is packed, verified and waiting; none of it
is deployed.

This exists as a document rather than a script because the environment the work
was done in cannot write to the live server tree, stop the stack, or start a
service. The checks are written out so they can be followed by hand, and so a
script can be made of them later by someone who can run it.

## What is waiting

| artifact | staged at | goes to |
| --- | --- | --- |
| mission | `D:\CAGE\xcsv-runtime\Exile.Tanoa.staging.pbo` | `E:\arma3server\mpmissions\Exile.Tanoa.pbo` |
| server addon | `D:\CAGE\xcsv-runtime\xcsv_chatter.staging.pbo` | `E:\arma3server\@ExileServer\addons\xcsv_chatter.pbo` |

The `sql_custom` OUTPUT fix is already written to both copies of `exile.ini` and
needs only a server start to take effect.

## Before you touch anything

```powershell
D:\XCSV\tools\xcsv-wiring-audit.ps1     # expect: 5 passed, 0 warned, 0 failed
& 'E:\ArmaTools\pbo.ps1' Verify 'D:\CAGE\xcsv-runtime\Exile.Tanoa.staging.pbo'
& 'E:\ArmaTools\pbo.ps1' Verify 'D:\CAGE\xcsv-runtime\xcsv_chatter.staging.pbo'
```

If the wiring audit fails, read it before deploying - it is checking for the
class of defect that made the Insurance app decoration for its whole life.

**Do not repack from source as part of deploying.** Pack and deploy as two
separate acts. A repack from a stale source is what silently rolled the mission
back on 08-10, and a repack of the addon from its stale source would have
deleted an entire network handler that existed only inside the deployed PBO.
These artifacts were packed from a source that was correct at pack time; that is
the whole value of staging them.

## Order, and why it is this order

1. **Stop GUARD, then the headless client, then the server.** Clients of the
   database before the database. The MariaDB error log for the 08-10 outage
   shows the server's twelve extDB connections aborting first and the service
   stopping four seconds later - that ordering is what makes a shutdown clean
   rather than one that aborts live connections.

2. **Confirm `arma3server_x64` is actually gone** before copying. The live PBO
   is locked while the server runs; the copy will fail rather than corrupt, but
   a failed copy that goes unnoticed means you start the old mission and wonder
   why nothing changed.

3. **Back up both live PBOs** with a timestamp suffix before overwriting, and
   `Verify` each file after the copy. A truncated copy is the failure this
   catches.

4. **Start MariaDB before anything else.** It is currently `Stopped` with
   StartType `Automatic`. If the server starts without it, extDB fails during
   world init and the process exits **with no error line** - which is a
   genuinely hard failure to read after the fact.

5. **Start GUARD** and let it autostart the server and HC (`autostart_server` is
   true, 45s delay). Do not start the server directly: GUARD adopting a server
   it did not start is the situation GUARD-HC-002 was written for, and there is
   no reason to exercise it.

6. **Prove it booted.** Watch the newest RPT in `E:\arma3server\profiles` for
   `Server is up and running`. Then check exactly one `Starting mission:` and no
   `No entry` lines. Then run `D:\XCSV_GUARD\tools\doctor.ps1`.

Expect doctor to read roughly `26 passed, 1 warned, 0 failed`, the warning being
the external infiSTAR 403. `mission-drift` should return to PASS once the swap
is done - it currently FAILS, correctly, and that failure is the fix made this
morning working.

## What to look for afterwards - none of these has ever appeared

This is the real acceptance test. Four log lines, none of which has been seen
once in the server's history:

```text
[XCSV_XM8] extra apps grid: 16 buttons in slide ...
```
Open the XM8 extra-apps page. 16 is the number; anything else means the grid
skipped something.

```text
[XCSV_INS] <uid> inspected '<fragment>' -> N row(s)
```
The first Player Inspector search ever run. Type at least two characters and
press Enter.

```text
[XCSV_POLICY] ... bought a policy for 2500
```
**The first Insurance purchase in the server's history.** This is a real test,
not a formality: it exercises the `xcsv_policy` INSERT, the charge reload on
next connect, and the death payout, none of which has ever executed. Expect a
non-zero `loaded N charge(s)` after reconnecting.

```text
[XCSV_WELCOME] reached the gate: seen=... version=1 force=...
```
Settles whether the lore briefing has ever been delivered. If it reads
`suppressed`, the briefing works and this profile had already seen it. If the
line is absent entirely, the script is not running and that is a new defect.

## If something is wrong

Every overwritten file has a `.<timestamp>.bak` beside it. Restore it, verify
it, and start again. Nothing in this deployment touches the database schema, so
there is nothing to roll back on that side.

## Known-good state to compare against

- GUARD `cargo test`: 267 passed, 0 failed.
- Mission PBO: 359 entries, checksum OK.
- Addon PBO: 12 entries, checksum OK.
- Wiring audit: 5 passed, 0 warned, 0 failed.
- Cold paths before deploy: 5 of 16 tags cold (`XCSV_DEBUG`, `XCSV_INS`,
  `XCSV_SHARED`, `XCSV_WELCOME`, `XCSV_XM8`). After a session with the XM8
  opened, `XCSV_SHARED` and `XCSV_XM8` should both go warm. `XCSV_DEBUG` is
  dormant by design.
