---
layout: wiki
section: docs
title: Memory
heading: Memory
blurb: Where project truth is recorded, and the RAG plan.
order: 12
source: Memory.md
---

XCSV project memory has four required layers:

- Vault: `C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX`, with `ROADMAP.md` as the active handoff.
- GitHub/source: `D:\XCSV`, `D:\XCSV_GUARD`, `E:\XCSV_ADDONS`, and `E:\ExileRepo`.
- Live server: `E:\arma3server`, deployment truth only. Live PBO edits must be unpacked/mirrored into `E:\ExileRepo\LiveSource\...` and committed.
- Wiki: source lives in `D:\XCSV\wiki\`; generated pages live under `docs/wiki` after `D:\XCSV\tools\build-docs.ps1`.

Rule: after any live server, PBO, database, launch, BattlEye, or GUARD change, update the vault, Git-tracked source, and wiki before calling the work done. Include exact paths, backup names, restart time, commit hashes, and validation evidence.

RAG plan: build a local read-only index over the vault, wiki source, repos, selected live config/source files, and recent logs. The index must redact secrets and tag each chunk by trust tier: live, committed source, vault, generated wiki, or log.

Current publishable first slice: run `D:\XCSV\tools\build-memory-index.ps1`,
then `D:\XCSV\tools\build-docs.ps1`. It writes `wiki\Memory-Index.md`, a
heading-level map of the vault and wiki that is safe to publish because it
skips common secret/config filenames.

Current local RAG slice: run `D:\XCSV\tools\build-rag-index.ps1`, then query it
with `D:\XCSV\tools\search-rag.ps1 -Query "your terms"`. It writes a local-only
JSONL chunk index to `D:\CAGE\xcsv-rag\xcsv-rag.jsonl`, a manifest to
`D:\CAGE\xcsv-rag\manifest.json`, and a last-query pulse marker to
`D:\CAGE\xcsv-rag\last-query.json`. XCSV GUARD reads the manifest and
last-query marker for the top-bar `rag` chip: green means the local index is
present, grey means missing, and an accent pulse means a RAG query was used in
the last few seconds. The committed scripts index vault notes, wiki source,
selected repo source/tools, addon source, and bounded recent live logs with
trust tiers, repo names, commit hashes where available, file paths, line ranges,
headings, and redacted snippets. The generated JSONL and marker files are not
committed or published.

Current server-state slice: live production is x64/extDB3. Operational evidence
is captured by `E:\ExileRepo\tools\diagnostics\x64-baseline.ps1`, persistence is
probed by `E:\ExileRepo\tools\database\test-extdb3-persistence.ps1`, and backups
are created by `E:\ExileRepo\tools\database\backup-exile-db.ps1`.
