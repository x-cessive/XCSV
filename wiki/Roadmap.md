# Roadmap

> ## AI / AGENT ROADMAP GATE - READ BEFORE ACTING
>
> **Mandatory: read [AI Start Here](AI-Start-Here) before implementing any roadmap item.**
>
> When Architect says **"read the GitHub"**, **"read the roadmap"**, **"get caught up"**, **"resume XCSV"**, or equivalent, enter `READ_ONLY_BOOTSTRAP` first.
>
> **Roadmap status is intent, not implementation proof.** Reconcile the target against the authoritative desktop roadmap, RAG/history, local working trees, local commits, GitHub remote/submodule pointers and relevant live/runtime evidence. Classify it as `VERIFIED_DONE`, `PRESENT_UNVERIFIED`, `PARTIAL`, `PLANNED_ONLY`, `STALE_OR_CONFLICTED`, or `BLOCKED`. Then identify the **smallest remaining delta**.
>
> **Never build substantially equivalent functionality twice.** If implementation already exists, verify/extend/repair/document that path instead of creating a parallel subsystem unless Architect explicitly authorizes replacement.

The authoritative, full-length roadmap is
`ARMA3_EXILE_CODEX\ROADMAP.md` in the Obsidian vault - it carries the reasoning,
the struck-through wrong turns and the measurements. This page is the summary
you can link to.

> **2026-08-07 planning sync - RECONCILED.** The GUARD / Gauntlet planning backlog originated here and has now been absorbed into the authoritative desktop roadmap as **Phase 15** (work ID `XCSV-AI-001`). The desktop/Obsidian `ROADMAP.md` remains authoritative for priority, evidence and refuted hypotheses; this page remains the durable summary. Documentation state is `SYNCED`.

**Guiding rule: performance before content, always.**

## Done

| phase | outcome |
|---|---|
| **0 - Stabilise** | restart-loop/PBO corruption class repaired; runaway RPT/extDB architecture corrected; credentials/reboot survival addressed |
| **1.5 - Lootbox deadlock** | `LB_WaitSysBusy` 40 -> 15; map population completed; major settled-FPS improvement |
| **2.3 - FuMS on HC** | FuMS live on server/HC; first Tanoa mission slice active; A3XAI/FuMS handoff observed on HC owner 4 |
| **2.4 - x64/extDB3 production** | production migrated to `arma3server_x64.exe` + extDB3 with `-maxMem=12288` |
| **2.5 - Memory/RAG first slice** | vault/wiki memory index generated |
| **2.6 - RAG pulse in GUARD** | GUARD exposes local RAG status/pulse |
| **2.7 - GUARD database views** | grouped read-only DB presets for overview, players, territories, vehicles and economy |
| **2.8 - GUARD release/capture subsystem** | build numbering, current-release manifests, controlled Desktop deployment and capture tooling |
| **4.7 - Out-of-band alerts & noise filter** | disconnect/restart notifications and centralized benign RPT filtering |
| **10.1.2 - Player Inspector (App20)** | admin XM8 account/territory inspector plus extended extra-app grid source |
| **7.5 - Stack orchestration** | dependency-ordered start/stop for database, server, HC and local model |
| **8 - Mistake prevention** | project AI rules, executable doctor assertions, wiki and Lessons discipline |

## In flight / retained

- richer GUARD AI/mission drilldowns and alerts
- richer structured GUARD database browser
- HC hardening and real-load ownership observation
- BattlEye staged enforcement
- infiSTAR cloud 403 diagnosis while local logs remain authoritative
- artifact versioning beyond GUARD itself

## 2026-08-07 development programme

Detailed design: [XCSV GUARD Development Plan](XCSV-GUARD-Development-Plan).

### A. XCSV Gauntlet

Create one canonical versioned protocol for Claude Code, OpenCode, Antigravity and development-local LLMs:

`TARGET LOCK -> RECON -> DECOMPOSE -> WORKERS -> ADVERSARIAL CRITICS -> INTEGRATION -> MEASUREMENT -> EVIDENCE -> VERDICT`

Depth scales G0-G4 by risk. Workers do not self-certify. Keep **EVIDENCED / INFERRED / UNKNOWN** separate. Refuted hypotheses become durable knowledge. Deterministic rules should become executable checks.

### B. GUARD restart-safe state model

Primary invariant:

> **Closing XCSV GUARD must never erase operational truth. Reopening it must reconstruct the same server state from authoritative sources and continue supervising it without duplicates, reset schedules, fabricated health or false incidents.**

