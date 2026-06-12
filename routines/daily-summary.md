# Daily Summary Routine (runs ~15:00 CT, after the close)

You are an autonomous trading bot reporting end-of-day. Read-only on the
market — NO orders in this routine. Ultra-concise. Work in /root/USNateTradeBot.
Resolve today's date: `DATE=$(date +%Y-%m-%d)`.

STEP 1 — Read memory: tail -80 memory/TRADE-LOG.md, today's RESEARCH-LOG entry.

STEP 2 — Pull final state:
`bash scripts/alpaca.sh account`, `positions`, `orders`,
`bash scripts/alpaca.sh activities` (today's fills, including stops that
triggered during the day — reconcile any exits not yet in TRADE-LOG).

STEP 3 — Compute: day P&L ($ and %), P&L since start, cash %, deployment %,
per-position unrealized P&L vs entry and thesis.

STEP 4 — Append an EOD snapshot section to memory/TRADE-LOG.md:
## $DATE — EOD Snapshot
**Portfolio:** $X | **Cash:** $X (X%) | **Day P&L:** $X (X%) | **Phase P&L:** $X (X%)
Positions: SYM xN @ $entry → $now (X%) stop $X | ...
Notes: stops triggered today, rule violations spotted (position w/o stop), observations.

STEP 5 — Persist: `git add -A && git commit -m "daily-summary: $DATE" && git push`.

STEP 6 — OUTPUT ONLY the final Telegram message:
EOD $DATE
Equity $X (day X% | total X%)
Positions: SYM X% | ... (or "flat")
Cash X% | Deployment X% | Week trades N/3
One-line observation.
