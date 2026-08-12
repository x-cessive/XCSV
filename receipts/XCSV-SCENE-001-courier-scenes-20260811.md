# XCSV-SCENE-001 - Courier Poptab Wreck Scenes

Issue: https://github.com/x-cessive/XCSV/issues/26

## Scope

First bounded server-authored world scene slice for player/content progression:
poptab courier vans, dead couriers with poptabs, and a locked safe that requires
the existing grinder path.

## Implementation

- `xcsv_chatter` now registers `class Scenes` and schedules
  `xcsv_chatter_fnc_courierScenes` once 120 seconds after startup.
- `scenes\fn_courierScenes.sqf` spawns two restart-local scenes per boot:
  `Land_Wreck_Van_F`, three dead courier units, one locked
  `Exile_Container_Safe_Small`, and smoke.
- Scene objects are tagged with `XCSV_SCENE` / `XCSV_SCENE_ID` and marked
  `ExileIsPersistent = false`; no database rows are created.
- Mission `class Safe` now exposes `Grind Lock` for locked safes when the player
  carries `Exile_Item_Grinder` and `Exile_Magazine_Battery`.

## Validation

- `Compare-Object` returned no differences between the Exile source and
  `E:\XCSV_ADDONS` mirror copies of `xcsv_chatter` config, bootstrap and scene
  files.
- `git diff --check` passed in `E:\ExileRepo` and `E:\XCSV_ADDONS`, with only
  Git LF-to-CRLF notices.
- Staging server PBO:
  `D:\CAGE\tmp\xcsv_chatter.courier-scenes.staging.pbo`
  - `pbo.ps1 Verify`: checksum OK, 15 entries, prefix `xcsv_chatter`
  - unpack scan confirmed `class Scenes`, `courierScenes`, `XCSV_SCENE`,
    `Land_Wreck_Van_F`, and `Exile_Container_Safe_Small`
- Staging mission PBO:
  `D:\CAGE\tmp\Exile.Tanoa.courier-scenes.staging.pbo`
  - `pbo.ps1 Verify`: checksum OK, 360 entries, prefix `Exile.Tanoa`
  - unpack scan confirmed `class Safe`, safe `class GrindLock`, and
    `CfgGrinding`

## Remaining Unknown

- Runtime spawn is pending live deployment and RPT validation.
- Player grinder completion on the spawned safe is pending in-game test.
