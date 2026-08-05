# XCSV Agent Rules

This hub owns the public site, wiki source, generated docs, memory tooling, and
submodule pointers for the XCSV Arma 3 Exile estate.

## RAG Maintenance

Keep the local RAG current after any change to vault notes, wiki/docs,
Git-tracked source, live server state, PBOs, launch scripts, BattlEye, database
tooling, or GUARD behavior:

1. Run `D:\XCSV\tools\build-memory-index.ps1`.
2. Run `D:\XCSV\tools\build-docs.ps1`.
3. Run `D:\XCSV\tools\build-rag-index.ps1`.

Use `D:\XCSV\tools\search-rag.ps1 -Query "terms"` before broad filesystem
searches for project history. The local JSONL index lives under
`D:\CAGE\xcsv-rag\` and must not be committed or published.

Record operational evidence in
`C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX\ROADMAP.md` and mirror durable
knowledge into `D:\XCSV\wiki\`.
