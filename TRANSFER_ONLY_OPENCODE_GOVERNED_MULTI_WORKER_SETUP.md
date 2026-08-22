# TRANSFER ONLY — OpenCode Governed Multi-Worker Setup

**NOT XCSV AUTHORITY.** This file exists only as a transport artifact because the current OpenCode credential can read `x-cessive/XCSV` but cannot read the private `the-stack` repo. Do not interpret this file as XCSV product scope or authority. Do not merge this branch into `main`.

## Architect authorization

Set up the local SOVRAN multi-worker environment so one human-facing Unified SOVRAN session can coordinate genuinely independent repository-rooted Claude/OpenCode workers **without weakening project boundaries**.

This is infrastructure/setup only. Do not begin Fabric/CORPUS/XCSV feature work.

## Required topology

- Unified SOVRAN → `SOVRAN_COMMAND_DECK`
- Fabric Worker → `D:\CAGE\SOVRAN_RECONCILIATION_FABRIC`
- CORPUS Worker → `D:\DEV\THE-CORPUS`
- XCSV Worker → `D:\XCSV`

A new terminal tab, spawned subagent, or `cd` into another repo is **not** an independent governed workspace.

## Canonical state

- Command Deck main: `6cfd392d00c907e65089d598501bf5ad5a3c6cb7`
- the-stack main: `33b85b8b64ae07cc22c2d72547ad9349fd4dfc4e`
- THE-CORPUS main: `3247c0489a0cafd47dd5310e334843a713cd27ed`
- XCSV main: `75826989c975fbc96c58499322c9a1583603f12c`
- Fabric main: `18ae5525f8afa2e5ea7f827753ea34aa8812ef54`

Portfolio state: CORPUS-160 accepted/closed and HOLD; STACK-1800 accepted and HOLD; XCSV #37 accepted/closed while #30 remains open; Fabric #27 is READY_NOT_STARTED; BLACKSITE remains HOLD.

## Non-negotiable rules

Do not weaken/remove `sovran-policy-hook.mjs`; do not blanket-authorize `D:\DEV`, `D:\CAGE`, or `D:\`; do not disable `OUT_OF_WORKTREE`; do not use symlink/junction tricks; do not modify `SOVRAN_PROJECT_BOUNDARIES`; do not touch BLACKSITE; do not force-push/reset/clean away local residue; do not invent authority by editing control/state files.

## Task

1. **Discover the real Orca/OpenCode workspace mechanism.** Inspect workspace metadata/config, launch/session mechanisms, SOVRAN shell landing, policy-hook cwd/workspace binding, and relevant the-stack/Command Deck governance docs. Record evidence before changing anything.

2. **Normalize Unified SOVRAN.** Safely put the existing Command Deck workspace on canonical `main` if no tracked work would be lost. Preserve legitimate local/untracked material.

3. **Create/register real independent governed workspaces** for Fabric, CORPUS, and XCSV using the existing canonical checkouts if possible. Avoid duplicate clones unless technically required. Preserve Fabric's intentional untracked `Cargo.lock` and XCSV `tools/local-ai`.

4. **Verify each workspace identity** with a fresh read-only session. Record cwd, `git rev-parse --show-toplevel`, remote, branch, HEAD, repo identity, and workspace identity. If a Fabric/CORPUS/XCSV worker reports `SOVRAN_COMMAND_DECK`, setup FAILS.

5. **Verify isolation safely.** Prove each worker can mutate only its own governed root and sibling-project mutation remains denied. Do not weaken policy to make tests pass.

6. **Make launch repeatable.** Create the smallest safe Orca-native launcher/configuration for named entrypoints: Unified SOVRAN, Fabric Worker, CORPUS Worker, XCSV Worker. It must open a real governed workspace, not merely another terminal tab. If ownership for a wrapper is ambiguous, document and stop rather than inventing a control-plane root.

7. **Preserve machine-to-machine authority boundaries.** Do not bypass the denial preventing one AI session from silently injecting prompts into another. Document the future governed dispatch shape instead: `Architect → Unified SOVRAN → bounded work claim → governed dispatcher → repo-owned workspace → independent worker`.

8. **Leave next lanes ready, not running:** Fabric #27 = `READY_TO_DISPATCH`; CORPUS Claim Registry = `READY_FOR_MILESTONE_ACTIVATION`; XCSV #30 = `READY_TO_DISPATCH`.

## Acceptance

PASS only if fresh verification proves:

- Unified SOVRAN repo = `SOVRAN_COMMAND_DECK`
- Fabric worker repo = `SOVRAN_RECONCILIATION_FABRIC`
- CORPUS worker repo = `THE-CORPUS`
- XCSV worker repo = `XCSV`
- each has its own governed root
- cross-project mutation remains denied
- no policy hook was weakened
- BLACKSITE and SOVRAN_PROJECT_BOUNDARIES were untouched

Return **SOVRAN GOVERNED MULTI-WORKER SETUP REPORT** with the discovered workspace mechanism; workspace roots/repos/branches/HEADs/launch methods; isolation proof; Unified normalization result; repeatable launcher/config; remaining manual step(s); readiness of Fabric #27, CORPUS Claim Registry activation, and XCSV #30; collision status; and final verdict `PASS_GOVERNED_MULTI_WORKER_READY` or `BLOCKED_<reason>`.

Commit/push/document substantive infrastructure changes through the owning repository according to its governance. Do not leave important setup truth only in the OpenCode transcript. STOP for Architect review after the report.