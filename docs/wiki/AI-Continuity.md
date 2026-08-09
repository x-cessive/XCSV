---
layout: wiki
section: docs
title: AI Continuity
heading: AI Continuity
blurb: Isolated Hermes/OpenClaw baton and failover workflow for XCSV.
order: 4
source: AI-Continuity.md
---

XCSV uses an isolated continuity lane named `XCSV_AI_CONTINUITY`.

Runtime state root: `D:\CAGE\xcsv-ai-continuity`

Tracked operator entrypoint: `D:\XCSV\tools\xcsv-continuity.ps1`

Hermes profile: `xcsvcontinuity`

OpenClaw profile: `xcsvcontinuity`

The lane carries only the active baton: work item, authority, source/runtime
state, evidence, unknowns, blockers, and one bounded next action. It must not
store chat transcripts or previous-worker summaries as authority.

## Commands

Create or update the current baton:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 checkpoint
```

Show the current baton:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 show
```

Hydrate a continuation summary:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 hydrate
```

Show worker policy:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 workers
```

Verify basic isolation:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 verify-isolation
```

Run the simulated worker-exhaustion check:

```powershell
D:\XCSV\tools\xcsv-continuity.ps1 failure-test
```

## Isolation Rules

XCSV handoffs, logs, receipts, prompts, worker histories, routing state, and
authority envelopes stay under `D:\CAGE\xcsv-ai-continuity` or tracked XCSV repo
files.

Do not store XCSV baton state in Hermes default state, Hermes
`sovran-command-deck`, OpenClaw default state, or any SOVRAN project directory.

## Canonical source (2026-08-09, XCSV-ORCH-002)

The orchestration code is no longer a single untracked directory. Canonical source
is the **private** repository `x-cessive/XCSV_ORCH`, checked out at `D:\XCSV_ORCH`.

```
D:\XCSV_ORCH                      canonical source (private, remote-backed)
      |  tools\deploy.ps1         validated deployment + SHA256 manifest
      v
D:\CAGE\xcsv-ai-continuity\tools  runtime
D:\CAGE\xcsv-ai-continuity\state  runtime state - never tracked, never deployed over
```

The runtime is a *deployment target*, not a second master. `deploy.ps1 -Verify`
proves runtime == manifest == canonical source; `-DryRun` shows the plan; the
previous version is archived before every change.

**Status is `DRIFT_RISK`, not `SINGLE_SOURCE`.** An independent critic made the
point and it was accepted: two independently writable copies that match at time T
are two copies. What is actually guaranteed is a *deploy-time verified copy* whose
divergence is detectable. A dirty-source deploy is refused outright (bytes that
exist in no commit must not reach the runtime), and every Gauntlet run verifies the
runtime before routing a claim — but a file edited mid-run still executes
unverified. Closing that would need an immutable runtime or load-time integrity
checking.

Two guards are proven by test, not merely written:

- Deploying to a directory without `state\CURRENT_HANDOFF.json` is **refused**,
  because the runtime scripts derive their state root from their own location and
  a stray deploy would mint a second continuity state root.
- Deploying against a baton whose `PROJECT` is not `XCSV` is **refused** at the
  boundary (verified with a `PROJECT=SOVRAN` baton).

Never hand-edit the runtime. Change canonical source, then deploy.

## Gauntlet Loop (XCSV AI workforce)

The Gauntlet Loop routes one bounded claim to a primary worker, then to critics
drawn from *different providers*, and loops findings back for repair before any
verdict is accepted.

```
ARCHITECT -> XCSV Work ID -> Hermes durable baton -> router (worker selection)
          -> worker (bounded authority) -> evidence -> baton update
          -> independent critic -> repair loop -> verdict
