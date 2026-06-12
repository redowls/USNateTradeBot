# Improvement Log

Append-only. One improvement per post-close run, numbered IMP-NNN.

## IMP-001 — 2026-06-12
Evidence: Paper account PA33JDUCZARX reset $10,000 → $0 at ~11:00 UTC on day 1 (still $0 at 22:00 UTC). Routines caught it only via prose vigilance — no hard rule existed. Inverse failure mode is worse: a reset to a larger default (e.g. $100k) would make the 20%-of-equity sizing rule scale entries 10x against an unverified baseline.
Change: Added an equity-reconciliation hard gate — if equity is $0 or deviates >10% beyond what open positions' P&L explains vs the last TRADE-LOG EOD snapshot, pre-market plans no trades and market-open places NO orders; both prefix the Telegram message with "OPERATOR ALERT: equity $X vs last snapshot $Y".
Files: routines/pre-market.md (STEP 2), routines/market-open.md (STEP 3 hard-checks)
Expected effect: Account resets/funding glitches become a hard trading blocker with an explicit operator alert, instead of relying on the session noticing; prevents mis-sized entries off a corrupted equity baseline. Strengthens capital protection (no limits loosened).
