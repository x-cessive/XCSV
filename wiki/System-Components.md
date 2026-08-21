# System Components

This page is generated from `registry/components.json` by `tools/build-component-inventory.ps1` for XCSV-REFACTOR-INV-001 / issue #30.

> Catalogue/source presence is not proof of live deployment. Runtime, deployment, boot and player evidence remain `UNKNOWN` unless explicitly recorded.

## Inventory State

- Registry classification: `PARTIAL_SOURCE_VERIFIED`
- Component entries: 328
- Source-wired concrete wiring evidence: 35
- Packed artifact evidence: 0
- Deployed evidence: 0
- Boot evidence: 0
- Player runtime evidence: 0

### By Repository

| Repository | Count |
| --- | ---: |
| `x-cessive/Exile` | 221 |
| `x-cessive/XCSV` | 27 |
| `x-cessive/XCSV_ADDONS` | 13 |
| `x-cessive/XCSV_GUARD` | 53 |
| `x-cessive/XCSV_ORCH` | 14 |

### By Kind

| Kind | Count |
| --- | ---: |
| `ADDON` | 56 |
| `DATABASE` | 83 |
| `MISSION_MODULE` | 38 |
| `OTHER` | 25 |
| `SCRIPT` | 29 |
| `SERVER_ADDON` | 3 |
| `TOOL` | 94 |

### By Working Verdict

| Verdict | Count |
| --- | ---: |
| `CONSOLIDATE_DUPLICATE` | 1 |
| `KEEP_VENDOR_REFERENCE` | 64 |
| `REFACTOR_ACTIVE` | 155 |
| `UNKNOWN` | 108 |

## Duplicate / Overlap Matrix Draft

| Surface | Evidence | Working verdict | Next lane |
| --- | --- | --- | --- |
| Scratchie residue | `catalogue/LiveSource/mpmissions/Exile.Tanoa/Scratchie` exists and `config.cpp` still contains Scratchie app/comment material; no live runtime verified. | `REFACTOR_ACTIVE` source-residue audit required | #30/#31 then gameplay lanes only after evidence |
| MarketByCyunide residue | `catalogue/LiveSource/mpmissions/Exile.Tanoa/MarketByCyunide` exists and player-market network messages remain in `config.cpp`; no live runtime verified. | `REFACTOR_ACTIVE` source-residue audit required | #30/#31 |
| Multiple revive implementations | `catalogue/Addons/ExileRevive`, `catalogue/Scripts/Enigma_Exile_Revive`, and `ReviveRequest` in current `config.cpp` all exist. | `CONSOLIDATE_DUPLICATE` candidate, no deletion authority | #34/#35 after authority decision |
| AI engines | A3XAI, DMS, Occupation, FuMS, VcomAI, Sarge and VEMF catalogue entries exist; GUARD source references A3XAI/FuMS as operational concerns. | `KEEP_VENDOR_REFERENCE` or `UNKNOWN` until live process/mod evidence | #35 |
| Vehicle lifecycle | AVS, VPS, persistent vehicles, claim, salvage, crash loot, paint, virtual garage and drones are all present across catalogue/LiveSource/XCSV_ADDONS. | `REFACTOR_ACTIVE` / `CONSOLIDATE_DUPLICATE` high risk | #34 |
| XCSV_ADDONS mirrors | `addons/mission/xcsv` and `catalogue/LiveSource/mpmissions/Exile.Tanoa/xcsv` both exist; `xcsv_chatter` exists in XCSV_ADDONS and LiveSource server-addons. | `CONSOLIDATE_DUPLICATE` custody decision required | #33 |

## Override Registry Draft

