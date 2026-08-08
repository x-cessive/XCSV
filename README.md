<div align="center">

# XCSV

**A dedicated Arma 3 Exile server, and every piece of software that keeps it alive.**

[![Server](https://img.shields.io/badge/XCSV_EXILE-Tanoa-3D9CFF.svg?style=for-the-badge)](https://x-cessive.github.io/XCSV/)
[![Status](https://img.shields.io/badge/status-in_development-E8B339.svg?style=for-the-badge)](#operational-status)
[![Site](https://img.shields.io/badge/site-x--cessive.github.io%2FXCSV-3FC16A.svg?style=for-the-badge)](https://x-cessive.github.io/XCSV/)

[![Arma 3](https://img.shields.io/badge/Arma_3-2.20.152984-blue.svg?logo=steam&logoColor=white)](https://arma3.com/)
[![Exile Mod](https://img.shields.io/badge/Exile_Mod-1.0.4a_Pineapple-00b2cd.svg)](https://exile.majormittens.co.uk/)
[![MariaDB](https://img.shields.io/badge/Database-MariaDB_10.11-003545.svg?logo=mariadb&logoColor=white)](https://mariadb.org/)
[![extDB3](https://img.shields.io/badge/Driver-extDB3_x64-00599c.svg)](https://github.com/x-cessive/Exile)
[![Rust](https://img.shields.io/badge/Console-Rust_+_egui-CE422B.svg?logo=rust&logoColor=white)](https://github.com/x-cessive/XCSV_GUARD)
[![SQF](https://img.shields.io/badge/Addons-SQF-ffb400.svg)](https://github.com/x-cessive/XCSV_ADDONS)

</div>

---

> ## AI / AGENT START HERE
>
> **Before acting on any roadmap item or creating commits, read [AI Start Here](wiki/AI-Start-Here.md) and [AI Provenance & Doc Sync](wiki/AI-Provenance-and-Doc-Sync.md).**
>
> If Architect says **"read the GitHub"**, **"read the roadmap"**, **"get caught up"**, or equivalent, enter the contract's **READ_ONLY_BOOTSTRAP** first. Roadmap status is intent, not implementation proof. Reconcile the desktop roadmap, RAG/history, local working trees, Git history, GitHub/submodule state and relevant live evidence; then work only on the remaining delta.
>
> **Current documentation state: `SYNCED` as of 2026-08-07 (work ID `XCSV-AI-001`).** The first SOVRAN-1 reconciliation is complete: GitHub's AI-contract and planning work was absorbed into the desktop roadmap as Phase 15 by append, and the desktop's operational evidence stays authoritative where this estate deliberately summarises it. Reconcile semantically on future divergence; never overwrite one side to force agreement.
>
> **AI-authored commits require XCSV provenance trailers** so the authenticated GitHub account and the authoring AI are not confused.
>
> **GUARD UI/behavior changes also require media refresh:** update the GitHub-facing
> screenshots and GIFs across the XCSV repos with `D:\XCSV_GUARD\tools\capture.ps1`
> before calling the work complete. For live debugging, keep Orca pinned left and
> XCSV GUARD pinned right with `D:\XCSV\tools\ai-desktop-capture.ps1 -Layout -Shot`;
> use `-WideGuardForShot` only for temporary wider captures, and restore the
> right-pinned layout afterward.

This repository is the **hub**. It holds the system map, documentation, wiki and submodule pointers for XCSV EXILE.

## 🗺️ The system

| repo | what it is | visibility |
|---|---|---|
| **[XCSV](https://github.com/x-cessive/XCSV)** | Hub, docs, roadmap, wiki and estate map. | public |
| 🛡️ **[XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD)** | Rust/egui operations console: integrity, RCon, metrics, AI/mission intelligence, DB views, notifications, stack supervision and release identity. | private |
| 🧩 **[XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS)** | Original XCSV addons and mission scripts. | private |
| 📦 **[Exile](https://github.com/x-cessive/Exile)** | Third-party catalogue, live-source mirrors, PBO tooling and BattlEye tooling. | public |

## 🚦 Operational status

XCSV EXILE runs on Tanoa and is actively developed as a live public server.

| | |
|---|---|
| Map | Tanoa (`Exile.Tanoa`) |
| Server | `arma3server_x64.exe` |
| Database | MariaDB 10.11 via extDB3 |
| Anti-cheat | BattlEye + infiSTAR |
| Headless client | live; A3XAI/FuMS handoff observed |

## 🧭 Development direction

### XCSV Gauntlet

One canonical, versioned protocol for Claude Code, OpenCode, Antigravity and development-local LLMs:

`TARGET LOCK -> RECON -> DECOMPOSE -> WORKERS -> ADVERSARIAL CRITICS -> INTEGRATION -> MEASUREMENT -> EVIDENCE -> VERDICT`

Gauntlet depth scales with risk. Workers may not self-certify. **EVIDENCED / INFERRED / UNKNOWN** remain separate. Deterministic rules should migrate into executable checks.

### GitHub-native execution tracking

XCSV uses **GitHub Issues + GitHub Projects** as the primary execution tracker. The roadmap remains durable priority/decision memory; issues and project state track active execution. This avoids duplicating work into a second Trello/Jira-style task database.

The official GitHub MCP Server is an optional enhancement after the baseline `git` / `gh` workflow is verified. Linear is the only serious future external candidate and should be reconsidered only if GitHub Projects develops a measurable limitation.

Full tooling decision record: **[AI / Development Tooling](wiki/AI-Tooling.md)**.

### GUARD reliability first

Primary invariant:

> **Closing XCSV GUARD must never erase operational truth. Reopening it must reconstruct the same server state from authoritative sources and continue supervising it.**

The plan includes config/state separation, schema migration and atomic persistence, startup reconciliation, desired-vs-observed state, restart persistence, RCon recovery, Safe Mode, backend contracts, self-diagnostics, Replay Mode, action journaling, Operations/Engineering UX, historical telemetry, SLO/headroom views, Incident Mode, operations mapping, artifact identity, deployment diff/rollback, provenance/compatibility and staging for high-risk work.

### GUARD as an evidence instrument

GUARD should increasingly answer not just **what is happening**, but **what changed, what evidence supports it, what the expected state is, and whether the system has enough headroom for the next feature**.

Development AIs may consume exported GUARD evidence, replay bundles, metrics and manifests. That does not imply unrestricted AI authority over production controls.

### Curated player systems

Prioritize integration and progression over raw addon count: Territory Manager, contracts/jobs, bounties, faction-standing integration, Chronicle, asynchronous community tools, choreographed events and selective objective systems. Keep Zombies/Vcom parked until measured HC/server headroom justifies reconsideration.

Full design: **[XCSV GUARD Development Plan](wiki/XCSV-GUARD-Development-Plan.md)**.

## ⚠️ Operating principles

1. Performance before content.
2. A PBO checksum alone is not enough; inspect entry paths.
3. Production is x64 + extDB3; do not revive the old extDB2/x86 path as a casual fallback.
4. `-filePatching` is load-bearing for the current A3XAI configuration path.
5. UNKNOWN is not zero and "no error logged" is not proof of function.
6. A production failure should surprise XCSV once; afterward it becomes evidence, a fixture or an executable check.
7. Green is quiet; deviations get attention.

## 🧭 Where things are

| I want to… | go to |
|---|---|
| Orient an AI / reconcile roadmap work | [AI Start Here](wiki/AI-Start-Here.md) |
| Understand AI attribution and desktop/GitHub sync | [AI Provenance & Doc Sync](wiki/AI-Provenance-and-Doc-Sync.md) |
| See tooling decisions / tracker policy | [AI / Development Tooling](wiki/AI-Tooling.md) |
| See the full current development programme | [XCSV GUARD Development Plan](wiki/XCSV-GUARD-Development-Plan.md) |
| See priority/order and completed work | [Roadmap](wiki/Roadmap.md) |
| Understand architecture | [Architecture](wiki/Architecture.md) |
| Diagnose the server | [Runbook](wiki/Runbook.md) |
| Build an XM8 app | [XM8 Apps](wiki/XM8-Apps.md) |
| Avoid repeated failures | [Lessons](wiki/Lessons.md) |
| Read about GUARD | [XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD) |
| Read XCSV addons | [XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS) |
| Browse third-party systems | [Exile](https://github.com/x-cessive/Exile) |

## ✍️ Documentation

`wiki/` is the Git-tracked wiki source. `docs/wiki/` is generated and should not be hand-maintained as an authority.

```powershell
.\tools\build-docs.ps1
.\tools\push-wiki.ps1
```

The desktop `ARMA3_EXILE_CODEX\ROADMAP.md` remains the authoritative full working roadmap. The first SOVRAN-1 reconciliation was performed on 2026-08-07 (`XCSV-AI-001`), so documentation state is **SYNCED**; classify it again at each bootstrap rather than assuming it stays that way. See [AI Provenance & Doc Sync](wiki/AI-Provenance-and-Doc-Sync.md).

## 🔒 Security / licensing

No production secrets belong in git. Runtime model output is untrusted text. Exile source is not copied into XCSV_ADDONS; overrides must preserve licensing and shared `CfgExileCustomCode` registrations must be merged deliberately.

---

<div align="center">
<sub>XCSV EXILE · built in the open · <a href="https://x-cessive.github.io/XCSV/">x-cessive.github.io/XCSV</a></sub>
</div>
