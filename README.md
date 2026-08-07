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

This repository is the **hub**. It holds no game code of its own — it holds the
map of the system, the documentation site, the wiki, and submodule pointers at
every repository that makes up XCSV EXILE.

If you are looking for something specific, start here.

> **Planning update — 2026-08-07:** the GitHub documentation now carries the
> current XCSV Gauntlet + GUARD reliability/UX + server optimization + curated
> player-development programme. See the
> [XCSV GUARD Development Plan](wiki/XCSV-GUARD-Development-Plan.md) and
> [Roadmap](wiki/Roadmap.md). The desktop/Obsidian roadmap remains authoritative
> and is pending manual reconciliation by Architect; any disagreement until then
> is explicit planning-state divergence.

<div align="center">

[![XCSV GUARD](https://x-cessive.github.io/XCSV/assets/shots/overview.png)](https://x-cessive.github.io/XCSV/guard/)

<sub><b>XCSV GUARD</b> supervising the live server ·
<a href="https://x-cessive.github.io/XCSV/guard/">more screenshots</a></sub>

</div>

## 🗺️ The system

| repo | what it is | visibility |
|---|---|---|
| **[XCSV](https://github.com/x-cessive/XCSV)** *(you are here)* | Hub. System map, [site](https://x-cessive.github.io/XCSV/), documentation, roadmap and development plan. | public |
| 🛡️ **[XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD)** | Operations console. Rust + egui. Integrity, RCon, metrics, AI/mission intelligence, database views, notifications, stack supervision and release identity. | private |
| 🧩 **[XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS)** | Our own addons and mission scripts. Written from scratch — contains no Exile source. | private |
| 📦 **[Exile](https://github.com/x-cessive/Exile)** | Catalogue of third-party addons/scripts plus live-source mirrors, PBO tooling and BattlEye tooling. | public |

```
                         ┌──────────────────────────┐
                         │       XCSV GUARD         │
                         │ integrity · RCon · AI    │
                         │ metrics · DB · restarts  │
                         └────────────┬─────────────┘
                                      │ supervises / observes
        ┌───────────────┬─────────────┼──────────────┬───────────────┐
        │               │             │              │               │
   ┌────▼────┐   ┌──────▼──────┐ ┌────▼─────┐  ┌─────▼─────┐  ┌──────▼──────┐
   │ MariaDB │◄──┤ arma3server │ │ Headless │  │ LM Studio │  │  BattlEye   │
   │  10.11  │   │    (x64)    │ │  client  │  │  (local)  │  │    RCon     │
   └─────────┘   └──────┬──────┘ └──────────┘  └───────────┘  └─────────────┘
     extDB3             │           AI + missions   triage only    UDP/CRC32
                        │           off main sim    never critical
        ┌───────────────┴───────────────┐
        │                               │
   ┌────▼─────────┐            ┌────────▼────────┐
   │ @ExileServer │            │  Exile.Tanoa    │
   │ server PBOs  │            │  mission PBO    │
   │ XCSV_ADDONS  │            │  XM8 apps       │
   └──────────────┘            └─────────────────┘
```

## 🚦 Operational status

The server is publicly listed as **`XCSV EXILE (In Development)`**. It runs, it
is played, and it is being actively built on. Treat everything here as a live
system rather than a finished product.

| | |
|---|---|
| Map | Tanoa (`Exile.Tanoa`) |
| Engine binary | `arma3server_x64.exe` with `-maxMem=12288` |
| Database | MariaDB 10.11 via extDB3 |
| Anti-cheat | BattlEye + infiSTAR |
| Headless client | live; A3XAI authorized and FuMS heartbeat on owner 4 |

## 🧭 Development direction

The next programme deliberately connects development method, operations tooling,
performance engineering and player experience rather than treating them as
separate projects.

### XCSV Gauntlet

Create one canonical, versioned development protocol for Claude Code, OpenCode,
Antigravity and development-local LLMs:

`TARGET LOCK -> RECON -> DECOMPOSE -> WORKERS -> ADVERSARIAL CRITICS -> INTEGRATION -> MEASUREMENT -> EVIDENCE -> VERDICT`

Gauntlet depth scales with risk. Workers may not self-certify. Confidence is not
proof. **EVIDENCED / INFERRED / UNKNOWN** remain separate. Deterministic checks
should migrate into executable assertions rather than relying on every AI to
remember prose perfectly.

### GUARD reliability before cosmetic polish

The primary invariant is:

> **Closing XCSV GUARD must never erase operational truth. Reopening it must reconstruct the same server state from authoritative sources and continue supervising it.**

Planned work includes startup reconciliation, process reattachment, persistent
absolute restart deadlines, RCon auto-reconnect, explicit backend health,
per-tab contracts, tab test harnesses, GUARD self-diagnostics, graceful backend
recovery, and only then a grouped/task-oriented shell redesign.

GUARD state will be classified as **durable**, **reconstructable**, or
**ephemeral** so old live values are never mistaken for current truth.

### GUARD as evidence/experiment instrument

Planned extensions include local historical telemetry, explicit operating
phases, before/after experiment support, subsystem performance budgets,
structured DB/operator objects, Incident Mode, a Tanoa operations map,
estate-wide artifact identity and deterministic documentation/state-drift checks.

### Curated player systems

The existing addon estate is already large. Prioritize integration and
progression over indiscriminate addon accumulation: Territory Manager,
contracts/jobs, bounties, meaningful faction-standing integration, Chronicle,
asynchronous community tools, choreographed events and selective objective
systems such as capture points. Keep Zombies/Vcom parked until measured HC/server
headroom supports reconsideration.

Full design: **[XCSV GUARD Development Plan](wiki/XCSV-GUARD-Development-Plan.md)**.

## ⚠️ Five things that are easy to get catastrophically wrong

Each of these cost real hours. They are encoded as automated checks or durable
rules so they cannot cost them twice.

1. **A PBO with a leading `\` on every entry path still passes a checksum verify.** Read the entry table.
2. **extDB2 was 32-bit only.** Production is x64 + extDB3; do not restore the old x86 path as a fallback.
3. **`-filePatching` is mandatory** for the current A3XAI configuration path.
4. **Arma's server simulation is heavily constrained by main-thread simulation/scheduled SQF.** More features must be measured, not assumed free.
5. **`extDB2 is already setup & locked` / `Unknown Protocol` can be symptoms of a restart loop rather than root causes.** Count mission starts and find the first causal error.

## 🧭 Where things are

| I want to… | go to |
|---|---|
| See the full current development programme | [XCSV GUARD Development Plan](wiki/XCSV-GUARD-Development-Plan.md) |
| See priority/order and completed work | [Roadmap](wiki/Roadmap.md) |
| Understand the architecture | [Docs → Architecture](https://x-cessive.github.io/XCSV/wiki/Architecture.html) |
| Diagnose a server that will not start | [Docs → Runbook](https://x-cessive.github.io/XCSV/wiki/Runbook.html) |
| Build an XM8 app | [Docs → XM8 Apps](https://x-cessive.github.io/XCSV/wiki/XM8-Apps.html) |
| Avoid a mistake already paid for | [Docs → Lessons](https://x-cessive.github.io/XCSV/wiki/Lessons.html) |
| Read about the operations console | [XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD) |
| Read about our own addons | [XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS) |
| Find a third-party addon or script | [Exile](https://github.com/x-cessive/Exile) |
| Pack or unpack a PBO | [`Exile/tools/pbo`](https://github.com/x-cessive/Exile/tree/master/tools) |

## 📥 Cloning

Submodules point at private repositories. Clone with `--recurse-submodules` if
you have access; without it you get the hub, the site and the wiki.

```bash
git clone --recurse-submodules https://github.com/x-cessive/XCSV.git
cd XCSV
git submodule update --remote --merge
```

## ✍️ Working on the documentation

`wiki/` is the Git-tracked wiki source. Site copies under `docs/wiki/` are generated.

```powershell
.\tools\build-docs.ps1
.\tools\push-wiki.ps1
```

Never hand-edit generated `docs/wiki/` as the authoritative source.

The desktop/Obsidian `ARMA3_EXILE_CODEX\ROADMAP.md` remains the authoritative
full working roadmap. The 2026-08-07 GitHub planning update intentionally notes
that Architect will manually reconcile the desktop documentation later.

## 🔒 What is deliberately not here

No RCon password, Telegram bot token, database credentials, infiSTAR key or
player data. Credentials live in gitignored configuration and are protected at
rest. If a secret appears here, that is a defect.

## ⚖️ Licensing

Exile Mod is **CC BY-NC-ND 4.0**. XCSV_ADDONS contains independent code rather
than modified Exile source. Where behavior must change, use sanctioned override
mechanisms and preserve licensing boundaries. `CfgExileCustomCode` has one
winning registration per function, so competing overrides must be merged rather
than silently replacing one another.

Our own code is personal tooling for one server, offered as-is, with no warranty
of any kind.

---

<div align="center">
<sub>XCSV EXILE · built in the open · <a href="https://x-cessive.github.io/XCSV/">x-cessive.github.io/XCSV</a></sub>
</div>
