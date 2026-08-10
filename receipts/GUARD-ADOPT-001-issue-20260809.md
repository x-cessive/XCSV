# GUARD-ADOPT-001 - adopted server control model

Work ID: `GUARD-ADOPT-001`

Owning repo: `XCSV_GUARD`

Priority: P2 - critical GUARD control/observation failure

Gauntlet: G3

## Problem

`ServerCtl::stop()` now safely refuses when GUARD has no owned `Child` handle:

```text
no owned server process handle; refusing broad process-name kill
```

That refusal is deliberate and safer than the old broad `taskkill /IM` behavior.
It prevents GUARD from killing unrelated dedicated servers or a PID that no
longer represents the validated target.

However, it leaves an operational control gap. If GUARD restarts while
`arma3server_x64.exe` remains running, the new GUARD process can observe the
configured server through process discovery but no longer owns the original
`Child` handle. Manual StopStack or restart-control paths can then refuse even
when there is exactly one configured server.

## Evidence

During GUARD-PERF-001:

- A pre-existing server PID `7956` was not the current GUARD child.
- Current GUARD could observe it but did not own the original child handle.
- Build 15/16 correctly removed broad image-name killing and moved diagnostic
  termination to a validated process handle.
- Build 16 proved minimized recovery when the replacement server became GUARD's
  direct child again.

## Required safety properties

- Never return to broad taskkill-by-image behavior.
- Active server executable must match configured `server_exe`.
- Ambiguous multiple-server state must refuse.
- Unrelated `arma3_x64.exe` / HC must never be targeted.
- Process identity must be revalidated before control.
- PID reuse must not create unsafe control.
- Adoption must not falsely imply GUARD originally spawned the process.
- Authority/state distinction between OBSERVED and OWNED/ADOPTED must remain explicit.

## Acceptance criteria

- GUARD distinguishes `OBSERVED`, `OWNED_CHILD`, and explicitly `ADOPTED` server control states.
- A single configured already-running server can be adopted only through a narrow, auditable path.
- Adoption records enough process identity to prevent PID-reuse confusion.
- Stop/restart control refuses when identity/path/count is ambiguous.
- Existing GUARD-owned child control remains unchanged.
- Tests cover unrelated Arma client, HC, mysqld, multiple servers, stale PID, wrong executable path, and GUARD restart/no-child cases.
- Runtime proof shows an adopted single configured server can be stopped/restarted without duplicate server or duplicate HC instances.

## Non-goals

- No privileged service.
- No broad remote-control API.
- No return to image-name killing.
- No assumption that OBSERVED means OWNED.

## Rollback

Keep the build 16 behavior: no owned child handle means refusal rather than unsafe termination.

## 2026-08-10 Codex source implementation

Agent: Codex/OpenAI

Starting classification: `PARTIAL`

Final source verdict: `PASS_SOURCE_VERIFIED`

Runtime/deployment verdict: `PASS_WITH_CAVEAT`

Changes:

- Added `ServerAuthority` with explicit `None`, `Observed`, `Adopted`, and
  `OwnedChild` states.
- Added narrow adoption in `ServerCtl`: a process can become `Adopted` only when
  the current process table has exactly one dedicated server process and the
  executable path matches configured `server_exe`.
- Stop/relaunch force-stop paths now use the same configured-executable
  validation before controlling an adopted process.
- The top bar and Overview server card display the current control authority.
- `server_authority` is classified in `state_model.rs` as reconstructable OS
  process state, never durable truth.
- If a server stop fails, GUARD now leaves MariaDB running and preserves a
  failure state instead of overwriting the status with a generic shutdown line.

Verification:

- `cargo test --manifest-path D:\XCSV_GUARD\Cargo.toml`: 256 passed, 0 failed,
  3 ignored.
- `cargo build --manifest-path D:\XCSV_GUARD\Cargo.toml`: passed with existing
  dead-code warnings.

Runtime evidence:

- Build `guard-0.7.1+17` deployed from commit
  `1be829e3f88ffadfe0e4c564f90f43030c787d93` with full tests: 256 passed,
  0 failed, 3 ignored.
- After GUARD restart, already-running server PID `21424` remained external to
  the new GUARD process and the UI displayed `control=adopted`.
- Deployed diagnostic stop validated configured executable identity and
  terminated adopted PID `21424`:
  `terminated requested managed server process via validated process handle`.
- GUARD recovery launched replacement server PID `41508` without creating a
  duplicate dedicated server.
- Build `guard-0.7.1+19` deployed from commit
  `6d821f2af16c89728622574afdfb411be3b872e4` with full tests: 256 passed,
  0 failed, 3 ignored.
- Build 19 added deterministic AI-launch window placement. `deploy.ps1`
  launched GUARD PID `16480` and placed it on the right half of the primary
  work area at `960,0 960x1032`; `archive/CURRENT.json` recorded
  `window_placement.ok=true`.
- Orca independently observed the same right-side window geometry and visible
  `adopted control` over server PID `41508`.
- GUARD doctor after build 19: 24 passed, 2 warned, 0 failed. The warnings were
  `hc-join` and known infiSTAR cloud `403 Forbidden`; `running-arch` passed for
  `arma3server_x64.exe` PID `41508`.

Caveat:

- Orca synthetic clicks against the visible `STOP EVERYTHING` button did not
  activate the button. Therefore the exact adopted StopStack GUI click path is
  still `NOT_OBSERVED`. The underlying adopted-process termination path is
  proven by deployed diagnostic stop, and stable right-side placement is now
  automated for repeatable future GUI proof.
