#!/usr/bin/env bash
# Thin Alpaca REST wrapper (paper account). Usage:
#   alpaca.sh account                  # equity, cash, buying power, daytrade_count
#   alpaca.sh positions                # open positions with unrealized P&L
#   alpaca.sh orders                   # open orders
#   alpaca.sh clock                    # market open/close state
#   alpaca.sh activities               # recent fills
#   alpaca.sh quote SYM                # latest quote
#   alpaca.sh bars SYM [TF] [LIMIT]    # bars, default 1Day x 30
#   alpaca.sh order '<json>'           # place order (full Alpaca order JSON)
#   alpaca.sh cancel ORDER_ID          # cancel one order
#   alpaca.sh close SYM                # cancel SYM's open orders, then liquidate
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/.env"
: "${ALPACA_API_KEY:?ALPACA_API_KEY missing — copy env.template to .env}"
: "${ALPACA_SECRET_KEY:?ALPACA_SECRET_KEY missing}"
EP="${ALPACA_ENDPOINT:-https://paper-api.alpaca.markets/v2}"
DEP="${ALPACA_DATA_ENDPOINT:-https://data.alpaca.markets/v2}"

req() { # METHOD URL [JSON_BODY]
  local m="$1" u="$2" d="${3:-}"
  local args=(-sS -X "$m" "$u"
    -H "APCA-API-KEY-ID: $ALPACA_API_KEY"
    -H "APCA-API-SECRET-KEY: $ALPACA_SECRET_KEY")
  [[ -n "$d" ]] && args+=(-H "Content-Type: application/json" -d "$d")
  curl "${args[@]}"
  echo
}

cmd="${1:?usage: alpaca.sh account|positions|orders|clock|activities|quote SYM|bars SYM|order JSON|cancel ID|close SYM}"
case "$cmd" in
  account)    req GET "$EP/account" ;;
  positions)  req GET "$EP/positions" ;;
  orders)     req GET "$EP/orders?status=open&limit=100" ;;
  clock)      req GET "$EP/clock" ;;
  activities) req GET "$EP/account/activities/FILL?page_size=50" ;;
  quote)      req GET "$DEP/stocks/${2:?symbol}/quotes/latest" ;;
  bars)       req GET "$DEP/stocks/${2:?symbol}/bars?timeframe=${3:-1Day}&limit=${4:-30}" ;;
  order)      req POST "$EP/orders" "${2:?order json}" ;;
  cancel)     req DELETE "$EP/orders/${2:?order id}" ;;
  close)
    sym="${2:?symbol}"
    # Liquidating while the symbol has open orders (its trailing stop) 403s
    # with held_for_orders — cancel them first.
    for id in $(req GET "$EP/orders?status=open&symbols=$sym" | jq -r '.[].id'); do
      req DELETE "$EP/orders/$id" >/dev/null || true
    done
    sleep 1
    req DELETE "$EP/positions/$sym"
    ;;
  *) echo "unknown subcommand: $cmd" >&2; exit 1 ;;
esac
