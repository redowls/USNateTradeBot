# Build USNateTradeBot — agentic Claude swing-trading bot (local routines)

## Context

Build the trading bot described in `redowls/USNateTradeBot` → "Trading Bot — Setup Guide.md" (50KB spec, from Nate Herk's video *"I Turned Claude Into a 24/7 Trader"*). Unlike USTradeWisBot/CryptoTradeWisBot (Python algos), here **Claude itself is the trader**: scheduled headless Claude runs read a memory-in-git rulebook, do web research, place orders through a thin bash Alpaca wrapper, and commit their logs/decisions back to git. The strategy improves over time because each run reads the accumulated memory, and review routines adjust the strategy files.

**User decisions (confirmed):**
- Fresh Alpaca **paper** account dedicated to this bot (keys to be provided at start of execution)
- **Claude WebSearch** for research (no Perplexity key)
- **Telegram** notifications via the existing `/root/claude-routines/run-routine.sh` delivery (no ClickUp)
- Build at `/root/USNateTradeBot`, push to `redowls/USNateTradeBot` (guide .md stays as docs)
- The video's **cloud routines are replaced by local cron** entries in `/root/claude-routines` (the user's existing cron-safe headless-Claude→Telegram scaffold with flock, timeout, per-routine `.conf` tool permissions)

**Strategy hard rules (from the guide — seed `memory/TRADING-STRATEGY.md` verbatim):**
~$10k paper capital · stocks only, NO options · 75–85% deployed · 5–6 positions, max 20% each · 10% trailing stop GTC on every position · cut losers at −7% · tighten trail to 7% at +15%, 5% at +20% · never tighten within 3% of price, never move a stop down · max 3 new trades/week · sector momentum; exit a sector after 2 consecutive failed trades · PDT: max 3 day-trades per 5 rolling days · min 2:1 R:R, documented catalyst before every entry · default HOLD when no edge.

## Repository layout (to create)

```
/root/USNateTradeBot/                  (clone of redowls/USNateTradeBot)
├── Trading Bot — Setup Guide.md      (existing — keep)
├── CLAUDE.md                          (agent instructions — Appendix A, adapted)
├── env.template                       (Alpaca paper keys only)
├── .env                               (gitignored, chmod 600)
├── .gitignore                         (.env, logs/)
├── scripts/
│   └── alpaca.sh                      (Appendix C: account|positions|orders|quote|order|close|cancel|clock)
├── routines/                          (the 5 workflow prompts — Appendix F, adapted)
│   ├── pre-market.md   ├── market-open.md   ├── midday.md
│   ├── daily-summary.md└── weekly-review.md
├── memory/                            (Appendix H seeds)
│   ├── PROJECT-CONTEXT.md  ├── TRADING-STRATEGY.md  ├── TRADE-LOG.md
│   ├── RESEARCH-LOG.md     └── WEEKLY-REVIEW.md
└── .claude/commands/
    ├── portfolio.md                   (read-only snapshot — Appendix G.1)
    └── trade.md                       (manual trade w/ rule validation — G.2)
```

