---
layout: wiki
section: docs
title: Roadmap
heading: Roadmap
blurb: Done, in flight, next, and deliberately parked.
order: 6
source: Roadmap.md
---

The authoritative, full-length roadmap is
`ARMA3_EXILE_CODEX\ROADMAP.md` in the Obsidian vault — it carries the reasoning,
the struck-through wrong turns and the measurements. This page is the summary
you can link to.

**Guiding rule: performance before content, always.** Adding content to a server
running at 22 FPS makes it worse, not better.

## Done

| phase | outcome |
|---|---|
| **0 — Stabilise** | 219-restart loop resolved (corrupt PBO entry paths); 419 MB RPT stopped (x64 + extDB2); credentials rotated across five locations; reboot survival |
| **1.5 — Lootbox deadlock** | `LB_WaitSysBusy` 40 → 15. Map population 66/103 → 103/103. **Server FPS 22 → 46.** The largest single win so far |
| **7.5 — Stack orchestration** | one button starts database → integrity gate → server → headless client → local model, and one stops them cleanly in reverse |
| **8 — Mistake prevention** | `CLAUDE.md` at each project root, `doctor.ps1` with 22 executable assertions, this wiki, the [Lessons](Lessons.html) page |

Also fixed along the way: the invisible safezone ring (160 errors → 0), a dead
`Exile_Scavenge` caused by a lost `CfgExileCustomCode` merge, four database query
defects, and a launcher landmine.

## In flight

**Headless client.** Moving A3XAI and missions off the single server thread is
the biggest remaining performance lever. Current state: the HC connects, BattlEye
verifies it, and the server never sends the mission. A packet capture showed 1107
packets server→HC, **all dropped**, and 0 packets HC→server. Next measurement is
a capture on the HC's outbound ephemeral port. Seven hypotheses have already been
falsified — see [Lessons](Lessons.html).

**Our own addons.** Faction radio chatter, speaking traders (16 types), a lore
briefing, an admin world census, and admin teleport are written and deployed.
In-game verification is outstanding.

## Next

| | |
|---|---|
| **Virtual Garage** | the *strategic* fix for world object count — vehicles stored out of the simulation rather than swept up by a cleanup script |
| **XM8 apps** | territory browser first (removes the most support burden), then a real scoreboard (establishes the `Rsc` slide pattern). Sixteen more catalogued in [XM8 Apps](XM8-Apps.html) |
| **BattlEye enforcement** | 51 rules at action 1, ~15,151 hits, ~2,367-item exception queue. Cannot be flipped until triaged — it would kick everyone including admins |
| **GUARD AI / mission tab** | only meaningful once missions run on the HC |

## Later

Player chat with the AI strictly isolated · lore and world voice · content
addons · a second headless client · CI on the repos · screenshots on the site.

## Deliberately parked

**extDB3 / 64-bit.** It buys memory headroom and longer restart windows. It does
**not** raise FPS. Revisit only once the headless client works and the 4 GB
ceiling is actually being pressed.

**Zombies, VcomAI.** Both are large simulation costs on a single-threaded server.
Not until the HC is carrying AI.

## Related

- [XM8 Apps](XM8-Apps.html) · [Architecture](Architecture.html) · [Lessons](Lessons.html)
