---
layout: wiki
title: Overview
blurb: What XCSV EXILE is, and where to start.
order: 1
source: Home.md
---

A dedicated **Arma 3 Exile** server on Tanoa, and every piece of software that
keeps it alive.

This wiki is the operator's manual. The [site](https://x-cessive.github.io/XCSV/)
is the shop window; the [hub repo](https://github.com/x-cessive/XCSV) is the map.

## Start here

| page | when you need it |
|---|---|
| **[Architecture](Architecture.html)** | understanding what talks to what |
| **[Runbook](Runbook.html)** | the server is broken and you need it fixed now |
| **[Repositories](Repositories.html)** | where a given file lives and why |
| **[XM8 Apps](XM8-Apps.html)** | building anything player- or admin-facing |
| **[Roadmap](Roadmap.html)** | deciding what to work on next |
| **[Lessons](Lessons.html)** | before repeating a mistake someone already paid for |

## The one-paragraph version

`arma3server.exe` (**32-bit — this is not optional**) loads Exile 1.0.4a and the
`Exile.Tanoa` mission, talks to MariaDB through extDB2 v71, and is policed by
BattlEye and infiSTAR. **XCSV GUARD**, a Rust console, supervises all of it:
it refuses to start the server if any PBO fails an integrity check, speaks
BattlEye RCon over UDP, watches log growth, performs a crash autopsy, and brings
the whole stack up or down with one button. Our own content lives in
**XCSV_ADDONS** and never contains a line of Exile source.

## Non-negotiables

- **32-bit server binary.** extDB2 has no x64 build and never did.
- **`-filePatching` on.** Without it A3XAI ends the mission during world init.
- **No Exile source in our repositories.** Override via `CfgExileCustomCode`.
- **Nothing the players type ever reaches the language model.** The model reads
  logs, holds no tools, and takes no actions.
- **No secrets in git.** Credentials sit in gitignored config, DPAPI-protected.
