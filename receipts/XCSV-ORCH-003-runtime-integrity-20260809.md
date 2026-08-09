# XCSV-ORCH-003 — Load-time runtime integrity

Date: 2026-08-09
Canonical source: `D:\XCSV_ORCH` → private repo `x-cessive/XCSV_ORCH`
Runtime: `D:\CAGE\xcsv-ai-continuity`

## Objective

Close the remaining gap: the runtime copy matched canonical source at deployment
time but stayed independently writable afterwards, so a file could change between
verification and execution.

## Phase 1 — identity contract

Each release carries a `manifest.json` binding source repo, source commit, clean-state
proof, build timestamp, schema version, destination root, tool version, the declared
file set, and a SHA256 for every artifact.

Explicitly separated:

| Immutable deployed code | Mutable runtime state |
| --- | --- |
| `releases\<commit>\*.ps1`, `worker-policy.json`, `manifest.json` | `state\`, `handoffs\`, `runs\`, `logs\`, `receipts\`, `hermes-home\` |

The manifest names both sets, so the boundary is data rather than convention.

## Phase 2–3 — load-time verification and TOCTOU

```
canonical commit -> manifest (per-file SHA256) -> CURRENT.json (release id + manifest SHA256)
                 -> load-time verification -> execution
```

`Import-XcsvVerifiedModule` reads a module's bytes **once**, hashes *those bytes*, and
executes *those same bytes* via `[scriptblock]::Create()`. There is no second
filesystem read between check and use, so for loaded modules TOCTOU is **closed**, not
narrowed. Verifying a path and then re-opening that path — the previous design — always
leaves a window.

Gated entrypoints: the Gauntlet controller, the Hermes launcher, and
`Invoke-XcsvWorker` itself. That last one matters most: it is the narrowest choke point
through which orchestration can cause a worker to execute, so no entrypoint can route
around the gate by taking a different path.

Failure mode is `INTEGRITY_BLOCKED`: no dispatch, no self-repair, no silent redeploy,
no fallback to unverified local code.

## Phase 4 — content-addressed releases

Releases live at `releases\<commit>\` and are never rewritten in place; rebuilding a
commit rebuilds the directory from a staging copy, so a half-written release is never
promoted. `CURRENT.json` is written temp-then-replace. `-Rollback` re-promotes a prior
release after verifying it. Retention keeps the last 5 and never prunes the current one.

**State-root decoupling was the load-bearing change.** Modules previously derived
`$Root` from `Split-Path $PSScriptRoot`. Running from `releases\<id>\` would therefore
have minted a continuity state root *per release* — the exact defect earlier guards
exist to prevent. The state root now resolves explicitly via `Get-XcsvStateRoot`
(`XCSV_STATE_ROOT`, else the default), and a test asserts no release directory contains
`state\`, `handoffs\`, `runs\`, `hermes-home\` or a baton.

## Phase 5 — adversarial suite: 19 passed, 0 failed

Blocks (code mutation):

| # | Case | Finding |
| --- | --- | --- |
| 1 | modified release script | `MODIFIED_FILE` |
| 2 | deleted release script | `MISSING_FILE` |
| 3 | undeclared script smuggled in | `UNDECLARED_FILE` |
| 4 | manifest rewritten to whitelist tampering | `MANIFEST_TAMPERED` |
| 5 | manifest removed | `MANIFEST_MISSING` |
| 6 | wrong expected source commit | `WRONG_SOURCE_COMMIT` |
| 7 | release built from a dirty tree | `DIRTY_SOURCE_RELEASE` |
| 8 | pointer to a non-existent release | `STALE_POINTER` |
| 9 | code edited after release | refused **at load time** |

Allows (state mutation): baton edit, log growth, `CURRENT_HANDOFF` survives a release
rebuild. Also proven: rollback promotes a previously verified release, no release
creates a second state root, a mid-run `CURRENT.json` pointer swap cannot redirect a
later import, and baton fields do not reach executable constructs.

A gate that blocks everything is an outage, not a safety feature — hence tests 10–12.

## Phase 7 — Hermes, integrity-gated

The XCSV-ORCH-002 isolation fix is preserved: XCSV uses its own `HERMES_HOME` and the
launcher **refuses** the shared home whose `state.db` is shared with the default and
`sovran-command-deck` profiles.

Hermes now also passes the integrity gate. With an undeclared file planted in the
release, `xcsv-hermes.ps1` exited non-zero with `INTEGRITY_BLOCKED` / `UNDECLARED_FILE`
and dispatched nothing.

## Phase 8 — OpenClaw, integrity-gated

Local routing configuration is unchanged and no provider secret was copied from another
profile. OpenClaw dispatch runs through `Invoke-XcsvWorker`, so it passes the same gate.

Codex takeover recovered that Claude's slow OpenClaw background run had completed only
as a simple ALIVE local routed turn. Codex then ran the missing gate proof:

| Case | Result |
| --- | --- |
| Corrupt runtime before dispatch | `INTEGRITY_BLOCKED`; no OpenClaw route |
| Restored verified runtime | OpenClaw `xcsvcontinuity` local Ollama session returned `ALIVE` |
| Session | `5ee5091d-9200-4388-aa9a-ae6b024a4f7f` |
| Elapsed | about 650 seconds |

Classification: `OPENCLAW_AUTO_ROUTING_VERIFIED_LOCAL_LANE`.
`FULL_WORK_ID_ROUTING_UNPROVEN` remains true: OpenClaw has not selected worker lanes,
persisted a baton, selected a critic, and returned final structured status for a whole
bounded Work ID.

## Codex takeover evidence

Claude reached its session limit after pushing
`8cb52165912fd2dcd2890397c351b477ee63c2ce`. Codex verified:

| Evidence | Result |
| --- | --- |
| `D:\XCSV_ORCH` local HEAD | `8cb52165912fd2dcd2890397c351b477ee63c2ce` |
| `D:\XCSV_ORCH` `origin/main` | same |
| Runtime release | `8cb52165912f` |
| Manifest SHA256 | `98FF21064F382F8FE370334D7369BAC3C11B70A0D47865897CCABAD0987E05E6` |
| Integrity suite | `19/19 PASS` |
| Regression suite | `16/16 PASS` |
| Hub continuity guard | `5/5 PASS` |
| XCSV_ORCH worktree | clean |

This is `HUMAN_DIRECTED_CROSS_PROVIDER_HANDOFF: VERIFIED`. It is not
`AUTOMATIC_OPENCLAW_FAILOVER`.

Final independent critic status: Claude CLI was blocked by session limit. OpenCode /
DeepSeek performed real read-only checks and confirmed source/runtime/provenance facts,
but timed out before emitting the required verdict JSON. Final critic classification is
`PARTIAL_TIMEOUT`, with no blocking source finding recovered.

## Root of trust — stated plainly

The chain terminates at `CURRENT.json` plus the integrity module. An attacker with
write access to the runtime root could rewrite pointer, manifest and code together.
Defeating that needs code signing or an OS-enforced immutable store, neither of which
is in place.

What this *does* defeat: accidental edits, partial deploys, stale pointers,
unreproducible releases, and any single-artifact tampering.

## Workforce — bounded operator actions

Three lanes are blocked on a decision that is ARCHITECT's to make, not mine. Each is
prepared to the point where exactly one action unblocks it. None blocks ordinary XCSV
orchestration.

### Qwen Code — `AUTH_REQUIRED`

Installed and executing (`@qwen-code/qwen-code` 0.21.8; `qwen --version` returns
0.21.8). Non-interactive runs fail with *"No auth type is selected. Please configure an
auth type before running in non-interactive mode."* The `qwen auth` subcommand is
listed as **removed** in this version, so the auth type is chosen on an interactive
first run.

Deliberately **not** pointed at local Ollama. That would produce a "Qwen" critic that is
really the Ollama model already voting, falsifying provider independence.

> **Operator action (one):** run `qwen` in a terminal and complete the authentication
> selection. Afterwards I will probe it, classify its true provider identity, and add it
> to the registry only if it passes — testing implementation and critic eligibility
> separately.

### Gemini — `ACCOUNT_MIGRATION_REQUIRED`

Precise error, captured this session:

> `IneligibleTierError: This client is no longer supported for Gemini Code Assist for
> individuals. To continue using Gemini, please migrate to the Antigravity suite of
> products: https://antigravity.google`

