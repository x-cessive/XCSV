# Architecture

## Processes

| process | bitness | why it exists |
|---|---|---|
| `arma3server.exe` | **x86** | the game server. x64 is forbidden — see below |
| `mysqld` (MariaDB 10.11) | x64 | player, territory and vehicle persistence |
| `arma3.exe -client -connect` | x64 | headless client — moves AI and missions off the server thread |
| `XCSV_GUARD.exe` | x64 | operations console; supervises everything above |
| LM Studio server | x64 | local model, log triage only |

### Why the server binary must be 32-bit

extDB2 ships as `extDB2.dll` only. There is no `extDB2_x64.dll`, there never
was, and no amount of configuration produces one. Launching
`arma3server_x64.exe` against it does not fail cleanly — it floods the RPT.
On 2026-08-01 that wrote **419 MB in under an hour** and forced a hard reboot.

The cost of x86 is a ~4 GB address ceiling that the server idles near 2 GB
against. That is the trade, and it is why restarts return memory and
`#shutdown` is used rather than `#restart` (the latter reloads the mission
inside the same process and never gives memory back).

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

**BattlEye** filters are currently **action 1 (log only)** across 51 rules with
~15,151 hits, essentially all legitimate mod activity. Flipping them on today
would kick everyone including admins. The triage queue is ~2,367 items.

**infiSTAR** logs locally and works; its cloud reporting has returned 403 from
the very first log line and never once succeeded.

Anything we write that creates, deletes or moves objects touches these filters.
Text- and UI-only addons need no exception, which is why they are preferred.

## Related

- [Runbook](Runbook) · [Repositories](Repositories) · [Lessons](Lessons)
