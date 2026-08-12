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

- Runtime spawn validated on live deploys. Initial deploy spawned two courier
  scenes and the presentation follow-up spawned two scenes with four map
  markers.
- Player grinder completion on the spawned safe is pending in-game test.
- Trader support follow-up: `Exile_Magazine_Battery` is now priced and listed
  in the Tools trader category next to `Exile_Item_Grinder`, so players can buy
  both items required by the safe `Grind Lock` condition.

## Follow-up Validation

- Presentation fix commit: Exile `4524770`, XCSV_ADDONS `c9a0a38`, hub
  `04d4015`.
- Battery trader fix commit: Exile `3413517`.
- Live `xcsv_chatter.pbo` presentation deploy backed up
  `E:\arma3server\@ExileServer\addons\xcsv_chatter.pbo.20260811-2118.COURIERVISUALS.bak`,
  verified checksum OK with 15 entries and prefix `xcsv_chatter`, and unpacked
  live scan confirmed marker, surface-aligned safe, and dead-body animation
  fixes.
- Fresh RPT `E:\arma3server\profiles\arma3server_x64_2026-08-11_21-10-29.rpt`
  showed two courier scenes spawned at `[5917.33,10605.3,0]` and
  `[5540.07,9909.48,0]`, final line:
  `[XCSV_SCENE] courier scene spawn complete: 2 scene(s), 12 object(s), 4 marker(s).`
- Live mission battery deploy backed up
  `E:\arma3server\mpmissions\Exile.Tanoa.pbo.20260811-2126.BATTERYTOOLS.bak`,
  verified checksum OK with 360 entries and prefix `Exile.Tanoa`, and unpacked
  live scan confirmed `Exile_Magazine_Battery` in `CfgExileArsenal` and
  `class Tools`.
- Final doctor after the battery deploy returned 26 passed, 1 warned, 0 failed;
  the only warning remains the known infiSTAR cloud 403.
