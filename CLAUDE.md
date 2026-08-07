# XCSV Claude Code Adapter

**XCSV-AI-CONTRACT: 1.0.0**

@wiki/AI-Start-Here.md
@wiki/AI-Provenance-and-Doc-Sync.md

Both imported policies are mandatory.

When Architect says **read the GitHub**, **read the roadmap**, **get caught up**, **resume XCSV**, or equivalent, enter `READ_ONLY_BOOTSTRAP` from the canonical contract before any implementation.

During bootstrap, explicitly classify the desktop/GitHub documentation relationship as `SYNCED`, `DESKTOP_AHEAD`, `GITHUB_AHEAD`, `DIVERGED`, or `UNKNOWN`. Never fix divergence by overwriting one side with the other.

The first SOVRAN-1 bootstrap ran on 2026-08-07 (`XCSV-AI-001`) and reconciled that divergence: the AI contract and GUARD programme landed on the desktop as Phase 15, and documentation state was left `SYNCED`. Do not inherit that verdict - re-classify from the actual files every session.

Any AI-authored commit must use the provenance trailers defined in `AI-Provenance-and-Doc-Sync.md`. Prefer `D:\XCSV\tools\ai-commit.ps1` after reviewing and staging the intended files. Do not change Git author identity merely to represent the AI.

Do not run `/init` over this file. Do not replace established XCSV instruction files with generated defaults.

Do not modify `%USERPROFILE%\.claude`, global hooks, global MCP configuration, or global permissions merely to make this repository work unless Architect explicitly asks. Project setup should remain Git-tracked wherever practical.

The authoritative local roadmap is `C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX\ROADMAP.md` when available. GitHub can be stale; local source can be ahead; live state can differ from both. Reconcile before acting.