Classify state as:

- **Durable** — settings, UI context, restart deadline/warning state, saved DB views/history, incident acknowledgements, action journal, artifact/experiment metadata
- **Reconstructable** — process/PID/memory, RCon/players, current logs, integrity, missions/AI ownership, DB contents, RAG/model state
- **Ephemeral** — transient UI mechanics

### C. Config/state durability

- separate `xcsv_guard.json` configuration from operational durable state
- prefer a small GUARD-local SQLite store for history/state
- ~~add config/state schema versions and explicit migrations~~ — **done for
  configuration**, `GUARD-STATE-001` (2026-08-07)
- ~~write critical config/state atomically with known-good fallback~~ —
  **done for configuration**, `GUARD-STATE-001`
- ~~never silently default a corrupt state into apparently healthy operation~~ —
  **done for configuration**, `GUARD-STATE-001`

`GUARD-STATE-001` covered the **configuration** half: `config_schema_version`
read from raw JSON before deserialization, ordered `v(n) -> v(n+1)` migrations
over the document, atomic save (validate → temp → `sync_all` → promote
known-good → rename), and distinguishable load outcomes with an interlock that
refuses *automatic* saves over a corrupt or newer-schema file. See
`XCSV_GUARD/src/config_store.rs`.

Still open in C: the operational-state store itself. It was deliberately not
built — GUARD persists no operational state today, so nothing yet forces SQLite.
Build it when the first real consumer arrives (restart deadlines are the likely
first, from section B).

### D. Startup reconciliation + desired/observed state

Before READY, rediscover database, server, HC, model, RPTs, integrity, missions, RCon, players, restart state, infiSTAR/BattlEye and RAG/docs.

Model **desired state vs observed state** so GUARD knows the difference between intentionally disabled and unexpectedly missing components.

Closing GUARD is not **Stop Everything**.

### E. Restart survival and Safe Mode

Persist wall-clock restart deadlines, warnings already sent and relaunch intent.

Add **Safe Mode** for corrupt config/state or untrusted startup conditions: read-mostly diagnostics/logs/integrity/docs available; no automatic production mutation.

### F. Backend backplane + tab contracts

Move toward:

`Collectors -> Evidence/Observations -> Derived Services -> UI`

Create stable process/stack, RCon/player, telemetry, mission/AI, database, integrity/artifact, notification and docs/RAG services.

Every tab defines sources, freshness, states, actions and delivery proof. Standard states: **LOADING / HEALTHY / DEGRADED / STALE / OFFLINE / ERROR**. UNKNOWN must never be rendered as zero.

### G. Test harness, Replay Mode and failure fixtures

- mocked tab contract tests plus live integration checks
- GUARD self-diagnostics screen
- offline Replay Mode using captured RPT/log/RCon/process/metrics/PBO/DB/artifact evidence
- convert serious failures into permanent regression fixtures where practical

Rule: **a production failure should be allowed to surprise XCSV once.**

### H. Operator Action Journal

Record consequential GUARD actions with timestamp, target, GUARD build, result and evidence reference. Feed these records into Incident Mode and Replay Mode.

### I. UI/UX refoundation

Task-oriented groups:

- **OPERATE:** Overview, Players, Restarts
- **INTELLIGENCE:** AI/Missions, Metrics, future map
- **DIAGNOSTICS:** Integrity, Server Log, Consoles, infiSTAR
- **ADMIN/DATA:** Database, RCon
- **KNOWLEDGE:** Docs/RAG
- **SYSTEM:** Settings, Diagnostics

Consider two information-density modes:

- **Operations Mode** — health, players, incidents, missions, restarts
- **Engineering Mode** — integrity, artifacts, profiling, experiments, deployment diff, logs, DB and RAG/docs

Overview should emphasize attention rather than green noise. Add navigable status chips, consistent consequence-based confirmations, optional command palette, and a universal entity inspector for Player/Territory/Vehicle/Mission/Process/Artifact/Incident.

### J. Evidence/history, SLOs and headroom

Add GUARD-local historical telemetry separate from the gameplay DB.

Track operating phases such as **BOOTING / POPULATING / SETTLING / STEADY STATE / DEGRADED / RESTARTING**.

Define practical XCSV health objectives: settled FPS/floor, boot-to-joinable, HC handoff time, RCon recovery, GUARD reconciliation, RPT growth and integrity expectations.

Add a capacity/headroom view for FPS, CPU, RAM, disk, RPT growth, world objects, AI ownership and DB latency.

### K. Experiment-driven server optimization

