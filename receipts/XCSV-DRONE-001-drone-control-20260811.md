# XCSV-DRONE-001 - Drone Trader and XM8 Drone Control V1

Issue: https://github.com/x-cessive/XCSV/issues/27

## Scope

First bounded drone ecosystem slice for the Exile Tanoa live server. This
implements the enabled low-risk drone tier, a player-facing XM8 control surface,
and practical counter gear required by the counter-UAS addendum.

## Implementation

- Renamed the trader category to `DRONES & ELECTRONICS`.
- Enabled a conservative first sale tier:
  - `I_UavTerminal`
  - `I_UAV_01_backpack_F`
  - `launch_I_Titan_F`
  - `Titan_AA`
- Added XM8 App22 `Drone Control` with:
  - owned/nearby drone status rows
  - coarse RF detector using `ItemRadio` or a UAV terminal
  - native terminal open button
  - selected-drone connect and disconnect actions
- Added a client ownership guard that disconnects the player from a UAV whose
  `ExileOwnerUID` does not match the player's UID.
- Deferred armed drones, Stompers, DLC drones, static AA sale and Nyx AA sale
  until each has separate runtime and balance proof.

## Validation

- Exile source commit: `effae18` (`Add XCSV drone control V1`).
- XCSV_ADDONS mirror commit: `5e7d780` (`Mirror XCSV drone control client app`).
- `Compare-Object` returned no differences between the Exile mission
  `xcsv\fn_droneControl.sqf` and the XCSV_ADDONS mirror.
- `D:\XCSV\tools\xcsv-wiring-audit.ps1` returned 5 passed, 0 warned, 0 failed.
- Staging mission PBO
  `D:\CAGE\tmp\Exile.Tanoa.drone-v1.staging.pbo` verified checksum OK with
  361 entries and prefix `Exile.Tanoa`.
- Staging unpack scan confirmed `DRONES & ELECTRONICS`, `launch_I_Titan_F`,
  `Titan_AA`, `xcsvDrone`, `XM8_App22`, `XM8SlideXcsvDrone`, and
  `fn_droneControl`.
- Live mission backup:
  `E:\arma3server\mpmissions\Exile.Tanoa.pbo.20260811-2157.DRONEV1.bak`.
- Live mission PBO SHA256 changed from
  `098C2DD9C12CA5BD4C0296B9867DDB4A36D147C6AE3DE1D0C8DB2EE6664E7B93`
  to
  `40C746125B278505112CD8D3FE6AC9BB9425235F7ECAE02B5B1F5AA31D0D9E28`.
- Live mission PBO verified checksum OK with 361 entries and prefix
  `Exile.Tanoa`.
- Live unpack scan confirmed the drone trader items, App22 classes, RF detector
  text, and ownership guard.
- `D:\XCSV\tools\pbo-drift-audit.ps1 -Only Exile.Tanoa` reported
  `Exile.Tanoa.pbo ok [ours]` with 361 identical files.
- Final doctor returned 26 passed, 1 warned, 0 failed; the warning is the known
  infiSTAR cloud `403 Forbidden`.

## Remaining Unknown

- Player purchase, assembly, connection, flight and disassembly of the AR-2
  Darter are pending in-game test.
- `player action ["UAVTerminalOpen", player]` is present but not yet
  player-runtime-proven on this stack.
- Titan AA lock/damage/destruction against the enabled AR-2 tier is pending
  in-game test.
- Safe-zone no-grief behavior for drones is pending in-game test.
- The counter-UAS addendum is implemented for sale availability and bounded
  detector logic, but cannot be marked `PASS_RUNTIME_VERIFIED` until practical
  counterplay is tested by a connected player.
