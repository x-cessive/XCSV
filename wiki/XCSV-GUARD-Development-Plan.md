# XCSV GUARD Development Plan

> Planning document synced from the 2026-08-07 XCSV design session.
>
> The authoritative full roadmap remains the local `ARMA3_EXILE_CODEX\ROADMAP.md` in the desktop Obsidian vault. Architect will reconcile the local documentation manually. Until then, any disagreement between this GitHub plan and the desktop roadmap is explicit planning-state divergence.

## Purpose

This plan collects the current design direction for XCSV GUARD and the surrounding XCSV engineering workflow. It is intentionally broader than UI polish: GUARD is becoming the instrumentation, supervision, evidence, deployment-identity and operator surface for the XCSV Exile estate.

The programme has four linked goals:

1. make AI-assisted development more rigorous through a versioned **Gauntlet Protocol**;
2. make GUARD restart-safe and backend-correct rather than merely visually functional;
3. turn GUARD into an evidence and experimentation instrument for server optimization;
4. improve the player experience through curated, coherent systems instead of uncontrolled addon accumulation.

---

## 1. XCSV Gauntlet Protocol

### Canonical flow

`TARGET LOCK -> RECON -> DECOMPOSE -> WORKERS -> ADVERSARIAL CRITICS -> INTEGRATION -> MEASUREMENT -> EVIDENCE -> VERDICT`

The protocol should be maintained once and exposed through thin integrations for Claude Code, OpenCode, Antigravity and development-local LLMs. Do not maintain independent copies that silently drift.

### Risk levels

- **G0** — documentation, trivial local work
- **G1** — isolated implementation; worker + critic
- **G2** — cross-component work; specialists + critic + integration review
- **G3** — production-affecting Arma/Exile change; recon + specialists + security/performance review + rollback + runtime evidence
- **G4** — architecture, persistence, database mutation, BattlEye/security or deployment infrastructure; full Gauntlet and independent verification

### Non-negotiable rules

- worker may not self-certify
- confidence is not proof
- separate **EVIDENCED / INFERRED / UNKNOWN**
- stop looping when requirements/evidence are satisfied; do not iterate merely to produce variants
- record refuted hypotheses
- distinguish bug repair from optional modernization
- preserve rollback
- deterministic checks belong in executable tooling rather than prompt memory

The existing XCSV rule "verification gaps are more dangerous than knowledge gaps" remains the foundation.

---

## 2. GUARD state ownership

Closing GUARD must never erase operational truth.

State must be classified deliberately.

### Durable

GUARD-owned information that should survive process exit:

- settings
- UI scale and navigation preference
- selected tab / operator context where useful
- window position/size where feasible
- saved database queries and history
- filters/preferences
- absolute scheduled restart deadline
- restart warnings already sent
- acknowledged incidents/operator notes
- artifact/release identity

### Reconstructable

External truth that should be re-probed rather than saved as fact:

- server process/PID/memory
- HC process/PID/memory
- MariaDB status
- local model status
- RCon state and players
- current RPT
- PBO integrity
- mission state
- AI ownership
- infiSTAR/BattlEye records
- database contents
- RAG/model health

### Ephemeral

Safe to discard:

- animation interpolation
- transient loading state
- temporary button feedback
- scroll momentum

Never present a persisted old live value as current truth after relaunch.

---

## 3. Startup reconciliation

GUARD should explicitly reconcile the system before declaring itself READY.

Suggested sequence:

1. load config
2. validate/migrate config and secrets
3. discover MariaDB
4. discover Arma server process and PID
5. discover HC process
6. discover local model
7. locate current RPT / HC RPT
8. rescan PBO integrity
9. reconstruct mission and AI state
10. connect/reconnect RCon
11. rebuild player state
12. reconcile restart deadline and warning state
13. check infiSTAR/BattlEye paths
14. check RAG/docs sources
15. enter **READY** or an explicit **DEGRADED** state

