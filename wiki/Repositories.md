# Repositories

Four repos, one system. The hub carries documentation and submodule pointers;
everything else lives where it is built.

| repo | visibility | submodule path in hub | what is in it |
|---|---|---|---|
| [XCSV](https://github.com/x-cessive/XCSV) | public | — | hub, site, wiki |
| [XCSV_GUARD](https://github.com/x-cessive/XCSV_GUARD) | private | `guard/` | Rust operations console |
| [XCSV_ADDONS](https://github.com/x-cessive/XCSV_ADDONS) | private | `addons/` | our own addons and mission scripts |
| [Exile](https://github.com/x-cessive/Exile) | public | `catalogue/` | third-party addons, scripts, tooling |

The hub is **public** because GitHub Pages on the free plan only publishes from
public repositories. Nothing private became public as a result — the hub holds
documentation and gitlinks, not code.

## Working copies on disk

| path | repo |
|---|---|
| `D:\XCSV` | hub |
| `D:\XCSV_GUARD` | console |
| `E:\XCSV_ADDONS` | our addons |
| `E:\ExileRepo` | catalogue |
| `E:\arma3server` | the live server (**not** a repo) |
| `E:\ArmaTools\mission\Exile.Tanoa` | live mission source (**not** a repo) |
| `C:\Users\Architect\Desktop\ARMA3_EXILE_CODEX` | Obsidian vault |

Note the two that are not repositories. `E:\arma3server` and the live mission
source are deployment targets. Content is authored in `E:\XCSV_ADDONS`, then
copied and packed into them.

## XCSV_GUARD layout

| path | purpose |
|---|---|
| `src/app.rs` | UI and application state |
| `src/theme.rs` | palette, type scale, composite widgets — visual changes go here |
| `src/pbo.rs` | PBO reader and integrity checker |
| `src/rcon.rs` | BattlEye RCon client, protocol up from UDP |
| `src/server.rs` | process supervision, RPT scanning, log-growth guard, crash autopsy |
| `src/stack.rs` | whole-stack start / stop orchestration |
| `src/ai.rs` | local model client — classification only, no tools |
| `src/metrics.rs` | performance history from infiSTAR `meta_data.log` |
| `src/secrets.rs` | DPAPI protection for credentials at rest |
| `tools/deploy.ps1` | build, test, archive the outgoing binary, deploy, update taskbar pin |
| `tools\taskbar-pin.ps1` | remove stale GUARD taskbar shortcuts and point the live shortcut at the deployed exe |
| `tools\capture.ps1` | screenshot subsystem for named tabs and responsive viewports |
| `tools/doctor.ps1` | 22 executable assertions, `-Json`, exit codes |

Deploy **through the script**, never by copying the exe. It refuses to deploy on
failing tests, archives the binary it replaces, prunes to the newest N,
regenerates SHA256/current-build manifests, updates the taskbar shortcut to the
single live Desktop exe, and launches that exe. The live location always holds
exactly one binary; taskbar pins must never point at `target\debug` or
`target\release`.

Any GUARD behavior or UI change must also refresh the GitHub-facing screenshots
and GIFs across the XCSV repos before the work is called complete. Use
`D:\XCSV_GUARD\tools\capture.ps1` for publishable tab captures and animated
assets, then update the hub/site outputs and relevant repo READMEs/wiki
references. For live debugging captures, use
`D:\XCSV\tools\ai-desktop-capture.ps1 -Layout -Shot` so Orca stays pinned left
and XCSV GUARD stays pinned right; `-WideGuardForShot` may temporarily enlarge
GUARD only when the tool restores the right-pinned layout afterward.

## XCSV_ADDONS layout

| path | side | notes |
|---|---|---|
| `xcsv_chatter/` | server | packs to `@ExileServer\addons\xcsv_chatter.pbo` |
| `mission/xcsv/` | client | copied into `Exile.Tanoa\xcsv\` |

Server addons live in `@ExileServer`, which is a *server mod* — clients never
receive it. Anything that draws per-player UI must ship in the mission.

## House rules for anything added to XCSV_ADDONS

- **Static text only** for anything the world says. If a language model helps
  write lines, that happens offline, a human reads the output, and survivors are
  pasted in as literals. Players have no path to influence it because there is
  nothing running to influence.
- **Create no objects** unless there is no alternative. BattlEye fights
  `createVehicle` / `deleteVehicle` / `setPos`, and auto-whitelisting those
  filters is how a cheat vector gets opened.
- **Never `while {true} do {sleep n}` on the server.** Use
  `ExileServer_system_thread_addTask`. Client-side loops are fine — they cost the
  player's frame, not the server's.
- **Verify entry paths after packing.** A checksum verify passes on a PBO whose
  internal paths are corrupt.

## Keeping the hub honest

Submodule pointers go stale **silently**. After pushing any member repo:

```bash
cd D:\XCSV
git submodule update --remote --merge
git commit -am "bump submodules"
git push
```

Otherwise the hub advertises an old commit and nobody notices.

## Related

- [Architecture](Architecture) · [Runbook](Runbook)