| Exile function | Replacement path |
| --- | --- |
| `ExileClient_action_execute` | `customcode\client\ExileClient_action_execute.sqf` |
| `ExileClient_construction_handleAbort` | `custom\Build_Limits\ExileClient_construction_handleAbort.sqf` |
| `ExileClient_construction_threads` | `custom\Build_Limits\ExileClient_construction_threads.sqf` |
| `ExileClient_gui_hud_event_onKeyDown` | `custom\ExileClient_gui_hud_event_onKeyDown.sqf` |
| `ExileClient_gui_hud_event_onKeyUp` | `custom\ExileClient_gui_hud_event_onKeyUp.sqf` |
| `ExileClient_gui_hud_renderGroupPanel` | `custom\ExileClient_gui_hud_renderGroupPanel.sqf` |
| `ExileClient_gui_selectSpawnLocation_event_onListBoxSelectionChanged` | `xs\spawn\Overwrites\ExileClient_gui_selectSpawnLocation_event_onListBoxSelectionChanged.sqf` |
| `ExileClient_gui_selectSpawnLocation_event_onSpawnButtonClick` | `xs\spawn\Overwrites\ExileClient_gui_selectSpawnLocation_event_onSpawnButtonClick.sqf` |
| `ExileClient_gui_selectSpawnLocation_show` | `xs\spawn\Overwrites\ExileClient_gui_selectSpawnLocation_show.sqf` |
| `ExileClient_gui_selectSpawnLocation_zoomToMarker` | `xs\spawn\Overwrites\ExileClient_gui_selectSpawnLocation_zoomToMarker.sqf` |
| `ExileClient_gui_xm8_slide_apps_onOpen` | `custom\ExileClient_gui_xm8_slide_apps_onOpen.sqf` |
| `ExileClient_gui_xm8_slide_extraApps_onClose` | `custom\ExileClient_gui_xm8_slide_extraApps_onClose.sqf` |
| `ExileClient_gui_xm8_slide_extraApps_onOpen` | `custom\ExileClient_gui_xm8_slide_extraApps_onOpen.sqf` |
| `ExileClient_object_container_pack` | `custom\VehicleCrashLoot\ExileClient_object_container_pack.sqf` |
| `ExileClient_object_item_construct` | `custom\Build_Limits\ExileClient_object_item_construct.sqf` |
| `ExileClient_object_player_event_hook` | `custom\ExileClient_object_player_event_hook.sqf` |
| `ExileClient_object_player_initialize` | `custom\ExileClient_object_player_initialize.sqf` |
| `ExileClient_object_player_safezone_checkSafezone` | `custom\ExileClient_object_player_safezone_checkSafezone.sqf` |
| `ExileClient_object_player_stats_reset` | `custom\ExileClient_object_player_stats_reset.sqf` |
| `ExileClient_object_player_stats_update` | `custom\ExileClient_object_player_stats_update.sqf` |
| `ExileClient_util_fusRoDah` | `myaddon\myfunction.sqf` |
| `ExileServer_object_container_packContainer` | `custom\VehicleCrashLoot\ExileServer_object_container_packContainer.sqf` |
| `ExileServer_object_player_createBambi` | `xs\spawn\Overwrites\ExileServer_object_player_createBambi.sqf` |
| `ExileServer_object_player_database_load` | `custom\VPS\ExileServer_object_player_database_load.sqf` |
| `ExileServer_object_vehicle_createNonPersistentVehicle` | `customcode\server\ExileServer_object_vehicle_createNonPersistentVehicle.sqf` |
| `ExileServer_object_vehicle_createPersistentVehicle` | `customcode\server\ExileServer_object_vehicle_createPersistentVehicle.sqf` |
| `ExileServer_object_vehicle_database_load` | `custom\VPS\ExileServer_object_vehicle_database_load.sqf` |
| `ExileServer_object_vehicle_database_update` | `custom\VPS\ExileServer_object_vehicle_database_update.sqf` |
| `ExileServer_system_database_connect` | `custom\StatusBar\ExileServer_system_database_connect.sqf` |
| `ExileServer_system_garbageCollector_deleteObject` | `ClaimVehicles_Client\custom\ExileServer_system_garbageCollector_deleteObject.sqf` |

## Network Message Registry Draft

| Message | Module |
| --- | --- |
| `depositItemRequest` | `system_safex` |
| `depositItemResponse` | `system_safex` |
| `hasSafeXRequest` | `system_safex` |
| `hasSafeXResponse` | `system_safex` |
| `updateMarXetResponse` | `system_safex` |
| `withdrawItemRequest` | `system_safex` |
| `withdrawItemResponse` | `system_safex` |
| `withdrawVehicleRequest` | `system_safex` |
| `withdrawVehicleResponse` | `system_safex` |
| `xcsvInspectRequest` | `system_xcsv` |
| `xcsvInspectResponse` | `system_xcsv` |
| `xcsvOwnerRequest` | `system_xcsv` |
| `xcsvOwnerResponse` | `system_xcsv` |
| `xcsvPolicyBuyRequest` | `system_xcsv` |
| `xcsvTeleportRequest` | `system_xcsv` |

## Init / Scheduler Map Draft

| Source | Evidence |
| --- | --- |
| mission init | `init.sqf`, `initPlayerLocal.sqf`, `initServer.sqf` exist in current LiveSource and contain execVM/preprocess/bootstrap wiring. |
| xcsv_chatter | `config.cpp` defines preInit/postInit and `bootstrap/fn_postInit.sqf` registers Exile server thread tasks. |
| XCSV mission modules | `fn_droneControl.sqf` registers an Exile client thread; several UI modules spawn scheduled client work. |
| GUARD | Rust modules include stack/server/db/rcon/live/metrics/docs/ai and UI tabs; runtime state not reverified in this lane. |
| ORCH | `x-cessive/XCSV_ORCH@8cb52165912fd2dcd2890397c351b477ee63c2ce observed at 2026-08-21T03:17:45Z`; ORCH paths are repository-relative when an explicit verified source is supplied. |

## Prioritized Refactor Queue Draft

1. Vehicle lifecycle and persistence overrides: AVS/VPS/persistent vehicles/claim/salvage/crash loot/paint/garage/drone overlap.
2. `CfgExileCustomCode` override registry hardening and duplicate-collision tests.
3. `CfgNetworkMessages` handler resolution and XCSV_ADDONS/LiveSource network custody.
4. XCSV_ADDONS to LiveSource mirror ownership and drift testing, especially `xcsv_chatter`.
5. Scratchie and MarketByCyunide residue classification without deleting source.
6. AI engine runtime authority split: A3XAI/DMS/Occupation/FuMS/VcomAI/Sarge/VEMF.
7. Init/event/scheduler ownership map and duplicate scheduler guardrails.
8. DB/extDB query group custody and BattlEye filter exception mapping.

## Remaining UNKNOWN Areas

- Live server deployment, loaded mods/servermods, packed PBO hashes, boot logs, live DB schema, live BattlEye filters and player-runtime behavior were not inspected.
- `REMOVE_CANDIDATE` is not used as deletion authority in this tranche.
- Issue #31 should use this registry as evidence input but should not claim global modernization completion.