An already-running Arma server is normal and must be attachable. A lost Rust `Child` handle must not make the process effectively unmanaged.

### Close vs stop

**Close XCSV GUARD** and **Stop Everything** are different operations.

Closing GUARD should leave server, HC, MariaDB and local model exactly where they are. Reopening GUARD should rediscover them.

---

## 4. Restart survival

The restart schedule must be based on an absolute wall-clock deadline, not only a process-local `Instant`.

Persist enough intent to prevent:

- schedule reset after GUARD closes
- duplicate warning notifications
- false crash/autopsy records
- lost relaunch state
- accidental duplicate server launch

Formal acceptance scenario:

1. server + HC + MariaDB + model are running
2. RCon connected
3. players present or zero-player state confirmed
4. restart deadline established
5. close GUARD
6. leave GUARD closed
7. reopen GUARD
8. verify same server PID is rediscovered
9. verify HC/model/DB are rediscovered
10. RCon reconnects
11. current RPT and mission/AI state rebuild
12. players refresh
13. restart deadline is unchanged
14. warnings are not duplicated
15. PBO state is rescanned
16. operator UI context returns where appropriate
17. no false crash incident is generated
18. no duplicate server process starts

---

## 5. GUARD Backplane

Tabs should render service contracts rather than each tab directly owning backend logic.

Conceptual model:

`Collectors -> Evidence / Observations -> Derived Services -> UI`

Candidate services:

- **Process / Stack Service**
- **RCon / Player Service**
- **Telemetry Service**
- **Mission / AI Service**
- **Database Service**
- **Integrity / Artifact Service**
- **Notification Service**
- **Docs / RAG Service**

Every observation should eventually be able to carry:

- timestamp
- source
- subject/category
- value
- severity
- age/freshness
- raw-evidence reference
- proof state

RCon in particular should become a continuously supervised backend service with reconnect/backoff rather than a connection that individual tabs manually request.

---

## 6. Standard tab contract

Every tab must state:

- what data it requires
- authoritative source(s)
- acceptable data age
- healthy behavior
- degraded behavior
- stale behavior
- offline/error behavior
- actions it exposes
- how action delivery is verified

Standard UI states:

**LOADING / HEALTHY / DEGRADED / STALE / OFFLINE / ERROR**

A blank panel is not an acceptable error state. `0` must never be used when the real state is UNKNOWN.

### Example: Players

Sources: RCon + BattlEye/infiSTAR + later DB operator object.

Healthy: connected RCon, recent player snapshot.

Degraded: RCon unavailable but recent connection logs still readable.

Actions: message, kick, ban.

Proof: command submitted through the RCon service and corresponding response/log evidence where available.

### Example: Database

Source: MariaDB via read-only contract.

Healthy: DB reachable, schema/query path valid.

Degraded: DB reachable but selected query failed.

Offline: DB unavailable.

Never imply that an empty query result means the database backend is healthy unless connectivity/query execution is itself evidenced.

---

## 7. Tab test harness and GUARD self-diagnostics

Create mocked contract tests plus separate live-integration checks.

Example Players cases:

- RCon connected + zero players
- one player
- many players
- disconnected
- reconnect after drop
- malformed response
- BattlEye log unavailable
- infiSTAR unavailable
- message/kick/ban command dispatch
- tab remains usable after backend recovery

Database cases:

- DB online
- DB offline
- query timeout/error
- zero rows
- large result
- read-only rejection
- reconnect after failure

Create a **GUARD System Diagnostics** screen that proves GUARD itself is wired correctly:

- Overview/process service
- Players/RCon
- Players/infiSTAR
- Database/MariaDB
- AI/server RPT
- AI/HC RPT
- Metrics/sysinfo
- Metrics/infiSTAR
- Integrity/PBO scanner
- Docs/wiki
- RAG
- Notifications

Principle: **prove GUARD works before GUARD claims the server works.**

