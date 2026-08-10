# FPS-REGIME-001 - "FPS decays with uptime" is the wrong shape

Work ID: `FPS-REGIME-001`

Owning target: live server `E:\arma3server`

Priority: P3 - performance characterisation

Gauntlet: G2

Date: 2026-08-10

Verdict: `ANALYSIS_COMPLETE_CAUSE_UNDETERMINED`

## Summary

The standing complaint is "FPS decays with uptime". Plotted against the RPT
history for the first time, that is not what the server does. It sits in one of
two regimes - roughly **23 FPS** or **46 FPS** - and steps between them. Long
boots are flat, not sloped.

## Correction to an earlier claim

`GUARD-HC-001` (issue #14) recorded a suggestion that the orphaned headless
client was a plausible contributor to FPS decay, on the reasoning that a server
without an HC carries the A3XAI and FuMS load itself.

**The data does not support that**, and the claim is withdrawn:

- Boot `2026-08-10_01-16-14` had **no HC join** and ran flat at **46.5 FPS**.
- Boots `2026-08-09_16-31-42` and `2026-08-09_20-31-43` had **no HC process at
  all** and ran flat at **~24 FPS** for four hours each.
- Boots with a joined HC appear in both regimes.

HC state does not predict the regime. Fixing GUARD-HC-001 was still correct on
its own terms - a server-only restart silently stranded the HC and never
recovered it - but it should not be expected to change FPS.

## Evidence

Eleven boots with enough samples, 2026-08-06 to 2026-08-10, from infiSTAR's
`processReporter` line (`Started @ <sec> : [FPS: x|PLAYERS: n|THREADS: t]`).

```text
Boot                UpMin   N HC     EarlyFps LateFps SlopeHr Units
2026-08-06_09-27-35    63  60 joined     45.5    24.9  -28.92   102
2026-08-09_16-31-42   239 236 no         24.4    24.0   -0.09   119
2026-08-09_20-31-43   238 235 no         22.5    24.9    0.89    99
2026-08-10_00-31-43    12  11 no         22.8    24.5   16.39      0
2026-08-10_00-44-55    30  29 joined     22.7    29.7   26.40    106
2026-08-10_01-16-14    32  30 no         46.3    46.5    0.69    100
2026-08-10_01-50-26    26  25 joined     46.2    46.5    0.91     85
2026-08-10_02-23-10    22  21 joined     46.4    46.5    0.24     87
2026-08-10_02-46-14    18  17 no         40.4    46.2   36.08     83
2026-08-10_03-05-32    18  17 joined     46.7    46.4   -2.17     86

regime  high (>=35 FPS): 6 boots   low (<35 FPS): 5 boots
  high mean 46.4 FPS
  low  mean 25.6 FPS
```

### Long boots are flat

The only boots that could show decay are the ones over an hour, and two of the
three are flat across their whole life:

```text
2026-08-09_16-31-42   239 min   24.4 -> 24.0 FPS   (-0.09 FPS/hr)
2026-08-09_20-31-43   238 min   22.5 -> 24.9 FPS   ( 0.89 FPS/hr)
```

Four hours at ~24 FPS with no downward trend. Whatever is wrong, uptime is not
the variable.

### Transitions are steps, on wall-clock time, with no in-game cause

Both observed transitions are abrupt, and the player count does not move across
either one:

```text
2026-08-06, 38 min in (10:06 wall-clock)
  up=37.4 min  fps=46.2  players=2
  up=38.4 min  fps=25.7  players=2      <- down
  up=40.4 min  fps=22.3  players=2

2026-08-10, 27.7 min in (01:12 wall-clock)
  up=26.7 min  fps=22.8  players=1
  up=27.7 min  fps=46.4  players=1      <- up
  up=29.7 min  fps=46.5  players=1
```

The second one is the important one: the server got **faster** mid-boot, by a
factor of two, with nothing in the mission changing. A gradual in-game
degradation cannot do that.

Every boot before 2026-08-10 01:12 is in the low regime; every boot after is in
the high regime.

### What was ruled out

- **Uptime** - four-hour boots flat.
- **HC join state** - both regimes contain boots with and without a joined HC.
- **Player count** - unchanged across both transitions.
- **Connected players generally** - the low regime occurs at `players=0`.
- **Mods, mission, world** - identical between a 24 FPS boot and a 46 FPS boot
  (same Exile/Tanoa, same A3XAI, FuMS, DMS, Occupation, infiSTAR).
- **Thread count** - 9.6 to 13.7 across all boots, no split by regime.
- **AI unit count** - 83 to 119, no split by regime.
- **The operator's game client** - its only session on 2026-08-10 ran 00:48:25
  to 00:50:17, two minutes, which cannot span a low period running from
  2026-08-09 16:31 to 2026-08-10 01:12.

## Interpretation

A clean 2:1 ratio that appears and disappears on wall-clock time, with
everything inside the game identical either side, is the signature of something
**outside the server process** taking host CPU. The RPT cannot name it, because
it only sees inside Arma.

This is stated as an interpretation, not a conclusion. The cause is
**undetermined**.

## Tooling added

- `tools/fps-report.ps1` - per-boot FPS-vs-uptime characterisation from the RPT
  history, with `-Curve` for a binned profile. Read-only. This is what produced
  the tables above and makes the analysis repeatable rather than a one-off.
- `tools/fps-watch.ps1` - samples the live server FPS next to per-process host
  CPU every 60s into `D:\CAGE\xcsv-fps-watch.csv`. Registered as the hidden
  scheduled task **XCSV FPS Watch**, running at logon. When the next transition
  happens, the rows either side of it name the responsible process.

Both open the live RPT with `FileShare.ReadWrite`, since the running server
holds it open and a plain read throws.

First sample confirms the instrument works, and incidentally shows the server is
not CPU-starved in the high regime:

```text
2026-08-10 03:26:01, up 19.7 min, 46.6 FPS, players 1, threads 11, total 10.4%
  XCSV_GUARD(36324) 5.3% | arma3server_x64(19932) 2.1% | arma3_x64(35648) 1.8%
```

## Next step

Wait for a transition to appear in `xcsv-fps-watch.csv`. That single event should
identify the cause directly, without further guessing. Until then the honest
status is that the regime split is real and well evidenced, and its cause is
unknown.

Do not act on the old "decays with uptime" framing - in particular, restarting
the server more often does not address a step change that happens 27 minutes
into a boot and can just as easily step the other way.
