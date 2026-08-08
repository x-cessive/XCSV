---
layout: wiki
section: docs
title: Architecture
heading: Architecture
blurb: Processes, threading, content layers, and the override seam.
order: 6
source: Architecture.md
---

## Processes

| process | bitness | why it exists |
|---|---|---|
| `arma3server_x64.exe` | x64 | the game server, migrated to extDB3 on 2026-08-05 |
| `mysqld` (MariaDB 10.11) | x64 | player, territory and vehicle persistence |
| `arma3_x64.exe -client -connect` | x64 | headless client - moves AI and missions off the server thread |
| `XCSV_GUARD.exe` | x64 | operations console; supervises everything above |
| LM Studio server | x64 | local model, log triage only |

### Database bridge

extDB2 was 32-bit only and caused the 2026-08-01 x64 failure. Production now uses
extDB3 with `@ExileServer\extDB3_x64.dll`, `@ExileServer\extdb3-conf.ini`, and
`@ExileServer\sql_custom\exile.ini`. The server launcher sets `-maxMem=12288`
as the explicit 12 GB x64 memory target.

## Threading — the fact that shapes every design decision

Arma's server simulation runs on **one thread**. `-cpuCount` and `-exThreads`
affect file, texture and geometry loading only. SQF `spawn` does not create a
thread; every scheduled script in every addon shares roughly **3 ms per frame**
on that single thread.

Consequences, all of which are load-bearing:

- More cores do not raise server FPS. A **headless client** does, because it is a
  separate process with its own thread.
- A private `while {true} do {sleep n}` loop in an addon does not get its own
  slice — it takes one from everything else. Use
  `ExileServer_system_thread_addTask`.
- Object count is the dominant FPS lever, because simulation is per-frame and
  serialised.

## Content layers

```
@ExileServer/addons/        server-side PBOs. Clients never receive these.
  exile_server.pbo            Exile's own core
  xcsv_chatter.pbo            ours — faction radio
  a3xai / dms / occupation    third-party AI and missions

mpmissions/Exile.Tanoa.pbo  the mission. Clients DO download this.
  config.cpp                  CfgXM8 app registrations, CfgExileCustomCode
  initPlayerLocal.sqf         client bootstrap
  xcsv/                       ours — trader voice, welcome, census, admin TP
```

That split is the reason trader dialogue and the welcome briefing are **not** in
the server PBO: anything that draws per-player UI has to ship in the mission,
because the mission is what clients actually receive.

## `CfgExileCustomCode` — the sanctioned override seam

Exile's own PBOs ship unmodified. Where behaviour needs changing, the function
is re-pointed at one of ours. This is what keeps us clean under
CC BY-NC-ND 4.0 and it is how the entire third-party ecosystem works.

**Exactly one registration per function wins.** If two addons want the same
function they must be merged by hand. A lost merge is why `Exile_Scavenge` was
silently dead on this server for weeks — three addons wanted
`ExileClient_object_player_initialize`, two made it into the merge and Scavenge
did not.

## The local model, and where it is not

XCSV GUARD can call a local model (LM Studio) to classify and explain logs.
Hard boundaries, by design:

- It has **no tools** and takes **no actions**. It returns text.
- Its output is **untrusted data**, never a decision and never load-bearing.
- Request bodies are written to a temp file, so no prompt content is ever
  interpolated into a command line.
- **Players cannot reach it.** In-world chatter is static text tables written
  offline and reviewed by a human. There is nothing running for a player to
  influence.
- The stack starts and stops fine without it.

## Anti-cheat

**BattlEye** has selected enforcement live: 4 of 51 script rules are enforcing.
The rest remain staged/log-only until their exceptions are triaged.

**infiSTAR** logs locally and works; its cloud reporting has returned 403 from
the very first log line and never once succeeded.

Anything we write that creates, deletes or moves objects touches these filters.
Text- and UI-only addons need no exception, which is why they are preferred.

## Related

- [Runbook](Runbook.html) · [Repositories](Repositories.html) · [Lessons](Lessons.html)
