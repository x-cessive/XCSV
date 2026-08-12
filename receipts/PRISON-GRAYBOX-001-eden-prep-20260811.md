# PRISON-GRAYBOX-001 - Eden Prep / Site Selection Ready

Issue: https://github.com/x-cessive/XCSV/issues/28

## Architect Override

Architect authorized The Prison Project to begin before `XCSV-DRONE-001` reaches
runtime verification. `XCSV-DRONE-001` remains `PARTIAL_DEPLOYED`; issue #27 is
not complete and drone/counter-UAS runtime proof remains pending.

GitHub issue #28 comment `5261344590` records the priority override.

## Scope Completed

- Re-read issue #28 full body; there were no comments/addenda at start of work.
- Reconciled current mission source, `mission.sqm`, `initServer.sqf`,
  Objects-Server-Side/M3Editor context, and live PBO custody.
- Chose direct Eden-authored mission source as the graybox custody model.
- Deferred `Objects-Server-Side` until after a measurable graybox exists.
- Added source-controlled Eden prep docs and helper scripts in Exile commit
  `bc57779`.
- Added mission-local Eden helper copies and corrected the Eden debug-console
  command in Exile commit `5e86b4d`, so the loaded mission can run:
  `execVM "tools\eden\prison_site_candidates.sqf";`
- Architect selected site `A_NORTH_CENTRAL_COAST` (`[7140,11800,0]`, 520m x
  360m, heading 35) on 2026-08-12. Added parametrized graybox builder
  `tools/eden/prison_graybox_build.sqf` (plus mission-local copy) that places
  the full perimeter, towers, gatehouse/intake, cellblocks, max-sec/SHU,
  medical/workshop, armory/utilities and dock staging as ONE undoable history
  step in the `PRISON_*` layers. Every classname used in the builder was
  verified against the running-server classdump (`E:\ArmaTools\classes\ALL.txt`).
  The builder never saves `mission.sqm`.

## Source Locations

- Current mission source:
  `E:\ExileRepo\LiveSource\mpmissions\Exile.Tanoa`
- Canonical Eden mission candidate:
  `E:\ExileRepo\LiveSource\mpmissions\Exile.Tanoa\mission.sqm`
- Current static-object convention:
  `E:\ExileRepo\LiveSource\mpmissions\Exile.Tanoa\initServer.sqf`
- Eden helper docs:
  `E:\ExileRepo\docs\PRISON-GRAYBOX-001.md`
- Eden helper scripts:
  `E:\ExileRepo\tools\eden\prison_site_candidates.sqf`
  `E:\ExileRepo\tools\eden\prison_graybox_tools.sqf`
- Mission-local Eden helper copies:
  `E:\ExileRepo\LiveSource\mpmissions\Exile.Tanoa\tools\eden\prison_site_candidates.sqf`
  `E:\ExileRepo\LiveSource\mpmissions\Exile.Tanoa\tools\eden\prison_graybox_tools.sqf`

## Candidate Sites

These are inspection candidates only. Terrain slope and visual fit remain
`UNKNOWN` until Architect inspects them in Eden.

| id | anchor | approximate footprint | orientation |
|---|---:|---:|---:|
| `A_NORTH_CENTRAL_COAST` | `[7140,11800,0]` | 520m x 360m | 35 deg |
| `B_EAST_INLAND_APPROACH` | `[13300,10400,0]` | 560m x 380m | 315 deg |
| `C_WESTERN_COASTAL_EDGE` | `[4400,11850,0]` | 500m x 340m | 80 deg |

`prison_site_candidates.sqf` creates temporary 3DEN comments and footprint
markers in a `PRISON_SITE_CANDIDATES` layer as one undo history step.

## Validation Evidence

- ExileRepo was clean before the prep commit.
- `git diff --check` passed.
- Classname/reference scan found local precedent for `Land_Mil_WallBig_4m_F`,
  `Land_Cargo_HQ_V4_F`, `Sign_Arrow_Large_Yellow_F`, and `Lamps_base_F`.
- Official Bohemia 3DEN docs were checked for `add3DENLayer`,
  `collect3DENHistory`, `create3DENEntity`, `set3DENAttribute`, and
  `set3DENLayer`.
- `mission.sqm`, `initServer.sqf`, and live `Exile.Tanoa.pbo` hashes were
  unchanged after the prep commit:
  - `mission.sqm`:
    `11B504C4743EE648B6C0AEE7CF722828ECD7DE8B671600B9218D325B5C9B9105`
  - `initServer.sqf`:
    `15BA4963870E41986F7802C4E8B2A7406383CA31E70817BA6C32B4164D04F22B`
  - live `Exile.Tanoa.pbo`:
    `40C746125B278505112CD8D3FE6AC9BB9425235F7ECAE02B5B1F5AA31D0D9E28`
- No live server deploy or PBO mutation was performed.
- `mission.sqm`, `initServer.sqf`, and live `Exile.Tanoa.pbo` hashes remained
  unchanged after the mission-local helper checkpoint.

## Tooling Caveat

Orca was started and reported runtime ready, but orchestration RPCs returned
`runtime_unavailable`. The formal worker/critic Gauntlet could not be completed
with real Orca provenance in this checkpoint.

## Verdict

`READY_FOR_ARCHITECT_SITE_SELECTION`

Do not claim `PASS_GRAYBOX_VERIFIED`. Architect has not selected a site, no
permanent prison geometry has been built, and no visual graybox acceptance has
occurred.
