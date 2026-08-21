---
layout: wiki
section: docs
title: GUARD Development
heading: GUARD Development
blurb: Gauntlet, reliability, UX, evidence, deployment and player-system programme.
order: 14
source: XCSV-GUARD-Development-Plan.md
generated: true
source_authority: wiki/XCSV-GUARD-Development-Plan.md
---

<!-- GENERATED FROM wiki/XCSV-GUARD-Development-Plan.md BY tools/build-docs.ps1. DO NOT EDIT docs/wiki BY HAND. -->

> Planning document synced from the 2026-08-07 XCSV design sessions.
>
> The authoritative full roadmap remains the local `ARMA3_EXILE_CODEX\ROADMAP.md` in the desktop Obsidian vault. Architect will reconcile the local documentation manually. Until then, any disagreement between this GitHub plan and the desktop roadmap is explicit planning-state divergence.

## Purpose

XCSV GUARD is evolving from an operator console into the **instrumentation, supervision, evidence, deployment-identity, incident-response and engineering surface** for the XCSV Exile estate.

The programme connects four goals:

1. rigorous AI-assisted engineering through a versioned **Gauntlet Protocol**;
2. restart-safe, backend-correct GUARD operation;
3. evidence-driven server optimization and experimentation;
4. curated player systems that increase coherence and retention without uncontrolled addon accumulation.

---

## 1. XCSV Gauntlet Protocol

Canonical flow:

`TARGET LOCK -> RECON -> DECOMPOSE -> WORKERS -> ADVERSARIAL CRITICS -> INTEGRATION -> MEASUREMENT -> EVIDENCE -> VERDICT`

Maintain one canonical version and expose it through thin integrations for Claude Code, OpenCode, Antigravity and development-local LLMs. Do not maintain independent drifting copies.

Risk levels:

- **G0** — documentation / trivial local work
- **G1** — isolated implementation; worker + critic
- **G2** — cross-component work; specialists + critic + integration review
- **G3** — production-affecting Arma/Exile change; recon + specialists + security/performance review + rollback + runtime evidence
- **G4** — architecture, persistence, database mutation, BattlEye/security or deployment infrastructure; full Gauntlet + independent verification

Non-negotiable rules:

- worker may not self-certify
- confidence is not proof
- separate **EVIDENCED / INFERRED / UNKNOWN**
- record refuted hypotheses
- distinguish repair from optional modernization
- preserve rollback
- deterministic checks belong in executable tooling rather than prompt memory

---

## 2. GUARD state ownership

> **Implemented 2026-08-07 (`GUARD-STATE-002`).** The classification below is no
> longer only a plan: it exists as a machine-checked registry in
> `XCSV_GUARD/src/state_model.rs`, which is the **canonical home** for the
> detailed model. This page keeps the concepts and the decisions; it does not
> duplicate the 58-entry table. A test parses `app/state.rs` and fails when a
> field is added to `GuardApp` without an ownership class, so the registry
> cannot quietly fall behind the struct.

### What the classification found

All 58 `GuardApp` fields are classified. The split is roughly 12 durable, 24
reconstructable, 34 ephemeral — deliberately more reconstructable than durable,
and a test asserts that stays true. Most of what a live console holds is other
people's truth; if durable ever outnumbers reconstructable, something is being
remembered that should have been re-proved.

**The finding: the scheduled-restart deadline cannot survive a restart, and
silently moves.** `supervisor.rs` holds `next_restart: Option<Instant>` and
computes it as `Instant::now() + interval`. `Instant` is monotonic-since-boot —
unserialisable, and meaningless across a process or machine restart. Because the
field starts `None` every process start, **every GUARD restart pushes the
server's scheduled restart out by up to four hours**, and `warned.clear()` means
a countdown players already saw can be broadcast again. Nothing logs it.

That is why the plan says restart-safe **absolute** deadlines: the type is wrong,
not just the persistence. Fixing it is step 5 work, not a config change.

### Enforcement, not documentation

The registry is typed, and the invariants are rejections rather than advice:

- durable state must name `GuardItself` as authority and declare where it
  persists — external truth that GUARD "remembers" is a lie waiting to happen
- reconstructable state must name an external authority and **cannot** be
  persisted as authoritative; `HistoryOnly` is allowed so trends survive, but a
  restored reading can never be read back as current
