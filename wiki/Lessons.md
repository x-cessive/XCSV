# Lessons

Mistakes that were actually made here, and the rule each one produced. Read this
before repeating one someone already paid for.

The headline finding, after auditing a full day of them: **seven of eight errors
were verification gaps, not knowledge gaps.** The fix is almost never "know
more". It is "check before asserting".

## Diagnosis

**A checksum verify is not an integrity check.** Three PBOs with a leading `\` on
every entry path verified clean and took the server down for six hours. Read the
entry table. → *[Runbook §6](Runbook)*

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

**`Get-Content | Set-Content` is not a targeted edit — it re-encodes the whole
file.** A one-character fix to the desktop `ROADMAP.md` was written as
`(Get-Content $p) -replace ... | Set-Content $p -Encoding utf8`. PowerShell 5.1
decodes with the ANSI codepage and writes a BOM, so the round-trip silently
re-encoded every non-ASCII byte in 147 KB of authoritative text: pre-existing
double-encoded UTF-8 became triple-encoded. It was recoverable only because the
transform happened to be invertible. Edit the specific lines, or read and write
bytes. `tools/check-text-safety.ps1` now fails the build on this shape.

**A safety check that cannot fail is worse than no check.** The first version of
that same checker computed repo-relative paths by `Substring` against a root
that could be an 8.3 short path (`C:\Users\ARCHIT~1\...`) while `Get-ChildItem`
returned the long form. Every relative path came out as garbage, matched no
protected pattern, and the check reported "clean" on a planted offender. It was
only caught because the test planted one and demanded it be found. `Get-Item`
expands 8.3; `Resolve-Path` does not. Always test a detector against a known
positive.

**Automation that stages broadly will eventually commit someone else's work.**
`sync-all.ps1` ran `git add -A` on the hub every hour. It swept an AI-authored
wiki edit into commit `9a97709` under a generic message with no provenance
trailers. The same script's member-repo loop had always been careful — detect
dirty, report, never touch — so the safe pattern was sitting ten lines above the
defect. Automation may commit only what it produced itself; anything else is
`BLOCKED_DIRTY_SOURCE`. See `tools/sync-policy.ps1`.

**A test that runs real automation runs its real side effects.** Proving the
repaired `sync-all.ps1` end-to-end in a sandbox clone also ran `push-wiki.ps1`,
which takes `-Root` as a parameter but publishes to a *hardcoded* production URL.
A throwaway test edit landed on the live GitHub wiki and had to be repaired by
re-mirroring from the hub. Any script that writes to a fixed production target
must verify that its input actually is the source that target belongs to;
`push-wiki.ps1` now compares the checkout's `origin` against the wiki repo and
refuses otherwise.

**An environment token silently outranks the credential you configured.** `gh`
prefers `GH_TOKEN` over its stored credential, so a fine-grained PAT in the
environment became the active account while a keyring OAuth token carrying the
needed `project` scope sat inactive. Every Projects write failed as "not
accessible by personal access token", and the obvious remedy is a dead end —
`gh` refuses to refresh a token supplied through the environment. The fix was to
stop using the env var, not to grant a scope. `gh auth status` lists *every*
account, not just the active one, and `gh api repos/... --jq .permissions`
reports the **user's** repo role, not the token's grant. The only proof of a
write is the write.

**A health check that asserts presence proves nothing about compatibility.**
`doctor.ps1` confirmed `extdb3-conf.ini` existed, and stayed green for two days
while GUARD could not parse a word of it — the Database tab was blank the whole
time (GUARD-DB-001). The file being there was true and entirely beside the point.
Check the capability you actually depend on, and check it in the **deployed
artifact**: a green `cargo test` proves the repository is correct, not that the
exe the operator launches is.

**An unrecognised CLI flag on a GUI binary launches the GUI.** A preflight flag
added for the check above would, on any older build, fall through to
`eframe::run_native` — opening a second GUARD from a health check, and two
instances have already cost roughly half the server's frame rate. Verify the
target supports the flag before invoking it; do not assume an unknown argument is
inert.

**`$ErrorActionPreference = 'Stop'` plus `native.exe 2>&1` aborts the script.**
PowerShell 5.1 wraps a native executable's stderr in a `NativeCommandError`, so a
mutation-testing harness died after writing its first mutation and before
reverting it, leaving the source file quietly modified. The "restored" message
never printed, and nothing else complained. Route native output through a file,
and confirm a restore by reading the file back rather than by the absence of an
error.

**An assertion can be incoherent rather than wrong-about-the-code.** A test
asserted escaped JSON does not contain `\a`; correctly escaped `\\a` *contains*
`\a`, so it could never pass. It failed against correct code and looked like a
bug in the code. When a brand-new test fails, suspect the test first.

**A guard built from a nearby predicate inherits that predicate's exclusions.**
A diagnostic refused to answer when the config was "degraded", reusing an
existing `is_degraded()`. But `Unavailable` — a first run — is deliberately *not*
degraded, while still meaning every value came from the defaults. So the guard
written to stop a check reporting on a machine it knew nothing about did exactly
that, in its most common case. Ask what the guard needs to be true, and write
*that* predicate; do not borrow one that answers a neighbouring question. Make
the match exhaustive so a new variant must be classified rather than inheriting
a permissive default.

**A verdict that cannot name its source cannot be told apart from a
coincidence.** A candidate build's PASS was read as verifying the operator's
machine. It had loaded a three-day-old config sitting beside the build output,
and passed only because that stale file happened to carry the same path. Any
check whose input is resolved at runtime should report *which* input it used,
next to the verdict.

**The same encoding trap, twice, in the tool that was written to catch
mistakes.** A mutation harness round-tripped source through
`Get-Content -Raw` / `Set-Content -Encoding utf8`, which decodes ANSI and writes
a BOM: two files silently gained a BOM and mangled em-dashes. This page already
carried that lesson. Worse, the rewritten harness's own mojibake self-check was
mangled the same way, because PowerShell 5.1 reads a BOM-less `.ps1` as ANSI, so
a non-ASCII literal inside the checker is itself corrupt — build such patterns
from char codes. A harness must prove its restore is byte-identical, including
encoding, rather than printing that it restored.

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

- [Runbook](Runbook) · [Architecture](Architecture)
