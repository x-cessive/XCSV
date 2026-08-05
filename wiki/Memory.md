# Memory

XCSV project memory has four required layers:

- Vault: `C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX`, with `ROADMAP.md` as the active handoff.
- GitHub/source: `D:\XCSV`, `D:\XCSV_GUARD`, `E:\XCSV_ADDONS`, and `E:\ExileRepo`.
- Live server: `E:\arma3server`, deployment truth only. Live PBO edits must be unpacked/mirrored into `E:\ExileRepo\LiveSource\...` and committed.
- Wiki: source lives in `D:\XCSV\wiki\`; generated pages live under `docs/wiki` after `D:\XCSV\tools\build-docs.ps1`.

Rule: after any live server, PBO, database, launch, BattlEye, or GUARD change, update the vault, Git-tracked source, and wiki before calling the work done. Include exact paths, backup names, restart time, commit hashes, and validation evidence.

RAG plan: build a local read-only index over the vault, wiki source, repos, selected live config/source files, and recent logs. The index must redact secrets and tag each chunk by trust tier: live, committed source, vault, generated wiki, or log.

Current first slice: run `D:\XCSV\tools\build-memory-index.ps1`, then
`D:\XCSV\tools\build-docs.ps1`. It writes `wiki\Memory-Index.md`, a heading-level
map of the vault and wiki that is safe to publish because it skips common
secret/config filenames.
