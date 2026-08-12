---
layout: wiki
section: docs
title: System Components
heading: System Components
blurb: Evidence-backed registry contract for addons, scripts, mods, live wiring and refactor status.
order: 15
source: System-Components.md
---

This page is the human-facing contract for the XCSV component registry.

Detailed inventory work is tracked by [XCSV-REFACTOR-INV-001](https://github.com/x-cessive/XCSV/issues/30) under the umbrella [XCSV-REFACTOR-001](https://github.com/x-cessive/XCSV/issues/29).

> **Catalogue presence is not proof of live deployment.** A component is not `LIVE` merely because it exists under `Exile/Addons`, `Exile/Scripts`, an old README, or a historical install receipt.

## Evidence ladder

Every addon, script, mod, mission module, server addon and major XCSV tool is classified using this ladder:

1. `CATALOGUE_PRESENT` — source/reference exists in Git.
2. `SOURCE_WIRED` — current mission/server source actually references it.
3. `PACKED_ARTIFACT_PRESENT` — a current PBO/artifact is accounted for.
4. `DEPLOYED_PRESENT` — the live test server contains/loads it.
5. `BOOT_EVIDENCE` — current RPT/extDB/GUARD evidence shows it initialized correctly.
6. `PLAYER_RUNTIME_EVIDENCE` — a player exercised the material behavior in game.

Higher levels do not get inferred from lower levels.

## Working verdicts

Each component receives one working refactor verdict:

- `KEEP_ACTIVE`
- `REFACTOR_ACTIVE`
- `CONSOLIDATE_DUPLICATE`
- `DISABLED_KEEP`
- `KEEP_VENDOR_REFERENCE`
- `ARCHIVE_CANDIDATE`
- `REMOVE_CANDIDATE`
- `UNKNOWN`

`REMOVE_CANDIDATE` is not deletion authority. Removal requires wiring, runtime, database, BattlEye, configuration and rollback evidence.

## Repository ownership

### XCSV

Hub, governance, documentation, receipts, audits, sync/build tooling and submodule pointers.

### Exile

Two deliberately different classes of content:

- third-party catalogue/reference material (`Addons`, `Scripts`, historical/reference/editor material), and
- current deployable custody under `LiveSource`.

The refactor program will make that separation impossible to confuse.

### XCSV_ADDONS

XCSV-authored game modules/addons. The refactor will establish one canonical source owner for each module and deterministic mirror/deployment rules where Exile LiveSource also carries a deploy copy.

### XCSV_GUARD

Native server control, supervision, RCon, observability and operator UI.

### XCSV_ORCH

Gauntlet/orchestration, worker policy, integrity and release/deploy automation.

## Component families

The registry groups components by behavior rather than by whichever folder they originally arrived in.

### AI / missions / HC

A3XAI, DMS, Occupation, FuMS, VcomAI, Sarge, VEMF, capture systems, zombie/anomaly AI, HC integration and XCSV scene/NPC logic.

### Vehicles

AVS, vehicle protection/persistence, claim systems, paint/customization, salvage, crash loot, virtual storage and drones/UGVs.

### Territory / building / raiding

Abandon territory, flag hacking, build limits/checks, lockpick, base-moving candidates and building exploit fixes.

### Economy / traders / storage

Trader configuration, XCSV price logic, Drone & Electronics, player market, Scratchie/lottery, travelling/barter traders, SafeX, loadouts and reward systems.

### XM8 / UI / HUD

XCSV XM8 apps, Drone Control, status bar, Pilot HUD, Vanilla HUD, spawn UI, number formatting and legacy application remnants.

### QoL / player events

Cruise, holster, audio fixes, melee reload, safe-zone markers, anti-floating, floor-peeking, missile warnings, scavenging and related event/key/thread handlers.

### Loot / survival / events

Helicopter crashes, shipwrecks, vehicle crash loot, lootboxes, seasonal events, Blowout, survival/farming and candidate zombie/anomaly systems.

### Map / Eden / static objects

`mission.sqm`, static-object code, server-side object candidates, 3DEN/editor tooling and [The Prison Project](https://github.com/x-cessive/XCSV/issues/28).

### Server addons / network / database

PBO source custody, PBO prefixes, `CfgNetworkMessages`, extDB queries, SQL migrations, BattlEye requirements and deployed hashes.

## Registry fields

The machine-readable registry produced by the inventory lane must capture at least:

```text
component_id
name
family
kind
repo
canonical_path
upstream_origin
license
ownership
status
runtime_authority
live_wiring
packed_artifact
startup_hook
custom-code hooks
network messages
XM8 registration
trader/economy hooks
DB schema/queries
BattlEye requirements
persistence impact
security/safe-zone impact
background loops/schedulers
performance risks
overlap/conflicts
tests/evidence
docs
refactor action
rollback
last verified
verdict
```

## Current status

The registry is **being established**. Until [#30](https://github.com/x-cessive/XCSV/issues/30) completes a current source/deployed/runtime reconciliation, historical `LIVE` labels remain useful evidence of past installation but are not automatically current-state truth.

The initial refactor sequence is:

1. inventory and wiring truth capture;
2. documentation/source ownership cleanup;
3. mission config/bootstrap/network modularization;
4. active component refactors by family;
5. archive/remove only proven dead paths;
6. final live/source/GitHub reconciliation.

See [Roadmap](Roadmap.html) for execution priority and [Architecture](Architecture.html) for system topology.