# XM8 app concepts - ten proposals

Generated 2026-08-11 by the idea gauntlet. Provider: OpenAI `gpt-5.5` via `codex exec`, briefed with the server's canon, the real engineering constraints, and the MEASURED database state below. The two Claude expert agents meant to run alongside it both died on an account session limit, so this is ONE provider's output reviewed by hand - not a two-provider consensus. Treat the ranking as a starting point, not a verdict.

## The measured state that filters every idea

Taken live, not assumed:

| table | rows |
| --- | --- |
| account | 56 |
| vehicle | 114 |
| player | 3 |
| territory | 0 |
| construction | 0 |
| container | 0 |
| clan | 0 |

**There are no bases, no flags, no clans and no storage containers on this server.** Every territory browser, raid log, protection-money tracker and clan roster idea is dead on arrival until somebody plants a flag. That single fact removed most of the obvious proposals before they were written.

Verified by hand afterwards, because several ideas depend on it: `vehicle` does carry `class`, `fuel`, `damage` and `position_x/y/z`, so the Salvage Sheet is buildable - but **only 1 of the 114 vehicles is owned by a real Steam UID**; the rest belong to spawner pseudo-accounts. Presenting them as player property would be a lie, which is why ambient salvage is the honest framing rather than a stylistic one.

## Verification status

These are PROPOSALS. Nothing here is built, and data claims were checked only where noted above. Re-check the row counts before building any of them.

---
Read the four files. I would build these, in this order of design value.

**1. Last Night**
Pitch: `SALVAGE NET: The island kept moving while you were gone. Here is what it cost.`

Why here: With 1-2 online, the server’s main missing feature is memory. This turns RPT/infiSTAR exhaust into a daily paper: missions spawned, AI activity, lootboxes, joins, deaths, FPS dips, restarts. It makes solo login feel like returning to a place.

Sketch:
```text
LAST NIGHT: SINCE 2026-08-10 22:14
[WARDEN] boot 03:11, FPS low 04:02
[YARD  ] 2 deaths, 1 kill, 3 joins
[SALVAGE] DMS convoy failed near Lijnhaven
          lootbox opened near 073-118

[ All ] [ Combat ] [ Trade ] [ System ]
```

Data: RPT log tags for `DMS`, `A3XAI`, `a3_exile_occupation`, lootbox events, FPS samples, connection lines; infiSTAR joins/kills/BattlEye events; `account.uid`, `account.last_connect_at`.

Path: read-only. Best as server parser publishing `XCSV_Chronicle`.

Cost/risk: M. Risk is reliable log parsing across different tag formats.

BE: No.

**2. Yard Memory**
Pitch: `THE YARD: Names do not disappear just because the man logged off.`

Why here: There are 56 accounts but only 3 player rows and no clans/bases. The hidden value is old history: who used to matter, who returned, who died often, who banked tabs. This gives social shape without requiring concurrency.

Sketch:
```text
YARD MEMORY
Name          Rep   K/D   Locker   Seen
Mason         840   4/9   12,300   2d ago
Rook          410   0/3      900   19d ago
Vega        2,140   8/2   51,000   today

[Sort: Seen] [Sort: Respect] [Sort: Locker]
```

Data: `account.uid`, `account.name`, `account.score`, `account.kills`, `account.deaths`, `account.locker`, `account.first_connect_at-STRING`, `account.last_connect_at-STRING`, `account.total_connections`.

Path: read-only.

Cost/risk: S. Risk is escaping names and monospace alignment.

BE: No.

**3. Incident Grid**
Pitch: `WARDEN CONTROL: Movement advisory. Violence clusters are not patrol routes.`

Why here: A solo player needs legibility before committing an hour. This converts mission/AI/death logs into rough grid-sector risk. It does not spawn anything, mark anything globally, or need live players.

Sketch:
```text
INCIDENT GRID - LAST 24H
073-118  HIGH   DMS, lootbox, 1 death
091-102  MED    A3XAI contact
050-084  LOW    occupation patrol

[24H] [7D] [Combat] [Salvage]
```

Data: RPT log tags with positions from `DMS`, `A3XAI`, `a3_exile_occupation`, lootbox events; infiSTAR kill/death lines if coordinates are present.

Path: read-only.

Cost/risk: M. Risk is coordinate extraction and converting world positions to map grid consistently.

BE: No.

**4. Salvage Sheet**
Pitch: `SALVAGE NET: Machines outlive owners. Here is what the island is still carrying.`

Why here: `vehicle` has 114 rows, but they are not player-owned. That is perfect: treat them as ambient salvage rumors, not property. Helps solo players choose a direction without pretending there is a vehicle market.

Sketch:
```text
SALVAGE SHEET
Grid     Class             State
084-096  Offroad           fuel 42%, dmg 8%
112-073  Hatchback         fuel 11%, dmg 31%
060-121  Boat              fuel 63%, dmg 4%

[Nearest] [Fuel] [Damage]
```

Data: `vehicle.class`, `vehicle.position_x`, `vehicle.position_y`, `vehicle.position_z`, `vehicle.fuel`, `vehicle.damage`, `vehicle.account_uid`.

Path: read-only.

Cost/risk: S/M. Risk is not leaking anything sensitive like PINs, inventory, or true ownership assumptions.

BE: No.

**5. Return Board**
Pitch: `WARDEN CONTROL: Intake, absence, and recurrence. Nothing personal.`

Why here: The player count is tiny, so even “someone returned after 23 days” matters. This makes asynchronous population visible without chat spam or clan systems.

