# XCSV-ORCH-002 — Canonicalize orchestration, Hermes runnable, OpenClaw routing

Date: 2026-08-09
Canonical source: `D:\XCSV_ORCH` → **private** repo `x-cessive/XCSV_ORCH`
Runtime: `D:\CAGE\xcsv-ai-continuity`

## Verdicts

| Subject | Verdict |
| --- | --- |
| Canonical source | `DRIFT_RISK` — remote-backed and deploy-time verified, but **not** a single source |
| Hermes | `RUNNABLE_VERIFIED` |
| OpenClaw | `AUTO_ROUTING_VERIFIED`, scoped to one local OpenClaw-routed Ollama turn |
| Orca | `DESKTOP_ONLY` |
| Gauntlet | mechanism `PASS_VERIFIED`; the evaluated claim came back `BLOCKED_BY_CRITIC` |

The canonical-source label was **downgraded on critic advice**. Two independently
writable copies that match at time T are two copies, not one source. The honest
description is a deploy-time verified copy with residual drift risk, and that is
what is recorded here rather than the stronger claim originally drafted.

## Phase 1–2 — canonical source and deployment

The orchestration layer previously existed in one untracked directory with no
remote. It is now the private repository `x-cessive/XCSV_ORCH`, with the runtime as
a *deployment target* rather than a second master.

`tools\deploy.ps1` enforces:

- **State-root guard.** Refuses any destination lacking `state\CURRENT_HANDOFF.json`,
  because the runtime scripts derive their state root from their own location.
  Proven by test: no second state root was created.
- **Project-boundary guard.** Refuses a baton whose `PROJECT` is not `XCSV`.
  Proven with a `PROJECT=SOVRAN` baton.
- Archive-before-change, SHA256 manifest with source commit, and `-Verify` that
  proves runtime == manifest == canonical source.

`tools\secret-scan.ps1` reports credential **classes and locations only**, never
values. It was self-tested against synthetic tokens first: it detected
telegram/slack/openai/private-key classes, exited non-zero, and printed nothing.
Only after that was its CLEAN verdict treated as meaningful.

A `.gitignore` bug was caught here: the `*secret*` rule silently excluded
`tools/secret-scan.ps1` itself from the first commit. Negations were added, and a
check confirmed real secret-shaped files (`.env`, `*token*`) are still ignored.

## Phase 3 — Hermes is runnable

`hermes.exe` was never missing; it lives in the install venv
(`...\hermes-agent\venv\Scripts\hermes.exe`) and is simply not on `PATH`. XCSV calls
it by absolute path via `src\xcsv-hermes.ps1`, with no machine PATH mutation.

**Key finding: `HERMES_PROFILE` alone does not isolate Hermes state.** A one-shot run
with only the profile set still wrote to the *shared* root `state.db`, which backs
session history, resume and kanban. Hermes derives that path from `HERMES_HOME`, and
its own source warns the mismatch causes "cross-profile data corruption".

XCSV now uses its own `HERMES_HOME` at `D:\CAGE\xcsv-ai-continuity\hermes-home`, and
the launcher **refuses** to run against the shared home. Verified: an XCSV one-shot
returned `ALIVE` while the shared root `state.db` SHA256 was **unchanged**. The
provider is local Ollama, so the lane needs no cloud credentials and nothing was
copied from the default or `sovran-command-deck` profiles.

## Phase 4 — OpenClaw actually routed a worker

Per OpenClaw's official Ollama provider documentation, the XCSV profile was given
its own local provider (`baseUrl http://127.0.0.1:11434`, deliberately **without**
`/v1`, which the docs warn breaks tool calling). The agent auth store was unblocked
with `OLLAMA_API_KEY=ollama-local`, the documented non-secret loopback marker.

**No credential was copied from the default agentDir** — the action that caused the
original XCSV-ORCH-001 collision was refused again.

Two clean runs of
`openclaw --profile xcsvcontinuity agent --local --model ollama/qwen3-4b-instruct:latest`
returned `ALIVE` (425s, then 504s with `ok=True`, no timeout), writing sessions into
the XCSV profile's own sessions directory.

`FULL_AUTO_ROUTING_VERIFIED` is still **not** claimed: routing one turn is not
OpenClaw dispatching workers for an entire Work ID unattended. The two claims are
kept separate on purpose.

`openclaw-ollama` shares the provider independence key `Ollama (local)` with the
direct Ollama workers — routing the same model through OpenClaw does not buy a
second independent opinion, and the router enforces that.

