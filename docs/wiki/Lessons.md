---
layout: wiki
section: docs
title: Lessons
heading: Lessons
blurb: Mistakes actually made here, and the rule each one produced.
order: 14
source: Lessons.md
---

Mistakes that were actually made here, and the rule each one produced. Read this
before repeating one someone already paid for.

## Profile creation can mutate shared state

Creating an isolated profile is not automatically side-effect-free. On
2026-08-08, `openclaw --profile xcsvcontinuity config file` initialized the XCSV
profile but also migrated the default OpenClaw `exec-approvals.json` into the new
profile and archived the default file as `.migrated`.

Rule: before using a tool profile as an isolation boundary, inspect or hash the
default/shared state, run the profile command, then re-check shared state. If the
tool migrates shared files, restore them immediately and classify the profile
path as collision-sensitive until proven otherwise.

On the same day, `openclaw --profile xcsvcontinuity doctor --fix
--non-interactive --yes` repaired the isolated profile enough for
`config validate`, `sessions list`, `plugins list`, and `skills list` to run.
That does not make it an automatic failover authority. A profile is only a
candidate for automation after before/after hash checks prove the default
profile was not mutated by the real commands it will run.

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

**Do not debug GUARD by minimizing and restoring the operator windows.** On
2026-08-08 the working desktop convention became Orca pinned left, XCSV GUARD
pinned right. Use `D:\XCSV\tools\ai-desktop-capture.ps1 -Layout -Shot` to set
that layout and capture the whole desktop. Use `-GuardTab RCon -Shot` or another
tab name when the task needs a specific GUARD tab. If the capture needs more
width for accurate scaling, use `-WideGuardForShot`; temporary enlargement is
allowed only if the tool restores Orca left / GUARD right before it exits. The
script also writes `guard-tree.txt` and `orca-tree.txt` beside the screenshot so
agents without image-reading capability still have text evidence.

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

**Credential repair evidence must be hash-only.** On 2026-08-08 GUARD's
encrypted RCon credential was stale while BattlEye accepted a different active
secret. The repair compared DPAPI-decrypted GUARD config and BattlEye config by
SHA256 only, updated `rcon_password_enc`, left plaintext empty, and restarted
GUARD. Do not print RCon secrets or DPAPI blobs in logs or receipts.

**A diagnostic kill switch still needs OS authority.** GUARD build 14 added a
narrow `--diagnostic-stop-managed-server <pid>` path that refused ambiguous
targets and proved PID 7956 was the configured `arma3server_x64.exe`, but
`taskkill` still returned Access Denied under the medium token. A safe target
selector is not the same as permission to terminate the target. Record the exact
Windows endpoint that failed, then stop retrying the same permission path.

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

**`$null.StartsWith(..)` throws, and `$null -ne ''` is True.** A doctor branch
tested `$cfgState.StartsWith('Ok')` before any null check, guarded by
`-ne ''` — which does not catch `$null` in PowerShell. The throw was swallowed by
the enclosing `catch`, so a genuine FAIL was silently downgraded to "could not
run the check". Normalise a value once where it enters, and test emptiness with
`[string]::IsNullOrEmpty`. A defensive `catch` around a whole block will convert
your own logic errors into inconclusive results rather than surfacing them.

**Anything git reads is a file too.** After fixing the harness below, a commit
message written with `Out-File -Encoding utf8` put a UTF-8 BOM into the commit
*subject line* — the same trap a third time, now in the provenance record itself.
Use `[System.IO.File]::WriteAllText` with a BOM-less encoder for commit messages,
not just source.

**The same encoding trap, twice, in the tool that was written to catch
mistakes.** A mutation harness round-tripped source through
`Get-Content -Raw` / `Set-Content -Encoding utf8`, which decodes ANSI and writes
a BOM: two files silently gained a BOM and mangled em-dashes. This page already
carried that lesson. Worse, the rewritten harness's own mojibake self-check was
mangled the same way, because PowerShell 5.1 reads a BOM-less `.ps1` as ANSI, so
a non-ASCII literal inside the checker is itself corrupt — build such patterns
from char codes. A harness must prove its restore is byte-identical, including
encoding, rather than printing that it restored.

**A zero that looks like data can be a broken write path.** The roadmap recorded
"0 territories, 0 constructions, 0 containers" as the server's population, and a
later review explicitly reasoned it was "real data, not a defect". Those were the
exact three tables whose INSERT templates the extDB2→extDB3 conversion had
broken; vehicles, whose template needed no conversion, persisted fine. A count
that is plausible is not evidence. Before believing an empty table, prove
something can be written to it.

