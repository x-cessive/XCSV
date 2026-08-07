# AI Start Here

**XCSV-AI-CONTRACT: 1.0.0**

This is the canonical operating contract for AI-assisted work across the XCSV Arma 3 Exile estate.

> **Core rule:** Never begin from what the roadmap says needs building. Begin by proving what remains to be built.

The desktop `C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX\ROADMAP.md` remains the authoritative full roadmap for priority, decisions, sequencing, refuted hypotheses and live operating memory. This GitHub document defines **how an AI must interpret and reconcile that roadmap before acting**.

## Trigger phrases

When Architect says any equivalent of:

- **read the GitHub**
- **read GitHub**
- **read the roadmap**
- **get caught up**
- **resume XCSV**
- **see what is next**

enter **READ_ONLY_BOOTSTRAP** first.

Do not implement, repair, deploy, commit, pull over dirty work, repack PBOs, change the database, change BattlEye, or mutate the live server during bootstrap unless Architect explicitly combines the request with authority to proceed.

## READ_ONLY_BOOTSTRAP

1. Read this contract completely.
2. Read the local authoritative desktop `ROADMAP.md` if available.
3. Run `D:\XCSV\tools\ai-reconcile.ps1` and inspect every repo it reports.
4. Use `D:\XCSV\tools\search-rag.ps1 -Query "<target terms>"` before broad filesystem archaeology.
5. Inspect the relevant local working tree before trusting GitHub: current branch, `git status`, current commit, uncommitted changes and relevant target files.
6. Compare the local commit to the remote branch without assuming GitHub is newer or authoritative for live state.
7. Inspect recent relevant commits and existing implementation before proposing new code.
8. Inspect relevant open GitHub issues/project items before creating a new execution record.
9. If the claim is operational, inspect the relevant live evidence: deployed artifact, RPT/HC RPT, database query, process state, GUARD state, BattlEye/infiSTAR logs or other source of truth.
10. Classify the requested/next roadmap item using the reconciliation states below.
11. Identify only the **remaining delta**.
12. Select the Gauntlet risk level.
13. Report a concise **XCSV BOOTSTRAP REPORT** before implementation.

## Authority hierarchy

Different sources answer different questions. Do not flatten them into one truth source.

| source | authority |
|---|---|
| Desktop `ROADMAP.md` | priority, intent, decisions, sequence, rejected/refuted paths |
| Local working tree | what code/files actually exist on this machine now |
| Local git history | what has been committed locally |
| GitHub remote | what has been published/pushed |
| GitHub Issues / Project | active execution record, ownership, current workflow state |
| Hub submodule pointers | which member-repo commits the hub currently references |
| Live server/deployed artifacts | what is actually deployed/running |
| Runtime evidence | whether the deployed behavior actually worked |
| Wiki/README/site | durable explanation and navigation; not proof by itself |

If these disagree, **the disagreement is the finding**. Do not silently choose the most convenient source.

## Roadmap Reconciliation Gate

Before implementation, assign exactly one state to the target:

### VERIFIED_DONE

Equivalent functionality exists **and the required verification evidence exists**.

Action: do not rebuild. Correct stale roadmap/wiki/issues if needed.

### PRESENT_UNVERIFIED

Implementation appears to exist, but required test/runtime/deployment proof is missing.

Action: do not rebuild. Verify the existing implementation.

### PARTIAL

Some required behavior exists.

Action: identify and implement only the missing delta. Do not create a parallel subsystem.

### PLANNED_ONLY

Roadmap/design exists but implementation does not.

Action: implementation may proceed after Target Lock and the appropriate Gauntlet.

### STALE_OR_CONFLICTED

Roadmap, local source, GitHub, submodules, docs or runtime evidence disagree materially.

Action: stop implementation, record the conflict and resolve authority/state first.

### BLOCKED

A required dependency, permission, environment, evidence source or decision is unavailable.

Action: preserve what is known and report the blocker without fabricating progress.

## Delta-first rule

After reconciliation ask:

> **What is the smallest remaining delta between the target behavior and what already exists?**

Do not restart from a blank-sheet design when 70-90% of the target already exists. Extend, repair, verify or document the existing path unless Architect explicitly authorizes replacement.

This is especially important for Exile because duplicate `CfgExileCustomCode` registrations, duplicate schedulers, duplicate network handlers and parallel mission systems can actively break production.

## XCSV BOOTSTRAP REPORT

Keep it short and factual:

