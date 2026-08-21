---
layout: wiki
section: docs
title: XM8 Apps
heading: XM8 Apps
blurb: How XM8 apps register, what is shipped, what is next.
order: 10
source: XM8-Apps.md
---

The XM8 is Exile's in-game phone and the sanctioned place to put
player-facing UI.

## How Registration Works

Apps are declared in the mission's `config.cpp` under `CfgXM8`, one
`XM8_AppNN_Button` class each:

```cpp
class XM8_App14_Button {
    idc = ...;
    text = "Admin TP";
    onButtonClick = "call XCSV_fnc_tpMenu";
    resource = ""; // "" == code-only, no slide
};
```

`resource = ""` gives a code-only app: the button simply calls a function. A
real slide needs an `Rsc` control tree. The slide pattern now exists, but every
new app still needs live XM8 exercise because keyboard focus, scrolling and
structured-text rendering cannot be proven from static source alone.

## Two Build Rules

1. Text and read-only UI cost nothing at BattlEye.
2. Anything that creates, deletes or moves an object touches `createVehicle`,
   `deleteVehicle` or `setpos`. Write narrow exceptions by hand and gate the app
   on an admin UID.

## Shipped

### App14 - Admin TP

Admin only. `xcsv/fn_adminTeleport.sqf`. Supports map-click teleport, teleport to
player, and teleport to named places. It moves `vehicle player`, not just the
unit, so vehicle occupants are not dropped out of moving vehicles.

Before raising `setpos.txt` enforcement, add one narrow BattlEye exception by
hand and watch infiSTAR's local logs on the first live use.

### App15 - Scoreboard

Player app. `xcsv/fn_scoreboard.sqf`, slide `XM8SlideXcsvScoreboard`, server
publisher `xcsv_chatter/scoreboard/fn_scoreboardPublish.sqf`. Read-only. The
client renders public `XCSV_Scoreboard`; opening the app does not query the
database.

### App16 - Field Notes

Player app. `xcsv/fn_fieldNotes.sqf`, slide `XM8SlideXcsvNotes`. Static
server-specific manual covering survival, medical, money/respect, territory
decay, building, vehicles/garage, safe zones, island context and faction
dossiers.

`FIELD-NOTES-001` added and live-deployed a `Fresh arrival` topic for the
configured 5-minute Bambi window. `FIELD-NOTES-003` folds the first
`Island intel / lore reader` slice into this same app as Warden Control, The
Yard and Salvage Net dossiers.

### App17 - Faction Standing

Player app. `xcsv/fn_standing.sqf`, slide `XM8SlideXcsvStanding`, server
publisher `xcsv_chatter/standing/fn_standingPublish.sqf`. Observational only:
standing does not yet gate prices, stock or progression.

### App18 - Trader Prices

Player app. `xcsv/fn_traderPrices.sqf`, slide `XM8SlideXcsvPrices`. Client-side
lookup built from mission config, so it tracks `CfgExileArsenal`, trader
categories and sell factor without a server call.

### App19 - Insurance / Dead Man's Switch

Player app. `xcsv/fn_policy.sqf`, slide `XM8SlideXcsvPolicy`,
`xcsv_chatter/network/fn_policyBuyRequest.sqf` and `fn_policyDeath.sqf`. This is
the first XCSV client-to-server write path. The dispatcher alias typo was
repaired in `XCSV-CHATTER-001`; first live purchase is still a real verification
item.

### App20 - Player Inspector

Admin only. `xcsv/fn_playerInspector.sqf`,
`xcsv_chatter/network/fn_inspectorRequest.sqf`, slide
`XM8SlideXcsvInspector`. Admin types a name fragment; the server resolves account
details and live territory flag membership, then answers as structured text to
the requesting admin session. Read-only, parameter-bound query.

### App21 - Bounty Board

Player app. `xcsv/fn_bountyBoard.sqf`, slide `XM8SlideXcsvBounty`. First slice
only: read-only contract-board surface that explains status, planned rules and
why payout posting is still locked. It does not call the server, reserve money,
mark targets, install death hooks or activate the unused bounty addons yet.

### App22 - Drone Control

Player app. `xcsv/fn_droneControl.sqf`, slide `XM8SlideXcsvDrone`. First slice
for `XCSV-DRONE-001`: native UAV status/convenience surface with coarse RF
detection, selected-drone connect/disconnect, and an ownership guard that refuses
connections to UAVs carrying another player's `ExileOwnerUID`.

The live trader category is `DRONES & ELECTRONICS`. V1 intentionally enables
only the AAF terminal, AR-2 Darter backpack, Titan AA launcher and Titan AA
missiles. Armed drones, Stompers, DLC UAVs, static AA and Nyx AA remain deferred
until balance and runtime counterplay are proven.

### Also Shipped, Not XM8

`XCSV: World census` is an admin scroll action that buckets and maps simulated
objects with `createMarkerLocal`, so markers exist only on the admin's machine.
It is an action rather than a keybind because infiSTAR strips unregistered key
handlers.

## Admin Backlog

1. Territory browser: every flag with owner, level, build rights and days until
   decay. Highest support value, but not useful to live-test until a territory
   exists.
2. Spectate / free-cam: check for collision with infiSTAR's camera first.
3. Object cleanup wand: delete the wreck/crate the census found. Requires a
   hand-written BattlEye exception.
4. Live server health: FPS, players, object count and memory in game.
5. Event trigger: force a helicrash, DMS mission or airdrop for testing.
6. Moderation: kick / ban with reason without opening RCon.
7. Ban / watchlist lookup.
8. Weather and time control.
9. Loot / vehicle spawner for testing only; highest BattlEye exposure here.

## Player Backlog

1. Bounty board: App21 read-only surface is staged; remaining delta is the
   server-owned contract ledger, escrow and trusted death-event payout path.
   `ExileBountySystem` and `MostWanted` are both present in the repo and must
   be audited before either is integrated.
2. Territory manager: pay protection, check decay, manage build rights without
   walking to the flag.
3. Virtual Garage remote: stored vehicles and where they are parked.
4. Job board: generated fetch/deliver tasks for solo direction.
5. Group / clan panel: members, online status, last seen, shared markers.
6. Island intel / lore reader: first faction-dossier slice lives in Field Notes;
   a separate app is deferred until there is dynamic intel to render.
7. Message board: asynchronous player-to-player notes.

## Order Of Work

```text
NOW      live-verify Insurance purchase and Field Notes render heartbeat
NEXT     territory browser / manager once a real territory exists
THEN     bounty board write path, job board, virtual garage remote, lore reader
LAST     anything that creates or deletes objects
```

## Related

- [Repositories](Repositories.html)
- [Roadmap](Roadmap.html)
- [Architecture](Architecture.html)