## Phase 5 — worker pool

| Worker | Status | Note |
| --- | --- | --- |
| `codex-cli` (OpenAI gpt-5.5) | READY | |
| `claude-cli` (Anthropic) | READY | native exe, argv-safe |
| `opencode-cli` (deepseek-v4-flash-free) | READY | slowest cloud lane |
| `openclaw-ollama` | READY | proves OpenClaw routes |
| `ollama-qwen3-4b-instruct` / `-4k` | READY | offline lanes |
| `qwen-code-cli` | AUTH_REQUIRED | installed 0.21.8, runs; auth type is interactive |
| `gemini-cli` | AUTH_REQUIRED | `IneligibleTierError` — provider-side tier rejection, OAuth account present |
| `ollama-llama32-1b` | DEGRADED | failed instruction-following qualification |
| `antigravity` | UNAVAILABLE | state exists at `~/.gemini/antigravity-cli`, but `bin/` is empty and no executable exists |

Qwen was deliberately **not** pointed at local Ollama. Doing so would have produced a
"Qwen" critic that was really the same model already voting — a fake fifth provider.

## Phase 14 — critic findings acted on

An independent Anthropic critic attacked the canonical-source claim and was right on
the sharpest point: the deployment had been made from a **`-dirty` tree**, so the
deployed bytes existed in no commit and could not be reproduced from the remote.

Repairs made in response:

- `-Verify` now reports `UNREPRODUCIBLE_DEPLOY` and `provenance: NOT_REPRODUCIBLE`
  when the manifest records a dirty/uncommitted source.
- `-Verify` now detects **unlisted extra files** and deleted files in the runtime,
  not just modified ones.
- Verification is no longer a habit: `Invoke-XcsvGauntlet` calls
  `Assert-XcsvRuntimeVerified` and **refuses to route any claim** against a drifted
  runtime. A `-Force` bypass is recorded in the result rather than hidden.
- Regression coverage added for all three.

A **second, fresh independent critic** (OpenAI `codex-cli` — which did not implement
any of the repairs) then reviewed the repaired state and found F1 only half-done:
`-Verify` *reported* an unreproducible deploy but `deploy` still *permitted* one.

Final repair: a dirty/uncommitted deploy is now **refused outright**. `-AllowDirty`
remains for deliberate local iteration and is recorded in the manifest, so the bypass
is auditable rather than silent. Regression test added.

Final state: regression **17 passed, 0 failed**; `-Verify` returns `MATCH` with
`provenance: REPRODUCIBLE_FROM_COMMIT` at commit `d8f0ca5`.

### Caveat disposition

| Finding | Disposition |
| --- | --- |
| F1 unreproducible `-dirty` deploy | **FIXED** — now refused, not merely reported |
| F2 deletion / extra-file drift untested | **FIXED** — both detected, both tested |
| F3 verification is a habit, not a property | **FIXED** — run gate refuses drifted runtime |
| F4 time-of-check/time-of-use window | **NONBLOCKING, accepted** — bounded to one run, not closed |
| F5 `SINGLE_SOURCE` overclaims | **FIXED by relabelling** — now `DRIFT_RISK` |

Accepted as still-open: the runtime remains a separate writable copy, and there is no
immutable or content-addressed load path, so a file edited after start-of-run
verification can still execute. The run gate bounds that window to a single run; it
does not close it. Closing it would need an immutable runtime or load-time integrity
checking, which is the next structural step.

## Isolation

Unchanged and re-proven by regression: 0 `SOVRAN_*` / `OPENCLAW_SECRET_*` / `SMTP_*` /
`MC_RCON_*` variables reach a worker, no SOVRAN banner in worker stdout, and
`cmd.exe /d` still bypasses the AutoRun shell landing.

## SECURITY_ACTION_REQUIRED (SOVRAN — not actionable from this lane)

During the XCSV-ORCH-001 audit, plaintext SOVRAN credentials were printed into an
agent transcript before masking was enabled. **This XCSV lane has no authority to
rotate them and did not attempt to.**

Affected secret **classes** (no values recorded anywhere in XCSV):

- SOVRAN Telegram bot token
- Slack bot token and Slack app token
- OpenClaw gateway auth token and hooks token
- `sovranos.com` SMTP password
- Minecraft RCON password

These should be rotated from a separately authorised SOVRAN security lane. A secret
scan of all XCSV changes returned `SECRET_SCAN_CLEAN` before every push, so no
plaintext copy entered any XCSV repo or runtime file.