This is **not** a missing login — `~/.gemini/google_accounts.json` has an active account
and `oauth_creds.json` exists. Google has withdrawn this client from the individual Code
Assist tier. Eligibility must not be bypassed.

Two legitimate paths, and the choice is ARCHITECT's:

1. **`ACCOUNT_MIGRATION_REQUIRED`** — migrate the account to Antigravity per Google's
   notice. Note the local Antigravity state at `~/.gemini/antigravity-cli` has history
   but an empty `bin/`, so no callable CLI exists yet.
2. **`API_KEY_REQUIRED`** — supply an XCSV-scoped `GEMINI_API_KEY` so the CLI uses
   direct API auth instead of Code Assist. This is a different supported product, not a
   circumvention.

### Orca — `DESKTOP_ONLY`

Desktop control is proven (runtime ready; a non-focus-stealing terminal in the XCSV
worktree returned the live baton). Orca's CLI exposes **no** pairing, mobile, device or
tunnel commands — `agent-context --json` lists 223 commands and none match — so pairing
is an app-UI action only. Approvals were not touched.

> **Operator action (one):** pair the phone in the Orca app, then from Orca Mobile in the
> XCSV workspace read the current Work ID and baton, start one bounded XCSV task, and
> confirm the result. Only then does `MOBILE_CONTROL_VERIFIED` become claimable.

## SECURITY_ACTION_REQUIRED (SOVRAN — unchanged, not actionable here)

Credential **classes** exposed in an earlier transcript, values never recorded in XCSV:
SOVRAN Telegram bot token, Slack bot and app tokens, OpenClaw gateway and hooks tokens,
`sovranos.com` SMTP password, Minecraft RCON password. Rotation belongs to a separately
authorised SOVRAN lane. No SOVRAN state was read or written. Secret scan returned
`SECRET_SCAN_CLEAN` before every push.
