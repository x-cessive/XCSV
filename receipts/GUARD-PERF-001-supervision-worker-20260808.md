# GUARD-PERF-001 Supervision Worker Receipt - 2026-08-08

Work item: GUARD-PERF-001 / GitHub issue #9

## Repair

Commit: `0f8beae8a40ebf89ea438525ee1377d7977b4ffa`

Changed behavior:

- `eframe::App::update` no longer performs operational polling.
- A lifecycle-independent `xcsv-guard-supervisor` worker owns crash detection,
  relaunch, autostart, scheduled restart processing, RPT scanning, PBO scanning,
  infiSTAR tailing, metrics, mission intel and player join/leave alerts.
- The UI reads a snapshot from the worker.
- UI start/stop/restart/rescan/config operations enqueue worker commands instead
  of executing server actions on the GUI thread.
- Server starts use an async preflight and re-check for an existing
  `arma3server` immediately before spawning.
- Stale start completions are rejected by stack epoch.
- Delayed HC launch is worker tick-owned and epoch guarded.
- PBO scans outside the start preflight are async completions, not supervisor
  loop disk scans.

## Verification

Implementation tests:

- `cargo test --manifest-path D:\XCSV_GUARD\Cargo.toml`
- result: 242 passed, 0 failed, 3 ignored

Release build:

- `cargo build --manifest-path D:\XCSV_GUARD\Cargo.toml --release`
- result: passed

Mutation checks killed:

- egui update reverted to `self.poll()`
- UI stop command mutated to start command
- stale start completion epoch guard removed
- synchronous PBO scan reintroduced into the worker loop

Independent critic:

- model/provider: independent worker `019fe2d4-76e5-7d11-9c0b-30ed6feafbd9`
- verdict after fixes: `PASS`
- cleared: spawn-boundary process check, one-command loop, tick-owned HC delay,
  stale start completion epoch guard, async PBO scans, UI command/snapshot
  routing

## Deployment

Command:

`D:\XCSV_GUARD\tools\deploy.ps1`

Result:

- deployed build: `guard-0.7.1+13`
- source state: `CLEAN`
- source commit: `0f8beae8a40e`
- live exe: `C:\Users\Architect\Desktop\XCSV_GUARD.exe`
- live SHA256:
  `A0D474E9E003FF63257BA5AB69302C75BC94D36576F491E7F2B63B9963324557`
- deployed at: `2026-08-08T15:57:48`
- old live build archived:
  `D:\XCSV_GUARD\archive\XCSV_GUARD_v0.7.1.12_20260808-145009.exe`

## Runtime Evidence

Baseline after deploy:

- `XCSV_GUARD` PID 4404, started 2026-08-08 15:57:48
- `arma3server_x64` PID 7956, started 2026-08-08 14:13:47
- `arma3_x64` PID 26612, started 2026-08-08 11:20:39

GUARD minimized:

- Orca observed the GUARD window collapsed to 16x16 with empty title.
- GUARD stayed minimized for 300 seconds.
- GUARD CPU advanced from 256.59375 to 524.140625 during that minimized window.
- Server and HC/client processes remained single-instance and running.

Critical recovery test:

`BLOCKED_RUNTIME_STOP`

The server could not be driven into the required down state from this session:

- `Stop-Process -Id 7956 -Force` returned Access denied.
- BattlEye RCon login using GUARD config failed; comparison showed
  `xcsv_guard.json` RCon secret and active BattlEye RCon secret do not match.
- BattlEye RCon login using the active BattlEye config succeeded, but both
  `#shutdown` and `shutdown` left PID 7956 running.
- `WM_CLOSE` to the server console returned false.
- A temporary highest-privilege scheduled task attempt returned Access denied.

Because the old server PID never exited, GUARD's minimized relaunch path could
not be observed. Do not mark GUARD-PERF-001 closed from this receipt alone.

## Doctor

Command:

`D:\XCSV_GUARD\tools\doctor.ps1`

Result after deployment/runtime attempts:

- 24 passed
- 2 warned
- 0 failed

Warnings:

- `hc-join`: latest server RPT contains "No more slot to add connection".
- `infistar-cloud`: infiSTAR cloud upload still returns 403.

## Verdict

`PARTIAL_BLOCKED_RUNTIME_STOP`

The architecture repair is implemented, tested, mutation-tested, critic-reviewed
and deployed. The decisive PASS condition is still not verified because the
test harness could not stop the currently elevated/live server process while
GUARD was minimized.
