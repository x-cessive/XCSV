# Roadmap

The Roadmap is durable planning direction for XCSV. It records what the programme is trying to improve next and where to route execution work. It is not an implementation ledger, source inventory, deployment record, runtime receipt, or proof that a feature is live.

For execution state, read the linked GitHub issues and pull requests. For component/source evidence, read [System Components](System-Components). For freshness, read `registry/current-state.json` and compare observations to the live source when the claim matters.

Historical roadmap/status material was moved to [Roadmap History](Roadmap-History).

## AI / AGENT ROADMAP GATE

Before acting on Roadmap material, read the root `AI-START-HERE.md` and reconcile the target against actual source, registry, issue, pull request and runtime evidence. This Roadmap records planning intent; it is not implementation proof, deployment proof or player-runtime proof.

Work only on the remaining verified delta. Treat `UNKNOWN` and `NOT_REVERIFIED` as valid outcomes when evidence is missing, and do not build duplicate functionality where an owning repository, issue or component already exists.

## Authority Boundary

Roadmap intent does not prove:

- source exists;
- source is wired;
- packed artifacts exist;
- deployed artifacts match source;
- runtime boot succeeded;
- live DB/BattlEye/player behavior was verified.

Those states require evidence from the owning source. `UNKNOWN` and `NOT_REVERIFIED` remain valid outcomes.

## Current Programme Directions

### Repository Fabric and Documentation Authority

Make XCSV the reference-grade hub for repository routing, evidence, documentation generation, AI bootstrap, provenance and cold rehydration.

Owning lanes:

- issue #39: repository identity/freshness/cold-rehydration foundation - complete;
- issue #30: component source inventory - accepted as partial source-verified, still open for live/deployment/runtime evidence;
- issue #31: README/wiki/documentation authority modernization;
- issue #37: durable guardrails/CI/audit enforcement.

### Component Truth and Runtime Evidence

Advance the component registry from source inventory toward deployed/runtime truth without deleting or rewriting gameplay source prematurely.

Remaining evidence families include:

- deployed PBO hashes and loaded `-mod` / `-servermod` command line;
- RPT/boot evidence;
- live DB schema/query presence;
- live BattlEye filter state;
- player-runtime behavior;
- runtime authority for overlapping AI, vehicle, economy and UI systems;
- XCSV_ADDONS to Exile LiveSource custody where source evidence is insufficient.

### GUARD Reliability and Evidence Instrumentation

Continue evolving GUARD as the operator evidence surface: startup reconciliation, durable/reconstructable state, RCon recovery, integrity/artifact identity, replay fixtures, diagnostics, incident mode, telemetry and deployment-diff support.

Implementation authority remains in `x-cessive/XCSV_GUARD`. This hub records the programme and routes to the owning repo.

### Gameplay-System Refactor Programme

Refactor active systems only after source, wiring, runtime and rollback evidence are sufficient. Priority families remain:

- vehicle lifecycle and persistence;
- territory/build/raiding;
- XM8/client UI;
- economy/traders/markets;
- AI/headless-client mission ownership;
- loot/events/survival;
- QoL scripts;
- map/static-object pipeline.

Issue #29 owns the parent programme. Issue #30 owns inventory/evidence. Later implementation slices should stay behavior-preserving unless explicitly authorized.

### AI and Development Workflow

Keep the Gauntlet/provenance model usable across providers while preserving authority boundaries. XCSV_ORCH owns orchestration implementation. XCSV owns the hub documentation, source-observation rules and AI-facing bootstrap route.

## Deliberately Parked Or Deferred

These directions remain parked until evidence and capacity support them:

- heavy new AI frameworks or duplicate ambient mission authority;
- broad zombie/Vcom-style additions without measured headroom;
- armed drones, heavy UGVs and expanded counter-UAS systems;
- write-capable XM8 flows without network/DB/BattlEye/runtime proof;
- major map/deployment architecture changes without drift and rollback evidence;
- automatic AI failover claims without isolation, routing and recovery proof;
- deletion of historical/vendor source before unique knowledge and rollback paths are preserved.

## Execution Links

| issue | owns |
|---|---|
| [#29](https://github.com/x-cessive/XCSV/issues/29) | parent system-wide refactor programme |
| [#30](https://github.com/x-cessive/XCSV/issues/30) | component registry and source/live evidence lane |
| [#31](https://github.com/x-cessive/XCSV/issues/31) | README/wiki/documentation authority cleanup |
| [#37](https://github.com/x-cessive/XCSV/issues/37) | deterministic guardrails, drift checks, CI/audits |
| [#39](https://github.com/x-cessive/XCSV/issues/39) | repository identity/freshness/cold-rehydration foundation |

## Related

- [Roadmap History](Roadmap-History)
- [System Components](System-Components)
- [Architecture](Architecture)
- [Repositories](Repositories)
- [Repository Identity & Freshness](Repository-Identity-and-Freshness)
