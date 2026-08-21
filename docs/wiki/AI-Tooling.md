---
layout: wiki
section: docs
title: AI / Development Tooling
heading: AI / Development Tooling
blurb: Selected, optional and rejected workflow tools, with the reason for each decision.
order: 3
source: AI-Tooling.md
generated: true
source_authority: wiki/AI-Tooling.md
---

<!-- GENERATED FROM wiki/AI-Tooling.md BY tools/build-docs.ps1. DO NOT EDIT docs/wiki BY HAND. -->

This page records tooling choices that affect XCSV's AI-assisted development workflow. Its purpose is to prevent every new AI session from re-evaluating the same project-management products and accidentally creating another source of truth.

## Decision rule

> **Prefer tools that strengthen GitHub/local evidence. Avoid tools that duplicate roadmap, issue or execution state.**

XCSV currently has enough moving parts: four repositories, local authoritative roadmap/memory, live deployment state, runtime evidence and multiple development AIs. A second independent task database creates more reconciliation work, not less.

## Selected now

### GitHub Issues + GitHub Projects — PRIMARY EXECUTION TRACKER

**Decision: USE.**

Why:

- issues live beside the source repositories and commits they describe
- one issue can be linked to branches, commits, PRs and sub-issues
- Projects can present the same underlying work as tables, boards and roadmap views
- custom fields can carry XCSV-specific reconciliation and Gauntlet metadata
- GitHub CLI lets Claude/other agents query and maintain the tracker from the server
- no external synchronization layer is required

XCSV workflow:

`BACKLOG -> RECONCILE -> READY -> IN PROGRESS -> VERIFY -> DONE`

Use `BLOCKED` explicitly.

See [AI Start Here](AI-Start-Here.html) for first-run setup and the roadmap reconciliation contract.

### GitHub CLI — PRIMARY REMOTE COMMAND SURFACE

**Decision: USE.**

Use `gh` for GitHub issues, PRs, Projects, authentication checks and other remote operations that cannot be proven from local `git` alone.

Do not let remote commands overwrite dirty local working trees. Local source reconciliation happens first.

### Official GitHub MCP Server — OPTIONAL ENHANCEMENT

**Decision: OPTIONAL / RECOMMENDED AFTER BASELINE WORKFLOW IS VERIFIED.**

Useful for MCP-capable development agents that benefit from direct remote repository, issue, PR and workflow context.

Rules:

- official GitHub MCP only
- OAuth preferred where supported
- no token/PAT committed to git
- minimum required scope
- no duplicate MCP registration
- local source/live evidence still outrank remote GitHub for their respective facts
- XCSV workflow must remain functional without MCP

GitHub documentation: <https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp-in-your-ide/set-up-the-github-mcp-server>

## Future candidate

### Linear

**Decision: DO NOT ADOPT YET. RE-EVALUATE ONLY IF GITHUB PROJECTS BECOMES A REAL BOTTLENECK.**

Linear is the strongest external candidate because its GitHub integration is deep and its current agent features can launch coding sessions through Claude Code or Codex.

Why it is not selected now:

- it would create another issue/project state layer immediately after XCSV standardized GitHub as the execution tracker
- XCSV first needs to prove the canonical reconciliation contract and GitHub Project workflow on the real server
- adopting Linear only makes sense if a measurable limitation remains after that

Trigger for reconsideration: GitHub Projects demonstrably cannot support an XCSV workflow requirement without fragile custom automation.

Official integration: <https://linear.app/integrations/github>

## Not selected

### Waffle

**Decision: DO NOT USE.**

Legacy/discontinued GitHub-board product. It does not belong in a new XCSV workflow.

### GitKraken Glo Boards / GitKraken Boards

**Decision: DO NOT USE.**

GitKraken Boards and Timelines were sunset at the end of 2022. Current GitKraken documentation treats Boards as a legacy integration.

Official notice: <https://help.gitkraken.com/gitkraken-desktop/boards/>

### Trello

**Decision: DO NOT USE AS XCSV TASK AUTHORITY.**

The GitHub Power-Up can attach branches, commits, issues and PRs to Trello cards, but that still creates a separate card/task state requiring synchronization.

### Jira

**Decision: DO NOT USE CURRENTLY.**

Powerful and appropriate for larger organizational software processes, but unnecessary overhead for the current XCSV workflow. GitHub already owns the code, issues, PRs and execution records.

### Asana

**Decision: DO NOT USE CURRENTLY.**

Its GitHub integration is useful for cross-functional/business coordination and PR-status visibility. XCSV does not currently need a second non-engineering task system.

### Monday.com / monday dev

**Decision: DO NOT USE CURRENTLY.**

Provides substantial GitHub issue/PR integration, but duplicates the selected GitHub-native development tracker.

### Wrike

**Decision: DO NOT USE CURRENTLY.**

Wrike can two-way sync tasks and GitHub issues, which is precisely another synchronization boundary XCSV is trying to remove.

### Kanban Tool

**Decision: DO NOT USE CURRENTLY.**

Can be connected to GitHub through integration/automation services, but provides no XCSV advantage over GitHub Projects sufficient to justify another board and sync layer.

## Additional tools worth adding to the XCSV roadmap

### GitHub Actions — deterministic drift / documentation checks

**Recommendation: HIGH.**

Add read-only CI checks that fail when deterministic project invariants drift, for example:

- all AI adapters declare the expected `XCSV-AI-CONTRACT` version
- required AI entrypoint files exist in every member repository
- `wiki/` and generated `docs/wiki/` are in sync
- required documentation pages are published by `build-docs.ps1`
- roadmap IDs referenced by commits/issues use the expected format
- member-repo submodule pointers are intentionally updated
- GUARD tests/build/release checks remain healthy

CI should detect drift, not auto-rewrite authoritative roadmap decisions.

### Dependabot — dependency update visibility

**Recommendation: MEDIUM-HIGH FOR XCSV_GUARD.**

Use conservatively for Rust/GitHub Actions dependencies once GUARD CI is stable. Prefer grouped/low-noise update cadence rather than a flood of automatic PRs.

GitHub documentation: <https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates>

### RustSec `cargo audit`

**Recommendation: HIGH FOR XCSV_GUARD.**

Add dependency vulnerability auditing to the Rust verification path. A finding should enter the normal reconciliation/Gauntlet workflow rather than being auto-fixed directly in production.

RustSec: <https://github.com/rustsec/rustsec/tree/main/cargo-audit>

### GitHub sub-issues and blocked-by relationships

**Recommendation: USE.**

Use these for true work decomposition and dependencies so the Gauntlet's specialist work can still roll up to one parent roadmap item without creating unrelated cards.

### GitHub issue-linked development branches

**Recommendation: USE WHERE IT IMPROVES TRACEABILITY.**

For material implementation, link the branch to the issue so an AI can recover the active work relationship across sessions.

### Backlog.md / repo-local AI boards

**Recommendation: WATCH, DO NOT ADOPT AS TASK AUTHORITY.**

Repo-local Markdown boards are attractive for offline/agent workflows, but adopting one now would create another task representation. Reconsider only if it can function as a generated/read-only view of GitHub Issues rather than an independent tracker.

## Tooling principle

> **A useful XCSV tool either strengthens evidence, reduces repeated discovery, or automates a deterministic check. If it merely copies state into another dashboard, it is probably negative value.**

## Related

- [AI Start Here](AI-Start-Here.html)
- [Roadmap](Roadmap.html)
- [XCSV GUARD Development Plan](XCSV-GUARD-Development-Plan.html)