---

## 8. UI/UX refoundation

Do reliability/backend work first, then visual polish.

### Navigation grouping

**OPERATE**
- Overview
- Players
- Restarts

**INTELLIGENCE**
- AI / Missions
- Metrics
- future Tanoa map

**DIAGNOSTICS**
- Integrity
- Server Log
- Consoles
- infiSTAR

**ADMIN / DATA**
- Database
- RCon

**KNOWLEDGE**
- Docs / RAG

**SYSTEM**
- Settings
- Diagnostics

### Global system strip

Keep server, players, FPS, memory, RCon, RAG, model and integrity state visible globally. Make status chips navigable:

- FPS -> Metrics
- players -> Players
- RCon -> RCon
- integrity -> Integrity
- AI -> AI/Missions

### Overview command center

Overview should answer four questions immediately:

1. Is the server healthy?
2. Are players online?
3. What needs attention?
4. What happens next?

Suggested layout:

- stack health strip: server / HC / DB / RCon / model / RAG / integrity
- KPI row: FPS / players / memory / world load
- **Needs Attention**: actionable exceptions only
- active missions and AI ownership
- recent joins/departures
- restart deadline
- operational timeline

### Operator experience

- preserve useful context between launches
- do not preserve stale live results as current truth
- consistent empty/loading/error states
- optional `Ctrl+K` command/search palette
- consequence-based confirmation pattern for destructive operations

Low consequence: immediate.

Medium consequence: one confirmation.

High consequence (permanent ban, force stop, Stop Everything, future DB write): explicit target and consequence.

---

## 9. Evidence/history layer

Add a GUARD-local telemetry/history store that is separate from the Exile gameplay database.

Use it for incident reconstruction and before/after comparison.

Questions GUARD should eventually answer:

- what was server FPS before a crash?
- what was CPU/memory/object load?
- which missions were active?
- how many AI groups existed and where were they owned?
- did RPT growth increase before failure?
- which artifact/build was deployed?
- did HC handoff change?

Suggested operational phases:

**BOOTING / POPULATING / SETTLING / STEADY STATE / DEGRADED / RESTARTING**

Do not accept performance comparisons while the world is still moving between population states.

---

## 10. Experiment-driven optimization

Every meaningful optimization should become an experiment:

`Hypothesis -> Baseline -> Bounded Change -> Gauntlet -> Runtime Observation -> Result -> Durable Memory`

Use Bohemia performance/slow-frame profiling as a deliberate investigation tool when normal metrics stop converging on a cause.

### Subsystem budgets

**AI**
- A3XAI groups
- DMS groups
- FuMS groups
- Occupation groups
- server-owned vs HC-owned

**World**
- vehicles
- constructions
- loot
- mission objects
- bodies/wrecks
- containers
- temporary objects

**Scheduler**
- recurring tasks
- origin
- cadence
- approximate runtime

**Network**
- high-frequency network messages
- public variables
- remote execution
- large synchronization events

**Database**
- query frequency
- latency
- rows touched
- indexing assumptions

Do not add HC2 until metrics show HC1/server distribution has reached a real scaling limit.

---

## 11. Database and operator objects

Move the Database UI toward:

- structured columns/rows
- sortable tables
- filters/search
- saved views
- recent query history
- snapshot comparison/export where useful

Build higher-level operator entities.

### Player

- account
- current character
- connections/session history
- kills/deaths/respect/poptabs
- territories
- vehicles
- market state
- moderation/incident context

### Territory

- owner/members/rights
- level/radius
- protection/decay state
- constructions
- containers
- vehicles

### Vehicle

- owner
- location
- damage/fuel
- territory
- last update
- persistence state

The in-game Player Inspector is a useful first slice, but the GUARD-side Player object should become the main operator investigation surface.

---

## 12. Incident Mode

When an incident occurs, GUARD should temporarily behave like an investigation console rather than a generic dashboard.

