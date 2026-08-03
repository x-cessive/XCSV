---
layout: wiki
section: docs
title: XM8 Apps
heading: XM8 Apps
blurb: How XM8 apps register, what is shipped, what is next.
order: 5
source: XM8-Apps.md
---

The XM8 is Exile's in-game phone and the only sanctioned place to put
player-facing UI.

## How registration works

Apps are declared in the mission's `config.cpp` under `CfgXM8`, one
`XM8_AppNN_Button` class each:

```cpp
class XM8_App14_Button {
    idc         = ...;
    text        = "Admin TP";
    onButtonClick = "call XCSV_fnc_tpMenu";
    resource    = "";          // "" == code-only, no slide
};
```

`resource = ""` gives a **code-only** app: the button simply calls a function.
A real slide needs an `Rsc` control tree, which is a substantially larger build —
**the first one will take several times longer than every one after it**, because
the pattern only has to be established once.

## Two rules that decide what to build

1. **Text and UI cost nothing at BattlEye.** Read-only apps need no filter
   exception at all.
2. **Anything that creates, deletes or moves an object** touches
   `createVehicle` / `deleteVehicle` / `setpos`. Those filters are genuine cheat
   vectors. **Never** run the autofilter over them; write the one narrow
   exception by hand, and gate the app on an admin UID.

## Shipped

### App14 — Admin TP *(admin only)*

`mission/xcsv/fn_adminTeleport.sqf`. Three ways to move:

- **Map click** — arms the map for 45 s, then shift-click a destination. Time-boxed
  so a stray click a minute later does not fling you across the island.
- **To a player** — one scroll action per online player.
- **To a named place** — trader zones and towns, for testing the dialogue addons.

It moves `vehicle player`, not the player: teleporting someone out of a moving
vehicle leaves that vehicle driverless at speed.

> ⚠️ **Before enabling BattlEye enforcement.** This uses `setPosATL`, which trips
> `battleye\setpos.txt`. Every rule there is action `1` (log only) today, so it
> logs and nothing else. The moment those are raised, this kicks whoever uses it —
> including you. Add **one narrow exception by hand**. infiSTAR is the second
> gatekeeper: it carries its own anti-teleport detection and its cloud has never
> succeeded here, so its admin list may not be loading. Watch `log_data.log` the
> first time you teleport, and if it flags you, add the UID rather than weakening
> the detection.

### Also shipped, not XM8

`XCSV: World census` — an admin scroll action that buckets and maps every
simulated object, using `createMarkerLocal` so the markers exist only on the
admin's machine. Delivered as an action rather than a keybind because infiSTAR
strips unregistered key handlers.

## Admin backlog

Ordered by support burden removed.

1. **Territory browser** — every flag with owner, level, build rights and **days
   until decay**. Highest value in the list; the decay column alone answers the
   most common ticket there is. Read-only. Queries already exist in `exile.ini`.
2. **Player inspector** — UID, ping, poptabs, respect, loadout, territory
   membership, session history. Every other admin action starts here.
3. **Spectate / free-cam** — watch a suspect without being visible. Check for a
   collision with infiSTAR's own camera first.
4. **Object cleanup wand** — look at a wreck, delete it. The census finds them;
   this removes them. Needs a hand-written BE exception.
5. **Live server health** — FPS, players, object count, memory in-game, from
   infiSTAR's `meta_data.log`. Removes the alt-tab.
6. **Event trigger** — force a helicrash, DMS mission or airdrop on demand.
7. **Moderation** — kick / ban with reason, without opening RCon.
8. **Ban / watchlist lookup** — check a GUID against history before acting.
9. **Weather and time control** — screenshots, and testing night-only content.
10. **Loot / vehicle spawner** — testing only. Heaviest BE exposure here; last, or
    never.

## Player backlog

1. **Scoreboard** — *build this first.* `getAccountScore` and `getAccountStats`
   already exist as queries, and the server's own broadcast has been advertising
   a P-key scoreboard that was never actually installed.
2. **Bounty board** — poptabs on a head, claimed by killing them.
   `ExileBountySystem` is already in the repo, unused.
3. **Territory manager** — pay protection, check decay, manage build rights
   without walking to the flag.
4. **Trader price lookup** — search an item, see where it sells and for how much.
   Saves an enormous amount of walking on Tanoa.
5. **Virtual Garage remote** — stored vehicles and where they are parked.
6. **Job board** — generated fetch/deliver tasks. Gives solo players direction,
   which is what most of them quit for.
7. **Group / clan panel** — members, online status, last seen, shared markers.
8. **Field medical guide** — what actually treats what. Nothing in game explains
   Exile's medical model.
9. **Island intel / lore reader** — faction dossiers and backstory. The permanent
   home for the welcome briefing's content.
10. **Message board** — asynchronous notes. Most of this server's players will
    never be online at the same time.

## Order of work

```
FIRST    Territory browser (admin)   -- removes the most support burden
THEN     Scoreboard (player)         -- establishes the Rsc slide pattern
THEN     Player inspector, trader price lookup, lore reader
LATER    bounty board, job board, virtual garage remote
LAST     anything that creates or deletes objects
```

## Related

- [Repositories](Repositories.html) · [Roadmap](Roadmap.html) · [Architecture](Architecture.html)
