# GUARD-HC-001 - orphaned headless client never recovered

Work ID: `GUARD-HC-001`

Owning repo: `XCSV_GUARD`

Issue: `x-cessive/XCSV` #14

Priority: P2 - silent loss of AI offload, does not self-heal

Gauntlet: G3

Date: 2026-08-10

Verdict: `PASS_RUNTIME_VERIFIED`

## Defect

After GUARD's *Restart server* path the headless client process survived the
server restart, failed to rejoin, and was never recovered. A3XAI and FuMS kept
running on the dedicated server instead of the HC. The condition did not
self-heal, because every later scheduled restart hit the same check.

Found while verifying BattlEye enforcement slice 3 (`BE-ENFORCE-003`).

Original observation, build `guard-0.7.1+20`, server restart at `02:17:58`:

```text
2:18:23 No more slot to add connection at 015030 (1523.6,3012.8)
2:18:29 "[A3XAI] A3XAI is now listening for headless client connection."
```

The surviving HC (PID `30564`) retried six seconds *before* A3XAI began
listening, was refused, and never retried. No join line appeared for that boot.

## Root cause

`src/app/worker.rs` `tick_hc_launch` early-returned on
`stack::hc_running(&exe, &args)`, which is a **process-existence** check - it
looks for an `arma3_x64.exe` whose command line carries the configured `-name=`
marker. It says nothing about whether that process is attached to the current
server. An orphan satisfied it, GUARD marked the component `Running`, and the
relaunch path returned early forever.

## Fix

Judge on join evidence for the current boot instead of process existence.

- `mission::hc_joined_in_server_log(text)` accepts only identifier-bearing lines
  the *server* emits: A3XAI's `logged in successfully` with an owner id, and
  FuMS's script transfer naming the HC slot. Bare readiness lines are rejected,
  because the defect boot logged A3XAI readiness and an HC script load while the
  client sat refused.
- `tick_hc_join_recovery` replaces a non-joining HC. It is armed only by a
  server start, judged exactly once per arming, vetoed by any join evidence,
  capped at one replacement per epoch, guarded by `stack_epoch` and the stop
  flag, and refuses to act when no server is running. `stop_hc` already matches
  on both `-client` and the `-name=` marker, so it cannot reach the operator's
  own game session.
- The verdict is latched per-RPT rather than re-derived each tick. `poll` reads
  only the RPT tail, so on a long-lived server the join line scrolls out of the
  window; re-deriving would eventually read "never joined" for a healthy HC and
  kill it.
- An HC process without a join now reports `Starting`, not `Running`, while the
  judgement is open. Claiming health there is what made the defect invisible on
  the stack panel.

Grace is 300s after server start, replacement launches 15s after the orphan is
stopped.

## The first attempt failed, and why

Build 21 shipped a version of this that **never fired**. Verified live: a
server-only restart orphaned HC PID `32096` as intended, and ten minutes later,
well past the grace period, the orphan was untouched.

The cause was in the fix, and it was the same mistake the original defect was
made of - trusting evidence not tied to the current boot. The latch read
`MissionIntel`, whose `from_logs` folds the server RPT together with the
headless client's **own** RPT. The client process survives a server-only
restart, so its log still held `Heart Beat Started for HC. using slot# 4` from
the previous boot. That set `fums_hc_slot`, the join predicate returned true,
and the latch vetoed the recovery it existed to trigger. Keying the latch reset
on the server RPT path changing did not help, because the stale evidence came
from a different file.

`MissionIntel::hc_joined()` was removed rather than left in place, so the
combined view cannot be reached for this decision again. Regression test:
`a_stale_headless_client_log_cannot_vouch_for_the_current_boot`, which asserts
both that the combined view really does pick up the stale slot and that the
server-log verdict still reads "not joined".

This is worth recording plainly: the bug was invisible to unit tests and to
review. Only running the real scenario against the real server caught it.

## Runtime proof

Build `guard-0.7.1+22`, commit `92c5c7a`, deployed from a CLEAN tree. The
scenario was reproduced deliberately: *Restart server* invoked at `03:03:09`
with HC PID `32096` already orphaned from the failed build-21 run, so its RPT
carried exactly the stale evidence that defeated the first attempt.

| offset | event |
|---|---|
| t+135s | server restarts, PID `17616` -> `19932`; HC `32096` survives |
| t+435s | orphan `32096` stopped - 300s after server start, as designed |
| t+450s | replacement HC `35648` launched - 15s later, as designed |
| t+495s | join recorded in the current boot's server RPT |

From the boot's own log, the defect and its automatic repair in one file:

```text
3:05:56 No more slot to add connection at 015030 (1523.6,3012.8)
3:11:35 "[A3XAI] Headless client HC (owner: 4) logged in successfully."
```

No human intervention between those two lines.

Final state: server `19932`, HC `35648`, `mysqld`, GUARD `36324`. Exactly one
dedicated server, exactly one HC. GUARD doctor:

```text
25 passed, 1 warned, 0 failed
PASS  hc-join               latest server/HC logs show successful HC join
PASS  battleye-enforcement  11 of 51 rules enforcing
```

Tests: 265 passed, 0 failed, 3 ignored (256 before this work).

## Known limitation

Recovery is armed by a **server start**, not by GUARD starting. If GUARD is
restarted while an HC is already orphaned, that orphan is not recovered until
the next server start. This is deliberate - a fresh GUARD has no boot to judge
against, and arming on GUARD start would risk killing a healthy HC whose join
evidence has already scrolled out of the RPT tail. In practice the scheduled
restart cycle covers it within `restart_interval_min`.

## Relevance to FPS decay

A scheduled restart that orphaned the HC left the dedicated server carrying
A3XAI and FuMS load indefinitely. That is a plausible contributor to the
standing "FPS decays with uptime" complaint and should be re-measured now that
restarts no longer strand the HC, before other causes are investigated.
