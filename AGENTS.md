# XCSV Agent Rules

**XCSV-AI-CONTRACT: 1.0.0**

This hub owns the public site, wiki source, generated docs, memory tooling and submodule pointers for the XCSV Arma 3 Exile estate.

## Mandatory entrypoint

Before interpreting the roadmap or starting implementation, read:

- `wiki/AI-Start-Here.md`
- `wiki/AI-Provenance-and-Doc-Sync.md`

When Architect says **read the GitHub**, **read the roadmap**, **get caught up**, **resume XCSV**, or equivalent, execute the contract's `READ_ONLY_BOOTSTRAP` first.

Roadmap status is intent, not implementation proof. Reconcile desktop roadmap, RAG/history, local working trees, commits, GitHub remote/submodule state and relevant live evidence. Work only on the remaining delta.

During bootstrap, declare documentation state as `SYNCED`, `DESKTOP_AHEAD`, `GITHUB_AHEAD`, `DIVERGED`, or `UNKNOWN`. Treat the first 2026-08-07 server reconciliation as `DIVERGED` until local evidence proves otherwise. Never overwrite one documentation side with the other merely to make them look synchronized.

Any AI-authored commit must include the provenance trailers defined in `wiki/AI-Provenance-and-Doc-Sync.md`. Prefer `D:\XCSV\tools\ai-commit.ps1` after reviewing and staging the intended files. Do not fake Git author identities.

## RAG maintenance

After applicable changes to vault notes, wiki/docs, Git-tracked source, live server state, PBOs, launch scripts, BattlEye, database tooling or GUARD behavior:

1. Run `D:\XCSV\tools\build-memory-index.ps1`.
2. Run `D:\XCSV\tools\build-docs.ps1`.
3. Run `D:\XCSV\tools\build-rag-index.ps1`.

Use `D:\XCSV\tools\search-rag.ps1 -Query "terms"` before broad filesystem searches for project history. The local JSONL index under `D:\CAGE\xcsv-rag\` must not be committed or published.

Record operational evidence in `C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX\ROADMAP.md` when that local authority is available, and mirror durable shared knowledge into `D:\XCSV\wiki\` without collapsing unique desktop evidence into the shorter GitHub summary.

## Live desktop debugging layout

When debugging XCSV GUARD through the desktop, do not minimize or reshuffle the
operator windows. Pin Orca to the left half of the primary screen and XCSV GUARD
to the right half:

```powershell
D:\XCSV\tools\ai-desktop-capture.ps1 -Layout -Shot
```

Use `-GuardTab <tab>` to navigate GUARD by name before capturing, for example
`-GuardTab RCon -Shot`. If a capture needs more width for accurate scaling, use
`-WideGuardForShot`; the tool may temporarily enlarge GUARD but must restore Orca
left / GUARD right before it exits. The tool writes full-desktop screenshots and
text state to `D:\CAGE\xcsv-desktop-shots`; the text files are the fallback
evidence for agents that cannot read images. Do not commit those local
screenshots.

## GUARD screenshots and GIFs

Any change to XCSV GUARD behavior or UI must refresh the GitHub-facing screenshots
and GIFs across the XCSV repos before the work is called complete. Use the
GUARD capture tooling (`D:\XCSV_GUARD\tools\capture.ps1`) for publishable tab
captures and animated assets, then update the hub/site outputs and the relevant
repo READMEs/wiki references. Treat stale images as stale documentation.
