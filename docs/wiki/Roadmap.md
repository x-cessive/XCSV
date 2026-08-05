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
`ARMA3_EXILE_CODEX\ROADMAP.md` in the Obsidian vault - it carries the reasoning,
the struck-through wrong turns and the measurements. This page is the summary
you can link to.

**Guiding rule: performance before content, always.** Adding content to a server
running at 22 FPS makes it worse, not better.

## Done

| phase | outcome |
|---|---|
| **0 - Stabilise** | 219-restart loop resolved (corrupt PBO entry paths); 419 MB RPT stopped (x64 + extDB2); credentials rotated across five locations; reboot survival |
| **1.5 - Lootbox deadlock** | `LB_WaitSysBusy` 40 -> 15. Map population 66/103 -> 103/103. **Server FPS 22 -> 46.** The largest single win so far |
| **7.5 - Stack orchestration** | one button starts database -> integrity gate -> server -> headless client -> local model, and one stops them cleanly in reverse |
| **8 - Mistake prevention** | `CLAUDE.md` at each project root, `doctor.ps1` with 22 executable assertions, this wiki, the [Lessons](Lessons.html) page |

Also fixed along the way: the invisible safezone ring (160 errors -> 0), a dead
`Exile_Scavenge` caused by a lost `CfgExileCustomCode` merge, four database query
defects, and a launcher landmine.

## In flight

**Telegram destination.** XCSV GUARD has the XCSV bot token DPAPI-encrypted and outbound Telegram enabled, but the configured `telegram_chat_id` currently points to a private DM with `SOVRANOS2026`, not the intended XCSV notifications channel. To finish this safely, add `@xcsv_guard_bot` as an admin in the XCSV channel, post one message there, then capture the `channel`/`supergroup` chat id from `getUpdates`. Do not reuse SOVRAN notification paths.

**FuMS missions on the headless client.** The HC connection and A3XAI handoff are solved; current work is wiring the mission framework onto the HC and proving ownership in the RPT/monitoring.

**GUARD operator views.** The GUARD refactor is committed and running. Next useful tabs are AI/mission ownership and a read-only database console for territories, vehicles, players and economy state.

## Next

| | |
|---|---|
| **Telegram channel capture** | replace the current private DM target with the real XCSV notifications channel id |
| **FuMS on HC** | run missions on the HC and prove which machine owns each AI group |
| **GUARD AI / mission tab** | live AI count by source, active missions, server-vs-HC ownership |
| **GUARD database console** | read-only territory, vehicle, player and economy views |
| **BattlEye enforcement** | 51 rules at action 1; triage exceptions before raising selected rules to action 7 |

## Later

Player chat with the AI strictly isolated; lore and world voice; content addons;
a second headless client; CI on the repos; screenshots on the site.

## Deliberately parked

**extDB3 / 64-bit.** It buys memory headroom and longer restart windows. It does
**not** raise FPS. Revisit only once the headless client works and the 4 GB
ceiling is actually being pressed.

**Zombies, VcomAI.** Both are large simulation costs on a single-threaded server.
Not until the HC is carrying AI.

## Related

- [XM8 Apps](XM8-Apps.html) - [Architecture](Architecture.html) - [Lessons](Lessons.html)