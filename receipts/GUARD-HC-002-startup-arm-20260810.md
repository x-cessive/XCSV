# GUARD-HC-002 - watch an already-running server for a headless join

Work ID: `GUARD-HC-002`

Owning repo: `XCSV_GUARD`

Priority: P2 - closes the recovery gap left open by GUARD-HC-001

Gauntlet: G3

Date: 2026-08-10

Verdict: `PASS_RUNTIME_VERIFIED`

## Defect

`GUARD-HC-001` recovers a headless client that never joined, but arms only on a
**server** start. A GUARD that comes up beside an already-running server never
judged the HC at all, so any sequence that restarts GUARD *after* the server
stranded the client with nothing watching until the next server start.

That was recorded as a known limitation when GUARD-HC-001 shipped, with the
expectation that the restart cycle would cover it. It was hit for real **within
the hour**, during the `GUARD-RCON-002` credential rotation: the server was
restarted so BattlEye would reload the new credential, GUARD was restarted
afterwards to pick it up, and the HC sat orphaned until a manual
`STOP EVERYTHING` / `START EVERYTHING` cycle cleared it.

The limitation is more reachable than it looked. Restarting GUARD after the
server is a normal thing to do, not an edge case.

## Fix

`tick_hc_startup_arm` adopts the join watch once, shortly after GUARD settles
(60s, so at least one poll has populated the RPT path and the server PID).

The interesting part is what stops it acting on stale information. The obvious
design is an age limit - "only adopt if the server started less than N minutes
ago" - but that is a proxy for the real question, and a hand-tuned one.

The real question is whether GUARD can actually *see* a join if there was one.
`poll` reads only the last `RPT_TAIL_BYTES` of the server log, so if the file is
larger than that window the join line may simply have scrolled out of view. In
that case "no evidence" describes where we looked, not the state of the HC, and
acting on it would kill a healthy client.

So the guard is the RPT size:

```rust
if self.rpt_bytes == 0 || self.rpt_bytes > RPT_TAIL_BYTES {
    // log is past the tail window; not judging
    return;
}
```

Only when the tail covers the whole boot is absence of evidence solid enough to
kill a process over. That makes the check self-correcting: it stops adopting at
exactly the point its own evidence stops being complete, with no tuning.

The `512 * 1024` literal in `poll` became `RPT_TAIL_BYTES` so the read and the
check cannot drift apart. A test asserts the magic number did not survive
alongside the constant - including the trap that the assertion's own text is
visible to `include_str!`, which is why the forbidden string is built with
`concat!`.

Every existing guard still applies: one-shot, vetoed by join evidence, skipped
when a server start already armed the deadline, refuses with no server running,
and gated on `hc_enabled`.

Commit `e996895`, build `guard-0.7.1+23`, source CLEAN.
Tests: 267 passed, 0 failed, 3 ignored (265 before).

## Runtime proof

The `GUARD-RCON-002` sequence was reproduced deliberately - the exact case that
previously stranded the HC permanently:

1. server restarted through the GUARD UI, `18752` -> `41960`
2. HC `40688` survived from the previous boot, refused re-entry
3. **GUARD restarted after the server**, `16956` -> `41420`, so no server start
   ever armed the check in that instance

Timeline from GUARD start at `04:23:57`:

| offset | event |
|---|---|
| +60s  | startup arm engages - RPT small enough for absence to mean something |
| +360s | orphan `40688` stopped, 300s grace after arming |
| +375s | replacement HC `29348` launched, 15s later as designed |
| +405s | join recorded in the current boot's server RPT |

Recovered **without a server start**, which is precisely the gap that was open.

Final state: server `41960`, HC `29348`, `mysqld`, GUARD `41420`. Exactly one
dedicated server and one HC. Doctor: **25 passed, 1 warned, 0 failed**, with
`hc-join` and `battleye-enforcement 11 of 51` passing; the single warning is the
known infiSTAR cloud 403.

## Remaining limitation

If GUARD starts beside a server whose RPT has already grown past
`RPT_TAIL_BYTES` (roughly an hour of uptime on current logging volume), it
declines to judge and logs why. That is deliberate - the alternative is killing
a healthy HC because the evidence scrolled out of the window - and the case is
covered by the next server start, which arms the check normally.