No `perplexity.sh` (routines use WebSearch). No `clickup.sh` (run-routine.sh already sends each routine's stdout to Telegram).

## Adaptations from the guide

1. **Cloud routines → local cron.** For each of the 5 workflows, add to `/root/claude-routines/`:
   - `natebot-<name>.md` — thin wrapper prompt: "Work in /root/USNateTradeBot. Follow routines/<name>.md exactly. Print only the final Telegram summary."
   - `natebot-<name>.conf` — overrides: `TIMEOUT_SECS` (~1200), `ALLOWED_TOOLS` granting Read/Write/Edit/Bash/WebSearch + git commit/push (mirror the pattern in the existing `uswisbot-postclose-improve` routine's conf).
   - Check `run-routine.sh` for a working-dir mechanism; if it always runs in `/root/claude-routines`, the wrapper prompt's explicit `cd /root/USNateTradeBot` instruction suffices (Bash tool), or add a `WORKDIR` conf override if trivial.
2. **Perplexity → WebSearch** in pre-market/midday/weekly prompts (search catalysts, earnings calendar, sector momentum, VIX/futures).
3. **No env-var prompt blocks** (cloud-specific). Scripts source the local `.env`.
4. **Persistence step kept**: every routine ends with `git add memory/ && git commit && git push` (memory-in-git is the whole point).
5. **Daily self-improvement routine (user requirement, 6th routine)** `natebot-improve` — post-close Mon–Fri, modeled on the existing `uswisbot-postclose-improve`: review TRADE-LOG/RESEARCH-LOG vs outcomes, make ONE small, safe improvement to routine prompts or strategy parameters (never violating hard rules), commit+push, report the change to Telegram. This is the "bot gets better day by day" loop.

## Cron schedule (VPS is UTC; guide times are America/Chicago, currently CDT = UTC−5)

| Routine | CT (guide) | cron (UTC) |
|---|---|---|
| natebot-premarket | 6:00 M–F | `0 11 * * 1-5` |
| natebot-market-open | 8:30 M–F | `30 13 * * 1-5` |
| natebot-midday | 12:00 M–F | `0 17 * * 1-5` |
| natebot-daily-summary | 15:00 M–F | `0 20 * * 1-5` |
| natebot-weekly-review | 16:00 Fri | `0 21 * * 5` |
| natebot-improve | ~17:00 M–F | `0 22 * * 1-5` |

Append to root's crontab below the existing entries, same `>> logs/cron.log` pattern. Add a comment noting the −1h shift needed when CST returns (November).

## Implementation steps

1. **Ask user for the new Alpaca paper API key + secret** (per their per-phase workflow: creds → checkpoint → push). Also confirm the paper endpoint `https://paper-api.alpaca.markets/v2`.
2. **Clone** `https://github.com/redowls/USNateTradeBot.git` to `/root/USNateTradeBot`; configure the shared PAT credential helper (same pattern as USTradeWisBot — `/root/.git-credentials` line already exists for redowls). **Caveat:** the PAT is fine-grained and may not include this repo — test with a dry-run push; if 403, ask user to add USNateTradeBot to the PAT's repo list.
3. **Scaffold** `.gitignore`, `env.template`, `.env` (chmod 600), `CLAUDE.md` (Appendix A adapted: WebSearch + Telegram, hard-rules quick reference, read-memory-first protocol).
4. **Write `scripts/alpaca.sh`** per Appendix C: curl wrapper, subcommands `account positions orders quote SYM order JSON close SYM cancel ID clock`; bake in the guide's Alpaca gotchas (wait for fill before placing trailing stop; trailing stops are GTC; PDT rejection handling). Verify against the paper account: `alpaca.sh account`, `clock`, `quote AAPL`.
5. **Seed `memory/`** from Appendix H, with real Day-0 equity from the paper account.
6. **Write the 5 routine prompts** in `routines/` from Appendix F, with the adaptations above (WebSearch, no env block, keep hard-check STEP gates: positions ≤6, weekly trades ≤3, ≤20% equity per position, catalyst documented, PDT room; market orders day-TIF then immediate 10% trailing stop GTC; midday cut −7% losers, tighten winners' trails).
7. **Write `.claude/commands/portfolio.md` and `trade.md`** per Appendix G.
8. **Wire local routines**: 6 wrapper `.md` + `.conf` files in `/root/claude-routines`, then append the 6 crontab entries.
9. **Verify** (see below), then commit everything and push.

## Verification

1. `bash scripts/alpaca.sh account|clock|quote AAPL` returns valid JSON from the paper endpoint.
2. Manual dry-run of one read-only routine: `/root/claude-routines/run-routine.sh natebot-daily-summary` → Telegram message arrives, memory committed and pushed.
3. Manual run of `natebot-premarket` (it's safe — research only, writes RESEARCH-LOG, no orders) → check the log quality and git push.
4. `crontab -l` shows the 6 entries; next trading morning, confirm pre-market + market-open fired via `logs/cron.log` and Telegram.
5. First real validation: market-open routine either places a rule-compliant paper trade (with trailing stop visible in `alpaca.sh orders`) or logs a justified HOLD.
6. Git: `git log` on GitHub shows routine commits (memory-in-git audit trail working).

## Out of scope (explicit)

- Live trading (paper only; going live is a later, separate decision)
- Perplexity/ClickUp integration
- Touching USTradeWisBot, USTradeBot V1, or CryptoTradeWisBot