```text
XCSV BOOTSTRAP REPORT
Contract: XCSV-AI-CONTRACT 1.0.0
Mode: READ_ONLY_BOOTSTRAP
Target: <roadmap item or requested area>

Roadmap: <what it says>
RAG/history: <relevant prior result/refuted hypotheses>
Local repo: <branch / clean-dirty / commit>
GitHub: <same commit / mismatch / unknown>
Issue/Project: <existing execution record / none / conflict>
Live evidence: <verified / unavailable / not required>
Classification: VERIFIED_DONE | PRESENT_UNVERIFIED | PARTIAL | PLANNED_ONLY | STALE_OR_CONFLICTED | BLOCKED
Remaining delta: <smallest actual missing work>
Gauntlet: G0 | G1 | G2 | G3 | G4
Conflicts/UNKNOWN: <only material items>
```

If Architect only said **read the GitHub**, stop after the bootstrap report and wait for the next instruction.

## Gauntlet after reconciliation

Reconciliation happens **before** the Gauntlet.

`READ -> RECONCILE -> CLASSIFY -> DELTA -> TARGET LOCK -> GAUNTLET -> VERIFY -> DURABLE SYNC`

Canonical Gauntlet flow:

`TARGET LOCK -> RECON -> DECOMPOSE -> WORKERS -> ADVERSARIAL CRITICS -> INTEGRATION -> MEASUREMENT -> EVIDENCE -> VERDICT`

Risk levels:

- **G0** documentation/trivial local work
- **G1** isolated implementation; worker + critic
- **G2** cross-component work; specialists + critic + integration review
- **G3** production-affecting Arma/Exile work; recon + specialists + security/performance review + rollback + runtime evidence
- **G4** architecture, persistence, DB mutation, BattlEye/security or deployment infrastructure; full Gauntlet + independent verification

Worker may not self-certify. Keep **EVIDENCED / INFERRED / UNKNOWN** distinct. Record refuted hypotheses.

## Work tracking: GitHub is primary

To avoid double work, XCSV uses **GitHub Issues + GitHub Projects** as the execution tracker. The roadmap remains the priority/decision memory; an issue is the active execution record.

Do not introduce Trello, Jira, Asana, Monday, Wrike, Kanban Tool, Linear or another board as a second task authority unless Architect explicitly changes this rule.

For material roadmap work:

1. Give the item a stable ID when it becomes active, e.g. `GUARD-REL-002`.
2. Search existing issues before creating one.
3. Use one GitHub issue as the execution record.
4. Use sub-issues for genuinely separable work, not every tiny code edit.
5. Link commits/PRs to the issue or stable ID.
6. Do not mark Done until verification and durable-sync requirements are satisfied.

Recommended GitHub Project workflow:

`BACKLOG -> RECONCILE -> READY -> IN PROGRESS -> VERIFY -> DONE`

Use `BLOCKED` as an explicit state, not a hidden comment.

Useful fields:

- Roadmap ID
- Owning repo
- Priority
- Reconciliation state
- Gauntlet level
- Verification state
- Target date only when real

Keep the same GitHub issue as the underlying work item rather than duplicating cards in another tracker.

## First-run GitHub Projects setup

This setup is authorized as part of XCSV's GitHub-native execution workflow, but it must happen only after local repository reconciliation so no dirty local work is overwritten.

On the first real SOVRAN-1 bootstrap:

1. Confirm GitHub CLI authentication:

```powershell
gh auth status
```

2. Ensure the token has GitHub Projects scope:

```powershell
gh auth refresh -s project
```

3. List existing projects before creating anything:

```powershell
gh project list --owner x-cessive
```

4. If an equivalent XCSV execution project already exists, use it. **Do not create a duplicate.** If none exists, create one:

```powershell
gh project create --owner x-cessive --title "XCSV Development"
```

5. Record the returned project number. Add fields only if equivalent fields do not already exist:

```powershell
gh project field-create <PROJECT_NUMBER> --owner x-cessive --name "Roadmap ID" --data-type TEXT
gh project field-create <PROJECT_NUMBER> --owner x-cessive --name "Owning Repo" --data-type SINGLE_SELECT --single-select-options "XCSV,XCSV_GUARD,XCSV_ADDONS,Exile,Cross-repo"
gh project field-create <PROJECT_NUMBER> --owner x-cessive --name "Reconciliation" --data-type SINGLE_SELECT --single-select-options "VERIFIED_DONE,PRESENT_UNVERIFIED,PARTIAL,PLANNED_ONLY,STALE_OR_CONFLICTED,BLOCKED"
gh project field-create <PROJECT_NUMBER> --owner x-cessive --name "Gauntlet" --data-type SINGLE_SELECT --single-select-options "G0,G1,G2,G3,G4"
gh project field-create <PROJECT_NUMBER> --owner x-cessive --name "Verification" --data-type SINGLE_SELECT --single-select-options "NOT_REQUIRED,NOT_STARTED,IN_PROGRESS,PASS,BLOCKED"
```

