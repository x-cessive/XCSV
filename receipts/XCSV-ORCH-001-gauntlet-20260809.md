# XCSV-ORCH-001 — AI Workforce Gauntlet Loop

Date: 2026-08-09
Lane: `XCSV_AI_CONTINUITY`
Runtime root: `D:\CAGE\xcsv-ai-continuity`
Verdicts: Hermes `PARTIAL` · OpenClaw `MANUAL_ONLY` · Orca `PARTIAL` · Gauntlet `PASS_VERIFIED`

## Objective

Finish the XCSV AI-continuity/orchestration system so a durable baton plus a
worker router can carry one bounded Work ID across multiple independent AI
workers, with critics that attack the work and a repair loop that closes it.

## Isolation audit (Phase 2)

Two real defects were found and repaired. Neither was cosmetic.

### Defect 1 — shared OpenClaw approval token (`COLLISION_RISK`)

`C:\Users\Architect\.openclaw-xcsvcontinuity\exec-approvals.json` carried a
socket token byte-identical to `C:\Users\Architect\.openclaw\exec-approvals.json`
and to its `.migrated` sibling (all three hashed to the same value). The socket
*paths* were correctly distinct; the shared *secret* was not.

Repair: rotated the XCSV profile token only (fresh 24-byte CSPRNG value, base64url).
The default profile was not modified. No socket was live at the time. Backup written
alongside as `exec-approvals.json.bak-token-collision-*`.

### Defect 2 — `cmd.exe` AutoRun re-injecting SOVRAN state (`COLLISION_RISK`)

`HKCU\Software\Microsoft\Command Processor\AutoRun` =
`D:\CAGE\SHELL_LANDING\sovran_cmd_autorun.cmd`.

Every npm-installed worker (`codex.cmd`, `gemini.cmd`, `opencode.cmd`) launches
through `cmd.exe`, so the landing script re-set `SOVRAN_WORKSPACE_ROOT`,
`SOVRAN_CAGE_ROOT` and `SOVRAN_POST_REINSTALL_ROOT` *after* the environment
scrub, and prepended its banner to worker stdout.

Repair: `cmd.exe` is now always invoked with `/d`, which suppresses AutoRun for
that invocation only. The SOVRAN shell landing is untouched and still works for
SOVRAN. Nothing was weakened globally.

### Verified after repair

A real child process launched through the XCSV worker layer sees:

- `0` `SOVRAN_*`, `OPENCLAW_SECRET_*`, `SMTP_*` or `MC_RCON_*` variables
- no SOVRAN banner in stdout (`gemini --version` returns a clean `0.52.0`)
- positive markers `XCSV_PROJECT`, `XCSV_STATE_ROOT`, `XCSV_ESTATE_ISOLATED`

### Classifications

| Boundary | Verdict |
| --- | --- |
| Shell landing script (`profile.ps1` / `sovran_shell_landing.ps1`) | `HARMLESS_SHARED_SHELL_PROFILE` |
| `cmd.exe` AutoRun reaching XCSV workers | `COLLISION_RISK` → repaired → `PASS_ISOLATED` |
| OpenClaw XCSV approval token | `CONTAMINATED` → repaired → `PASS_ISOLATED` |
| Hermes `xcsvcontinuity` profile | `PASS_ISOLATED` (clean, no SOVRAN tokens) |
| XCSV runtime state under `D:\CAGE\xcsv-ai-continuity` | `PASS_ISOLATED` (SOVRAN hits are prohibition text only) |
| Shared binaries (ollama/codex/opencode/claude/openclaw) | `HARMLESS_SHARED_INFRASTRUCTURE` |

## Worker registry (Phase 3)

Available, probe-verified: `codex-cli` (OpenAI gpt-5.5), `claude-cli` (Anthropic),
`opencode-cli` (deepseek-v4-flash-free), `ollama-qwen3-4b-instruct`, `ollama-qwen3-4b-4k`.

Not available, and recorded rather than dropped: `gemini-cli` (IneligibleTierError —
auth tier revoked by provider), `qwen-code-cli` (not installed), `antigravity`
(not locally callable), `ollama-llama32-1b` (DEGRADED — failed a trivial
instruction-following probe, so explicitly not critic-eligible).

## Failure tests (Phase 6)

Nine scenarios, all real. Every one preserved the baton.