- ephemeral state cannot claim any persistence
- startup policy must match the class: `LoadValidateReconcile` / `ProbeFromUnknown`
  / `Reset`

`Observed<T>` carries the freshness rule in the type: it starts `Unknown`, and
`fresh_value()` returns `None` for anything stale or unprobed. A caller that
wants a last-known reading must use `any_value()`, which hands back the timestamp
too — so a screen can say "3 minutes ago" but cannot imply "now".

### Configuration stays configuration

`xcsv_guard.json` remains owned by `GUARD-STATE-001`. A test asserts that
*only* the config and its schema version declare `Persistence::ConfigFile`, so
operational state cannot drift into the config file and two components cannot
both claim the schema version.

### Operational store: `STORE_INTERFACE_ONLY`

Two concrete durable operational consumers are now proven — the absolute
deadline and the warnings already issued — plus small operator context. That
justifies declaring the contract step 5 consumes. It does **not** justify SQLite
for one timestamp and a `Vec<u32>`. When the first slice lands it should reuse
`GUARD-STATE-001`'s already-validated atomic writer rather than introduce a new
storage engine. Revisit when a consumer needs querying or history, not before.

---

Closing GUARD must never erase operational truth.

### Durable

GUARD-owned state that should survive process exit:

- settings and UI preferences
- selected tab / useful operator context
- saved DB views and query history
- filters/preferences
- absolute scheduled restart deadline
- restart warnings already issued
- acknowledged incidents / operator notes
- action journal
- artifact/release identity
- experiment metadata

### Reconstructable

External truth that must be re-probed rather than persisted as fact:

- server / HC / model / MariaDB process state
- PIDs and memory
- RCon state and players
- current RPT / HC RPT
- PBO integrity
- mission state / AI ownership
- infiSTAR / BattlEye records
- database contents
- RAG/model health

### Ephemeral

Safe to discard:

- animation/interpolation
- temporary button feedback
- loading spinners
- scroll momentum

Never present persisted old live values as current truth after relaunch.

---

## 3. Separate configuration from operational state

`xcsv_guard.json` should remain configuration. Durable operational history/state should move to a separate GUARD-owned store, preferably a small local SQLite database.

Configuration examples:

- paths / ports
- server args
- feature switches
- notification settings
- HC/model configuration

Operational-state examples:

- restart deadline
- action journal
- incident acknowledgements
- DB query history
- deployment identities
- experiment records
- saved views / UI context

Add explicit schema versioning and migrations for both config and durable state. New GUARD releases must be able to explain and test migrations rather than silently defaulting fields.

Important writes should be atomic:

`write temp -> close/flush -> validate -> atomic replace`

Retain at least one known-good previous configuration/state copy.

---

## 4. Startup reconciliation

GUARD should explicitly reconcile the estate before declaring READY.

Suggested sequence:

1. load config
2. validate/migrate config and durable-state schema
3. discover MariaDB
4. discover Arma server process/PID
5. discover HC
6. discover local model
7. locate current RPT / HC RPT
8. rescan PBO integrity
9. reconstruct mission/AI state
10. reconnect RCon
11. rebuild player state
12. reconcile restart deadline/warning state
13. check infiSTAR/BattlEye paths
14. check RAG/docs sources
15. enter **READY**, **DEGRADED**, or **SAFE MODE**

An already-running server is normal and must be attachable. A lost Rust `Child` handle must not make the process effectively unmanaged.

### Close vs stop

**Close XCSV GUARD** and **Stop Everything** are separate operations.

Closing GUARD must leave server, HC, MariaDB and model exactly where they are. Reopening GUARD should rediscover them.

---

## 5. Desired state vs observed state

Model each managed component with both operator intent and measured reality.

Example:

| component | desired | observed |
|---|---|---|
| MariaDB | Running | Running |
| Server | Running | Running |
| HC | Running | Stopped |
| RCon | Connected | Reconnecting |
| Local model | Optional | Offline |

This distinguishes **disabled/stopped intentionally** from **expected to be healthy but missing** and gives GUARD a clean reconciliation model.

---

## 6. Restart survival

Scheduled restarts must use persisted wall-clock deadlines, not only process-local `Instant` values.

Persist enough intent to prevent:

- schedule reset after GUARD closes
- duplicate warnings
- false crash/autopsy events
- lost relaunch intent
- duplicate server launches

