---
layout: wiki
section: docs
title: AI Continuity
heading: AI Continuity
blurb: Isolated Hermes/OpenClaw baton and failover workflow for XCSV.
order: 4
source: AI-Continuity.md
---

XCSV uses an isolated continuity lane named `XCSV_AI_CONTINUITY`.

Runtime state root: `D:\CAGE\xcsv-ai-continuity`

Tracked operator entrypoint: `D:\XCSV\tools\xcsv-continuity.ps1`

Hermes profile: `xcsvcontinuity`

OpenClaw profile: `xcsvcontinuity`

The lane carries only the active baton: work item, authority, source/runtime
state, evidence, unknowns, blockers, and one bounded next action. It must not
store chat transcripts or previous-worker summaries as authority.

## Commands

Create or update the current baton:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 checkpoint
```

Show the current baton:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 show
```

Hydrate a continuation summary:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 hydrate
```

Show worker policy:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 workers
```

Verify basic isolation:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 verify-isolation
```

Run the simulated worker-exhaustion check:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 failure-test
```

## Isolation Rules

XCSV handoffs, logs, receipts, prompts, worker histories, routing state, and
authority envelopes stay under `D:\CAGE\xcsv-ai-continuity` or tracked XCSV repo
files.

Do not store XCSV baton state in Hermes default state, Hermes
`sovran-command-deck`, OpenClaw default state, or any SOVRAN project directory.

## Current Status

Status is `PARTIAL` for OpenClaw automation and `HANDOFF_READY` for the XCSV
baton.

Hermes profile isolation is established. OpenClaw profile isolation exists, but
initializing `openclaw --profile xcsvcontinuity config file` unexpectedly
migrated default `C:\Users\Architect\.openclaw\exec-approvals.json` into the new
profile and archived the default file as `.migrated`. The default file was
restored from the archive. Treat OpenClaw profile initialization as
collision-sensitive until this behavior is fully understood and covered by a
stronger collision test.

## 2026-08-08 EXILE-DB-001 Checkpoint

Active extDB3 SQL_CUSTOM file is proven as
`E:\arma3server\@ExileServer\sql_custom\exile.ini`. Proof: launcher runs from
`E:\arma3server` with `-servermod=@ExileServer`; RPT loaded
`E:\arma3server\@ExileServer\extDB3_x64.dll`; extDB3 logs are written under
`@ExileServer\logs`; local runbooks and extDB3 staging tools identify
`@ExileServer\sql_custom\exile.ini` as the live SQL_CUSTOM file. The
`@ExileServer\extDB\sql_custom\exile.ini` copy is a byte-identical compatibility
mirror.

EXILE-DB-001 repaired four `$CUSTOM_1$` query templates:
`insertConstruction`, `insertContainer`, `updateContainer`, and
`createTerritory`. The repair uses `NULLIF(?, 'NULL')`; `updateContainer` and
`createTerritory` require non-sequential `SQL1_INPUTS` so the former
`$CUSTOM_1$` argument remains bound to the nullable column.

OpenClaw remains collision-sensitive. The XCSV profile reports zero sessions at
`C:\Users\Architect\.openclaw-xcsvcontinuity\agents\main\sessions\sessions.json`,
but its approval file copied shared authorization material from the default
profile. Manual failover via the XCSV baton is the allowed continuity path until
OpenClaw profile initialization is fully characterized.
