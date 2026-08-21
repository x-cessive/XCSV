# XCSV AI Start Here

**XCSV-AI-CONTRACT: 1.0.0**

You are in `x-cessive/XCSV`, the XCSV project hub. This repository routes work, records evidence, owns the canonical wiki source, and publishes generated documentation. It is not the live server and it is not the implementation authority for every member repository.

Read these before acting:

1. `registry/repository-identity.json`
2. `registry/current-state.json`
3. `wiki/AI-Start-Here.md`
4. `wiki/AI-Provenance-and-Doc-Sync.md`
5. the GitHub issue/PR that authorizes the current work

## What XCSV Is Canonical For

- project-hub navigation and repository-family routing
- `wiki/` canonical documentation source and `docs/wiki/` generated projection
- AI bootstrap, provenance, documentation-sync, and cold-rehydration contracts
- hub tooling, memory/RAG tooling, and member-repository pointers
- project-level component registry and evidence maps

## What XCSV Is Not Canonical For

- `x-cessive/XCSV_GUARD` Rust application source
- `x-cessive/XCSV_ADDONS` first-party addon/module source
- `x-cessive/XCSV_ORCH` orchestration implementation source
- `x-cessive/Exile` third-party catalogue and LiveSource implementation source
- live server health, deployed PBOs, live DB, live BattlEye, RPT/boot, or player-runtime behavior unless those exact sources were inspected
- portfolio-wide SOVRAN authority

## Freshness Rule

`registry/current-state.json` records observations only. A prior `VERIFIED_AT_OBSERVATION` entry is not standing `CURRENT` truth. Derive live freshness by comparing the recorded identity to the actual source at read time.

If a source is unavailable, stale, or uninspected, report `UNKNOWN`, `STALE`, or `NOT_REVERIFIED`. Do not promote GitHub source presence into runtime/deployment truth.

## Documentation Authority

Edit canonical docs in `wiki/`. Regenerate `docs/wiki/` with `tools/build-docs.ps1`. Do not hand-maintain generated Pages output as authority. Publish the live GitHub Wiki only from `wiki/` through the established publication mechanism and only when authorized.

## Completion Obligations

For any substantive work:

- preserve evidence and exact SHAs;
- run the relevant validation checks;
- update docs generated from changed canonical source;
- record documentation impact and completion impact;
- post a GitHub receipt when the issue/PR workflow requires it.

## Stop Conditions

Stop instead of proceeding if repository identity is wrong, the worktree has unexpected local changes, authorization points to another issue/repo, required live evidence is unavailable for a live claim, or the task would mutate member repositories, runtime state, deployed artifacts, secrets, `BLACKSITE`, `SOVRAN_PROJECT_BOUNDARIES`, or `the-stack/CONTROL.md` without explicit authority.

For the full contract, continue in [wiki/AI-Start-Here.md](wiki/AI-Start-Here.md).
