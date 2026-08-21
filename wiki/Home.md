# XCSV

XCSV is the project hub for a Tanoa-based Arma 3 Exile server estate. It provides the public documentation surface, repository-family map, evidence-backed component registry, AI/provenance contracts, and shared tooling that help humans and AIs work without confusing source, deployment, and runtime truth.

> **AI / AGENT START HERE:** begin at the root `AI-START-HERE.md`, then read [AI Start Here](AI-Start-Here), [Repository Identity & Freshness](Repository-Identity-and-Freshness), and [AI Provenance & Doc Sync](AI-Provenance-and-Doc-Sync) before interpreting roadmap state or creating commits.

> **documentation state: `UNKNOWN`:** this page records the documentation reconciliation state required by the AI contract. Treat GitHub Wiki and Pages publication as unverified unless a later receipt proves synchronization from merged canonical `wiki/` source.

## What Makes Up XCSV

| repository | owns |
|---|---|
| `x-cessive/XCSV` | project hub, canonical wiki source, generated docs relationship, registry, AI/provenance contracts, shared tooling |
| `x-cessive/XCSV_GUARD` | native Rust/egui operations console, tests, build/deploy tooling |
| `x-cessive/XCSV_ADDONS` | first-party XCSV addons and mission modules |
| `x-cessive/XCSV_ORCH` | XCSV-specific AI/Gauntlet orchestration implementation |
| `x-cessive/Exile` | third-party catalogue/reference estate plus separated LiveSource custody |

The hub routes to member repositories. It does not replace their source authority.

## What Is Verified

- Repository identity and routing are recorded in `registry/repository-identity.json`.
- Source observations are recorded in `registry/current-state.json`.
- The source inventory from issue #30 is accepted as `PARTIAL_INVENTORY / PARTIAL_SOURCE_VERIFIED`.
- Component counts and concrete source-wiring evidence belong to [System Components](System-Components) and `registry/components.json`, not this front door.
- Canonical wiki source is `wiki/`; generated Pages projection is `docs/wiki/`.

## What Is Not Verified By This Wiki

This wiki does not prove live server health. Unless a newer receipt records actual inspection, these remain `NOT_REVERIFIED` or `UNKNOWN`:

- deployed PBOs and hashes;
- loaded `-mod` / `-servermod` command line;
- RPT/boot evidence;
- live database state;
- live BattlEye filters;
- player-runtime behavior.

## Where To Go Next

| need | page |
|---|---|
| architecture and evidence boundaries | [Architecture](Architecture) |
| component inventory and source-wiring evidence | [System Components](System-Components) |
| repository ownership and local path notes | [Repositories](Repositories) |
| operations and recovery | [Runbook](Runbook) |
| XM8 app source/status boundaries | [XM8 Apps](XM8-Apps) |
| map authoring and static object custody | [Custom Map Editing](Custom-Map-Editing) |
| drone and counter-UAS design boundary | [Drone & Counter-UAS](Drone-and-Counter-UAS) |
| GUARD design programme | [GUARD Development Plan](XCSV-GUARD-Development-Plan) |
| roadmap and future work | [Roadmap](Roadmap) |
| historical lessons | [Lessons](Lessons) |

## Working Principle

Built, committed, accepted, deployed, and runtime-verified are different states. XCSV documentation should help you find the right evidence source, not pretend one source proves the whole system.
