# XCSV Agent Rules

**XCSV-AI-CONTRACT: 1.0.0**

This hub owns the public site, wiki source, generated docs, memory tooling and submodule pointers for the XCSV Arma 3 Exile estate.

## Mandatory entrypoint

Before interpreting the roadmap or starting implementation, read:

`wiki/AI-Start-Here.md`

When Architect says **read the GitHub**, **read the roadmap**, **get caught up**, **resume XCSV**, or equivalent, execute the contract's `READ_ONLY_BOOTSTRAP` first.

Roadmap status is intent, not implementation proof. Reconcile desktop roadmap, RAG/history, local working trees, commits, GitHub remote/submodule state and relevant live evidence. Work only on the remaining delta.

## RAG maintenance

After applicable changes to vault notes, wiki/docs, Git-tracked source, live server state, PBOs, launch scripts, BattlEye, database tooling or GUARD behavior:

1. Run `D:\XCSV\tools\build-memory-index.ps1`.
2. Run `D:\XCSV\tools\build-docs.ps1`.
3. Run `D:\XCSV\tools\build-rag-index.ps1`.

Use `D:\XCSV\tools\search-rag.ps1 -Query "terms"` before broad filesystem searches for project history. The local JSONL index under `D:\CAGE\xcsv-rag\` must not be committed or published.

Record operational evidence in `C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX\ROADMAP.md` when that local authority is available, and mirror durable knowledge into `D:\XCSV\wiki\`.
