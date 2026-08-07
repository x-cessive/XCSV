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
> **Before acting on any roadmap item, read [AI Start Here](wiki/AI-Start-Here.md).**
>
> If Architect says **"read the GitHub"**, **"read the roadmap"**, **"get caught up"**, or equivalent, enter the contract's **READ_ONLY_BOOTSTRAP** first. Roadmap status is intent, not implementation proof. Reconcile the desktop roadmap, RAG/history, local working trees, Git history, GitHub/submodule state and relevant live evidence; then work only on the remaining delta.
>
> **Do not duplicate substantially equivalent functionality.** If sources disagree, reconcile the conflict before implementation.

This repository is the **hub**. It holds the system map, documentation, wiki and submodule pointers for XCSV EXILE.

> **Planning update — 2026-08-07:** GitHub carries the current XCSV Gauntlet + GUARD reliability/UX + server optimization + curated player-development programme. See the [XCSV GUARD Development Plan](wiki/XCSV-GUARD-Development-Plan.md) and [Roadmap](wiki/Roadmap.md). The desktop/Obsidian roadmap remains authoritative and is pending manual reconciliation by Architect.

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

### GUARD reliability first

Primary invariant:

> **Closing XCSV GUARD must never erase operational truth. Reopening it must reconstruct the same server state from authoritative sources and continue supervising it.**

The plan now includes:

- separate config from durable operational state
- schema versioning/migrations and atomic persistence
- startup reconciliation and desired-vs-observed state
- absolute restart persistence and RCon auto-reconnect
- Safe Mode for damaged/untrusted startup state
- backend backplane and formal tab contracts
- self-diagnostics and restart-survival acceptance tests
- Replay Mode plus historical failure fixtures
- Operator Action Journal
- Operations Mode vs Engineering Mode UX
- universal entity inspector
- historical telemetry, explicit SLOs and capacity/headroom views
- Incident Mode and Tanoa operations map
- artifact registry, deployment diff and explicit rollback identity
- documentation/state drift auditing
- addon provenance and compatibility matrix
- Change Impact Graph
- isolated staging path for high-risk G3/G4 work

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

`wiki/` is the Git-tracked wiki source. `docs/wiki/` is generated and should not be hand-maintained as the authoritative source.

```powershell
.\tools\build-docs.ps1
.\tools\push-wiki.ps1
```

The desktop `ARMA3_EXILE_CODEX\ROADMAP.md` remains the authoritative full working roadmap. Architect will manually reconcile it with this GitHub planning state.

## 🔒 Security / licensing

No production secrets belong in git. Runtime model output is untrusted text. Exile source is not copied into XCSV_ADDONS; overrides must preserve licensing and shared `CfgExileCustomCode` registrations must be merged deliberately.

---

<div align="center">
<sub>XCSV EXILE · built in the open · <a href="https://x-cessive.github.io/XCSV/">x-cessive.github.io/XCSV</a></sub>
</div>