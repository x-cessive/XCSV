# AI Provenance and Documentation Sync

**XCSV-AI-PROVENANCE: 1.0.0**

This policy is a mandatory companion to [AI Start Here](AI-Start-Here). It governs two failure classes that the roadmap reconciliation contract alone cannot solve:

1. **who actually produced a GitHub change**, when the Git author/pusher may still be Architect's authenticated account; and
2. **how to reconcile the desktop roadmap/memory with GitHub when one or both sides have advanced independently.**

> **Never hide authorship. Never overwrite disagreement. Attribute the work and reconcile the knowledge.**

## 1. AI work provenance

GitHub authentication identifies the account that pushed a commit. It does **not** reliably identify which AI authored the implementation. XCSV therefore uses explicit commit-message trailers plus an execution-record receipt.

### Mandatory commit trailers for AI-authored commits

Every commit materially authored or edited by an AI must end with trailers in this form:

```text
XCSV-Agent: claude-code
XCSV-Agent-Role: primary
XCSV-Work-ID: GUARD-REL-002
XCSV-Contract: 1.0.0
```

Allowed `XCSV-Agent` values include:

- `claude-code`
- `opencode`
- `antigravity`
- `codex`
- `chatgpt`
- `local-llm:<stable-name>`
- `mixed` when human and AI materially co-authored the same commit
- `automation` for deterministic XCSV scripts that create commits

Do not invent an AI identity. If the exact model is not reliably known, do **not** guess it.

`XCSV-Agent-Role` should normally be one of:

- `orchestrator`
- `primary`
- `worker`
- `critic`
- `automation`

If the work has a roadmap/issue ID, `XCSV-Work-ID` is mandatory. If no stable ID exists yet for material work, create/reuse the GitHub execution issue first and assign an ID rather than pushing anonymous work.

`XCSV-Contract` records the XCSV AI operating-contract version used for the work.

### Optional model trailer

Only when the agent can establish its exact model identity without guessing:

```text
XCSV-AI-Model: <exact-model-id>
```

Omit it otherwise.

### Human-only commits

Human-only commits do not need an AI trailer. Do not label human work as AI work merely because an AI discussed the task.

If Architect and an AI materially co-authored the changed content, use:

```text
XCSV-Agent: mixed
```

and identify the AI participants in the GitHub issue receipt.

### Do not fake Git authors

Do not change `git config user.name`, `user.email`, signing keys, or GitHub account identity merely to make an AI look like a separate GitHub user. The normal authenticated Git identity remains intact. XCSV provenance trailers are attribution metadata, not cryptographic signatures.

Do not add fake `Co-authored-by` addresses for AI systems.

## 2. AI work receipt

For material work tracked by an issue, the AI that closes or hands off the work must leave a compact issue comment:

```text
XCSV AI WORK RECEIPT
Work ID: GUARD-REL-002
Agent: claude-code
Role: primary
Commits: <sha>, <sha>
Starting classification: PARTIAL
Final verdict: PASS_VERIFIED | PASS_CANDIDATE | BLOCKED | UNKNOWN
Verification: <tests/runtime evidence>
Desktop/GitHub docs: SYNCED | DESKTOP_AHEAD | GITHUB_AHEAD | DIVERGED | UNKNOWN
Remaining UNKNOWN: <only material items>
```

List critic/worker agents in the receipt when they materially participated, even when they did not create a commit.

The issue receipt is the searchable human-facing provenance record; commit trailers are the source-level provenance record.

## 3. Documentation authority is layered, not duplicated

The desktop and GitHub documentation do different jobs.

### Desktop roadmap / vault

`C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX\ROADMAP.md`

Authority for:

- current working priority and sequence
- decisions and operator intent
- refuted hypotheses and dead ends
- detailed live/runtime evidence
- temporary investigation state that is too operational or verbose for public GitHub docs

### GitHub wiki / roadmap

