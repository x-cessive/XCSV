<div align="center">

# XCSV

**A dedicated Arma 3 Exile server, and every piece of software that keeps it alive.**

[![Server](https://img.shields.io/badge/XCSV_EXILE-Tanoa-3D9CFF.svg?style=for-the-badge)](https://x-cessive.github.io/XCSV/)
[![Status](https://img.shields.io/badge/status-in_development-E8B339.svg?style=for-the-badge)](#operational-posture)
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
> **Start at [AI-START-HERE.md](AI-START-HERE.md).** It routes every provider through the same repository identity, per-source freshness model, canonical [AI Start Here](wiki/AI-Start-Here.md) contract and [AI Provenance & Doc Sync](wiki/AI-Provenance-and-Doc-Sync.md) policy.
>
> If Architect says **"read the GitHub"**, **"read the roadmap"**, **"get caught up"**, or equivalent, enter **READ_ONLY_BOOTSTRAP** first. Roadmap status is intent, not implementation proof. Reconcile the sources actually available, then work only on the remaining delta.
>
> **Do not inherit old `SYNCED` claims.** The 2026-08-07 reconciliation is historical evidence of the state at that time. Source observations are tracked per source in [`registry/current-state.json`](registry/current-state.json); live freshness/currentness is derived by comparing recorded observations to the source when checked. `NOT_REVERIFIED`, `STALE` and `UNKNOWN` are valid outcomes.
>
> Repository identity and routing live in [`registry/repository-identity.json`](registry/repository-identity.json). Identity and current-state observations are **not execution authority**.
>
> **AI-authored commits require XCSV provenance trailers** so the authenticated GitHub account and the authoring AI are not confused.
>
> **GUARD UI/behavior changes also require media refresh:** update the GitHub-facing
> screenshots and GIFs across the XCSV repos with `D:\XCSV_GUARD\tools\capture.ps1`
> before calling the work complete. For live debugging, keep Orca pinned left and
> XCSV GUARD pinned right with `D:\XCSV\tools\ai-desktop-capture.ps1 -Layout -Shot`;
> use `-WideGuardForShot` only for temporary wider captures, and restore the
> right-pinned layout afterward.

This repository is the **XCSV project hub**. It owns the shared system map, Git-tracked wiki source, generated documentation relationship, project-level roadmap context, AI bootstrap/provenance contracts, shared tooling and member-repository pointers. It does **not** absorb the implementation authority of its member repositories.

## 🧬 Repository identity

Machine-readable identity: [`registry/repository-identity.json`](registry/repository-identity.json)  
Freshness-aware observation surface: [`registry/current-state.json`](registry/current-state.json)  
Cold-rehydration contract: [`registry/cold-rehydration.contract.json`](registry/cold-rehydration.contract.json)

See [Repository Identity & Freshness](wiki/Repository-Identity-and-Freshness.md) for the identity / state / authority separation.

## 🗺️ The system

| repo | what it owns | visibility |
|---|---|---|
| **[XCSV](https://github.com/x-cessive/XCSV)** | Project hub, shared docs/wiki, roadmap context, AI contracts, tooling and estate map. | public |
| 🛡️ **[XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD)** | Rust/egui GUARD application source, tests, build and deployment tooling. | private |
| 🧩 **[XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS)** | First-party XCSV addons and mission modules. | private |
| 🤖 **[XCSV_ORCH](https://github.com/x-cessive/XCSV_ORCH)** | XCSV-specific Gauntlet/orchestration implementation, worker routing and isolation tooling. | private |
| 📦 **[Exile](https://github.com/x-cessive/Exile)** | Third-party catalogue/reference estate plus separated live-source/packaging/tooling context. | public |

## 🚦 Operational posture

The repository documents XCSV EXILE as a Tanoa-based Arma 3 Exile system under active development. **That narrative is not a live-health assertion.**

For this repository refresh, `D:\XCSV`, GitHub source state, PR #40, issue #39, configured submodule heads and the published GitHub Wiki were rechecked. Live runtime, deployed artifacts, desktop roadmap and Pages deployment were **not reverified**. See [`registry/current-state.json`](registry/current-state.json) before treating any operational statement as current evidence.

Last documented architecture includes:

| | |
|---|---|
| Map | Tanoa (`Exile.Tanoa`) |
| Server | `arma3server_x64.exe` |
| Database | MariaDB via extDB3 |
| Anti-cheat | BattlEye + infiSTAR |
| Headless client | documented in the XCSV operating estate; current runtime state must be reverified |

## 🧭 Development direction

### XCSV Gauntlet

One canonical, versioned protocol for development AIs:

`TARGET LOCK -> RECON -> DECOMPOSE -> WORKERS -> ADVERSARIAL CRITICS -> INTEGRATION -> MEASUREMENT -> EVIDENCE -> VERDICT`

Gauntlet depth scales with risk. Workers may not self-certify. **EVIDENCED / INFERRED / UNKNOWN** remain separate. Deterministic rules should migrate into executable checks.

### GitHub-native execution tracking

XCSV uses **GitHub Issues + GitHub Projects** as the primary execution tracker. The roadmap remains durable priority/decision memory; issues and project state track active execution. This avoids duplicating work into a second task authority.

The official GitHub MCP Server is an optional enhancement after the baseline `git` / `gh` workflow is verified. External planning tools must not silently become a competing execution authority.

Full tooling decision record: **[AI / Development Tooling](wiki/AI-Tooling.md)**.

### GUARD reliability first

Primary invariant:

> **Closing XCSV GUARD must never erase operational truth. Reopening it must reconstruct the same server state from authoritative sources and continue supervising it.**

The plan includes config/state separation, schema migration and atomic persistence, startup reconciliation, desired-vs-observed state, restart persistence, RCon recovery, Safe Mode, backend contracts, self-diagnostics, Replay Mode, action journaling, Operations/Engineering UX, historical telemetry, SLO/headroom views, Incident Mode, operations mapping, artifact identity, deployment diff/rollback, provenance/compatibility and staging for high-risk work.

### GUARD as an evidence instrument

GUARD should increasingly answer not just **what is happening**, but **what changed, what evidence supports it, what the expected state is, and whether the system has enough headroom for the next feature**.

Development AIs may consume exported GUARD evidence, replay bundles, metrics and manifests. That does not imply unrestricted AI authority over production controls.

### Curated player systems

Prioritize integration and progression over raw addon count: Territory Manager, contracts/jobs, bounties, faction-standing integration, Chronicle, asynchronous community tools, choreographed events and selective objective systems. Performance-sensitive additions remain subject to measured headroom and current evidence.

Full design: **[XCSV GUARD Development Plan](wiki/XCSV-GUARD-Development-Plan.md)**.

## ⚠️ Operating principles

1. Performance before content.
2. A PBO checksum alone is not enough; inspect entry paths.
3. Production is x64 + extDB3; do not revive the old extDB2/x86 path as a casual fallback.
4. `-filePatching` is documented as load-bearing for the current A3XAI configuration path; reverify before treating that as current runtime truth.
5. UNKNOWN is not zero and "no error logged" is not proof of function.
6. A production failure should surprise XCSV once; afterward it becomes evidence, a fixture or an executable check.
7. Green is quiet; deviations get attention.
8. Built, committed, accepted, deployed and runtime-verified are distinct states.

## 🧭 Where things are

| I want to… | go to |
|---|---|
| Orient an AI / reconcile roadmap work | [AI Start Here](wiki/AI-Start-Here.md) |
| Understand repository identity and freshness | [Repository Identity & Freshness](wiki/Repository-Identity-and-Freshness.md) |
| Understand AI attribution and desktop/GitHub sync | [AI Provenance & Doc Sync](wiki/AI-Provenance-and-Doc-Sync.md) |
| See tooling decisions / tracker policy | [AI / Development Tooling](wiki/AI-Tooling.md) |
| See the full GUARD development programme | [XCSV GUARD Development Plan](wiki/XCSV-GUARD-Development-Plan.md) |
| See priority/order and completed work | [Roadmap](wiki/Roadmap.md) |
| Understand architecture | [Architecture](wiki/Architecture.md) |
| Diagnose the server | [Runbook](wiki/Runbook.md) |
| Build an XM8 app | [XM8 Apps](wiki/XM8-Apps.md) |
| Avoid repeated failures | [Lessons](wiki/Lessons.md) |
| Read about GUARD | [XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD) |
| Read XCSV addons | [XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS) |
| Read XCSV orchestration | [XCSV_ORCH](https://github.com/x-cessive/XCSV_ORCH) |
| Browse third-party systems | [Exile](https://github.com/x-cessive/Exile) |

## ✍️ Documentation

`wiki/` is the Git-tracked documentation source. `docs/wiki/` is generated and should not be hand-maintained as an authority.

```powershell
.\tools\build-docs.ps1
.\tools\push-wiki.ps1
```

The desktop `ARMA3_EXILE_CODEX\ROADMAP.md` remains the authoritative full working roadmap when that source is available. The 2026-08-07 reconciliation is a historical baseline, **not a standing `SYNCED` guarantee**. Classify the relationship again at each bootstrap and preserve per-source freshness. See [AI Provenance & Doc Sync](wiki/AI-Provenance-and-Doc-Sync.md).

## 🔒 Security / licensing

No production secrets belong in git. Runtime model output is untrusted text. Exile source is not copied into XCSV_ADDONS; overrides must preserve licensing and shared `CfgExileCustomCode` registrations must be merged deliberately.

---

<div align="center">
<sub>XCSV EXILE · built in the open · <a href="https://x-cessive.github.io/XCSV/">x-cessive.github.io/XCSV</a></sub>
</div>