Show a chronological evidence chain:

- metric degradation
- RPT growth/errors
- HC heartbeat/ownership change
- mission state
- process exit/restart
- PBO/build identity
- recent deployment/configuration state

Provide direct navigation to relevant RPT, HC RPT, integrity records, artifact identity, process state and documentation/history.

---

## 13. Tanoa operations map

Build a read-only map when source data is available for eligible operational entities:

- active FuMS/DMS missions
- AI concentration/ownership
- helicopter crashes
- loot/world events
- travelling trader
- territories
- other known event markers

This is an operator visualization, not another gameplay authority system.

---

## 14. Artifact Registry

Extend release identity beyond GUARD itself.

Track:

- mission PBO
- server PBOs
- custom addons
- scripts
- BattlEye filters
- extDB query files
- deployment bundles

Desired fields:

- artifact ID
- version/build
- source commit
- build timestamp
- SHA256
- deployed SHA256
- status

GUARD should be able to state **SOURCE != DEPLOYED** explicitly instead of relying on memory.

---

## 15. Documentation / state drift auditor

Build deterministic checks comparing:

- roadmap Done/Next state
- XM8 shipped/backlog state
- README feature counts
- submodule revisions
- release manifests
- eventually deployed hashes

Current documentation drift (for example, shipped features remaining in backlog lists) is evidence this should become executable rather than manual.

---

## 16. Curated player systems

The estate already contains a large number of addons/scripts. The goal is not "more mods"; it is a coherent server with progression, reasons to return, and systems that interact.

Priorities:

1. **Territory Manager**
2. **Contract / Job Board** — salvage, delivery, recovery, smuggling, recon, bounty, trader resupply, supply recovery, faction work
3. **Bounty system**
4. **Faction-standing integration** — contracts, information, trader access/discounts, cosmetics, radio responses; avoid crude combat buffs
5. **Server Chronicle** — significant persistent world events
6. **Asynchronous message board/community tools**
7. **Choreographed rotating events** connecting storms, FuMS/DMS, crashes, traders and faction radio
8. Investigate **ZCP/Capture Points** before adding another heavy AI framework

Keep Zombies and VcomAI parked until measured server/HC headroom justifies reconsideration.

---

## 17. Current implementation reality

Already present in the GitHub snapshot:

- refactored GUARD tab modules
- x64/extDB3 production support
- stack orchestration
- PBO integrity gate
- mission/AI log parsing
- grouped read-only database presets
- release/build identity for GUARD
- RAG status integration
- out-of-band join/leave/restart notifications
- central benign RPT filter
- XM8 Player Inspector App20 source
- extended XM8 extra-app grid source

Still planned or partial:

- canonical Gauntlet protocol
- multi-AI rule adapter/drift system
- startup reconciliation
- restart deadline persistence
- RCon auto-reconnect service
- backend backplane/health registry
- complete tab contracts/tests
- GUARD self-diagnostics
- grouped navigation redesign
- Overview command-center redesign
- historical telemetry
- formal experiment system
- structured DB browser/operator entities
- Incident Mode
- Tanoa operations map
- estate-wide Artifact Registry
- state-drift auditor
- major new curated player systems

Do not promote source presence to live runtime verification without runtime evidence.

---

## Recommended sequence

1. Gauntlet architecture
2. canonical AI-rule distribution/drift detection
3. GUARD state ownership model
4. startup reconciliation/process reattachment
5. persistent absolute restart scheduling
6. RCon auto-reconnect
7. backend health registry/backplane
8. tab contracts and test harness
9. GUARD self-diagnostics
10. shell/navigation redesign
11. Overview command-center redesign
12. structured database/browser work
13. telemetry/history + experiments
14. Incident Mode
15. operations map
16. Artifact Registry/state drift
17. curated player progression/content

---

## Governing principle

> **GUARD should never need to remember that the server is healthy. It should be able to prove the server is healthy again every time it starts.**
