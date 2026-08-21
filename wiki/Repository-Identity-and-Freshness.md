# Repository Identity and Freshness

> **Status:** XCSV reference-model material under `XCSV-REPO-001`.
>
> This page explains repository identity and observation semantics. It does **not** grant execution authority and does not replace the XCSV AI contract, roadmap, runtime evidence, or member-repository source.

## Three things that must never be collapsed

### Identity

**What repository is this, what does it own, and where should work be routed?**

Machine-readable source:

- `registry/repository-identity.json`
- schema: `registry/repository-identity.schema.json`

Identity includes both:

- `canonical_for`
- `not_canonical_for`

The negative boundary is deliberate. An AI must be able to determine not only what XCSV owns, but what it must route elsewhere.

### State

**What was actually observed, from which source, and how fresh is that observation?**

Machine-readable source:

- `registry/current-state.json`
- schema: `registry/current-state.schema.json`

State is recorded per source. Valid freshness vocabulary:

- `VERIFIED_CURRENT`
- `NOT_REVERIFIED`
- `STALE`
- `UNKNOWN`

One current source never makes the whole system current. A freshly inspected GitHub branch does not refresh the local SOVRAN-1 worktree, desktop roadmap, live server, deployed artifacts, published GitHub Wiki or Pages deployment.

### Authority

**What may happen?**

Repository identity and current-state observations are never authority.

The XCSV AI contract still requires reconciliation before mutation. Roadmap status remains intent rather than implementation proof. Operational actions require the authority and evidence appropriate to their scope.

## XCSV hub boundary

XCSV is the project hub for durable project-level navigation, wiki/docs, roadmap context, AI bootstrap/provenance and shared tooling.

It is **not** the implementation authority for every XCSV subsystem.

| Repository | Owning role |
|---|---|
| `x-cessive/XCSV` | project hub, shared docs/wiki/tooling and estate map |
| `x-cessive/XCSV_GUARD` | GUARD Rust application source, tests, build/deploy tooling |
| `x-cessive/XCSV_ADDONS` | first-party XCSV addon and mission-module source |
| `x-cessive/XCSV_ORCH` | XCSV-specific orchestration implementation source |
| `x-cessive/Exile` | third-party catalogue/reference estate and packaging/tooling context |

The hub may route to a member repository. That route does not silently grant write or execution authority in the child.

## Documentation supply chain

XCSV's documentation model remains:

```text
wiki/*.md
   canonical Git-tracked documentation source
        |
        +--> tools/build-docs.ps1 --> docs/wiki/*.md
        |                            generated Pages source
        |
        +--> tools/push-wiki.ps1 --> XCSV.wiki.git
                                     published GitHub Wiki
```

`docs/wiki/` is generated and is not hand-maintained authority.

The published GitHub Wiki is also a projection. Its freshness must be verified separately from the tracked `wiki/` source.

## Cold rehydration

Machine-readable contract:

- `registry/cold-rehydration.contract.json`

Purpose:

> A fresh AI with no prior chat/session context should be able to identify repository scope, authority boundaries, freshness, member routing, documentation obligations and stop conditions from repository truth alone.

The contract is read-only. Its existence is not a PASS. A PASS requires a fresh-agent evaluation against a committed candidate and an independently recorded result.

## Rules for README and wiki prose

1. Prefer durable identity and architecture in narrative docs.
2. Route volatile state to a freshness-aware state surface.
3. If a volatile fact must appear in prose, identify its observation time/source or label it as not reverified.
4. Do not rewrite historical reports to make them look current.
5. Do not render `UNKNOWN` as healthy, zero or absent.
6. Do not infer runtime deployment from source presence.
7. Do not infer authority from capability, repository access, issue state or roadmap order.

## Relationship to existing refactor work

This work is additive to existing XCSV lanes:

- Issue #29 owns the system-wide XCSV refactor programme.
- Issue #31 owns README/wiki/generated-documentation authority cleanup.
- Issue #37 owns refactor guardrails and CI/audit integration.
- Issue #39 owns the missing identity/freshness/cold-rehydration model.

Do not create parallel substitutes for those lanes.
