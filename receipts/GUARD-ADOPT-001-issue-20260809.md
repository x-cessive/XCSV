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