**A migration that converts 125 of 129 cases looks like it worked.** The
conversion handled every plain-`?` statement and silently mis-handled all four
using the older `$CUSTOM_n$` syntax. Post-migration validation counted sections
and checked for forbidden strings — it never checked that each statement's
declared input count matched its own placeholders. When converting a template
language, assert the invariant the target enforces, not the shape of the output.

**Verify a fix by re-running the experiment that established the defect.** A
background thread was added to wake GUARD's event loop so a minimized console
would keep supervising. It was reasonable, it compiled, its tests passed — and
deployed to the live server it changed nothing, because Windows does not deliver
a redraw to a minimized window at all. Only re-running the original kill-while-
minimized trial showed that. A fix for a runtime defect is a hypothesis until the
runtime says otherwise.

**Throttle the notification, not the detector.** GUARD-PERF-001 produced a real
Telegram flood once minimized-supervision gaps repeated in the same incident:
407s, then smaller 39-82s class gaps. The repair was incident coalescing at the
notification boundary, not weakening the detector. Count every missed
supervision window, preserve largest/total gap evidence, send one recovery after
a proven healthy interval, and keep the architectural defect open until
supervision leaves the render callback.

**A runtime recovery test also needs a reliable failure injector.** The
GUARD-PERF-001 supervision-worker build moved supervision off egui and stayed
active while minimized, but the decisive kill-while-minimized acceptance could
not complete because the current `arma3server_x64` process could not be stopped
from the medium-integrity agent session. Process kill, window close, and a
temporary highest-privilege scheduled task were denied; BattlEye RCon logged in
with the active config but did not stop the process, and GUARD's encrypted RCon
secret did not match the active BattlEye secret. Record that as
`BLOCKED_RUNTIME_STOP`, not as a pass or fail of the supervision worker.

**PID safety needs a handle, not a second command.** Build 14 validated the
right server PID and then asked `taskkill` to terminate that PID. That left both
a permission mismatch and a PID-reuse window. Build 15 changed the diagnostic
stop path to open the process with
`PROCESS_QUERY_LIMITED_INFORMATION|PROCESS_TERMINATE|SYNCHRONIZE`, validate the
image path through that handle, and terminate through the same handle. It also
made malformed diagnostic CLI flags fail closed with exit code `2` instead of
falling through to normal GUARD launch.

**HC process detection cannot depend on one Windows process API.** During the
first successful minimized recovery, GUARD relaunched the server but spawned
duplicate headless clients because the sysinfo path did not reliably prove an
existing `-name=XCSV_HC` command line. Build 16 kept the fast sysinfo check but
added a CIM fallback and a defensive pre-spawn HC check. The clean retest
recovered server PID `41016` and exactly one HC PID `5788`.

**Do not upgrade a runtime pass to closure when the critic is missing.** Build
16 met the core minimized recovery condition, but the independent Claude critic
stalled on repeated local approval prompts and never returned `worker_done`.
Record the runtime pass and the critic tooling block separately; close the
issue only after an independent critic returns a verdict or Architect waives the
requirement.

**Safe refusal is not the same as complete operator control.** Closing
GUARD-PERF-001 proved minimized background recovery with an owned server child
handle. It also exposed a separate adopted-process gap: after GUARD itself
restarts, it may observe a still-running configured `arma3server_x64.exe` but
correctly refuse `StopStack` because it does not own that process handle.
Track that as GUARD-ADOPT-001. Do not regress to broad taskkill-by-image; model
`OBSERVED`, `OWNED_CHILD`, and `ADOPTED` authority explicitly.

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

## 2026-08-08 EXILE-DB-001

**A nullable placeholder is not automatically SQL NULL.** In the extDB3 SQL_CUSTOM path, binding literal `NULL` through `?` stored `0` for a nullable integer and the string `NULL` for a nullable varchar. The working pattern was SQL-side normalization: `NULLIF(?, 'NULL')`. When the old `$CUSTOM_n$` argument was located between ordinary placeholders, the `SQL1_INPUTS` list also had to stay non-sequential so money, ids, build rights, and nullable fields did not shift.

## 2026-08-09 XCSV-ORCH-001 (AI workforce)