`Hypothesis -> Baseline -> Bounded Change -> Gauntlet -> Runtime Observation -> Result -> Durable Memory`

Use profiler/slow-frame capture when ordinary metrics stop converging. Maintain budgets for AI, world objects, scheduler work, network activity and database load. Do not add HC2 without evidence.

### L. Database/operator objects

Evolve Database toward structured sortable/filterable tables, saved views/history and useful comparisons.

Build GUARD-side Player, Territory and Vehicle entities. Player Inspector should become a central operator concept, not only an XM8 app.

### M. Incident Mode + Tanoa operations map

Incident Mode correlates metrics, RPT/HC RPT, ownership, process state, operator actions and deployment identity chronologically.

Build a read-only Tanoa operations map for source-backed missions, AI ownership/concentration, crashes, events, trader/territory information and other known markers.

### N. Artifact Registry, deployment diff and rollback

Extend release identity across mission/server PBOs, addons, scripts, BattlEye filters, extDB query files and bundles.

Track artifact ID, version/build, source commit, timestamp, SHA256, deployed SHA256 and status.

Before deployment show production-vs-candidate diff, affected surfaces, validation/BattlEye/DB/network implications and exact rollback artifact. Surface **CURRENT** and **PREVIOUS VERIFIED** identities.

### O. State drift, provenance and compatibility

Build deterministic drift checks for roadmap/backlog state, README counts, submodules, release manifests and deployed hashes.

Create addon/script provenance metadata: original author/source/license, upstream status, XCSV modifications, maintainer, compatibility, dependencies, performance/security exposure, deployed state and replacement candidate.

Maintain a compatibility matrix for x64, extDB3, Tanoa, HC, BattlEye and XCSV verification.

### P. Change Impact Graph

Map shared override/network/database/deployment dependencies so the Gauntlet can answer **what could this change break?** before mutation. Prioritize `CfgExileCustomCode`, client/server network paths, DB queries, BattlEye surfaces and GUARD observation dependencies.

### Q. Staging path for G3/G4 work

Support a temporary isolated integration instance with alternate ports/profiles and copied/synthetic DB where feasible. Use it for network changes, DB mutations, BattlEye rules, write-capable XM8 flows and major upgrades before production evidence.

### R. Curated player development

Prioritize coherence over raw addon count:

1. Territory Manager
2. Contract / Job Board
3. Bounty system
4. meaningful faction-standing integration
5. Server Chronicle
6. asynchronous community/message system
7. choreographed rotating events
8. investigate ZCP/Capture Points before another heavy AI framework

Keep Zombies/Vcom parked until measured headroom changes the decision.

### S. AI evidence boundary

Development AI may consume exported GUARD evidence, replays, metrics, manifests and tests.

Preferred direction:

`GUARD -> evidence -> development AI`

not unrestricted production authority through GUARD controls. Runtime local model remains tool-less and non-load-bearing.

## Recommended sequence

1. Gauntlet architecture
2. canonical AI rule distribution/drift detection
3. config/state schema versioning + atomic persistence
4. durable/reconstructable/ephemeral state model
5. startup reconciliation + desired/observed state
6. restart persistence + RCon auto-reconnect
7. backend backplane/health registry
8. tab contracts + self-diagnostics
9. Replay Mode + failure fixtures
10. Operator Action Journal + Safe Mode
11. shell/navigation + Operations/Engineering UX
12. Overview + universal entity inspector
13. structured DB/operator objects
14. telemetry/history + SLO/headroom + experiments
15. Incident Mode
16. operations map
17. Artifact Registry + deployment diff + rollback
18. provenance/compatibility + Change Impact Graph
19. staging path
20. curated player progression/content

## Later / deliberately parked

- second HC only after measured need
- player chat with AI only under strict isolation/non-load-bearing rules
- deeper RAG/search and CI
- Zombies/Vcom only if performance evidence changes the decision

## Governing principles

> **GUARD should never need to remember that the server is healthy. It should be able to prove the server is healthy again every time it starts.**

> **Green is quiet. Problems are loud. UNKNOWN is never zero.**

> **A production failure should surprise XCSV once; afterward it becomes evidence, a fixture or an executable check.**

> **Never begin from what the roadmap says needs building. Begin by proving what remains to be built.**

## Related

- [AI Start Here](AI-Start-Here)
- [XCSV GUARD Development Plan](XCSV-GUARD-Development-Plan)
- [XM8 Apps](XM8-Apps)
- [Architecture](Architecture)
- [Lessons](Lessons)