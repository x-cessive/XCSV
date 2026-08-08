# GUARD-PERF-001 - Diagnostic Stop Path

Date: 2026-08-08

Verdict: `PARTIAL_BLOCKED_PERMISSION`

Gauntlet: G3

GitHub: https://github.com/x-cessive/XCSV/issues/9

## Implementation

XCSV_GUARD commit:
`567799ec1a4c459cd7b9f991b34a2106583a9fd6`

Deployed build:

- build id: `guard-0.7.1+14`
- source state: `CLEAN`
- deployed exe: `C:\Users\Architect\Desktop\XCSV_GUARD.exe`
- SHA256:
  `159268D199D8DDB228B23CDA471DC4AAD14215891BD432F7C4C9076BC4906DB0`

The build adds one narrow CLI diagnostic:

```text
--diagnostic-stop-managed-server <pid> [json-report]
```

It exits before normal GUI launch and refuses unless all of these are true:

- exactly one dedicated `arma3server` process is present
- the requested PID is that process
- the target executable path is observable
- the target executable path matches configured `server_exe`

It does not target HC, `mysqld`, SOVRAN, or unrelated `arma3_x64` processes.

## Tests

`cargo test` in `D:\XCSV_GUARD`:

- `249 passed`
- `0 failed`
- `3 ignored`

Focused diagnostic tests prove acceptance and refusal cases for:

- exact configured server PID
- multiple dedicated server processes
- unrelated `arma3_x64` / `mysqld` / SOVRAN-like processes
- unobservable executable path
- wrong server path
- exact CLI flag parsing
- non-numeric PID refusal

Release build passed.

## Runtime Evidence

Deployed GUARD build 14 was running as PID `17692`.

Baseline before the controlled stop attempt:

- server PID: `7956`
- HC/client PID: `26612`
- UDP ports `2302`, `2303`, `2304`, `2306` owned by PID `7956`

GUARD minimized proof before stop attempt:

- PID: `17692`
- `GetWindowPlacement.showCmd`: `2`
- minimized: `true`

Medium-token diagnostic execution wrote:

```json
{
  "action": "diagnostic_stop_managed_server",
  "pid": 7956,
  "ok": false,
  "refused": false,
  "reason": "ERROR: The process with PID 7956 could not be terminated. Reason: Access is denied.",
  "target_name": "arma3server_x64.exe",
  "target_exe": "E:\\arma3server\\arma3server_x64.exe",
  "matching_server_count": 1
}
```

Report path:
`D:\CAGE\xcsv-runtime\guard-perf-001-stop-7956-build14.json`

This proves the new diagnostic selected the intended managed server and did not
touch unrelated processes, but the current medium token still cannot terminate
PID `7956`.

## Elevated Scheduled Task Attempts

Temporary highest-run-level scheduled task creation:

- action: `Register-ScheduledTask`
- result: `Access is denied`
- classification: `BLOCKED_PERMISSION`

Existing `XCSV GUARD` task mutation attempt:

- action: `schtasks /Change /TN "XCSV GUARD" /TR ...`
- result: requested run-as password, then `Access is denied`
- classification: `BLOCKED_PERMISSION`

Read-back confirmed the existing task action remained unchanged:

- execute: `C:\Users\Architect\Desktop\XCSV_GUARD.exe`
- arguments: empty
- working directory: `C:\Users\Architect\Desktop`

## Final State

The minimized real-process recovery acceptance condition remains unproven:

```text
GUARD minimized
+ real server process exits
-> background supervisor detects and relaunches exactly one server
```

The remaining blocker is not GUARD source coverage; it is obtaining an
authorized elevated process-exit trigger or starting the live server under a
GUARD-owned handle that can be terminated for the acceptance test.