| Test | Result |
| --- | --- |
| F1 unavailable worker never selected | routed to `claude-cli` instead |
| F2 real 1s timeout against a cloud worker | `TIMEOUT`, process killed |
| F3 unsatisfiable output contract | `MALFORMED` across 2 lanes, never a false PASS |
| F4 all critic providers excluded | `BLOCKED` with 0 lanes |
| F5/F6 all clouds down | local Ollama carried the claim, `PASS` |
| F7 worker killed mid-task | partial stdout captured, baton intact |
| F8 routing to a missing executable | recorded as data, not fatal |
| F9 baton write after a failure sequence | succeeded and re-parsed |

F8 initially **failed**: a missing binary threw and aborted the run. Fixed —
launch failure now returns a `launch_failed` record so the router can act on it.

## Gauntlet acceptance run (Phase 7)

Claim: *"the tracked XCSV continuity artifacts have drifted from runtime, and the
correct reconciliation direction is runtime → tracked."* Bounded, read-only.

| Claim | Role | Worker | Provider | Verdict |
| --- | --- | --- | --- | --- |
| C1 | primary analyst | `codex-cli` | OpenAI | `PARTIAL` |
| C2 | independent critic | `claude-cli` | Anthropic | `CONFIRM` |
| C3 | second critic | `opencode-cli` | OpenCode | `CONFIRM` |
| C4 | offline lane | `ollama-qwen3-4b-instruct` | Ollama (local) | `DRIFT_CONFIRMED` |
| C5 | replacement worker | `codex-cli` | OpenAI | hydrated from baton alone |

Four distinct providers. Critic separation held on every claim.

### The critics were right

C2 and C3 both blocked the reconciliation *direction*, arguing a 5x/23x size
replacement destroys tracked-only content unreviewed. Orchestrator verification
confirmed it: `D:\XCSV\tools\xcsv-continuity.ps1` is a deliberate 378-byte
delegating wrapper, not a stale copy. Since the runtime script derives its state
root from its own location, copying runtime over tracked would have created a
second continuity state root under `D:\XCSV`.

Reconciliation was changed from **copy** to **curated update**. The wrapper was
left untouched. The loop prevented a real mistake.

### Repair loop

The first run had three failing lanes. Root cause was a genuine bug in the
orchestrator, not flaky models: **`cmd.exe` truncates an argv argument at its
first newline**, so multi-line prompts delivered only line 1 to every `.cmd`
worker. Codex was answering the role preamble — hence its "Understood, I'll
operate as read-only" replies. `claude.exe` is a native binary and was unaffected,
which is why it alone appeared reliable.

Fix: prompts for `.cmd` workers now go over **stdin**, never argv. Secondary
repairs: forbid tool use for evidence-only critics (`opencode` was hitting an
`external_directory` auto-reject), and replace angle-bracket placeholders with a
literal template (small local models were echoing `<DRIFT_CONFIRMED|NO_DRIFT>`).

After repair all four claims passed on their first lane.

## OpenClaw — failed closed

`openclaw --profile xcsvcontinuity agent --local` reaches the agent lane and
returns `ProviderAuthError: No API key found for provider "openai"`. OpenClaw's
own error text recommends copying auth profiles from the main agentDir — the
exact action that produced the original token collision.

That path was refused. OpenClaw remains `MANUAL_ONLY`. Routing authority stays
with the deterministic XCSV router. No claim of automatic failover is made.

## Files

Runtime (`D:\CAGE\xcsv-ai-continuity`): `tools\xcsv-workers.ps1`,
`tools\xcsv-gauntlet.ps1`, `tools\xcsv-failure-tests.ps1`,
`tools\xcsv-gauntlet-run.ps1`, `config\worker-policy.json`,
`runs\XCSV-ORCH-001\*`, `logs\failure-tests.json`, `logs\baton-audit.jsonl`.

Tracked: `continuity\worker-policy.json` (curated), `wiki\AI-Continuity.md`,
`wiki\Lessons.md`, `wiki\Roadmap.md`, this receipt.

## Remaining unknowns

- Hermes has no CLI on `PATH` and the `xcsvcontinuity` profile has no API keys;
  the baton is carried by XCSV tooling, not a running Hermes agent.
- OpenClaw auto-routing needs XCSV-scoped provider credentials from ARCHITECT.
- `gemini-cli` needs re-auth/migration before it can rejoin the roster.
- Orca runtime was started manually mid-session; mobile pairing not re-verified.
