# INFISTAR-AUDIT-001 - the audit trail is now backed up; the 403 is not ours to fix

Work ID: `INFISTAR-AUDIT-001`

Owning target: `E:\arma3server\@infiSTAR_A3_vision`, GUARD doctor

Priority: P2 - single copy of the only audit record

Gauntlet: G2

Date: 2026-08-10

Verdict: `PASS_BACKUP_VERIFIED` / `EXTERNAL_BLOCKER_403`

## Two separate problems

GUARD doctor has carried one warning for days:

```text
WARN infistar-cloud  133 of the last 200 lines are 403 Forbidden
     -> The hosted panel receives nothing. Local logs are the only audit
        trail and are unbacked-up.
```

That is two claims. Only one of them was actionable from this machine.

## The 403 is an external blocker

Diagnosed, not guessed. `log_data.log` contains **6,612** occurrences of

```text
The remote server returned an error: (403) Forbidden.
```

with the first at `01.08.2026 09:26:41` - the very start of the retained log, so
it has been failing at least since then and possibly longer.

The client itself is healthy. `vision.log` shows `Loading config.vision` 577
times and `Successfully loaded ... config.vision` 574 times across the same
period. So the uploader starts, reads its configuration, and the **remote** end
refuses it. A 403 is an authorisation decision made by infiSTAR's server, not a
local fault.

Ruled out as red herrings: three `GetLicenseInformation ERROR` lines on
2026-08-03 are `The process cannot access the file ... config.vision`, i.e. file
lock contention from two server instances overlapping. They are unrelated to the
403, which is constant and predates them.

**This needs the infiSTAR licence renewed or reissued by the account holder.**
There is no local change that fixes it, and none was attempted. It stays as a
doctor warning on purpose - suppressing it would hide a real gap in coverage.

## The unbacked-up part is fixed

With the panel receiving nothing, the local logs are the entire record of admin
actions, player joins, BattlEye events and Zeus usage - 31.9 MB across 15 files,
history back to 2026-08-01 - and they sat on the same drive as the server with
no copy anywhere. One disk fault and the audit trail was gone.

`tools/backup-infistar-logs.ps1` takes a compressed, hash-manifested snapshot
onto a different drive:

```text
archived 15 file(s), 31.93 MB -> 1.06 MB  infistar-20260810-043750.zip
verified 16 entries in the archive (including MANIFEST.txt)
```

Design decisions worth stating:

- **Read-only with respect to the live logs.** It copies; it never truncates,
  rotates or deletes anything under `@infiSTAR_A3_vision`. infiSTAR holds those
  files open, and truncating a log a running process has a handle on risks
  corruption or silently lost writes. E: has 118 GB free, so there is no reason
  to take that risk - growth is not the problem, absence of a copy is.
- **Opens with `FileShare.ReadWrite`**, because the busy files throw on a plain
  `Copy-Item`.
- **`config.vision` is excluded deliberately.** It is configuration rather than
  audit data and holds the infiSTAR licence material. It happens to be
  exclusively locked while the server runs, but relying on that would mean the
  archive quietly starts collecting credentials the first time a backup runs
  with the server stopped.
- **A SHA-256 manifest per file.** An audit trail you cannot prove is unmodified
  is a weak audit trail.
- **The archive is verified before the staging copy is deleted.** An unverified
  backup is a guess.
- **Staging lives on the destination drive, never C:** - filling the system
  drive with scratch data is a mistake this estate has already made once.

Scheduled as **XCSV infiSTAR Audit Backup**, daily at 05:15, hidden, with
`-StartWhenAvailable` so a machine that was off does not silently skip a day.
First run returned `LastTaskResult 0`. Retention keeps 30 archives, roughly
32 MB at current compression.

## Doctor updated

The old remediation text said the logs "are unbacked-up", which is now false and
would mislead the next reader. It now states what the 403 actually is and points
at the archive.

A new check watches the thing that can silently fail:

```text
PASS  audit-backup  3 archive(s), newest 0 h old
```

It warns if the newest snapshot is over 48 hours old, if the directory holds no
snapshots, or if it is missing entirely. A backup job that quietly stops is the
realistic failure here, and nothing was watching for it before.

Doctor now reads **26 passed, 1 warned, 0 failed** - the single remaining
warning being the external 403.

## Follow-up for ARCHITECT

Renew or reissue the infiSTAR licence if hosted-panel reporting is still wanted.
Until then the local archive is the audit trail of record, and it is now
verifiable and off-drive.
