# Drone and Counter-UAS

Drone and counter-UAS work belongs to the curated player-system programme. The current documentation records source and design boundaries; it does not prove live runtime behavior.

## Current Evidence Boundary

The source inventory identifies drone-related mission/UI surfaces and supporting catalogue material where present. The accepted issue #30 result is `PARTIAL_INVENTORY / PARTIAL_SOURCE_VERIFIED`, so deployed drone behavior, live trader stock, BattlEye impact, persistence, and player-runtime counterplay remain `NOT_REVERIFIED` unless a newer receipt says otherwise.

## Documented V1 Direction

XM8 App22 is the documented player-facing Drone Control surface. Its intended first slice is a constrained UAV convenience/status interface with ownership checks and a narrow equipment set.

Deferred until evidence supports them:

- armed drones;
- Stompers and heavy UGV workflows;
- DLC UAV expansion;
- static anti-air systems;
- Nyx AA and broader counterplay;
- persistence guarantees beyond verified source/runtime evidence.

## Architecture Questions To Keep Explicit

| question | evidence needed |
|---|---|
| Who owns drone purchase/spawn? | trader config, mission wiring, server handler evidence |
| Who owns persistence? | DB/query/source and restart runtime evidence |
| What can players control? | XM8/UI source plus live exercise |
| What can counter drones? | weapon/trader/BattlEye/runtime evidence |
| What does infiSTAR/BattlEye allow? | live filter/log evidence |
| What is deployed? | packed artifacts and runtime source/hash comparison |

## Design Constraint

Do not add drone capability merely because source exists. Drone systems touch economy, player power, anti-cheat, persistence, and server performance. Treat them as G3/G4 work until the relevant source, deployment, and runtime evidence is captured.

## Related

- [XM8 Apps](XM8-Apps)
- [System Components](System-Components)
- [Architecture](Architecture)
- [Roadmap](Roadmap)
