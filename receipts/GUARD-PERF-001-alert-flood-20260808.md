# GUARD-PERF-001 Alert Flood Receipt - 2026-08-08

Work item: GUARD-PERF-001 / GitHub issue #9

## Runtime Trigger

Architect reported continuous Telegram supervision-gap alerts from the live
test-server GUARD process. Observed repeated gap durations included roughly:

- 407s
- 39s
- 82s
- 63s
- 68s
- 74s
- 62s

The detector was not removed or suppressed. This receipt records a separate
notification-flood repair while the architectural defect remains open.

## Repair

Commit: `e2004c1d9c4f99894cec58ca8bea8c6fa453bc3a`

Changed files:

- `D:\XCSV_GUARD\src\app\pacing.rs`
- `D:\XCSV_GUARD\src\app\state.rs`
- `D:\XCSV_GUARD\src\app\supervisor.rs`
- `D:\XCSV_GUARD\src\state_model.rs`

Behavior:

- first stalled supervision gap in an incident sends one Telegram alert;
- repeated stalled polls inside the same incident are coalesced, not resent;
- coalesced state preserves gap count, largest observed gap, and total missed
  supervision seconds;
- after 120s of healthy supervision cadence, GUARD sends at most one recovery
  alert and resets suppression;
- a later distinct incident can alert again;
- the status bar and `supervision_stalls` counter still expose the underlying
  GUARD-PERF-001 failure.

The 120s recovery interval intentionally mirrors the existing relaunch grace:
shorter healthy windows are still inside the same likely catch-up incident.

## Tests

Command:

`cargo test --manifest-path D:\XCSV_GUARD\Cargo.toml`

Result:

- 230 passed
- 0 failed
- 3 ignored

New coverage includes:

- first gap alerts
- repeated gaps are suppressed and coalesced
- recovery behavior
- a later incident alerts again
- recovery prevents permanent suppression
- the new notification state is classified as ephemeral in the GUARD state
  registry

Deploy also reran the release test suite with the same result.

## Deployment

Command:

`D:\XCSV_GUARD\tools\deploy.ps1`

Result:

- deployed build: `guard-0.7.1+12`
- source state: `CLEAN`
- source commit: `e2004c1d9c4f`
- live exe: `C:\Users\Architect\Desktop\XCSV_GUARD.exe`
- live SHA256:
  `BE9B7B65F9F8017F6C834B7DDC00869BC250D3087AA7610A33B1D1C6426F57A8`
- deployed at: `2026-08-08T14:50:16`
- old live build archived:
  `D:\XCSV_GUARD\archive\XCSV_GUARD_v0.7.1.11_20260808-130907.exe`

Post-deploy process evidence:

- `XCSV_GUARD` PID 17460, started 2026-08-08 14:50:17
- `arma3server_x64` PID 7956 remained running

## Doctor

Command:

`D:\XCSV_GUARD\tools\doctor.ps1`

Result after deployment:

- 24 passed
- 2 warned
- 0 failed

Current warnings:

- `hc-join`: latest server RPT contains "No more slot to add connection".
  Classification: `UNRELATED_DEFECT`.
- `infistar-cloud`: 125 of last 200 infiSTAR lines are 403 Forbidden.
  Classification: `UNRELATED_DEFECT / PRE_EXISTING`.

Neither warning is caused by the notification flood repair.

## Verdict

`PASS_FLOOD_MITIGATED`

GUARD-PERF-001 remains open. Critical supervision still ultimately must move
off the egui/render callback and into a real supervision backplane/thread with
the UI reading a snapshot.

## GitHub State

Direct issue update was not attempted in this pass because the current known
GitHub credential state previously failed issue/project writes with:

`403 Resource not accessible by personal access token`

This remains `BLOCKED_PERMISSION` until Architect supplies or activates a token
with the required Issues/Projects permissions.
