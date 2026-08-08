---
layout: wiki
section: docs
title: Runbook
heading: Runbook
blurb: The server is broken and you need it back.
order: 7
source: Runbook.md
---

For when the server is broken and you need it back.

## 0. First move, always

Open **XCSV GUARD**. Its Overview tab runs the pre-flight checks below
automatically, every poll. If it is already telling you what is wrong, believe it
before you believe the RPT.

![XCSV GUARD Overview](https://x-cessive.github.io/XCSV/assets/shots/overview.png)

Then, from a shell:

```powershell
D:\XCSV_GUARD\tools\doctor.ps1          # executable assertions
D:\XCSV_GUARD\tools\doctor.ps1 -Json    # same, machine-readable, exit codes
```

## 1. Read the RPT correctly

**Count mission starts before reading a single error.**

```powershell
Select-String -Path <newest .rpt> -Pattern 'Starting mission:' | Measure-Object
```

- **1** — the server started once. Errors after it are probably real.
- **more than 1** — you are in a restart loop. **Only the first error is real.**
  Everything after it, including every database error, is a symptom.

Two messages that are *always* symptoms and never causes:

- `extDB2 is already setup & locked` — extDB2 locks after a successful init, so
  this only appears on a second pass, which means a loop.
- `Unknown Protocol` — same story.

## 2. The restart loop checklist

In order of how often it has actually been the answer here:

1. **PBO entry paths.** A PBO whose entries all begin with `\` passes a checksum
   verify and still breaks everything — Arma resolves `<prefix>` + `\path`, finds
   nothing, and the server core never loads. Check the entry table, not the
   checksum:
   ```powershell
   E:\ExileRepo\tools\pbo\pbo.ps1 List -Path <pbo>
   ```
   No entry may begin with `\` or `/`. XCSV GUARD's **Integrity** tab does this
   for every loaded PBO and refuses to start the server if any fails.
2. **Wrong database bridge.** Production is `arma3server_x64.exe` + extDB3. If
   x64 is running, verify `@ExileServer\extDB3_x64.dll`,
   `@ExileServer\extdb3-conf.ini`, and `@ExileServer\sql_custom\exile.ini`.
3. **Missing `-filePatching`.** A3XAI reads `a3xai_config.sqf` as a loose file
   and silently ends the mission during world init without it.
4. **Database reachable?** MariaDB up, credentials in `extdb3-conf.ini` current.
5. **A config parse error in the mission.** One bad brace in `config.cpp` ends
   the mission before anything else runs.

## 3. Disk filling / RPT growing

XCSV GUARD's log guard watches MB/min and alerts. If it is climbing:

- Confirm the active process is `arma3server_x64.exe` and capture a baseline.
- Check the newest RPT for a repeating line; a single addon in a tight failure
  loop can write hundreds of MB.
- Old RPTs are safe to delete. The live one is not.

## 4. Restarting properly

Use XCSV GUARD's **Restarts** tab, which issues **`#shutdown`**, not `#restart`.

`#restart` reloads the mission inside the same process and never returns memory.
Use `#shutdown` so the x64 process exits cleanly and comes back under the
current launch parameters.

## 4.1 x64/extDB3 operating checks

Production is `arma3server_x64.exe` + extDB3 with `-maxMem=12288`.

```powershell
E:\ExileRepo\tools\diagnostics\x64-baseline.ps1
E:\ExileRepo\tools\database\test-extdb3-persistence.ps1
E:\ExileRepo\tools\database\backup-exile-db.ps1 -WhatIf
```

If the latest server RPT contains `No more slot to add connection`, the headless
client did not claim an HC slot. GUARD doctor reports this as `hc-join`.

## 5. Whole-stack start / stop

The **Start Everything** button brings up, in order: database → integrity gate →
server → headless client → local model. **Stop Everything** takes them down
cleanly in reverse.

If the server will not start, the integrity gate is the first thing to check —
by design it will block a start rather than let a corrupt PBO produce a loop.

## 6. After any repack

Repacking is the single most dangerous routine operation here.

```powershell
E:\ExileRepo\tools\pbo\pbo.ps1 Pack -Path <src> -Out <dst> -Prefix <prefix>
E:\ExileRepo\tools\pbo\pbo.ps1 List -Path <dst>      # ALWAYS. Read the paths.
```

The packer once used `Resolve-Path`, which hands a path back in whatever form it
was given — so a source path containing an 8.3 short name
(`C:\Users\ARCHIT~1\…`) stayed short while directory enumeration returned the
long form (`C:\Users\Architect\…`). One character of difference left a separator
on every entry path. It now uses `Get-Item -LiteralPath` and refuses to pack a
bad entry, but **verify anyway**.

The corruption is arithmetically visible — broken files are exactly one byte
larger per entry.

## 7. Player trouble

- **Live player list, kick, ban, message** — XCSV GUARD **Players** tab.
- **Who connected** — BattlEye connection history is the only local record of
  who reached a publicly listed box.
- **Object count run away?** In-game, as an admin, use the scroll action
  **XCSV: World census** — it buckets and maps every simulated object, locally
  to you only.

## Related

- [Architecture](Architecture.html) · [Lessons](Lessons.html) · [Roadmap](Roadmap.html)