## Component Registry

| Component | Family | Kind | Repo | Path | Evidence | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `EXILE-ADDON-A3-EXILE-OCCUPATION-DEVELOPMENT` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/a3_exile_occupation-development` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-A3-VEMF-RELOADED` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/a3_vemf_reloaded` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-A3-VEMF-RE-RELOADED` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/A3_vemf_re-reloaded` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-A3XAI` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/A3XAI` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-CHANGING-RYAN-S-ZOMBIES-DEMONS-MOD-SOUNDS-FOR-DUMMIES` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Changing Ryan's Zombies & Demons Mod Sounds for dummies` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-CLAIMCRATES` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ClaimCrates` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-CLAIM-VEHICLES` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Claim-Vehicles` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-DMS-EXILE` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/DMS_Exile` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILEREBORN-REBORN-ZOMBIES` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-FUMS-HC-EXILE` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/FuMS-HC-Exile` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-HALVPAINTSHOP-EXILE` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/HalvPaintshop-Exile` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-SARGE-AI` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Sarge-AI` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-VCOMAI-3-0-3-3-2` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/VcomAI-3.0-3.3.2` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-VCOMAI-3-0-DEVELOP` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/VcomAI-3.0-develop` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-ZCP-A3-EXILE` | AI / missions / HC | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ZCP-A3-Exile` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-LIVE-MISSION-CLAIMVEHICLES-CLIENT` | AI / missions / HC | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/ClaimVehicles_Client` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-EXILE-ANTI-FLOATING-BUG-SCRIPT-AKA-STAIR-BUG` | AI / missions / HC | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile-Anti-Floating-bug-script-aka-stair-bug` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-EXILEMOD-ADVANCED-REPAIR` | AI / missions / HC | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/ExileMod-Advanced-Repair` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILEMOD-SUPER-ADVANCED-REPAIR-SYSTEM-SARS` | AI / missions / HC | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exilemod-Super-Advanced-Repair-System-SARS` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-A3-EXILE-SCRATCHIE` | Economy / traders / storage | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/a3-exile-scratchie` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILEBARTERTRADER` | Economy / traders / storage | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileBarterTrader` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILEBOUNTYSYSTEM` | Economy / traders / storage | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileBountySystem` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILELOADOUTS` | Economy / traders / storage | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileLoadouts` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-EXILESAFEX` | Economy / traders / storage | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileSafeX` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-EXILETRAVELLINGTRADER` | Economy / traders / storage | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileTravellingTrader` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-PLAYERMARKETBYCYUNIDE` | Economy / traders / storage | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/PlayerMarketByCyunide` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-LIVE-MISSION-MARKETBYCYUNIDE` | Economy / traders / storage | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/MarketByCyunide` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-SCRATCHIE` | Economy / traders / storage | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/Scratchie` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-EXILEBOUNTYSYSTEM` | Economy / traders / storage | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/ExileBountySystem` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-TRADER-MOD` | Economy / traders / storage | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Trader-Mod` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `XCSV-ADDONS-MISSION-FN-BOUNTYBOARD-SQF` | Economy / traders / storage | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_bountyBoard.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-TRADERVOICE-SQF` | Economy / traders / storage | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_traderVoice.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-AI-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/ai.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-ACTIONS-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/actions.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-MOD-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/mod.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-PACING-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/pacing.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-STATE-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/state.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-SUPERVISOR-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/supervisor.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-AI-TAB-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/ai_tab.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-CONSOLES-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/consoles.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-DATABASE-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/database.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-DOCS-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/docs.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-INFISTAR-TAB-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/infistar_tab.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-INTEGRITY-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/integrity.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-METRICS-TAB-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/metrics_tab.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-MOD-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/mod.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-OVERVIEW-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/overview.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-PLAYERS-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/players.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-RCON-TAB-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/rcon_tab.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-RESTARTS-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/restarts.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-SERVERLOG-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/serverlog.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-UI-SETTINGS-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/ui/settings.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-APP-WORKER-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/app/worker.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-CONFIG-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/config.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-CONFIG-STORE-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/config_store.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-CONSOLE-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/console.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-DB-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/db.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-DOCS-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/docs.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-INFISTAR-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/infistar.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-LIVE-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/live.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-MAIN-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/main.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-METRICS-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/metrics.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-MISSION-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/mission.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-NOTIFY-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/notify.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-PBO-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/pbo.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-RAG-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/rag.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-RCON-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/rcon.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-SECRETS-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/secrets.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-SERVER-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/server.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-STACK-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/stack.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-STATE-MODEL-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/state_model.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-STEAMBUILD-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/steambuild.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-SRC-GUARD-SRC-THEME-RS` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/src/theme.rs` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-CAPTURE-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/capture.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-DEPLOY-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/deploy.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-DEPRECATED-CONVERT-EXILE-INI-SH` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/deprecated/convert_exile_ini.sh` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-DEPRECATED-EXTDB2-TO-EXTDB3-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/deprecated/extdb2_to_extdb3.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-DEPRECATED-PATCH-PBO-EXTDB3-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/deprecated/patch_pbo_extdb3.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-DEPRECATED-README-MD` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/deprecated/README.md` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-DOCTOR-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/doctor.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-MAKE-ICON-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/make_icon.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-SOURCE-GATE-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/source-gate.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-TASKBAR-PIN-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/taskbar-pin.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-TELEGRAM-CAPTURE-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/telegram-capture.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-GUARD-TOOL-GUARD-TOOLS-TESTS-SOURCE-GATE-TESTS-PS1` | GUARD / operations | `TOOL` | `x-cessive/XCSV_GUARD` | `guard/tools/tests/source-gate.tests.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-AI-COMMIT-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/ai-commit.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-AI-DESKTOP-CAPTURE-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/ai-desktop-capture.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-AI-RECONCILE-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/ai-reconcile.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-BACKUP-INFISTAR-LOGS-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/backup-infistar-logs.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-BUILD-COMPONENT-INVENTORY-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/build-component-inventory.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-BUILD-DOCS-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/build-docs.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-BUILD-MEMORY-INDEX-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/build-memory-index.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-BUILD-RAG-INDEX-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/build-rag-index.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-CHECK-TEXT-SAFETY-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/check-text-safety.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-CURRENT-STATE-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/current-state.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-FPS-REPORT-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/fps-report.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-FPS-WATCH-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/fps-watch.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-PBO-DRIFT-AUDIT-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/pbo-drift-audit.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-PUSH-WIKI-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/push-wiki.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-RCON-PROBE-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/rcon-probe.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-ROTATE-RCON-PASSWORD-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/rotate-rcon-password.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-SEARCH-RAG-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/search-rag.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-SYNC-ALL-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/sync-all.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-SYNC-POLICY-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/sync-policy.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-TESTS-COMPONENT-INVENTORY-PROVENANCE-TESTS-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/tests/component-inventory-provenance.tests.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-TESTS-COMPONENT-INVENTORY-TESTS-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/tests/component-inventory.tests.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-TESTS-CONTINUITY-STATE-TESTS-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/tests/continuity-state.tests.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-TESTS-CURRENT-STATE-TESTS-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/tests/current-state.tests.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-TESTS-SYNC-POLICY-TESTS-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/tests/sync-policy.tests.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-XCSV-COLDPATHS-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/xcsv-coldpaths.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-XCSV-CONTINUITY-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/xcsv-continuity.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-HUB-TOOL-TOOLS-XCSV-WIRING-AUDIT-PS1` | Hub build/sync/audit tooling | `TOOL` | `x-cessive/XCSV` | `tools/xcsv-wiring-audit.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-A3-EXILE-LOOTBOX` | Loot / survival / events | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/a3_exile_lootbox` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-BIGFOOTS-SHIPWRECKS` | Loot / survival / events | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/bigfoots-shipwrecks` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILE-LOOT-COMPILER-JS` | Loot / survival / events | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/exile-loot-compiler-js` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXTENDED-SURVIVAL-PACK-MOD` | Loot / survival / events | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Extended Survival Pack (Mod)` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-FARMING-SCRIPTS-FOR-EXTENDED-SURVIVAL-PACK-MOD` | Loot / survival / events | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Farming-scripts-for-Extended-Survival-Pack-Mod` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-TRICK-OR-TREAT` | Loot / survival / events | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Trick-Or-Treat` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-ALIAS-ANOMALY-CREATURES` | Loot / survival / events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Alias-Anomaly-Creatures` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-BLOWOUT` | Loot / survival / events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Blowout` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-EXILE-PLANTS` | Loot / survival / events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile-Plants` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-OBJECTS-SERVER-SIDE` | Map / Eden / static objects | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Objects-Server-Side` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-R3F-LOGISTICS` | Map / Eden / static objects | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/R3F Logistics` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-MISSION-SQM` | Map / Eden / static objects | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/mission.sqm` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-R3F-LOG` | Map / Eden / static objects | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/R3F_LOG` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-PRISONGRAYBOX-SQF` | Map / Eden / static objects | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_prisonGraybox.sqf` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-SRC-SRC-XCSV-CONTROLLER-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `src/xcsv-controller.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-SRC-SRC-XCSV-GAUNTLET-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `src/xcsv-gauntlet.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-SRC-SRC-XCSV-HERMES-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `src/xcsv-hermes.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-SRC-SRC-XCSV-INTEGRITY-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `src/xcsv-integrity.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-SRC-SRC-XCSV-WORKERS-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `src/xcsv-workers.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TEST-TESTS-XCSV-FAILURE-TESTS-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tests/xcsv-failure-tests.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TEST-TESTS-XCSV-GAUNTLET-RUN-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tests/xcsv-gauntlet-run.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TEST-TESTS-XCSV-GAUNTLET-V2-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tests/xcsv-gauntlet-v2.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TEST-TESTS-XCSV-GAUNTLET-V3-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tests/xcsv-gauntlet-v3.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TEST-TESTS-XCSV-INTEGRITY-TESTS-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tests/xcsv-integrity-tests.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TEST-TESTS-XCSV-REGRESSION-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tests/xcsv-regression.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TOOL-TOOLS-DEPLOY-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tools/deploy.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TOOL-TOOLS-RELEASE-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tools/release.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ORCH-TOOL-TOOLS-SECRET-SCAN-PS1` | ORCH / AI workforce | `TOOL` | `x-cessive/XCSV_ORCH` | `tools/secret-scan.ps1` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-EXILEINCOMINGMISSILE` | QoL / player events | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileIncomingMissile` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-FISHING-SCRIPT-FOR-EXTENDED-SURVIVAL-PACK-MOD` | QoL / player events | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/fishing-script-for-Extended-Survival-Pack-Mod` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-A3WARNINGSCRIPT` | QoL / player events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/A3WarningScript` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILE-AUTO-RELOAD-MELEE-WEAPONS` | QoL / player events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile_auto_Reload_melee_weapons` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILEMOD-HOLSTERPLUS` | QoL / player events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/ExileMod-HolsterPlus` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILEMOD-STOPMOANING` | QoL / player events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/ExileMod-StopMoaning` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILE-SAFEZONE-MARKERS` | QoL / player events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile-Safezone-Markers` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILE-SCAVENGE` | QoL / player events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile_Scavenge` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-FISHINGBOAT` | QoL / player events | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/FishingBoat` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-LIVE-MISSION-CONFIG-CPP` | Server addons / network / database | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/config.cpp` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-INITSERVER-SQF` | Server addons / network / database | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/initServer.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-SERVERADDON-EXILE-SERVER-CONFIG` | Server addons / network / database | `SERVER_ADDON` | `x-cessive/Exile` | `catalogue/LiveSource/server-addons/exile_server_config` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-SERVERADDON-XCSV-CHATTER` | Server addons / network / database | `SERVER_ADDON` | `x-cessive/Exile` | `catalogue/LiveSource/server-addons/xcsv_chatter` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-SERVER-XCSV-CHATTER` | Server addons / network / database | `SERVER_ADDON` | `x-cessive/XCSV_ADDONS` | `addons/xcsv_chatter` | CATALOGUE_PRESENT, SOURCE_WIRED | `CONSOLIDATE_DUPLICATE` |
| `XCSV-BE-CATALOGUE-ADDONS-AVS-BATTLEYE-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/AVS/BattlEye.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXAD-BATTLEYE-REMOTEEXEC-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExAd/BattlEye/remoteexec.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXAD-BATTLEYE-SCRIPTS-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExAd/BattlEye/scripts.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILE-ABANDON-TERRITORY-BATTLEYE-DELETEVEHICLE-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/Exile_Abandon_Territory/Battleye/deleteVehicle.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILE-ABANDON-TERRITORY-BATTLEYE-PUBLICVARIABLE-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/Exile_Abandon_Territory/Battleye/publicvariable.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-ATTACHTO-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/attachTo.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-BANS-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/bans.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-CREATEVEHICLE-LOG` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/createvehicle.log` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-CREATEVEHICLE-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/createVehicle.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-DELETEVEHICLE-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/deleteVehicle.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-HIDEOBJECT-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/hideObject.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-MPEVENTHANDLER-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/mpeventhandler.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-REMOTECONTROL-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/remotecontrol.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-REMOTEEXEC-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/remoteexec.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-SCRIPTS-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/scripts.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-SELECTPLAYER-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/selectPlayer.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-SETDAMAGE-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/setDamage.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-SETPOS-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/setpos.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-SETVARIABLE-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/setVariable.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-TEAMSWITCH-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/teamswitch.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-WAYPOINTCONDITION-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/waypointcondition.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-BATTLEYE-WAYPOINTSTATEMENT-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/battleye/waypointstatement.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-ADDONS-R3F-LOGISTICS-BATTLEEYE-SCRIPTS-TXT` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/Addons/R3F Logistics/BattleEye/scripts.txt` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-TOOLS-BATTLEYE-BE-AUTOFILTER-PS1` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/tools/battleye/be-autofilter.ps1` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-BE-CATALOGUE-TOOLS-BATTLEYE-BE-EXCEPTION-PS1` | Server addons / network / database | `OTHER` | `x-cessive/Exile` | `catalogue/tools/battleye/be-exception.ps1` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-A3-EXILE-SCRATCHIE-MYSQL-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/a3-exile-scratchie/mysql/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-A3-EXILE-SCRATCHIE-MYSQL-SCRATCHIE-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/a3-exile-scratchie/mysql/scratchie.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-A3EXILEVPS-EXILESERVER-OBJECT-PLAYER-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/A3ExileVPS/ExileServer_object_player_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-A3EXILEVPS-EXILESERVER-OBJECT-VEHICLE-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/A3ExileVPS/ExileServer_object_vehicle_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-A3EXILEVPS-EXILESERVER-OBJECT-VEHICLE-DATABASE-UPDATE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/A3ExileVPS/ExileServer_object_vehicle_database_update.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-ARMA-3-EXILE-VIRTUAL-GARAGE-DATABASE-STUFF-SQLUPDATE-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/Arma-3-Exile-Virtual-Garage/Database Stuff/SQLUpdate.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-ARMA-3-EXILE-VIRTUAL-GARAGE-DATABASE-STUFF-VIRTUALGARAGE-EXTDB2-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/Arma-3-Exile-Virtual-Garage/Database Stuff/VirtualGarage_extDB2.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-ARMA-3-EXILE-VIRTUAL-GARAGE-DATABASE-STUFF-VIRTUALGARAGE-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/Arma-3-Exile-Virtual-Garage/Database Stuff/VirtualGarage.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-ARMA-3-EXILE-VIRTUAL-GARAGE-EXILESERVER-EXTDB-SQL-CUSTOM-V2-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/Arma-3-Exile-Virtual-Garage/@ExileServer/extDB/sql_custom_v2/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-AVS-EXILESERVER-ADDONS-AVS-HOOKS-AVS-SYSTEM-DATABASE-CONNECT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/AVS/@ExileServer/addons/AVS/hooks/AVS_system_database_connect.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-AVS-EXILESERVER-EXTDB-SQL-CUSTOM-V2-AVS-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/AVS/@ExileServer/extDB/sql_custom_v2/avs.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXAD-EXILESERVER-EXTDB-SQL-CUSTOM-64-BIT-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExAd/@ExileServer/extDB/sql_custom (64-bit)/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXAD-EXILESERVER-EXTDB-SQL-CUSTOM-V2-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExAd/@ExileServer/extDB/sql_custom_v2/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEBARTERTRADER-SERVER-BARTER-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileBarterTrader/Server/barter.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEBARTERTRADER-SERVER-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileBarterTrader/Server/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEBASEMOVER-SERVER-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileBaseMover/Server/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEFLAGHACKING-SERVER-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileFlagHacking/Server/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEPERSISTENTVEHICLES-VIEWREADMEFIRST-EXILE-ALTIS-CUSTOMCODE-SERVER-EXILESERVER-OBJECT-VEHICLE-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExilePersistentVehicles/ViewReadMeFirst/Exile.Altis/customcode/server/ExileServer_object_vehicle_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEPUBLICVIRTUALGARAGE-SERVER-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExilePublicVirtualGarage/Server/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEPUBLICVIRTUALGARAGE-SERVER-PUBLICVG-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExilePublicVirtualGarage/Server/publicVG.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONSTRUCTION-DATABASE-DELETE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_construction_database_delete.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONSTRUCTION-DATABASE-INSERT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_construction_database_insert.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONSTRUCTION-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_construction_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONSTRUCTION-DATABASE-LOCKUPDATE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_construction_database_lockUpdate.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONTAINER-DATABASE-DELETE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_container_database_delete.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONTAINER-DATABASE-INSERT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_container_database_insert.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONTAINER-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_container_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONTAINER-DATABASE-SETPIN-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_container_database_setPin.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-CONTAINER-DATABASE-UPDATE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_container_database_update.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-PLAYER-DATABASE-INSERT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_player_database_insert.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-PLAYER-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_player_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-PLAYER-DATABASE-UPDATE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_player_database_update.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-VEHICLE-DATABASE-DELETE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_vehicle_database_delete.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-VEHICLE-DATABASE-INSERT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_vehicle_database_insert.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-VEHICLE-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_vehicle_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-VEHICLE-DATABASE-RESETCODE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_vehicle_database_resetCode.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-OBJECT-VEHICLE-DATABASE-UPDATE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_object_vehicle_database_update.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-CLAN-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_clan_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-DATABASE-CONNECT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_database_connect.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-DATABASE-HANDLEBIG-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_database_handleBig.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-DATABASE-QUERY-FIREANDFORGET-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_database_query_fireAndForget.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-DATABASE-QUERY-INSERTSINGLE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_database_query_insertSingle.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-DATABASE-QUERY-SELECTFULL-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_database_query_selectFull.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-DATABASE-QUERY-SELECTSINGLEFIELD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_database_query_selectSingleField.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-DATABASE-QUERY-SELECTSINGLE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_database_query_selectSingle.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-TERRITORY-DATABASE-INSERT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_territory_database_insert.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-EXILESERVER-ADDONS-EXILE-SERVER-CODE-EXILESERVER-SYSTEM-TERRITORY-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/@ExileServer/addons/exile_server/code/ExileServer_system_territory_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-MPMISSIONS-CORE-CLIENT-FILES-EXADCLIENT-STATSBAR-CUSTOMCODE-EXILESERVER-SYSTEM-TERRITORY-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/mpmissions/Core_client_files/ExAdClient/StatsBar/CustomCode/ExileServer_system_territory_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEREBORN-REBORN-ZOMBIES-MPMISSIONS-CORE-CLIENT-FILES-EXADCLIENT-VIRTUALGARAGE-CUSTOMCODE-EXILESERVER-SYSTEM-TERRITORY-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileReborn-Reborn_Zombies/mpmissions/Core_client_files/ExAdClient/VirtualGarage/CustomCode/ExileServer_system_territory_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILESAFEX-SERVER-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileSafeX/Server/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILESAFEX-SERVER-SAFEX-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileSafeX/Server/safex.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILE-TREE-STAY-DOWN-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/exile-tree-stay-down/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILE-TREE-STAY-DOWN-QUERY-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/exile-tree-stay-down/query.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEVEHICLECUSTOMSMODS-CLIENT-CUSTOMCODE-SERVER-EXILESERVER-OBJECT-VEHICLE-DATABASE-INSERT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileVehicleCustomsMods/Client/customcode/server/ExileServer_object_vehicle_database_insert.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEVEHICLECUSTOMSMODS-CLIENT-CUSTOMCODE-SERVER-EXILESERVER-OBJECT-VEHICLE-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileVehicleCustomsMods/Client/customcode/server/ExileServer_object_vehicle_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEVEHICLECUSTOMSMODS-EXILE-ALTIS-CUSTOMCODE-SERVER-EXILESERVER-OBJECT-VEHICLE-DATABASE-INSERT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileVehicleCustomsMods/Exile.Altis/customcode/server/ExileServer_object_vehicle_database_insert.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEVEHICLECUSTOMSMODS-EXILE-ALTIS-CUSTOMCODE-SERVER-EXILESERVER-OBJECT-VEHICLE-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileVehicleCustomsMods/Exile.Altis/customcode/server/ExileServer_object_vehicle_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEVEHICLECUSTOMSMODS-SERVER-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileVehicleCustomsMods/Server/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEVEHICLECUSTOMSMODS-SERVER-VEHICLECUSTOMS-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileVehicleCustomsMods/Server/VehicleCustoms.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEZ-MOD-DATABASE-EXTDB2-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileZ-Mod/database/extDB2/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEZ-MOD-DATABASE-EXTDB3-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileZ-Mod/database/extDB3/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-EXILEZ-MOD-DATABASE-ZOMBIEKILL-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/ExileZ-Mod/database/ZombieKill.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-MOSTWANTED-MOSTWANTED-CLIENT-OVERWRITES-EXILESERVER-OBJECT-PLAYER-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/MostWanted/MostWanted_Client/overwrites/ExileServer_object_player_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-MOSTWANTED-MOSTWANTED-EXTDB-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/MostWanted/MostWanted-extDB.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-MOSTWANTED-MOSTWANTED-SQL-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/MostWanted/MostWanted-SQL.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-PLAYERMARKETBYCYUNIDE-INSTALL-EXILE-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/PlayerMarketByCyunide/install/exile.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-PLAYERMARKETBYCYUNIDE-INSTALL-PLAYERMARKET-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/PlayerMarketByCyunide/install/playermarket.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-TRICK-OR-TREAT-RESET-KNOCKED-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/Trick-Or-Treat/RESET KNOCKED.SQL` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ADDONS-TRICK-OR-TREAT-TRICKORTREAT-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Addons/Trick-Or-Treat/TrickOrTreat.SQL` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-EXILELOOTDROP-SRC-EXILELOOTDROP-EXILELOOTDROP-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/ExileLootDrop/src/ExileLootDrop/ExileLootDrop.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-LIVESOURCE-MPMISSIONS-EXILE-TANOA-CUSTOM-STATUSBAR-EXILESERVER-SYSTEM-DATABASE-CONNECT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/custom/StatusBar/ExileServer_system_database_connect.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-LIVESOURCE-MPMISSIONS-EXILE-TANOA-CUSTOM-VPS-EXILESERVER-OBJECT-PLAYER-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/custom/VPS/ExileServer_object_player_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-LIVESOURCE-MPMISSIONS-EXILE-TANOA-CUSTOM-VPS-EXILESERVER-OBJECT-VEHICLE-DATABASE-LOAD-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/custom/VPS/ExileServer_object_vehicle_database_load.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-LIVESOURCE-MPMISSIONS-EXILE-TANOA-CUSTOM-VPS-EXILESERVER-OBJECT-VEHICLE-DATABASE-UPDATE-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/custom/VPS/ExileServer_object_vehicle_database_update.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-ORIGINAL-ADDONS-SOVRAN-ZEUS-SCHEMA-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/original-addons/sovran_zeus/schema.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-SCRIPTS-STATUSBAR-32-64BIT-MASTER-32BIT-EXILESERVER-SYSTEM-DATABASE-CONNECT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Scripts/Statusbar-32-64Bit-master/32bit!!!!!!!!!  ExileServer_system_database_connect.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-SCRIPTS-STATUSBAR-32-64BIT-MASTER-64BIT-EXILESERVER-SYSTEM-DATABASE-CONNECT-SQF` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Scripts/Statusbar-32-64Bit-master/64bit!!!!!!!!!  ExileServer_system_database_connect.sqf` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-SCRIPTS-W4-LOCKPICK-3-SQL-LOCKPICK-SQL` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/Scripts/w4_lockpick/3 - SQL/lockpick.sql` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-TOOLS-DATABASE-BACKUP-EXILE-DB-PS1` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/tools/database/backup-exile-db.ps1` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-TOOLS-DATABASE-TEST-EXTDB3-PERSISTENCE-PS1` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/tools/database/test-extdb3-persistence.ps1` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-TOOLS-EXTDB3-BUILD-EXTDB3-STAGE-PS1` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/tools/extdb3/build-extdb3-stage.ps1` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-TOOLS-EXTDB3-README-MD` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/tools/extdb3/README.md` | CATALOGUE_PRESENT | `UNKNOWN` |
| `XCSV-DB-CATALOGUE-TOOLS-EXTDB3-XCSV-BRIEFING-SQL-INI` | Server addons / network / database | `DATABASE` | `x-cessive/Exile` | `catalogue/tools/extdb3/xcsv-briefing-sql.ini` | CATALOGUE_PRESENT | `UNKNOWN` |
| `EXILE-ADDON-ABANDON-FLAG` | Territory / building / raiding | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Abandon Flag` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-ABANDON-FLAG-PBO` | Territory / building / raiding | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Abandon Flag.pbo` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-DMD-BUILDINGREPLACE` | Territory / building / raiding | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/DMD_BuildingReplace` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILE-ABANDON-TERRITORY` | Territory / building / raiding | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Exile_Abandon_Territory` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-EXILEBASEMOVER` | Territory / building / raiding | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileBaseMover` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILEBUILDCHECK` | Territory / building / raiding | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileBuildCheck` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-EXILEFLAGHACKING` | Territory / building / raiding | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileFlagHacking` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-BUILD-LIMITS` | Territory / building / raiding | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Build-Limits` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILE-BLOCK-FLOOR-PEEKING` | Territory / building / raiding | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile_Block_Floor_Peeking` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-W4-LOCKPICK` | Territory / building / raiding | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/w4_lockpick` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-0-GO-GET-INFISTAR` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/0. GO GET INFISTAR` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-A3EX-CMAT` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/A3EX_CMAT` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-BLCKEAGLES-REVISITED-RC` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/blckeagles-revisited-RC` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXAD` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExAd` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-EXILEREVIVE` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileRevive` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILE-TREE-STAY-DOWN` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/exile-tree-stay-down` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILEZ-MOD` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileZ-Mod` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-MOSTWANTED` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/MostWanted` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-PERSISTENT-TREE-CHOPPING-BY-FLYINGDUTCHMEN` | Unclassified inventory | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Persistent Tree Chopping by flyingdutchmen` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-LIVE-MISSION-ABANDON-SQF` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/abandon.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-ADDONS` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/addons` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-CUSTOM` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/custom` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-CUSTOMCODE` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/customcode` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-DESCRIPTION-EXT` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/description.ext` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-GADD-APPS` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/GADD_Apps` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-HC` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/HC` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-INITPLAYERLOCAL-SQF` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/initPlayerLocal.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-INIT-SQF` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/init.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-INTRO-SQF` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/intro.sqf` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-PBOPREFIX` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/$PBOPREFIX$` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-RSCDEFINES-HPP` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/RscDefines.hpp` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-STRINGTABLE-XML` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/stringtable.xml` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-TOOLS` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/tools` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-XCSV` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/xcsv` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-XS` | Unclassified inventory | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/xs` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-ENIGMA-EXILE-REVIVE` | Unclassified inventory | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Enigma_Exile_Revive` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXAD-HALOPARACHUTE-STANDALONE` | Unclassified inventory | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/ExAd-HaloParachute-Standalone` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-HELIPAD` | Unclassified inventory | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Helipad` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-A3EXILEVPS` | Vehicles | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/A3ExileVPS` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-ARMA-3-EXILE-VIRTUAL-GARAGE` | Vehicles | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Arma-3-Exile-Virtual-Garage` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-AVS` | Vehicles | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/AVS` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-ADDON-EXILEHELICRASHES` | Vehicles | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileHelicrashes` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILEPERSISTENTVEHICLES` | Vehicles | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExilePersistentVehicles` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILEPUBLICVIRTUALGARAGE` | Vehicles | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExilePublicVirtualGarage` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILE-VEHICLE-CRASH-LOOT` | Vehicles | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/Exile-Vehicle-Crash-Loot` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-ADDON-EXILEVEHICLECUSTOMSMODS` | Vehicles | `ADDON` | `x-cessive/Exile` | `catalogue/Addons/ExileVehicleCustomsMods` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-LIVE-MISSION-AVS` | Vehicles | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/AVS` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-EXILE-FIX-DRONE-UAV-STEALING` | Vehicles | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile-fix-drone-uav-stealing` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-VEHICLE-SALVAGE` | Vehicles | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Vehicle_Salvage` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `XCSV-ADDONS-MISSION-FN-DRONECONTROL-SQF` | Vehicles | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_droneControl.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-RSCINGAMEUI-HPP` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/RscInGameUI.hpp` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `EXILE-LIVE-MISSION-XM8-SERVER-INFO-HTML` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/Exile` | `catalogue/LiveSource/mpmissions/Exile.Tanoa/xm8_server_info.html` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-A3EXILEPILOTHUD` | XM8 / UI / HUD | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/A3ExilePilotHUD` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-EXILE-LARGE-NUMBERS-IN-XM8` | XM8 / UI / HUD | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile-large-numbers-in-Xm8` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILEMOD-CRUISEMODE` | XM8 / UI / HUD | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/ExileMod-CruiseMode` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-EXILE-VANILLA-HUD` | XM8 / UI / HUD | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Exile-Vanilla-Hud` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `EXILE-SCRIPT-STATUSBAR-32-64BIT-MASTER` | XM8 / UI / HUD | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/Statusbar-32-64Bit-master` | CATALOGUE_PRESENT | `KEEP_VENDOR_REFERENCE` |
| `EXILE-SCRIPT-XSSPAWN` | XM8 / UI / HUD | `SCRIPT` | `x-cessive/Exile` | `catalogue/Scripts/xsSpawn` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-ADMINTELEPORT-SQF` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_adminTeleport.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-CENSUS-SQF` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_census.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-FIELDNOTES-SQF` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_fieldNotes.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-OWNERTOOLS-SQF` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_ownerTools.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-SCOREBOARD-SQF` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_scoreboard.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-STANDING-SQF` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_standing.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-FN-WELCOME-SQF` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/fn_welcome.sqf` | CATALOGUE_PRESENT, SOURCE_WIRED | `REFACTOR_ACTIVE` |
| `XCSV-ADDONS-MISSION-UI` | XM8 / UI / HUD | `MISSION_MODULE` | `x-cessive/XCSV_ADDONS` | `addons/mission/xcsv/ui` | CATALOGUE_PRESENT | `REFACTOR_ACTIVE` |