Formal acceptance scenario:

1. server + HC + MariaDB + model running
2. RCon connected
3. restart deadline established
4. close GUARD
5. leave GUARD closed
6. reopen GUARD
7. same server PID rediscovered
8. HC/model/DB rediscovered
9. RCon reconnects
10. RPT, missions, AI and players rebuild
11. restart deadline remains unchanged
12. warnings are not duplicated
13. integrity is rescanned
14. useful UI context returns
15. no false crash incident
16. no duplicate server launch

---

## 7. GUARD Safe Mode

If configuration/state is corrupt or critical dependencies cannot be trusted, GUARD should still open in a read-mostly **SAFE MODE**.

Safe Mode should:

- never auto-start or mutate the server stack
- clearly display the fault
- retain diagnostics, logs, integrity inspection, docs and recovery tools
- allow restoration of a known-good config/state copy
- keep secrets unavailable if decryption/identity is uncertain

A broken operations console should remain useful during the incident that broke it.

---

## 8. GUARD Backplane

Tabs should render service contracts rather than individually owning backend logic.

`Collectors -> Evidence / Observations -> Derived Services -> UI`

Candidate services:

- Process / Stack Service
- RCon / Player Service
- Telemetry Service
- Mission / AI Service
- Database Service
- Integrity / Artifact Service
- Notification Service
- Docs / RAG Service

Every observation should eventually carry:

- timestamp
- source
- subject/category
- value
- severity
- age/freshness
- raw-evidence reference
- proof state

RCon should be continuously supervised with reconnect/backoff rather than manually connected by individual tabs.

---

## 9. Standard tab contracts and self-diagnostics

Every tab must define:

- required data
- authoritative source(s)
- acceptable age
- healthy / degraded / stale / offline / error behavior
- permitted actions
- proof that an action reached its backend

Standard UI states:

**LOADING / HEALTHY / DEGRADED / STALE / OFFLINE / ERROR**

Blank panels and UNKNOWN-as-zero are not acceptable.

Create mocked contract tests plus separate live-integration checks for all tabs and build a **GUARD System Diagnostics** screen proving connections such as Players/RCon, Database/MariaDB, AI/server RPT, AI/HC RPT, Metrics, Integrity, Docs/RAG and Notifications.

Principle: **prove GUARD works before GUARD claims the server works.**

---

## 10. Replay Mode and failure fixtures

Build an offline **Replay Mode** that loads captured evidence bundles such as:

- server/HC RPT slices
- infiSTAR/BattlEye logs
- RCon responses
- process snapshots
- metrics
- PBO metadata
- selected read-only DB snapshots
- artifact/deployment identity

Use replay bundles as regression fixtures for parsers, UI states and incident reconstruction.

Every serious production failure should become a permanent fixture when practical, including:

- leading-backslash PBO corruption
- extDB restart loop / lock symptoms
- missing `-filePatching`
- MariaDB unavailable
- RPT runaway
- HC not joining / joining without handoff
- FuMS parser wording changes
- RCon unavailable
- stale infiSTAR log
- BOM/corrupt config
- duplicate GUARD process
- server already running before GUARD starts

A production failure should be allowed to surprise XCSV once.

---

## 11. Operator Action Journal

Record consequential GUARD actions independently of game logs.

Each record should include:

- timestamp
- action
- target
- initiating GUARD build
- result
- evidence reference where available

Examples: start/stop stack, message/kick/ban, restart warnings, scheduled shutdown, relaunch, PBO gate refusal, deployment/rollback.

This becomes part of Incident Mode and Replay Mode.

---

## 12. UI/UX refoundation

Reliability/backend work comes first, then visual polish.

### Navigation

**OPERATE** — Overview, Players, Restarts

**INTELLIGENCE** — AI / Missions, Metrics, future Tanoa map

**DIAGNOSTICS** — Integrity, Server Log, Consoles, infiSTAR

**ADMIN / DATA** — Database, RCon

**KNOWLEDGE** — Docs / RAG

**SYSTEM** — Settings, Diagnostics

### Two GUARD modes

Consider two information-density modes within the same application:

- **Operations Mode** — health, players, incidents, missions, restarts, immediate actions
- **Engineering Mode** — integrity, artifacts, profiling, experiments, deployment diff, logs, DB exploration, RAG/docs