```

Tools (runtime root `D:\CAGE\xcsv-ai-continuity\tools`):

| Tool | Purpose |
| --- | --- |
| `xcsv-workers.ps1` | Worker invocation + SOVRAN credential scrub + authority flags |
| `xcsv-gauntlet.ps1` | Router, critic separation, durable baton writes |
| `xcsv-failure-tests.ps1` | Nine real failure/exhaustion scenarios |
| `xcsv-gauntlet-run.ps1` | The XCSV-ORCH-001 acceptance run |

Routing degrades `OpenAI -> Anthropic -> OpenCode -> local Ollama -> BLOCKED`.
A critic may never share a provider with the implementer it reviews; provider
identity, not worker id, is the separation key.

## Isolation: two real defects found and repaired (2026-08-09)

**1. Shared OpenClaw approval token.** `exec-approvals.json` in the XCSV profile
carried a socket token *byte-identical* to the default/SOVRAN-era profile. The
socket paths differed but the shared secret did not. Repaired by rotating the
XCSV token only; the default profile was left untouched.

**2. `cmd.exe` AutoRun re-injecting SOVRAN state.**
`HKCU\Software\Microsoft\Command Processor\AutoRun` points at the SOVRAN shell
landing script. Because every npm-installed worker (`codex.cmd`, `gemini.cmd`,
`opencode.cmd`) launches through `cmd.exe`, the landing script re-injected
`SOVRAN_*` into each worker *after* the environment scrub and prepended its
banner to worker stdout. Repaired by always invoking `cmd.exe /d`, which
disables AutoRun for that invocation only and leaves the SOVRAN shell landing
fully intact for SOVRAN's own use.

Verified after repair: a real child process sees **0** `SOVRAN_*` /
`OPENCLAW_SECRET_*` / `SMTP_*` variables, no banner in stdout, and the positive
markers `XCSV_PROJECT` / `XCSV_STATE_ROOT` / `XCSV_ESTATE_ISOLATED`.

The shared shell profile itself is classified `HARMLESS_SHARED_SHELL_PROFILE`:
it sets three workspace-root variables, prints a banner, and changes directory.
It carries no credentials, baton, or model configuration.

## Current Status

Status is `PARTIAL` for automated failover and `HANDOFF_READY_MANUAL_FAILOVER`
for the XCSV baton.

Fresh checks on 2026-08-08 proved the existing continuity lane is usable for a
manual baton and read-only sidecar critics:

- `D:\XCSV\tools\xcsv-continuity.ps1 hydrate` reads the active XCSV baton.
- `D:\XCSV\tools\xcsv-continuity.ps1 verify-isolation` returns
  `PASS_BASIC_ISOLATION`.
- `D:\XCSV\tools\xcsv-continuity.ps1 failure-test` returns
  `PASS_FAILURE_DOES_NOT_MUTATE_HANDOFF`.
- `openclaw --profile xcsvcontinuity config validate` reports the isolated
  config valid.
- `openclaw --profile xcsvcontinuity sessions list --json` reports zero
  sessions under
  `C:\Users\Architect\.openclaw-xcsvcontinuity\agents\main\sessions\sessions.json`.
- `openclaw --profile xcsvcontinuity plugins list --json --enabled` loads 32
  enabled bundled plugins with no registry diagnostics.
- `openclaw --profile xcsvcontinuity skills list --json --eligible` succeeds;
  unavailable optional skills were disabled by
  `openclaw --profile xcsvcontinuity doctor --fix --non-interactive --yes`.
- The default and profile OpenClaw approval files remain distinct by SHA256
  after repair.
- `ollama run qwen3-4b-instruct "Reply exactly: XCSV local fallback OK"`
  returned the requested phrase.

Do not upgrade this to automatic failover authority yet. Hermes profile
isolation is file-proven, but no `hermes` executable is currently on `PATH` and
the `xcsvcontinuity` profile has no API keys. OpenClaw profile initialization
previously migrated the default
`C:\Users\Architect\.openclaw\exec-approvals.json` into the new profile and
archived the default file as `.migrated`; the default file was restored. Treat
OpenClaw as collision-sensitive and read-only until profile operations are
covered by a stronger before/after hash test that wraps real OpenClaw commands.

## 2026-08-08 EXILE-DB-001 Checkpoint

Active extDB3 SQL_CUSTOM file is proven as
`E:\arma3server\@ExileServer\sql_custom\exile.ini`. Proof: launcher runs from
`E:\arma3server` with `-servermod=@ExileServer`; RPT loaded
`E:\arma3server\@ExileServer\extDB3_x64.dll`; extDB3 logs are written under
`@ExileServer\logs`; local runbooks and extDB3 staging tools identify
`@ExileServer\sql_custom\exile.ini` as the live SQL_CUSTOM file. The
`@ExileServer\extDB\sql_custom\exile.ini` copy is a byte-identical compatibility
mirror.

EXILE-DB-001 repaired four `$CUSTOM_1$` query templates:
`insertConstruction`, `insertContainer`, `updateContainer`, and
`createTerritory`. The repair uses `NULLIF(?, 'NULL')`; `updateContainer` and
`createTerritory` require non-sequential `SQL1_INPUTS` so the former
`$CUSTOM_1$` argument remains bound to the nullable column.

OpenClaw remains collision-sensitive. The XCSV profile reports zero sessions at
`C:\Users\Architect\.openclaw-xcsvcontinuity\agents\main\sessions\sessions.json`,
but its approval file copied shared authorization material from the default
profile. Manual failover via the XCSV baton is the allowed continuity path until
OpenClaw profile initialization is fully characterized.

## 2026-08-09 XCSV-ORCH-001 — Gauntlet acceptance

Verdict: `PASS_VERIFIED` for the Gauntlet Loop, `MANUAL_ONLY` for OpenClaw.

Four claims were routed to **four distinct providers**, each on its first lane:

| Claim | Role | Worker | Provider |
| --- | --- | --- | --- |
| C1 | primary analyst | `codex-cli` | OpenAI (gpt-5.5) |
| C2 | independent critic | `claude-cli` | Anthropic |
| C3 | second critic | `opencode-cli` | OpenCode (deepseek-v4-flash-free) |
| C4 | offline lane | `ollama-qwen3-4b-instruct` | Ollama (local) |
| C5 | replacement worker | `codex-cli` | OpenAI |

The critic loop did real work. The claim under test was "the tracked XCSV
continuity artifacts have drifted from runtime, and the correct reconciliation
is runtime -> tracked". C1 returned `PARTIAL`; C2 and C3 both `CONFIRM`ed that
the *direction* was unproven and that a 5x/23x size replacement would destroy
tracked-only content unreviewed.

They were right. `D:\XCSV\tools\xcsv-continuity.ps1` is a deliberate 378-byte
*delegating wrapper* that invokes the runtime tool, not a stale copy of it.
Because the runtime script derives its state root from its own location,
copying runtime over tracked would have silently created a second continuity
state root under `D:\XCSV`. The reconciliation was therefore changed from
**copy** to **curated update**, and the wrapper was left untouched.

Handoff was proven without transcript: a fresh `codex-cli` process given only
`CURRENT_HANDOFF.json` correctly restated the work item, the next exact action,
and a prohibition it was under.

## 2026-08-09 XCSV-ORCH-002 — Hermes runnable, OpenClaw routing

### Hermes is now runnable for XCSV

`hermes.exe` was never missing — it lives in the install venv at
`...\hermes-agent\venv\Scripts\hermes.exe` and is simply not on `PATH`. XCSV calls
it by absolute path through `src\xcsv-hermes.ps1` rather than mutating machine PATH.

**`HERMES_PROFILE` alone does not isolate Hermes state.** A one-shot run with only
`HERMES_PROFILE=xcsvcontinuity` still wrote to the *shared* root `state.db`, which
backs session history, resume and kanban. Hermes resolves that path from
`HERMES_HOME`, and its own source warns this causes "cross-profile data corruption".

XCSV therefore has its own `HERMES_HOME` at
`D:\CAGE\xcsv-ai-continuity\hermes-home`, and the launcher **refuses** to run
against the shared home. Verified: an XCSV Hermes one-shot returned `ALIVE` while
the shared root `state.db` SHA256 was **unchanged**.

The provider is local Ollama, so this lane needs no cloud credentials and nothing
was copied from the default or `sovran-command-deck` profiles.

### OpenClaw did route a worker

Following OpenClaw's official Ollama provider documentation, the XCSV profile was
given its own local provider (`baseUrl http://127.0.0.1:11434`, **no** `/v1` — the
docs warn `/v1` breaks tool calling). The agent auth store was unblocked with
`OLLAMA_API_KEY=ollama-local`, the non-secret loopback marker the docs specify.

`openclaw --profile xcsvcontinuity agent --local --model ollama/qwen3-4b-instruct:latest`
returned `ALIVE` and wrote its session into the XCSV profile's own sessions
directory. **No credential was copied from the default agentDir.**

This is a genuine routed turn, so the `openclaw-ollama` lane is `READY`. It is
still **not** `FULL_AUTO_ROUTING_VERIFIED`: routing one turn is not the same as
OpenClaw selecting and dispatching workers for a whole Work ID unattended, and
those two claims are deliberately kept apart.

Note `openclaw-ollama` shares the provider independence key `Ollama (local)` with
the direct Ollama workers. Routing the same underlying model through OpenClaw does
not buy a second independent opinion, and the router enforces that.

### OpenClaw: failed closed, deliberately

`openclaw --profile xcsvcontinuity agent --local` reaches the agent lane but
returns `ProviderAuthError: No API key found for provider "openai"`. OpenClaw's
own remedy text suggests copying auth profiles from the main agentDir — which is
exactly what produced the original approval-token collision. That path was
refused. OpenClaw stays `MANUAL_ONLY`; routing authority remains with the
deterministic XCSV router until ARCHITECT supplies XCSV-scoped credentials.