Sketch:
```text
RETURN BOARD
New intake:     2 names this week
Returned:       Rook after 19 days
Gone quiet:     Hale, 42 days absent
Most regular:   Mason, 31 connects

[Week] [Month] [All time]
```

Data: `account.name`, `account.first_connect_at-STRING`, `account.last_connect_at-STRING`, `account.total_connections`.

Path: read-only.

Cost/risk: S. Risk is date formatting from extDB3, so tag DATETIME as `-STRING`.

BE: No.

**6. Salvage Math**
Pitch: `SALVAGE NET: Traders buy at half. Count before you crawl home.`

Why here: The 0.5 sell factor is brutal and not intuitive. Trader Prices already exposes item prices; this app makes the economy playable by letting a solo scavenger estimate what a haul is actually worth before wasting time.

Sketch:
```text
SALVAGE MATH
Search: rifle
MX 6.5mm            buy 9,000  sell 4,500
Need 2,500 tabs:
  1x optic AMS, or
  6x common rifles

[Buy] [Sell] [Goal: 2500]
```

Data: config walk of trader price config already used by Trader Prices; sell factor from mission config / server price config.

Path: read-only, UI-only calculator.

Cost/risk: S. Risk is not duplicating too much of Trader Prices UI.

BE: No.

**7. Notice Wire**
Pitch: `THE YARD: Pay the board or keep talking to yourself.`

Why here: This is the cleanest asynchronous social feature after removing Player Market. No item transfer, no escrowed goods, no fake economy. Just paid, limited, server-signed messages that give the island memory.

Sketch:
```text
NOTICE WIRE
[THE YARD]  Mason: shots near 073-118.
[SALVAGE]   Vega: boat left south pier.
[WARDEN]    Contract notices are logged.

[Post 250 tabs] [Filter]
```

Data: NEW table `xcsv_notice(id, uid, name, channel, body, created_at, expires_at)`. Useful immediately after first post.

Path: write. Server resolves UID/name from session, validates channel enum, strips/limits text, charges fixed 250 tabs server-side, checks affordability before deduction, per-UID cooldown, deducts before insert.

Cost/risk: M. Risk is text sanitization for structured text and spam control.

BE: No.

**8. Bounty Ledger**
Pitch: `THE YARD: Respect is talk. Escrow is louder.`

Why here: Low population means bounties do not need instant action; they create long-lived tension. This uses the 56-account history as targets and does not require clans, flags, or bases.

Sketch:
```text
BOUNTY LEDGER
Target       Escrow   Posted
Mason        2,500    3d ago
Rook         1,000    today

[Post] [My Risk] [Closed]
```

Data: `account.uid`, `account.name`, `account.kills`, `account.deaths`; NEW table `xcsv_bounty(id, poster_uid, target_uid, amount, created_at, expires_at, claimed_by_uid, claimed_at)`. Useful once posted.

Path: write. Server resolves poster from session, validates target exists and is not self, fixed min/max amount server-side, checks money immediately, deducts before insert, per-UID cooldown. Claim/payout must be driven by trusted server kill event, not client request.

Cost/risk: L. Risk is kill attribution and payout correctness.

BE: No.

**9. Warden Receipts**
Pitch: `WARDEN CONTROL: Administrative contact is recorded. Interpret that how you like.`

Why here: On a small server, admin actions and BattlEye events shape trust. A sanitized audit feed makes the place feel governed without exposing private data or turning into surveillance theatre.

Sketch:
```text
WARDEN RECEIPTS
03:11 restart completed
04:02 FPS below threshold
11:44 BattlEye kick recorded
12:18 admin action logged

[System] [Security] [Admin]
```

Data: infiSTAR admin action logs, joins, BattlEye events; RPT boot/restart/FPS samples.

Path: read-only, sanitized server-published feed.

Cost/risk: M. Risk is redacting admin names, GUIDs, IPs, and sensitive BE detail.

BE: No.

**10. Standing Wire**
Pitch: `Three voices, one inmate. The island has already scored you.`

Why here: `XCSV_Standing` and `XCSV_Scoreboard` are already published. This app would remix them into short radio-style comparisons: who the Yard fears, who Salvage trusts, who Warden tolerates. Almost free, and it reinforces canon.

Sketch:
```text
STANDING WIRE
THE YARD       Mason leads by 31 points
SALVAGE NET    Vega has the deepest locker
WARDEN CONTROL Rook survives more than he wins

[Mine] [Top] [Changes]
```

Data: existing public variables `XCSV_Standing`, `XCSV_Scoreboard`; optionally `account.locker`, `account.kills`, `account.deaths` if not already included.

Path: read-only.

Cost/risk: S. Risk is wording variety without making it jokey or mystical.

BE: No.

**Value/Cost Rank**
1. Last Night
2. Yard Memory
3. Standing Wire
4. Return Board
5. Salvage Sheet
6. Incident Grid
7. Salvage Math
8. Notice Wire
9. Warden Receipts
10. Bounty Ledger

**Build First**
1. Last Night: directly solves “what happened since last time.”
2. Yard Memory: exposes the 56-account history already sitting unused.
3. Standing Wire: nearly free because the public variables already exist.

**Nearly Free**
Standing Wire, Yard Memory, Return Board, and Salvage Math. They are mostly rendering and sorting existing data/config, with no BE exposure and no client-server write path.

**Blocked Until Someone Plants A Flag**
- Protection Ledger: flag tax deadlines and unpaid protection money.
- Raid Scar Map: territory damage, breaching history, rebuild pressure.
- Clan Wire: roster changes, internal standing, shared enemies.


