# XCSV-AI-003 - Hermes/OpenClaw Continuity Verification

Date: 2026-08-08

Verdict: `PARTIAL`

Gauntlet: G2

GitHub: https://github.com/x-cessive/XCSV/issues/11

## Scope

Verify and repair the existing Hermes/OpenClaw/Ollama continuity lane without
adding a new subsystem. The goal is manual baton continuity plus read-only
sidecar critics, not automatic failover authority.

## Evidence

- `D:\XCSV\tools\xcsv-continuity.ps1 hydrate` reads the active baton.
- `D:\XCSV\tools\xcsv-continuity.ps1 verify-isolation` returned
  `PASS_BASIC_ISOLATION`.
- `D:\XCSV\tools\xcsv-continuity.ps1 failure-test` returned
  `PASS_FAILURE_DOES_NOT_MUTATE_HANDOFF`.
- `openclaw --profile xcsvcontinuity config validate` reported the isolated
  config valid.
- `openclaw --profile xcsvcontinuity sessions list --json` reported zero
  sessions under the isolated profile path.
- `openclaw --profile xcsvcontinuity plugins list --json --enabled` loaded 32
  enabled bundled plugins with no registry diagnostics.
- `openclaw --profile xcsvcontinuity skills list --json --eligible` succeeded.
- `openclaw --profile xcsvcontinuity doctor --fix --non-interactive --yes`
  disabled unavailable optional skills.
- Default and profile OpenClaw approval files remained distinct by SHA256 after
  repair.
- `ollama run qwen3-4b-instruct "Reply exactly: XCSV local fallback OK"`
  returned the requested phrase.
- Desktop layout capture remains available at
  `D:\CAGE\xcsv-desktop-shots\desktop-20260808-174910.png` with text-state
  files for non-vision agents.

## Changes

- Updated `continuity/worker-policy.json` with current Hermes/OpenClaw/Ollama
  readiness.
- Updated `wiki/AI-Continuity.md` with current proof and remaining boundaries.
- Updated `wiki/Roadmap.md` and `wiki/Lessons.md`.
- Added `tools/tests/continuity-state.tests.ps1`.
- Rebuilt `docs/wiki`, memory index, and RAG index.

## Tests

- `tools\tests\continuity-state.tests.ps1`: 5 passed, 0 failed.
- `tools\tests\sync-policy.tests.ps1 -Quiet`: 33 passed, 0 failed.
- `tools\check-text-safety.ps1`: clean.

## Remaining Unknowns

- No `hermes` executable is currently on `PATH`; Hermes runtime invocation is
  not proven.
- Hermes `xcsvcontinuity` profile exists but has no API keys.
- OpenClaw remains collision-sensitive because earlier profile initialization
  moved default approval state; it is read-only until stronger before/after hash
  tests wrap real profile commands.
- Claude and OpenCode are installed/observed, but live contract bootstrap in
  their own sessions was not performed in this slice.

## Next

Highest-value active roadmap item remains `GUARD-PERF-001`: prove real managed
server process exit while GUARD is minimized causes background detection and
exactly one relaunch, then continue the RCon drift/shutdown investigation.