6. Add the bootstrap issue to the project:

```powershell
gh project item-add <PROJECT_NUMBER> --owner x-cessive --url https://github.com/x-cessive/XCSV/issues/1
```

7. Pin the bootstrap issue in the hub repo:

```powershell
gh issue pin 1 --repo x-cessive/XCSV
```

8. Configure useful project views in the GitHub UI if needed: table for reconciliation/detail, board for workflow, roadmap only for items with real dates. Do not invent deadlines merely to populate a roadmap view.

9. Before creating any future issue, search first:

```powershell
gh issue list --repo x-cessive/XCSV --state all --search "<roadmap id or target terms>"
```

## Optional GitHub MCP enhancement

The normal XCSV workflow does **not** require MCP: local git, GitHub CLI, the canonical contract and `ai-reconcile.ps1` are sufficient.

However, the official GitHub MCP Server is a useful optional enhancement for Claude/other MCP-capable development agents because it can expose remote repository, issue, PR and workflow context directly to the agent.

Rules:

- use GitHub's official MCP server only
- prefer OAuth where supported
- never commit PATs/tokens into `.mcp.json`, `CLAUDE.md`, repo config or shell scripts
- scope credentials to the minimum needed
- MCP remote state does not outrank the local working tree or live server
- if MCP is unavailable, the workflow must still work through `git` / `gh`

If Claude Code on SOVRAN-1 supports the official remote GitHub MCP flow and Architect wants it enabled, Claude should first inspect existing MCP configuration with `/mcp` / Claude's MCP commands and **avoid adding a duplicate server**. Authentication remains local/user-scoped rather than committed with a secret.

## Completion transaction

Implementation is not complete merely because code exists or was pushed.

For applicable work, close the loop in this order:

1. verify the implementation and print/read back changed regions
2. run required tests/checks
3. collect runtime evidence where the claim is operational
4. commit the owning repository
5. update authoritative desktop roadmap and owning area note
6. update Git-tracked wiki/source documentation
7. run `D:\XCSV\tools\build-memory-index.ps1`
8. run `D:\XCSV\tools\build-docs.ps1`
9. run `D:\XCSV\tools\build-rag-index.ps1`
10. update the GitHub issue/project state
11. commit/push the hub docs and member-repo/submodule pointer changes as appropriate
12. verify local vs remote state and report exact commits plus remaining UNKNOWNs

If the desktop roadmap cannot be updated in the current environment, say so explicitly and leave a visible GitHub planning-state divergence marker rather than pretending synchronization happened.

## Native AI adapters

### Claude Code

The XCSV hub contains `CLAUDE.md`, which imports this contract automatically. Member repositories route Claude back to this contract. Claude Code project instructions are Git-tracked; do not rewrite global `%USERPROFILE%\.claude` settings unless Architect explicitly asks.

### OpenCode

The hub `AGENTS.md` points here and `opencode.json` includes this file as project instructions. Member repos also contain `AGENTS.md` routers.

### Antigravity

The repos include `.agents/rules/00-xcsv-ai-entrypoint.md`. Workspace rules should be **Always On**. If Antigravity has not activated the committed workspace rule, set it to Always On once; do not create a competing copy of this contract.

### Development-local LLMs

Give them this contract plus the specific target evidence they need. Runtime GUARD local models are excluded: they remain tool-less, untrusted, non-load-bearing classifier/explainer components.

## First server-side setup after pulling these changes

When Architect returns to SOVRAN-1/XCSV and starts Claude Code:

1. Start Claude from the relevant XCSV repo.
2. Say **"read the GitHub"**.
3. Claude should discover its repo-local adapter, read this contract, locate the desktop roadmap and run `D:\XCSV\tools\ai-reconcile.ps1`.
4. Claude should inspect Issue `XCSV-AI-001` / hub Issue #1 and existing GitHub Projects state.
5. If the GitHub Project is not yet configured, follow **First-run GitHub Projects setup** above rather than inventing another tracker.
6. If a member repo adapter or local checkout is missing, Claude should report exactly what is missing and repair only the Git-tracked project setup after checking for local uncommitted work.
7. Do not run `/init` blindly over existing instruction files. Existing XCSV instruction files are deliberate and should be extended, not replaced.
8. Return the `XCSV BOOTSTRAP REPORT` before implementation.

No additional global Claude configuration is required for the normal XCSV workflow.

## Governing efficiency rules

> **Roadmap status is intent, not implementation proof.**

> **GitHub absence is not proof that local/live work does not exist.**

> **Source presence is not proof of runtime success.**

> **Do not duplicate substantially equivalent functionality. Find the delta.**

> **If sources disagree, reconcile before implementation.**

> **A completed change leaves code, evidence and durable memory aligned.**
