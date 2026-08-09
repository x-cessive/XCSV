# EXILE-DB-001 Reconciliation - 2026-08-09

Issue: https://github.com/x-cessive/XCSV/issues/10

## Current Tracker State

- GitHub issue #10: closed
- Project state: `VERIFIED_DONE` / `PASS` / `G4`
- Repair evidence already posted: active extDB3 SQL_CUSTOM files repaired, active and mirror hashes recorded, server restarted, extDB3 log had no SQL_CUSTOM errors, disposable probe rows proved `insertConstruction`, `insertContainer`, `updateContainer`, and `createTerritory` store SQL `NULL` correctly, and probe data was removed.

## 2026-08-09 Read-Only Live Check

Command used:

`E:\ExileRepo\tools\database\test-extdb3-persistence.ps1`

Result:

- required SQL sections present
- `account`: 40 rows
- `player`: 3 rows, latest `last_updated_at` 2026-08-09 07:45:40
- `vehicle`: 115 rows, latest `last_updated_at` 2026-08-09 04:12:41
- `container`: 0 rows
- `territory`: 0 rows

Additional read-only table count:

- `construction`: 0 rows
- `container`: 0 rows
- `territory`: 0 rows

No database credentials were printed; queries used a temporary mysql defaults file and removed it afterward.

## Reconciliation Verdict

`PASS_VERIFIED` remains supported for the SQL/extDB3 repair itself.

Actual player-driven construction, container, and territory persistence through restart/reload is still `UNKNOWN` because the live tables currently contain no rows in those three affected tables and the available evidence does not show a real player/admin placement surviving restart after the repair.

## Next Highest-Value Work

If no higher-priority active defect appears, the next XCSV work item should be a bounded EXILE-DB-001 post-closure verification:

1. Capture baseline counts for `construction`, `container`, and `territory`.
2. Use an actual in-game admin/player action to place one disposable construction, one disposable lockable container, and one disposable territory flag.
3. Confirm rows appear with expected nullable fields.
4. Restart/reload the server through the normal controlled path.
5. Confirm the same rows reload in-game and remain in the database.
6. Remove only the disposable test objects and verify cleanup.

This is a verification gap, not evidence that the repaired SQL has regressed.
