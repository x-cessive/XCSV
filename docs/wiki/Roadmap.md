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
| **2.3 - FuMS on HC** | FuMS installed on the live server and HC; active first slice is `PlayerWatch` plus Tanoa `CommsAlpha` and `Help_Helo`. A3XAI and FuMS both hand off to HC owner 4; FuMS heartbeat started |
| **7.5 - Stack orchestration** | one button starts database -> integrity gate -> server -> headless client -> local model, and one stops them cleanly in reverse |
| **8 - Mistake prevention** | `CLAUDE.md` at each project root, `doctor.ps1` with 22 executable assertions, this wiki, the [Lessons](Lessons.html) page |

Also fixed along the way: the invisible safezone ring (160 errors -> 0), a dead
`Exile_Scavenge` caused by a lost `CfgExileCustomCode` merge, four database query
defects, and a launcher landmine.

## In flight

**Telegram destination.** XCSV GUARD has the XCSV bot token DPAPI-encrypted and outbound Telegram enabled, but the configured `telegram_chat_id` currently points to a private DM with `SOVRANOS2026`, not the intended XCSV notifications channel. To finish this safely, add `@xcsv_guard_bot` as an admin in the XCSV channel, post one message there, then capture the `channel`/`supergroup` chat id from `getUpdates`. Do not reuse SOVRAN notification paths.

**GUARD operator views.** The GUARD refactor is committed and running. Next useful tabs are AI/mission ownership and a read-only database console for territories, vehicles, players and economy state.

**FuMS follow-up.** The inherited `Georgetown` FuMS mission is disabled because its ported static mission file still has parser defects. Repair and validate it before re-enabling.

## Next

| | |
|---|---|
| **Telegram channel capture** | replace the current private DM target with the real XCSV notifications channel id |
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

## 2026-08-05 Notes

- FuMS active mission markers are expected; the red circle/X at Comms Alpha marks the active FuMS mission.
- Admin teleport was hotfixed to execute server-side through `xcsvTeleportRequest` instead of client-local `setPosATL`. Source is mirrored under `E:\ExileRepo\LiveSource\...`; live backups use timestamp `20260805-100625`.
- Scroll-wheel admin teleport was fixed after map-click TP proved healthy. The scroll addAction handlers now pass `[position, label]` into `XCSV_fnc_tpTo`, matching the map-click path. Live mission backup: `E:\arma3server\mpmissions\Exile.Tanoa.pbo.20260805-103536.pre-scroll-tp-fix.bak`.
- Admin teleport safety was tightened after rough named coordinates could land in water and one TP killed the admin. Named scroll targets now use verified mission marker/trader coordinates, and the server resolves requests through `BIS_fnc_findSafePos`, rejects unsafe water/off-map/no-ground destinations, zeroes velocity, and temporarily disables damage during placement. Live backups use timestamp `20260805-105842`.
- GUARD's FuMS "not seen" state was a parser bug, not a FuMS outage. Live FuMS logs show server init, script transfer to HC, and HC heartbeat slot 4; `D:\XCSV_GUARD\src\mission.rs` now recognizes the current FuMS log phrases.
- 64-bit server support is deferred to a full extDB3 migration. Current production remains 32-bit because extDB2 is 32-bit only. A non-live candidate builder exists at `E:\ExileRepo\tools\extdb3\build-extdb3-stage.ps1`; latest staged bundle `D:\CAGE\extdb3-stage\20260805-104957\bundle` passed static checks but has not been live-booted.
- Project memory rule tightened: every live change must update the Obsidian vault, Git-tracked source, and wiki source before completion.
