# GUARD-PERF-001 final closure receipt

Date: 2026-08-09

Verdict: PASS_VERIFIED

Issue: `#9`

Deployed build:

- `guard-0.7.1+16`
- XCSV_GUARD: `6d50564827c77bfddd2a616c84ff6c8dbb557bf7`
- Supporting commit: `79b21508b654bc8d0d101a8df7eae38e9211e84e`
- XCSV evidence commit: `67e54208b30c1575b009418a9a9819e4d7770f6c`
- SHA256: `5F23A5CEF6585790B7E9FA4B23832723CBF217DD09AE9A98BBC232F2BFC2EDF5`
- Tests: `254 passed`, `0 failed`, `3 ignored`
- Doctor: `25 PASS`, `1 WARN`, `0 FAIL`

Final runtime proof:

- GUARD stayed minimized.
- Real server PID `37804` was terminated.
- Background supervisor detected loss.
- Replacement server PID `41016` launched under GUARD PID `23548`.
- UDP `2302`, `2303`, `2304`, `2306` returned.
- Mission initialized.
- extDB3 connected.
- Server reached UP state.
- Exactly one HC PID `5788` returned.

Independent critic:

- Separate independent GitHub/source/evidence review returned `PASS_VERIFIED`.
- It accepted the pushed runtime receipt as satisfying the critical condition:
  `GUARD minimized + real server process exit -> background supervisor detects and recovers exactly one healthy server without GUI restoration`.
- Earlier Orca Claude critic failure remains classified separately as `BLOCKED_TOOLING`; it is superseded by the later independent critic result and is not a runtime contradiction.

Repairs closed by this issue:

- Malformed `--diagnostic-stop-managed-server` fails closed and does not launch normal GUARD.
- Termination uses a validated Windows process handle.
- Executable identity is revalidated through that handle.
- Broad image-name server killing is refused when no owned child handle exists.
- PID handoff / PID-reuse exposure is materially reduced.
- HC duplicate prevention includes sysinfo plus CIM fallback.

Separate follow-up:

- `GUARD-ADOPT-001` tracks explicit safe adoption/control authorization for an already-running configured server after GUARD restarts without an owned `Child` handle.