`D:\XCSV\wiki\` and the published GitHub copies

Authority for:

- shared durable engineering knowledge
- the public/operator roadmap summary
- AI operating contracts
- repository navigation and reproducible procedures

### Generated site docs

`D:\XCSV\docs\wiki\`

Generated output only. Never use generated Pages files as an independent authority and never reconcile by hand-editing them. Change `wiki\*.md` and run `build-docs.ps1`.

## 4. Documentation reconciliation states

During `READ_ONLY_BOOTSTRAP`, explicitly classify desktop/GitHub documentation state:

### SYNCED

Relevant durable knowledge agrees and the known reconciliation baseline is current.

### DESKTOP_AHEAD

Desktop contains relevant durable changes that GitHub has not yet absorbed.

### GITHUB_AHEAD

GitHub contains relevant durable planning/contract changes that the desktop roadmap has not yet absorbed.

### DIVERGED

Both sides contain unique or conflicting relevant information, or the relationship cannot be safely represented as one side simply being ahead.

### UNKNOWN

The AI cannot inspect both sides.

**Resolved 2026-08-07 (`XCSV-AI-001`).** The 2026-08-07 AI-contract work was assumed `DIVERGED`; the first SOVRAN-1 bootstrap confirmed that assumption was correct and then reconciled it. GitHub-only material (contract, provenance policy, tooling decision, GUARD development plan, Gauntlet) was absorbed into the desktop roadmap as Phase 15 by append; desktop-only material (measurements, RPT/PBO forensics, refuted hypotheses) stayed on the desktop and remains deliberately abstracted here. Neither side was overwritten. State is now `SYNCED`.

This resolution is a snapshot, not a standing guarantee. Classify the relationship again at every bootstrap; never inherit `SYNCED` from a previous session. Do not call either side a complete replacement for the other.

## 5. First reconciliation after returning to SOVRAN-1

When Architect first says **read the GitHub** after these GitHub-side changes arrive:

1. Enter `READ_ONLY_BOOTSTRAP`.
2. Do **not** run `git pull`, reset, checkout, merge, or overwrite the desktop roadmap before inspecting local dirty/unpushed state.
3. Run `D:\XCSV\tools\ai-reconcile.ps1`.
4. Read the complete desktop `ROADMAP.md`.
5. Read `D:\XCSV\wiki\Roadmap.md`, `AI-Start-Here.md`, this policy and the relevant owning-area docs.
6. Fetch remote refs when safe, but do not merge merely to learn what remote contains.
7. Identify desktop-only, GitHub-only and conflicting durable facts by roadmap ID/topic.
8. Preserve refuted hypotheses, evidence, timestamps, hashes, paths and UNKNOWNs from the desktop; do not collapse them into a shorter GitHub summary and then overwrite the desktop with that summary.
9. Preserve new GitHub planning/contracts that do not yet exist on desktop.
10. Build a concise **DOCUMENTATION RECONCILIATION PLAN** before editing either side.
11. Merge semantically: update the desktop roadmap as the full working memory, then update GitHub `wiki\` as the durable shared/public representation.
12. Run `build-memory-index.ps1`, `build-docs.ps1`, and `build-rag-index.ps1` after reconciliation.
13. Commit/push only after local working trees and generated outputs are understood.
14. Leave an issue receipt with the resulting desktop/GitHub state and exact relevant commit SHAs.
15. Only then classify the documentation layer `SYNCED`.

If the desktop roadmap has a local change whose meaning is unclear, preserve it and report the conflict. Do not delete it because GitHub lacks an equivalent line.

## 6. Anti-junk rules

To prevent the documentation estate from becoming duplicated and contradictory:

- **one canonical source per concept**; other surfaces use short summaries and links
- AI workflow canon: `wiki/AI-Start-Here.md` + this companion policy
- detailed GUARD programme: `wiki/XCSV-GUARD-Development-Plan.md`
- full operational roadmap: desktop `ROADMAP.md`
- shared/public roadmap summary: `wiki/Roadmap.md`
- generated Pages copies: never hand-maintained
- do not paste the full roadmap into README, CLAUDE, AGENTS, site home and wiki Home
- do not create `ROADMAP-v2`, `ROADMAP-new`, `final-roadmap`, duplicate wiki pages or AI-specific copies to avoid reconciling the real files
- use links, stable IDs and issue records rather than repeated prose
- archive/strike/refute wrong theories in the authoritative roadmap rather than silently removing history that prevents future duplicate work

## 7. Completion rule

An AI-authored GitHub change is not complete until:

1. commits carry XCSV provenance trailers;
2. the execution issue contains an AI work receipt when material;
3. code/runtime verification is represented honestly;
4. desktop/GitHub documentation state is declared;
5. required documentation/RAG reconciliation is complete or explicitly marked `DIVERGED`/`UNKNOWN`;
6. no generated doc was treated as an independent source;
7. no substantially equivalent task/issue/subsystem was duplicated.

## Governing rules

> **The pusher is not necessarily the authoring agent; record both realities.**

> **Synchronization is not copying. Reconciliation preserves unique knowledge from both sides.**

> **When documentation is stale or divergent, say so before changing it.**

> **Do not make a clean-looking repo by deleting evidence you have not understood.**