### Overview

Overview should answer:

1. Is the server healthy?
2. Are players online?
3. What needs attention?
4. What happens next?

Show healthy state quietly. Elevate deviations and actionable attention.

Global status chips should route to their owning screens. Consider a `Ctrl+K` command/search palette.

### Universal entity inspector

Use one consistent drilldown pattern for Player, Territory, Vehicle, Mission, Process, PBO/Artifact and Error/Incident entities rather than inventing a new detail layout per tab.

### Destructive actions

Use consequence-based confirmations: immediate for low risk, one confirmation for medium risk, explicit target/consequence confirmation for permanent bans, force-stop, Stop Everything and future DB mutation paths.

---

## 13. Evidence/history and SLOs

Add a GUARD-local telemetry/history store separate from the Exile gameplay DB.

Track enough history to reconstruct incidents and compare before/after changes.

Suggested operational phases:

**BOOTING / POPULATING / SETTLING / STEADY STATE / DEGRADED / RESTARTING**

Define practical XCSV service-level objectives/targets such as:

- settled FPS target/floor
- boot-to-joinable time
- HC handoff time
- RCon recovery time
- GUARD reconciliation time
- maximum unexplained RPT growth
- zero unknown broken PBOs
- zero unexplained restart loops

GUARD should judge health against explicit XCSV targets, not merely whether a process exists.

---

## 14. Capacity/headroom view and experiment-driven optimization

Create a headroom view for:

- server FPS margin
- HC/server CPU margin
- RAM
- disk free space
- RPT growth trend
- world-object trend
- AI group trend/ownership
- DB latency trend

Every meaningful optimization should follow:

`Hypothesis -> Baseline -> Bounded Change -> Gauntlet -> Runtime Observation -> Result -> Durable Memory`

Use Bohemia performance/slow-frame profiling when normal metrics stop converging.

Subsystem budgets should cover AI, world objects, scheduled tasks, network traffic and database workload.

Do not add HC2 until measurements show a real scaling need.

---

## 15. Database and operator objects

Move Database toward structured columns/rows, sorting, filtering/search, saved views, query history and snapshot comparison/export where useful.

Higher-level entities:

- **Player** — account, character, sessions, economy, territories, vehicles, moderation context
- **Territory** — owner, members, rights, protection/decay, constructions, containers, vehicles
- **Vehicle** — owner, location, damage/fuel, territory, update/persistence state

Player Inspector should become a central GUARD operator object, not only an XM8 app.

---

## 16. Incident Mode

When something breaks, GUARD should switch from dashboard behavior to chronological investigation.

Correlate:

- metrics
- RPT/HC RPT changes
- AI/HC ownership
- process state
- operator actions
- artifact/deployment identity
- recent config/deployment changes

Provide direct navigation to supporting evidence.

---

## 17. Tanoa operations map

Build a read-only operator map when source data exists for active missions, AI concentration/ownership, crashes, world events, travelling trader, territories and other known markers.

This is visualization, not gameplay authority.

---

## 18. Artifact Registry, deployment diff and rollback

Extend release identity to mission PBOs, server PBOs, custom addons, scripts, BattlEye filters, extDB query files and deployment bundles.

Track:

- artifact ID
- version/build
- source commit
- build timestamp
- SHA256
- deployed SHA256
- status

Before deployment, show a **Deployment Diff**:

- production build vs candidate
- changed files/surfaces
- network/DB/BattlEye impact
- validation status
- rollback artifact

GUARD should surface **CURRENT** and **PREVIOUS VERIFIED** identities and make rollback availability obvious. Do not rely on an operator remembering where the backup is.

---

## 19. Documentation/state drift auditor

Build deterministic checks comparing roadmap status, XM8 shipped/backlog state, README counts, submodule revisions, release manifests and eventually deployed hashes.

Current documentation drift proves this should become executable rather than manual.

---

## 20. Addon provenance and compatibility registry

Treat the old Exile ecosystem as a maintained distribution rather than a folder of historical mods.

Track for each addon/script where practical:

- original author/source
- license
- last upstream release
- upstream maintained/abandoned status
- XCSV modifications and maintainer
- current compatibility state
- dependencies
- performance cost/risk
- network/security exposure
- deployed state
- replacement candidate

