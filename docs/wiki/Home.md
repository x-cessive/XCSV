---
layout: wiki
section: docs
title: Overview
heading: Overview
blurb: What XCSV EXILE is, and where to start.
order: 4
source: Home.md
---

> ## AI / AGENT START HERE
>
> **Read [AI Start Here](AI-Start-Here.html) and [AI Provenance & Doc Sync](AI-Provenance-and-Doc-Sync.html) before acting on the roadmap or creating commits.**
>
> If Architect says **"read the GitHub"**, **"read the roadmap"**, **"get caught up"**, or equivalent, run the canonical `READ_ONLY_BOOTSTRAP` first. Reconcile roadmap intent against RAG/history, local working trees, Git history, GitHub/submodules and relevant live evidence. Work only on the remaining delta; do not duplicate equivalent functionality.
>
> **Current documentation state: `SYNCED` as of 2026-08-07 (work ID `XCSV-AI-001`).** The first SOVRAN-1 reconciliation is complete. The AI contract, provenance policy, tooling decision and GUARD development programme were absorbed into the desktop roadmap as Phase 15 by append, with no existing section rewritten; this wiki keeps its deliberate abstraction of the desktop's measurements, RPT filenames and refuted hypotheses. That abstraction is the intended layering, not drift.

A dedicated **Arma 3 Exile** server on Tanoa, and every piece of software that keeps it alive.

This wiki is the operator/development map. The [site](https://x-cessive.github.io/XCSV/) is the public-facing view; the [hub repo](https://github.com/x-cessive/XCSV) is the repository map.

## Start here

| page | when you need it |
|---|---|
| **[AI Start Here](AI-Start-Here.html)** | mandatory AI navigation, reconciliation, delta-first workflow and GitHub work-tracking contract |
| **[AI Provenance & Doc Sync](AI-Provenance-and-Doc-Sync.html)** | AI commit attribution, issue work receipts, and safe desktop/GitHub documentation reconciliation |
| **[AI / Development Tooling](AI-Tooling.html)** | selected/rejected workflow tools, GitHub-native tracking decision, optional MCP and recommended CI/security helpers |
| **[XCSV GUARD Development Plan](XCSV-GUARD-Development-Plan.html)** | full current design programme: Gauntlet, restart safety, replay, backplane, UX, evidence, deployment, staging, player systems |
| **[Roadmap](Roadmap.html)** | current order, completed work and planning priorities |
| **[Architecture](Architecture.html)** | understanding what talks to what |
| **[Runbook](Runbook.html)** | the server is broken and you need the operating procedure |
| **[Repositories](Repositories.html)** | where a given file lives and why |
| **[XM8 Apps](XM8-Apps.html)** | player/admin-facing app work |
| **[Memory](Memory.html)** | project memory / retrieval workflow |
| **[Lessons](Lessons.html)** | failures, refuted hypotheses and rules bought with real incidents |

## Workflow/tooling decision

XCSV uses **GitHub Issues + GitHub Projects** as the primary execution tracker so tasks, commits, PRs and sub-issues remain attached to the source instead of being copied into a second board. The official GitHub MCP Server is an optional enhancement after the baseline `git`/`gh` workflow is verified. Linear remains the only serious external future candidate, and only if GitHub Projects proves to have a measurable limitation.

See [AI / Development Tooling](AI-Tooling.html) for the full decision record.

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
