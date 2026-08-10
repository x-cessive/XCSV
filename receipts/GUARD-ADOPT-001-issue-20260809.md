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

## 2026-08-10 Claude takeover - adopted StopStack GUI click path

Agent: Claude Opus 5 (Claude Code)

Starting classification: inherited `PASS_WITH_CAVEAT` with the exact adopted
StopStack GUI click path `NOT_OBSERVED`.

Final verdict for the click path: `PASS_GUI_CLICK_VERIFIED`.

### Root cause of the failed synthetic clicks

The clicks did not fail because of an Orca defect or a timing race. GUARD
published no accessibility surface at all.

`Cargo.toml` declared:

```toml
eframe = { version = "0.28", default-features = false, features = ["default_fonts", "glow"] }
```

`default-features = false` silently dropped eframe's default `accesskit`
feature. Measured on the deployed build 19 process (PID `16480`):

```text
AutomationElement.FromHandle(hwnd)
  root name='XCSV GUARD' class='Window Class' framework='Win32'
  descendant count = 0
```

The window was a single opaque Win32/`glow` surface. There was no
`STOP EVERYTHING` element for any automation client to locate or invoke, so
the GUI click path was not merely unproven - it was unreachable.

### Change

Re-enabled the standard feature in `D:\XCSV_GUARD\Cargo.toml`:

```toml
eframe = { version = "0.28", default-features = false, features = ["accesskit", "default_fonts", "glow"] }
```

This adds no GUARD-specific control surface. It restores the ordinary
operating-system accessibility tree, exposing exactly the widgets already
drawn on screen. Every existing adoption/identity validation in
`ServerCtl::stop_adopted` remains on the path; activation still runs through
egui's own widget click handling.

Commit: `5b148bb6f7467a0aa1250d10929698099de7951c`
"Expose accessibility tree for GUI automation".

Verification: `cargo test`: 256 passed, 0 failed, 3 ignored.

### Runtime proof

Build `guard-0.7.1+20` deployed via `tools\deploy.ps1` from commit
`5b148bb6f746`, `source_state=CLEAN`, sha256
`3CC4E72256BF6CD049FAE1415B4B808F3181DF028E9CAF069FBB27E8E1DCD0FE`.
Deploy relaunched GUARD as PID `16496` and placed it at `960,0 960x1032`
(`window_placement.ok=true`).

Adoption precondition: GUARD was relaunched while the configured
`arma3server_x64.exe` PID `41508` (started 01:16:14) was already running.

Accessibility tree after the fix: 102 descendants, including GUARD's own
rendered state read directly from the UI:

```text
[Text] 'server'   [Text] 'running'
[Text] 'control'  [Text] 'adopted'
[Button] '.  STOP EVERYTHING'   InvokePatternIdentifiers.Pattern
  bounding rect x=1095 y=67 w=102 h=16
```

The bounding rectangle falls inside the right-half GUARD window, confirming the
invoked element is the visible on-screen control and not a hidden widget.

Observed sequence:

```text
PRE     2026-08-10T01:49:25.5433870-04:00  adopted server pid=41508  mysqld=35644
INVOKE  2026-08-10T01:49:25.5609577-04:00  InvokePattern.Invoke() on STOP EVERYTHING
t+2s    server=GONE  mysqld=GONE
```

GUARD UI immediately after the invoke: `server` -> `stopped`, status
`stack: shutting down...`, and the control flipped to `. START EVERYTHING`.
`Get-Service MariaDB` -> `Stopped`.

MariaDB safety: the database was stopped only on the success path. The failure
path is source-verified at `src\app\worker.rs:949-956` - when `stop_adopted`
returns `Err`, GUARD sets `stop_db = false` and records
`server stop failed, database left running`. The shutdown thread also waits for
`arma_running()` to go false (up to 20s) before touching the service, so the
database is never stopped underneath a live server.

### Recovery

Recovery was driven through the same UI path (`START EVERYTHING` invoked via
`InvokePattern`) at `2026-08-10T01:50:21`:

- exactly one dedicated server, PID `37604`; no duplicate `arma3server_x64.exe`
- no duplicate HC
- MariaDB back to `Running`
- `Starting mission count = 1` - no restart loop
- control authority correctly transitioned `adopted` -> `owned` once GUARD
  spawned the replacement itself; `server` -> `running`
- GUARD window still exactly `960,0 960x1032`

GUARD doctor was run twice. Immediately after the restart it read
`23 passed, 3 warned, 0 failed`, with `population` at `16/103` and `hc-join`
warned - both simply because the server had only just booted. Once population
and the HC join completed, the settled run read:

```text
25 passed, 1 warned, 0 failed
```

This is better than the build 19 baseline of `24 passed, 2 warned, 0 failed`.
The only remaining warning is the known infiSTAR cloud `403 Forbidden`.
Notably `hc-join` now **passes** - `latest server/HC logs show successful HC
join` - where it had been a standing warning for Codex. Confirmed in the RPT:

```text
1:52:40 "[A3XAI] Headless client HC (owner: 4) logged in successfully."
1:53:50 "##FuMsnInit: Script Transfer complete to Headless Client <4:HC> in 53.7 secs"
```

Final process state: exactly one dedicated server `arma3server_x64.exe` PID
`37604`, exactly one headless client `arma3_x64.exe` PID `30564`, `mysqld` PID
`33860`, GUARD PID `16496`. No duplicate server, no duplicate HC.

### Verdict change

The exact adopted StopStack GUI click path is no longer `NOT_OBSERVED`. The
real on-screen button was activated through the standard accessibility invoke
path, the adopted server PID exited, MariaDB was stopped safely and only after
the server was gone, and recovery produced no duplicate server or HC.

Note on scope: this proves the click path on build 20. Build 19 remains
permanently unclickable by automation, because the accessibility tree it never
published cannot be added retroactively.