**`cmd.exe` truncates an argv argument at its first newline.** Multi-line prompts
passed as a command-line argument to the npm `.cmd` worker shims delivered only
line 1. Codex received just the role preamble ("You are an XCSV analyst… do not
modify files") and dutifully replied "Understood, I'll operate as read-only" — so
three workers looked flaky, unreliable, or badly aligned when the orchestrator was
at fault. `claude.exe` is a native binary with no `cmd.exe` in its launch path,
which is exactly why it alone appeared to work. **Send multi-line prompts over
stdin, never argv.** When several independent models all behave strangely in the
same way, suspect the harness before the models.

**A shared secret defeats separate paths.** The XCSV and default OpenClaw profiles
had correctly distinct approval *socket paths* and a byte-identical approval
*token*. Path isolation reads as isolation at a glance and is not. Compare the
secrets, not the filenames.

**Registry AutoRun runs inside your children.** `HKCU\Software\Microsoft\Command
Processor\AutoRun` re-ran the SOVRAN shell landing inside every `cmd.exe`, so it
re-injected `SOVRAN_*` *after* the environment scrub and prepended a banner to
worker stdout. Scrubbing a child's environment is not enough when something
re-populates it on the way in. `cmd.exe /d` disables it per-invocation without
weakening anything globally.

**A critic that cannot follow an output contract cannot be trusted with a
verdict.** `llama3.2:1b` answered "Yes." when asked to reply exactly "ALIVE". It
was marked DEGRADED and barred from critic duty rather than left in the roster to
produce confident-looking noise.

**Small models copy your placeholders.** `VERDICT: <DRIFT_CONFIRMED|NO_DRIFT>`
came back literally, angle brackets and all. Give small models a filled-in
template to imitate, not a grammar to interpret.

**The critics earned their keep.** Two independent providers blocked a
"reconcile runtime → tracked" plan on the grounds that the direction was never
proven. They were right: the tracked file was a deliberate 378-byte delegating
wrapper, and copying over it would have created a second continuity state root.
An independent critic is worth most precisely when the primary analysis sounds
reasonable.

**Fail closed at a boundary.** OpenClaw's own error text recommended copying
provider auth from the default agentDir — the exact action that caused the
original contamination. Automatic routing was refused and the working manual
path retained, rather than weakening the XCSV/SOVRAN boundary to claim a feature.

## 2026-08-09 XCSV-ORCH-002 (canonicalization)

**Path isolation is not state isolation — check where the database actually lives.**
`HERMES_PROFILE=xcsvcontinuity` resolved the right *config* while still writing
session state to the shared root `state.db`, because Hermes derives that path from
`HERMES_HOME`. The profile looked isolated and was not. When a tool has both a
"profile" and a "home", the home is usually the real boundary.

**A `.gitignore` pattern broad enough to catch secrets will also catch your
security tooling.** `*secret*` silently excluded `tools/secret-scan.ps1` from the
first commit — the scanner would have been the one file missing from the repo.
Check what your ignore rules *excluded*, not just that the commit looked clean.

**Self-test the scanner before trusting a CLEAN verdict.** A secret scanner that
never fires is indistinguishable from one that works. Ours was run against
synthetic tokens first: it detected four classes, exited non-zero, and printed no
values. Only then was CLEAN meaningful.

**PowerShell unrolls single-element arrays on return.** A worker returning exactly
one evidence item collapsed `evidence` from an array to a bare string, and `.Count`
then failed under StrictMode. The leading-comma idiom (`return ,[string[]]@(...)`)
is required at every function boundary that yields a collection.

**Write the regression test for the harness bug, not just the product bug.** The
suite that locks in the `cmd.exe` argv truncation defect immediately caught two
*new* self-inflicted defects — the array unrolling, and a status-vocabulary change
(`AVAILABLE` -> `READY`) that had quietly made every implementation worker
unroutable. Neither would have surfaced until a live run.

**Don't buy independence with a relabel.** Pointing the newly installed Qwen CLI at
local Ollama would have produced a "Qwen" critic that was really the same model
already voting. Workers now carry a `provider_independence_key` separate from their
display name, and `openclaw-ollama` deliberately shares a key with the direct
Ollama lanes.

**Distinguish "it routed once" from "it routes".** OpenClaw genuinely dispatched a
worker and returned a real answer, which earns the lane a READY status — but not
`FULL_AUTO_ROUTING_VERIFIED`. One routed turn is not unattended dispatch of a whole
Work ID, and collapsing those two claims is how a demo becomes a false capability.
