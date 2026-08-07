# XCSV EXILE

A dedicated **Arma 3 Exile** server on Tanoa, and every piece of software that keeps it alive.

This wiki is the operator/development map. The [site](https://x-cessive.github.io/XCSV/) is the public-facing view; the [hub repo](https://github.com/x-cessive/XCSV) is the repository map.

> **Planning state — 2026-08-07:** GitHub carries the current Gauntlet + GUARD reliability/UX + server optimization + deployment/provenance + curated player-development backlog. The desktop `ARMA3_EXILE_CODEX\ROADMAP.md` remains authoritative and will be reconciled manually by Architect.

## Start here

| page | when you need it |
|---|---|
| **[XCSV GUARD Development Plan](XCSV-GUARD-Development-Plan)** | full current design programme: Gauntlet, restart safety, replay, backplane, UX, evidence, deployment, staging, player systems |
| **[Roadmap](Roadmap)** | current order, completed work and planning priorities |
| **[Architecture](Architecture)** | understanding what talks to what |
| **[Runbook](Runbook)** | the server is broken and you need the operating procedure |
| **[Repositories](Repositories)** | where a given file lives and why |
| **[XM8 Apps](XM8-Apps)** | player/admin-facing app work |
| **[Memory](Memory)** | project memory / retrieval workflow |
| **[Lessons](Lessons)** | failures, refuted hypotheses and rules bought with real incidents |

## Current GUARD programme

GUARD is being evolved around these principles:

- one canonical **Gauntlet Protocol** across development AIs
- explicit **durable / reconstructable / ephemeral** state ownership
- separate configuration from durable operational state
- schema migrations and atomic persistence
- startup reconciliation and **desired vs observed** component state
- restart-safe absolute deadlines and RCon auto-recovery
- Safe Mode for damaged/untrusted startup state
- backend service/backplane contracts for every tab
- self-diagnostics and formal tab integration tests
- offline Replay Mode plus permanent failure fixtures
- Operator Action Journal
- task-oriented UX with Operations/Engineering modes
- historical telemetry, explicit SLOs and capacity/headroom
- Incident Mode and a read-only Tanoa operations map
- artifact registry, deployment diff and explicit rollback identity
- documentation/state drift checks
- addon provenance/compatibility registry
- Change Impact Graph
- isolated staging for risky G3/G4 work
- GUARD evidence exported to development AI without granting unrestricted production authority

Core invariants:

> **GUARD should never need to remember that the server is healthy. It should be able to prove the server is healthy again every time it starts.**

> **A production failure should surprise XCSV once; afterward it becomes evidence, a fixture or an executable check.**

## Player-development direction

The estate is already large. Prefer coherence and progression over blind addon count: Territory Manager, contracts/jobs, bounties, meaningful faction standing, Chronicle/community systems, choreographed world events and selective objective systems. Keep heavyweight additional AI frameworks parked until measured headroom supports them.

## Non-negotiables

- production remains x64 + extDB3
- `-filePatching` remains load-bearing for the current A3XAI configuration path
- no Exile source copied into XCSV original addons
- secrets stay out of git
- runtime local-model output is untrusted and non-load-bearing
- UNKNOWN is not zero; absence of logged failure is not proof of function
- performance changes require settled, comparable evidence
