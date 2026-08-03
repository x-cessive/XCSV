<div align="center">

# XCSV

**A dedicated Arma 3 Exile server, and every piece of software that keeps it alive.**

[![Server](https://img.shields.io/badge/XCSV_EXILE-Tanoa-3D9CFF.svg?style=for-the-badge)](https://x-cessive.github.io/XCSV/)
[![Status](https://img.shields.io/badge/status-in_development-E8B339.svg?style=for-the-badge)](#operational-status)
[![Site](https://img.shields.io/badge/site-x--cessive.github.io%2FXCSV-3FC16A.svg?style=for-the-badge)](https://x-cessive.github.io/XCSV/)

[![Arma 3](https://img.shields.io/badge/Arma_3-2.20.152984-blue.svg?logo=steam&logoColor=white)](https://arma3.com/)
[![Exile Mod](https://img.shields.io/badge/Exile_Mod-1.0.4a_Pineapple-00b2cd.svg)](https://exile.majormittens.co.uk/)
[![MariaDB](https://img.shields.io/badge/Database-MariaDB_10.11-003545.svg?logo=mariadb&logoColor=white)](https://mariadb.org/)
[![extDB2](https://img.shields.io/badge/Driver-extDB2_v71_(x86)-00599c.svg)](https://github.com/x-cessive/Exile)
[![Rust](https://img.shields.io/badge/Console-Rust_+_egui-CE422B.svg?logo=rust&logoColor=white)](https://github.com/x-cessive/XCSV_GUARD)
[![SQF](https://img.shields.io/badge/Addons-SQF-ffb400.svg)](https://github.com/x-cessive/XCSV_ADDONS)

</div>

---

This repository is the **hub**. It holds no game code of its own — it holds the
map of the system, the documentation site, the wiki, and submodule pointers at
every repository that makes up XCSV EXILE.

If you are looking for something specific, start here.

## 🗺️ The system

| repo | what it is | visibility |
|---|---|---|
| **[XCSV](https://github.com/x-cessive/XCSV)** *(you are here)* | Hub. System map, [site](https://x-cessive.github.io/XCSV/), [documentation](https://x-cessive.github.io/XCSV/wiki/Home.html), submodules. | public |
| 🛡️ **[XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD)** | Operations console. Rust + egui. PBO integrity gate, BattlEye RCon, crash autopsy, live metrics, whole-stack start/stop. | private |
| 🧩 **[XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS)** | Our own addons and mission scripts. Written from scratch — contains no Exile source. | private |
| 📦 **[Exile](https://github.com/x-cessive/Exile)** | Catalogue of third-party addons and scripts, plus the custom PBO packer and BattlEye tooling. | public |

```
                         ┌──────────────────────────┐
                         │       XCSV GUARD         │  Rust console
                         │  integrity · RCon · AI   │  one button starts
                         │  metrics · restarts      │  and stops all of it
                         └────────────┬─────────────┘
                                      │ supervises
        ┌───────────────┬─────────────┼──────────────┬───────────────┐
        │               │             │              │               │
   ┌────▼────┐   ┌──────▼──────┐ ┌────▼─────┐  ┌─────▼─────┐  ┌──────▼──────┐
   │ MariaDB │◄──┤ arma3server │ │ Headless │  │ LM Studio │  │  BattlEye   │
   │  10.11  │   │    (x86)    │ │  client  │  │  (local)  │  │    RCon     │
   └─────────┘   └──────┬──────┘ └──────────┘  └───────────┘  └─────────────┘
     extDB2 v71         │           AI + missions   triage only    UDP/CRC32
                        │           off the main    never in the
        ┌───────────────┴───────────────┐   thread  critical path
        │                               │
   ┌────▼─────────┐            ┌────────▼────────┐
   │ @ExileServer │            │  Exile.Tanoa    │
   │ server PBOs  │            │  mission PBO    │
   │ XCSV_ADDONS  │            │  XCSV_ADDONS    │
   └──────────────┘            │  XM8 apps       │
                               └─────────────────┘
```

## 🚦 Operational status

The server is publicly listed as **`XCSV EXILE (In Development)`**. It runs, it
is played, and it is being actively built on. Treat everything here as a live
system rather than a finished product.

| | |
|---|---|
| Map | Tanoa (`Exile.Tanoa`) |
| Engine binary | `arma3server.exe` — **32-bit, required** (see below) |
| Database | MariaDB 10.11 via extDB2 v71 |
| Anti-cheat | BattlEye + infiSTAR |
| Headless client | connection unresolved — [see the docs](https://x-cessive.github.io/XCSV/wiki/Runbook.html) |

## ⚠️ Five things that are easy to get catastrophically wrong

Each of these cost real hours. They are encoded as automated checks in XCSV
GUARD so they cannot cost them twice.

1. **A PBO with a leading `\` on every entry path still passes a checksum
   verify.** Arma resolves `<prefix>` + `\path`, finds nothing, and the server
   core silently never loads — producing a restart loop whose visible symptoms
   are all *database* errors. This once produced **219 mission starts in eight
   minutes**. Verifying is not enough; you have to read the entry table.
2. **extDB2 is 32-bit only.** There is no `extDB2_x64.dll` and there never was.
   Pairing it with `arma3server_x64.exe` wrote a **419 MB RPT in under an hour**
   and forced a hard reboot.
3. **`-filePatching` is mandatory.** A3XAI reads its config as a loose file.
   Without the flag it silently ends the mission during world init and the
   server loops.
4. **Arma's server simulation is single-threaded.** `spawn` does not create a
   thread — every scheduled script shares roughly 3 ms per frame. More cores do
   not help. A headless client does.
5. **`extDB2 is already setup & locked` is a symptom, not a cause.** So is
   `Unknown Protocol`. Count `Starting mission:` instead; more than one means a
   restart loop and the first error is the only real one.

## 🧭 Where things are

| I want to… | go to |
|---|---|
| Understand the architecture | [Docs → Architecture](https://x-cessive.github.io/XCSV/wiki/Architecture.html) |
| Diagnose a server that will not start | [Docs → Runbook](https://x-cessive.github.io/XCSV/wiki/Runbook.html) |
| Build an XM8 app | [Docs → XM8 Apps](https://x-cessive.github.io/XCSV/wiki/XM8-Apps.html) |
| Avoid a mistake already paid for | [Docs → Lessons](https://x-cessive.github.io/XCSV/wiki/Lessons.html) |
| See what is being built next | [Docs → Roadmap](https://x-cessive.github.io/XCSV/wiki/Roadmap.html) |
| Read about the operations console | [XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD) |
| Read about our own addons | [XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS) |
| Find a third-party addon or script | [Exile](https://github.com/x-cessive/Exile) |
| Pack or unpack a PBO | [`Exile/tools/pbo`](https://github.com/x-cessive/Exile/tree/master/tools) |

## 📥 Cloning

Submodules point at private repositories. Clone with `--recurse-submodules` if
you have access; without it you get the hub, the site and the wiki, which is
most of what is useful anyway.

```bash
git clone --recurse-submodules https://github.com/x-cessive/XCSV.git
cd XCSV
git submodule update --remote --merge     # refresh pointers to each repo's tip
```

## 🔒 What is deliberately not here

No RCon password, no Telegram bot token, no database credentials, no infiSTAR
key, no player data. Credentials live in gitignored config beside their binaries
and are DPAPI-protected at rest. If you find any of the above in this repository,
that is a bug — open an issue.

## ⚖️ Licensing

Exile Mod is **CC BY-NC-ND 4.0**, which forbids distributing modified Exile. It
does not forbid writing independent addons that *call* Exile, which is what
everything in `XCSV_ADDONS` is. Where Exile's behaviour needs changing we
override the function through `CfgExileCustomCode`; Exile's own PBOs ship
unmodified. **No Exile source is ever pasted into our repositories.**

One consequence worth knowing: `CfgExileCustomCode` allows exactly **one**
registration per function. Two addons wanting the same one must be merged by
hand. A lost merge is why `Exile_Scavenge` was silently dead on this server for
weeks.

Our own code is personal tooling for one server, offered as-is, with no warranty
of any kind.

---

<div align="center">
<sub>XCSV EXILE · built in the open · <a href="https://x-cessive.github.io/XCSV/">x-cessive.github.io/XCSV</a></sub>
</div>