Build a compatibility matrix covering important dimensions such as x64, extDB3, Tanoa, HC behavior, BattlEye enforcement and XCSV runtime verification.

---

## 21. Change Impact Graph

Map important dependencies so the Gauntlet can answer **what could this change break?** before mutation.

Examples include:

`CfgExileCustomCode -> mission override -> client function -> network message -> server handler -> extDB query -> BattlEye -> GUARD observation`

This is especially important for shared override points and the lost-merge class of failure.

---

## 22. Staging / isolated integration environment

For risky G3/G4 work, support a temporary isolated integration instance using alternate ports/profiles and a copied or synthetic database, with no public listing.

Use staging for networking changes, DB mutations, BattlEye enforcement, new write-capable XM8 flows and major mod upgrades when feasible.

Staging evidence should precede production for high-risk changes; production runtime evidence is still required afterward.

---

## 23. Curated player systems

The goal is not more mods; it is coherent progression and reasons to return.

Priorities:

1. Territory Manager
2. Contract / Job Board — salvage, delivery, recovery, smuggling, recon, bounty, trader resupply, supply recovery, faction work
3. Bounty system
4. Faction-standing integration — contracts, information, access/discounts, cosmetics, radio responses; avoid crude combat buffs
5. Server Chronicle
6. asynchronous message board/community tools
7. choreographed rotating events connecting storms, FuMS/DMS, crashes, traders and faction radio
8. investigate ZCP/Capture Points before another heavy AI framework

Keep Zombies and VcomAI parked until measured server/HC headroom changes the decision.

---

## 24. AI evidence boundary

Development AIs may eventually consume exported GUARD evidence packages, replay fixtures, metrics, manifests and test results.

The preferred direction is:

`GUARD -> evidence -> development AI`

not unrestricted:

`development AI -> GUARD production controls`

The runtime local model remains tool-less, non-load-bearing and without authority.

---

## 25. Current implementation reality

Already present in the GitHub snapshot:

- refactored GUARD tab modules
- x64/extDB3 production support
- stack orchestration
- PBO integrity gate
- mission/AI log parsing
- grouped read-only DB presets
- GUARD release/build identity
- RAG status integration
- join/leave/restart notifications
- benign RPT filtering
- XM8 Player Inspector App20 source
- extended XM8 extra-app grid source

Still planned/partial:

- canonical Gauntlet protocol and AI adapters
- state schema / SQLite durable-state layer
- atomic persistence / migration framework
- startup reconciliation
- desired-vs-observed state model
- Safe Mode
- restart deadline persistence
- RCon auto-reconnect
- backend backplane/health registry
- tab contracts/tests and self-diagnostics
- Replay Mode/failure fixtures
- Operator Action Journal
- grouped navigation / Operations-vs-Engineering UX
- SLO/headroom model
- historical telemetry / experiments
- structured DB/operator entities
- Incident Mode
- Tanoa operations map
- estate-wide Artifact Registry / deployment diff / rollback UX
- state-drift auditor
- addon provenance/compatibility matrix
- Change Impact Graph
- isolated staging path
- major curated player systems

Do not promote source presence to live runtime verification without runtime evidence.

---

## Recommended sequence

1. Gauntlet architecture
2. canonical AI-rule distribution/drift detection
3. config/state schema versioning + atomic persistence foundation
4. GUARD durable/reconstructable/ephemeral state model
5. startup reconciliation + desired/observed state
6. absolute restart persistence + RCon auto-reconnect
7. backend health registry/backplane
8. tab contracts + self-diagnostics
9. Replay Mode + historical failure fixtures
10. Operator Action Journal + Safe Mode
11. shell/navigation + Operations/Engineering UX
12. Overview + universal entity inspector
13. structured DB/operator objects
14. telemetry/history + SLO/headroom + experiments
15. Incident Mode
16. operations map
17. Artifact Registry + deployment diff + rollback
18. provenance/compatibility + Change Impact Graph
19. staging path for high-risk work
20. curated player progression/content

---

## Governing principles

> **GUARD should never need to remember that the server is healthy. It should be able to prove the server is healthy again every time it starts.**

> **Green is quiet. Problems are loud. UNKNOWN is never rendered as zero.**

> **A production failure should be allowed to surprise XCSV once; afterward it should become evidence, a fixture, or an executable check.**
