# BE-ENFORCE-003 - BattlEye enforcement slice 3

Work ID: `BE-ENFORCE-003`

Owning target: live server `E:\arma3server\battleye\scripts.txt`

Priority: P3 - security hardening, evidence-gated

Gauntlet: G3

Date: 2026-08-10

Verdict: `APPLIED_PENDING_RESTART`

## Scope

Promote the remaining never-fired BattlEye script filters from action 1
(log only) to action 3 (log + kick, no ban), continuing the safe-leading-edge
programme. Slice 1 (rules 17/41/43/45) went live 2026-08-05. Slice 2 (rules
22/26/33/36) went live 2026-08-06. Both were still at zero kicks when this
slice was evaluated.

## Rule numbering - resolved

The prior slice hit a split/index drift: `scripts.txt` mixes line endings
(48 CRLF plus 4 lone LF), so `Get-Content` sees 52 lines while a CRLF-only
split sees 49. Neither count is BattlEye's.

This slice resolved the mapping empirically instead of assuming it. Splitting
the raw file on `LF` yields 53 entries: index 0 is the `//new2` comment,
indices 1..51 are the 51 rules, index 52 is the trailing empty. BattlEye
numbers the filter lines from 0 and does not number the comment, so:

```text
log #N  ==  LF-split index N+1
```

Two independent confirmations:

1. The action-3 lines sit at LF indices `[18, 23, 27, 34, 37, 42, 44, 46]`,
   which under `N = LFidx - 1` are rules `{17, 22, 26, 33, 36, 41, 43, 45}` -
   an exact 8/8 match with the slices 1 and 2 recorded in the roadmap.
2. Sampled log text matches the mapped rule keyword: `#3` -> `camCreate`
   (`"camera" camcreate`), `#7` -> `createVehicle` (`"eagle_f"`), `#13` ->
   `addAction` (`_title,_iconIdle,_hint`), `#21` -> `compile`
   (`... >> "file")`).

A CRLF-only split was tested and rejected: it produces only 49 entries, so
`#49` has no line at all, and it maps the action-3 set to
`{18, 22, 26, 33, 36, 41, 42, 43}`, which does not match the recorded slices.

## Evidence

`E:\arma3server\battleye\scripts.log`, full history:

- 68,212 violation records (32,605 at the time of slice 2)
- 10 consecutive days, 2026-08-01 10:06:38 to 2026-08-10 00:50:14
- 5 distinct players: `Mr. Sage` (36,203), `weed` (29,214), `exile` (1,446),
  `[CSP] Walter` (1,018), `goldie` (331)
- 39 distinct rule numbers have ever fired

Rule numbers with **zero hits across the entire history**:
`0, 1, 2, 17, 22, 26, 33, 36, 41, 43, 45, 50`.

Of these, `17, 22, 26, 33, 36, 41, 43, 45` are already action 3 - so slices 1
and 2 have produced **zero kicks** across the full 10-day window. That is the
gate for continuing.

## Change applied

Promoted the three remaining never-fired rules:

| rule | LF idx | keyword | exceptions |
|---|---|---|---|
| `#0` | 1 | `eventHandler` | 59 |
| `#1` | 2 | `"setVariable [\"Exile"` | 32 |
| `#2` | 3 | `ctrlCreate` | 7 |

**Rule `#50` was deliberately excluded.** It is `1 ""` - the trailing catch-all
that logs any script activity no earlier rule matched. Promoting an
empty-pattern rule to kick would eject players for anything unrecognised. It
must stay at action 1 permanently.

## Method and verification

Backup taken and hash-verified before the edit:

```text
E:\arma3server\battleye\_backups\scripts.txt.20260810-021034.pre-slice3.bak
pre-edit sha256 032032DB2DC9BC62235E4737047200CB0B2339F6A2ECA0D97C9373BCF061540F
```

The edit was performed at byte level, not by line rewriting, so the mixed line
endings could not be normalised. Each target offset was validated twice before
writing: the leading token had to be exactly `1 ` (`0x31 0x20`), and the text
that followed had to match the expected rule name. Only then was the single
action byte flipped `0x31` -> `0x33`.

Post-edit verification against the backup:

- sizes identical, 48,826 bytes both
- **exactly 3 bytes differ**: offsets `8`, `8310`, `12648`, each `'1'` -> `'3'`
- line-ending integrity preserved: 48 CRLF and 4 lone LF, unchanged
- print-back of the changed region confirms `3 eventHandler`,
  `3 "setVariable [\"Exile"`, `3 ctrlCreate`
- enforcement now **11 of 51** rules

```text
post-edit sha256 05C8CAB456EE801C0A79E023A4A18673A083EEE7728006B9DDCCC08091235571
```

## Activation and residual risk

BattlEye loads filters at boot, so this takes effect at the next server
restart. GUARD is configured for `restart_interval_min = 240` with
`restart_enabled = True`.

Honest limitation on the evidence: the zero-hit history covers 5 distinct
players over 10 days. All three promoted rules fire on client-side UI and
scripting activity, so a code path no one exercised in that window could still
produce a false positive. The exception lists are large (59/32/7), which is why
these rules never fired, but "never fired for 5 players" is weaker than "never
fires". Mitigations: action 3 is log + kick with **no ban**, so any false
positive is recoverable by reconnecting; the hash-verified backup allows an
immediate revert; and enforcement should be watched in `scripts.log` for new
`#0`, `#1`, `#2` entries once players connect.

## Rollback

```text
Copy-Item E:\arma3server\battleye\_backups\scripts.txt.20260810-021034.pre-slice3.bak `
          E:\arma3server\battleye\scripts.txt
```

Then restart the server. Expected restored sha256
`032032DB2DC9BC62235E4737047200CB0B2339F6A2ECA0D97C9373BCF061540F`.
