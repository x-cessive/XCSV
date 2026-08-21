---
layout: wiki
section: docs
title: Repositories
heading: Repositories
blurb: Five repositories, one XCSV project: what lives where, and why.
order: 9
source: Repositories.md
generated: true
source_authority: wiki/Repositories.md
---

<!-- GENERATED FROM wiki/Repositories.md BY tools/build-docs.ps1. DO NOT EDIT docs/wiki BY HAND. -->

Five repositories currently make up the XCSV GitHub project family. The XCSV hub carries shared documentation, project-level navigation/tooling and selected submodule pointers; implementation source remains in the owning member repository.

Machine-readable hub identity and relationships are also recorded in `registry/repository-identity.json`.

| repo | visibility | submodule path in hub | owning role |
|---|---|---|---|
| [XCSV](https://github.com/x-cessive/XCSV) | public | — | project hub, site/wiki source, shared project tooling and estate map |
| [XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD) | private | `guard/` | Rust operations-console application source, tests, build/deploy tooling |
| [XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS) | private | `addons/` | first-party XCSV addons and mission modules |
| [XCSV_ORCH](https://github.com/x-cessive/XCSV_ORCH) | private | — | XCSV-specific Gauntlet/orchestration source, routing and isolation tooling |
| [Exile](https://github.com/x-cessive/Exile) | public | `catalogue/` | third-party catalogue/reference estate plus separated live-source/packaging/tooling context |

The hub is **public** because it provides the public XCSV documentation/site surface. Private member-repository source must not be copied into the public hub merely to improve discoverability.

## Identity, state and authority

Repository membership answers **where to route**, not **what is authorized**.

- `registry/repository-identity.json` describes XCSV hub identity and member relationships.
- `registry/current-state.json` records per-source observation/freshness.
- The XCSV AI contract defines reconciliation-before-mutation behavior.
- Member repositories remain authoritative for their own implementation source.
- GitHub source presence is never sufficient proof of live runtime/deployment state.

See [Repository Identity & Freshness](Repository-Identity-and-Freshness.html).

## Working copies on disk — historical/documented layout

The paths below are retained because they are operationally useful history. During the XCSV-REPO-001 reconciliation, `D:\XCSV` was inspected and preserved; the other local/runtime paths in this table remain `NOT_REVERIFIED` unless `registry/current-state.json` records a newer observation.

| documented path | repository / role |
|---|---|
| `D:\XCSV` | XCSV hub |
| `D:\XCSV_GUARD` | GUARD console |
| `D:\XCSV_ORCH` | XCSV orchestration source (documented canonical source in its own repo README) |
| `E:\XCSV_ADDONS` | XCSV addons |
| `E:\ExileRepo` | Exile catalogue/source checkout |
| `E:\arma3server` | live server deployment target (**not** a repo) |
| `E:\ArmaTools\mission\Exile.Tanoa` | documented mission/deployment working path (**not** a repo) |
| `C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX` | documented desktop roadmap/vault location |

Do not use this table to infer current filesystem state. Reverify before mutation, deployment or recovery work.

## XCSV_GUARD layout

The owning repository is `x-cessive/XCSV_GUARD`. The following paths describe the documented GUARD source architecture and should be rechecked against the current GUARD HEAD when exact implementation detail matters.

| path | purpose |
|---|---|
| `src/app.rs` | UI and application state |
| `src/theme.rs` | palette, type scale, composite widgets |
| `src/pbo.rs` | PBO reader and integrity checker |
| `src/rcon.rs` | BattlEye RCon client |
| `src/server.rs` | process supervision and server/log handling |
| `src/stack.rs` | stack orchestration |
| `src/ai.rs` | local-model client boundary |
| `src/metrics.rs` | performance history/metrics handling |
| `src/secrets.rs` | credential-at-rest handling |
| `tools/deploy.ps1` | GUARD deployment workflow |
| `tools/capture.ps1` | publishable screenshot/media capture |
| `tools/doctor.ps1` | executable diagnostic assertions |

Deploy through the owning repository's established tooling; do not infer current deploy semantics from this hub summary when the GUARD repo has newer evidence.

Any GUARD behavior or UI change must also refresh GitHub-facing screenshots/GIFs as required by the current XCSV agent contract.

## XCSV_ADDONS layout

The owning repository is `x-cessive/XCSV_ADDONS`.

Historically documented core surfaces include:

| path | side | notes |
|---|---|---|
| `xcsv_chatter/` | server | first-party XCSV server-side module source |
| `mission/` | client/mission | first-party XCSV mission-side source |

Exact deployment mirror/canonical-source relationships are being reconciled under the active XCSV refactor programme; do not create a second hand-maintained copy merely because a deployment mirror exists.

## XCSV_ORCH boundary

`x-cessive/XCSV_ORCH` owns the XCSV-specific AI-workforce orchestration implementation: routing, authority envelopes, isolation enforcement, worker registry, tests and deployment tooling.

The XCSV hub documents and routes to ORCH but does not become the orchestration source authority. XCSV_ORCH also remains distinct from the SOVRAN platform `the-stack`; no merge or authority transfer is implied by similar capability.

## Exile boundary

`x-cessive/Exile` contains a mixed estate: third-party catalogue/reference material and first-party packaging/live-source/tooling context.

Catalogue presence is not evidence that a component is currently deployed. Preserve upstream attribution/licensing and distinguish historical install evidence from current source wiring and runtime verification.

## Keeping the hub honest

The three configured hub submodules are currently:

- `guard/` -> XCSV_GUARD `master`
- `addons/` -> XCSV_ADDONS `master`
- `catalogue/` -> Exile `master`

`XCSV_ORCH` is a project member but is not currently configured as a hub submodule.

Submodule pointers can go stale silently. Established XCSV reconciliation tooling should verify/publish pointer changes only after the member repository's source state is understood; do not blindly update a dirty local hub.

## House rules that remain relevant

- Preserve third-party provenance and licensing.
- Prefer bounded module initialization over duplicate global/event/scheduler hooks.
- Verify packed entry paths, not just artifact checksums.
- Do not infer LIVE from README/catalogue presence.
- Do not collapse project-hub routing into child-repository write authority.
- Reconcile local/source/runtime truth before high-risk changes.

## Related

- [Repository Identity & Freshness](Repository-Identity-and-Freshness.html)
- [Architecture](Architecture.html)
- [System Components](System-Components.html)
- [Runbook](Runbook.html)
