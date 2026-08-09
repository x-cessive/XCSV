# GUARD-PERF-001 build 16 minimized recovery receipt

Date: 2026-08-08

Verdict: PARTIAL

Runtime acceptance evidence:

- Deployed build: `guard-0.7.1+16`
- XCSV_GUARD commit: `6d50564827c77bfddd2a616c84ff6c8dbb557bf7`
- Deployed SHA256: `5F23A5CEF6585790B7E9FA4B23832723CBF217DD09AE9A98BBC232F2BFC2EDF5`
- Tests during deploy: `254 passed`, `0 failed`, `3 ignored`
- Diagnostic fail-closed commit: `79b21508b654bc8d0d101a8df7eae38e9211e84e`
- HC duplicate prevention commit: `6d50564827c77bfddd2a616c84ff6c8dbb557bf7`

Real minimized recovery:

- GUARD PID: `23548`
- GUARD minimized proof after recovery evidence: `IsMinimized=true` at `2026-08-08T20:17:56-04:00`
- Stopped real server PID: `37804`
- Stop report: `D:\CAGE\xcsv-runtime\guard-perf-001-build16-stop-37804.json`
- Stop result: `ok=true`, `refused=false`, reason `terminated requested managed server process via validated process handle`
- Replacement server PID: `41016`
- Replacement parent PID: `23548` (GUARD)
- UDP ports `2302`, `2303`, `2304`, `2306`: owned by `41016`
- HC PID after repair: `5788`
- HC parent PID: `23548` (GUARD)
- Duplicate HC check: exactly one `arma3_x64.exe` with `-name=XCSV_HC`

Recovery logs:

- Server RPT: `E:\arma3server\profiles\arma3server_x64_2026-08-08_20-10-32.rpt`
- Mission marker: `Starting mission` at `20:10:53`
- extDB marker: `ExileServer - Connected to database!` at `20:11:02`
- World marker: `ExileServer - Game world initialized! Let the fun begin!` at `20:11:14`
- Server-up marker: `ExileServer - Server is up and running! Version: 1.0.42` at `20:11:20`
- HC connected marker: `ExileServer - Player headlessclient (UID HC5788) connected!` at `20:12:44`
- A3XAI HC marker: `Headless client HC (owner: 4) logged in successfully.` at `20:12:48`
- FuMS HC marker: `HC started! Starting HeartBeat monitor for slot#4 : HC` at `20:14:00`

Doctor:

- `25 passed`, `1 warned`, `0 failed`
- Remaining warning: `infistar-cloud` 403 Forbidden, pre-existing local-log-only audit warning.

Why verdict is not `PASS_VERIFIED`:

- The runtime PASS condition itself is met.
- The independent critic requirement is not met. Orca task `task_90d8a47752d3` / dispatch `ctx_1f30b7fa3c2e` was started with Claude, but repeatedly stalled on local approval prompts and never sent `worker_done`; it was stopped and marked `BLOCKED_TOOLING`.
- Do not close GUARD-PERF-001 until an independent critic returns `PASS_VERIFIED` or Architect waives that requirement.
