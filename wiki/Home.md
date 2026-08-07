# XCSV EXILE

A dedicated **Arma 3 Exile** server on Tanoa, and every piece of software that
keeps it alive.

This wiki is the operator's manual. The [site](https://x-cessive.github.io/XCSV/)
is the shop window; the [hub repo](https://github.com/x-cessive/XCSV) is the map.

> **2026-08-07 planning sync:** the GitHub wiki now includes the current XCSV
> Gauntlet, GUARD reliability/UX, server-optimization and curated player-system
> programme. The desktop/Obsidian roadmap remains authoritative and will be
> reconciled manually by Architect.

## Start here

| page | when you need it |
|---|---|
| **[Architecture](Architecture)** | understanding what talks to what |
| **[Runbook](Runbook)** | the server is broken and you need it fixed now |
| **[Repositories](Repositories)** | where a given file lives and why |
| **[XM8 Apps](XM8-Apps)** | building anything player- or admin-facing |
| **[Roadmap](Roadmap)** | deciding what to work on next |
| **[XCSV GUARD Development Plan](XCSV-GUARD-Development-Plan)** | Gauntlet, GUARD reliability/UX, telemetry, optimization and player-system direction |
| **[Memory](Memory)** | finding what is true without rediscovery |
| **[Lessons](Lessons)** | before repeating a mistake someone already paid for |

## The console

![XCSV GUARD](https://x-cessive.github.io/XCSV/assets/shots/tour.gif)

More at [the project page](https://x-cessive.github.io/XCSV/guard/).

## The one-paragraph version

`arma3server_x64.exe` loads Exile 1.0.4a and the
`Exile.Tanoa` mission, talks to MariaDB through extDB3, and is policed by
BattlEye and infiSTAR. **XCSV GUARD**, a Rust console, supervises all of it:
it refuses to start the server if any PBO fails an integrity check, speaks
BattlEye RCon over UDP, watches log growth, reconstructs mission/AI state,
provides read-only database views, performs incident capture, and brings the
whole stack up or down through controlled operator actions. Our own content lives
in **XCSV_ADDONS** and never contains a line of Exile source.

The next GUARD refoundation focuses on restart-safe supervision, startup
reconciliation, backend contracts for every tab, self-diagnostics, historical
evidence/experiments and a more coherent task-oriented UI. The governing
principle is that GUARD should be able to prove the server's state again every
time GUARD starts rather than relying on process-local memory.

## Non-negotiables

- **64-bit server binary with extDB3.** Do not restore extDB2 or the old x86 launcher.
- **`-filePatching` on.** Without it A3XAI ends the mission during world init.
- **No Exile source in our repositories.** Override via `CfgExileCustomCode`.
- **Runtime local model is non-load-bearing and has no tools/actions.** Player-controlled/log data remains untrusted input.
- **No secrets in git.** Credentials sit in gitignored config, DPAPI-protected.
- **Verification before assertion.** Separate EVIDENCED / INFERRED / UNKNOWN and preserve refuted hypotheses.
