---
layout: wiki
section: docs
title: Lessons
heading: Lessons
blurb: Mistakes actually made here, and the rule each one produced.
order: 9
source: Lessons.md
---

Mistakes that were actually made here, and the rule each one produced. Read this
before repeating one someone already paid for.

The headline finding, after auditing a full day of them: **seven of eight errors
were verification gaps, not knowledge gaps.** The fix is almost never "know
more". It is "check before asserting".

## Diagnosis

**A checksum verify is not an integrity check.** Three PBOs with a leading `\` on
every entry path verified clean and took the server down for six hours. Read the
entry table. → *[Runbook §6](Runbook.html)*

**Blaming the wrong component costs the most time.** "pbo.ps1 is not at fault"
was asserted, then disproved by reproducing the bug from a short-name path. The
tool *was* the root cause. Reproduce before exonerating.

**Symptoms outnumber causes in a loop.** `extDB2 is already setup & locked` and
`Unknown Protocol` were treated as database problems for hours. Count
`Starting mission:` first.

**Measurements taken at the wrong moment are lies.** An object count of 269 was
reported as the plateau; it was taken mid-population and the real figure was 576.
The improvement was ~17%, not 61%. Let the system settle before measuring.

**"FPS decays with uptime" was wrong.** It was a lootbox deadlock —
`LB_WaitSysBusy` at 40 stalled population at 66/103. Fixing it took FPS from 22
to 46 and completed the map. A plausible-sounding pattern is not a diagnosis.

**Do not dismiss volume as noise.** 160 `Sign_sphere100cm_EP1` errors were
written off as harmless. It is an Arma 2 class — the inner safezone ring was
invisible. Corrected to `Sign_Sphere100cm_F`, errors went to zero.

**Read the enclosing block before calling something a bug.** `SC_mapMarkers = true`
was flagged as leaking loot positions. It sits inside `if (SC_debug)`, which is
false.

## Tooling traps that produce silent no-ops

**PowerShell `.Replace()` with `\r\n` on an LF file does nothing** — and returns
success. Two INI edits "succeeded" and changed nothing, then a meaningless test
"verified" them. Use `awk`, and verify by printing the section back.

**`Set-Content -Encoding utf8` writes a BOM.** A BOM in `xcsv_guard.json` made
`serde_json` reject the file, so the app silently ran on `Default` — no paths, no
credentials, and no error. The parser now strips it, with tests.

**A Rust module that is never declared never compiles.** `mod secrets;` was
missing from `main.rs`, so credentials stayed plaintext while the documentation
said otherwise. Adding a file is not adding a feature.

**Nested regex through bash quoting produces confident garbage.** It reported
"288 corrupt entries" in a perfectly healthy PBO. Use the dedicated search tool,
or write the pattern to a file.

**Credentials live in more places than you remember.** After an RCon password
rotation the console could not authenticate — the old value was still in
`xcsv_guard.json`. Five locations had to be updated. Grep for the old value
before declaring a rotation done.

## Debugging discipline

**A log that stopped writing is not a process that stopped working.** The
headless client was recorded for days as "loads the world and then never joins",
because its RPT goes quiet the moment loading finishes. It had been connecting
the whole time — the client's own console window said `Player headlessclient
connected` in plain text. Nobody had looked at the window. When a process is
alive and its log is silent, check the process, not the log.

**Volume of errors is not severity.** Every HC join floods the server RPT with
hundreds of `BEServer::finishDestroyPlayer(<id>): users.get failed`. It is
noise, and it pulled attention away from the real question for a long time.

**Seven failed hypotheses on the headless client** — BattlEye, SteamCMD binary,
loopback vs LAN, missing slot, server busy, `@A3XAI_HC`, startup race — produced
nothing. A packet capture produced the only hard fact in the whole investigation:
1107 packets server→HC, all dropped; 0 packets HC→server. **When hypotheses stop
converging, stop hypothesising and measure.**

**A relaxed check is sometimes the correct fix.** The PBO checker judged a
missing prefix header as `Broken` and blocked autostart. Three live addons ship
that way legitimately, deriving their path from `CfgPatches`. It is a warning,
not an error. Confirm against reality before hard-failing.

**A latch that is never cleared runs once.** `stack_probing` was set and never
reset, so the probe fired a single time and then appeared to work forever.
Anything set by one thread should be cleared by the one that finishes the job.

## Standing rules

- **Verify, then assert.** Not the other way round.
- **Reproduce before exonerating** a component.
- **Read the enclosing block** before calling something a bug.
- **After any file edit, print the result back** — especially through PowerShell.
- **Correct the record when wrong**, in the same turn, plainly.
- **Record dead ends**, not only successes. Seven failed hypotheses are worth
  writing down precisely so nobody spends the evening on hypothesis eight.

## Related

- [Runbook](Runbook.html) · [Architecture](Architecture.html)
