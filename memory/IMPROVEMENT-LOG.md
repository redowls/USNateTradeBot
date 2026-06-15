# Improvement Log

Append-only. One improvement per post-close run, numbered IMP-NNN.

## IMP-001 — 2026-06-12
Evidence: Paper account PA33JDUCZARX reset $10,000 → $0 at ~11:00 UTC on day 1 (still $0 at 22:00 UTC). Routines caught it only via prose vigilance — no hard rule existed. Inverse failure mode is worse: a reset to a larger default (e.g. $100k) would make the 20%-of-equity sizing rule scale entries 10x against an unverified baseline.
Change: Added an equity-reconciliation hard gate — if equity is $0 or deviates >10% beyond what open positions' P&L explains vs the last TRADE-LOG EOD snapshot, pre-market plans no trades and market-open places NO orders; both prefix the Telegram message with "OPERATOR ALERT: equity $X vs last snapshot $Y".
Files: routines/pre-market.md (STEP 2), routines/market-open.md (STEP 3 hard-checks)
Expected effect: Account resets/funding glitches become a hard trading blocker with an explicit operator alert, instead of relying on the session noticing; prevents mis-sized entries off a corrupted equity baseline. Strengthens capital protection (no limits loosened).

## IMP-002 — 2026-06-15
Evidence: For two consecutive sessions the bot deferred its only ideas as vague prose with no actionable level — 06-12 "VLO, BKR on Energy RS post-FOMC", 06-15 "NVDA, AVGO on a pullback to support; revisit post-FOMC". No trigger price, support/stop, target, or invalidation is ever recorded. With FOMC Wed Jun 17 and Juneteenth (closed) Fri Jun 19, the next session is meant to "revisit post-FOMC" but nothing defines at what price NVDA/AVGO becomes a 2:1 buy — the deferred edge is lost and must be re-derived, and a clean entry between routines can be missed. improve.md STEP 2 names "a format that loses information" as a target.
Change: Added watchlist discipline to the pre-market routine. STEP 1 now triages each prior "Watchlist:" item as TRIGGER HIT (promote to a trade idea), PENDING (carry forward), or INVALIDATED (drop). STEP 4 requires every deferred idea recorded as an actionable line (ticker, trigger price, support/stop, target ≥2:1, catalyst, invalidation) — vague prose disallowed. STEP 5 requires the RESEARCH-LOG "Watchlist:" line in that actionable form.
Files: routines/pre-market.md (STEP 1, STEP 4, STEP 5)
Expected effect: A deferred setup survives session-to-session as an executable plan, so post-FOMC/pullback entries fire on a pre-defined 2:1 trigger instead of being re-researched or missed. Reinforces hard rule 11 (documented 2:1 plan before entry); no limit loosened.
