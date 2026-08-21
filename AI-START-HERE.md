# XCSV AI Start Here

**XCSV-AI-CONTRACT: 1.0.0**

This root file is intentionally short.

**Mandatory:** before interpreting roadmap items, creating commits, or starting implementation, read:

- `registry/repository-identity.json`
- `registry/current-state.json`
- `wiki/AI-Start-Here.md`
- `wiki/AI-Provenance-and-Doc-Sync.md`

The identity manifest answers **what this repository is and is not canonical for**. The current-state file records **per-source observations/freshness only**; it is never authority. The wiki documents define the canonical XCSV AI operating contract, provenance, work receipts and safe desktop/GitHub reconciliation.

Together they define the **read the GitHub** bootstrap, authority hierarchy, roadmap reconciliation states, delta-first rule, Gauntlet ordering, GitHub work tracking, AI provenance and completion transaction.

If working from a member repo on SOVRAN-1, the canonical XCSV AI-contract paths are:

- `D:\XCSV\wiki\AI-Start-Here.md`
- `D:\XCSV\wiki\AI-Provenance-and-Doc-Sync.md`

## Freshness rule

The 2026-08-07 reconciliation is historical evidence that the documentation layers were reconciled **at that time**. Do not inherit `SYNCED` into a new session.

At every bootstrap:

1. inspect the sources actually available;
2. classify each relevant source independently;
3. preserve `NOT_REVERIFIED`, `STALE` or `UNKNOWN` where evidence is missing;
4. never advance a local/runtime/wiki-publication freshness claim merely because GitHub source was inspected.

`registry/current-state.json` is a convenience observation surface, not a substitute for checking the actual source when the claim matters.

## Cold rehydration

`registry/cold-rehydration.contract.json` defines the read-only acceptance contract for a fresh AI with no prior chat context. Its presence is not proof of PASS; a real evaluation must be executed and recorded independently.

Do not duplicate the full policies into multiple AI files. Native adapters should route back to the canonical documents.
