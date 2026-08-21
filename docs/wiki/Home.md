---
layout: wiki
section: docs
title: Overview
heading: Overview
blurb: What XCSV EXILE is, and where to start.
order: 5
source: Home.md
---

> ## AI / AGENT START HERE
>
> **Start at the root `AI-START-HERE.md`, then read [AI Start Here](AI-Start-Here.html) and [AI Provenance & Doc Sync](AI-Provenance-and-Doc-Sync.html) before acting on the roadmap or creating commits.**
>
> If Architect says **"read the GitHub"**, **"read the roadmap"**, **"get caught up"**, or equivalent, run the canonical `READ_ONLY_BOOTSTRAP` first. Reconcile roadmap intent against RAG/history, local working trees, Git history, GitHub/submodules and relevant live evidence. Work only on the remaining delta; do not duplicate equivalent functionality.
>
> **Do not inherit the 2026-08-07 `SYNCED` result as current truth.** It is historical evidence of that reconciliation. Current observations are source-specific; see [Repository Identity & Freshness](Repository-Identity-and-Freshness.html) and `registry/current-state.json`. `NOT_REVERIFIED`, `STALE` and `UNKNOWN` are valid outcomes.
>
> documentation state: `UNKNOWN`. The tracked XCSV wiki and published GitHub Wiki may be verified independently, but the desktop roadmap remains `NOT_REVERIFIED` until inspected.

A dedicated **Arma 3 Exile** server on Tanoa, and every piece of software that keeps it alive.

This wiki is the operator/development map. The [site](https://x-cessive.github.io/XCSV/) is the public-facing view; the [hub repo](https://github.com/x-cessive/XCSV) is the repository map.

## Start here

| page | when you need it |
|---|---|
| **[AI Start Here](AI-Start-Here.html)** | mandatory AI navigation, reconciliation, delta-first workflow and GitHub work-tracking contract |
| **[Repository Identity & Freshness](Repository-Identity-and-Freshness.html)** | what XCSV is/is not canonical for, per-source freshness, and cold-rehydration rules |
| **[AI Provenance & Doc Sync](AI-Provenance-and-Doc-Sync.html)** | AI commit attribution, issue work receipts, and safe desktop/GitHub documentation reconciliation |
| **[AI / Development Tooling](AI-Tooling.html)** | selected/rejected workflow tools, GitHub-native tracking decision, optional MCP and recommended CI/security helpers |
| **[XCSV GUARD Development Plan](XCSV-GUARD-Development-Plan.html)** | durable GUARD design programme: Gauntlet, restart safety, replay, backplane, UX, evidence, deployment, staging, player systems |
| **[Roadmap](Roadmap.html)** | priority/order, completed work and planning intent; not implementation proof by itself |
| **[Architecture](Architecture.html)** | understanding what talks to what |
| **[Runbook](Runbook.html)** | operating/recovery procedures |
| **[Repositories](Repositories.html)** | where a given file lives and why |
| **[XM8 Apps](XM8-Apps.html)** | player/admin-facing app work |
| **[Memory](Memory.html)** | project memory / retrieval workflow |
| **[Lessons](Lessons.html)** | failures, refuted hypotheses and rules bought with real incidents |

## Workflow/tooling decision

XCSV uses **GitHub Issues + GitHub Projects** as the primary execution tracker so tasks, commits, PRs and sub-issues remain attached to the source instead of being copied into a second board. The official GitHub MCP Server is an optional enhancement after the baseline `git`/`gh` workflow is verified. External planning tools must not silently become a competing execution authority.

See [AI / Development Tooling](AI-Tooling.html) for the full decision record.

## GUARD development programme

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

These are durable programme directions, not proof that every item is implemented or currently deployed.

Core invariants:

> **GUARD should never need to remember that the server is healthy. It should be able to prove the server is healthy again every time it starts.**

> **A production failure should surprise XCSV once; afterward it becomes evidence, a fixture or an executable check.**

## Player-development direction

The estate is already large. Prefer coherence and progression over blind addon count: Territory Manager, contracts/jobs, bounties, meaningful faction standing, Chronicle/community systems, choreographed world events and selective objective systems. Performance-sensitive additions remain subject to measured headroom and current evidence.

## Non-negotiables

- production architecture is documented as x64 + extDB3; reverify runtime before treating documentation as live proof
- `-filePatching` is documented as load-bearing for the A3XAI configuration path; reverify before operational use
- no Exile source copied into XCSV original addons
- secrets stay out of git
- runtime local-model output is untrusted and non-load-bearing
- UNKNOWN is not zero; absence of logged failure is not proof of function
- performance changes require settled, comparable evidence
- built, committed, accepted, deployed and runtime-verified are distinct states
