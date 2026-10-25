# Terminal

A password-gated trading terminal on one **Cloudflare Worker** + **D1**. Pick a timeframe
(**1D · 3D · 1W**) and it ranks perpetual-futures setups, sizes them to your account rules, and
shows the intel behind each: open interest vs market cap, funding, breakouts and "since when",
Korea vs global flow, and order-book impact.

## What each panel uses

| Panel | Source (public APIs, cached at the edge) | What it shows |
|---|---|---|
| **Setups** | Hyperliquid candles (1d/3d/1w), funding, OI, max leverage; CoinGecko derivatives + markets; Upbit + Bithumb; hourly snapshots in D1 | Long/short score with a per-component breakdown, the breakout (when, level, move since, holding or failed), and a plan: stop, 2R target, size, leverage, which limit bound it |
| **Korea flow** | Upbit + Bithumb 24h KRW turnover; CoinGecko global volume | TokenPost-style table: Korea share, global share, Korea ÷ global, interest score, ₩ turnover |
| **Leverage map** | CoinGecko derivatives (all venues) + markets; Hyperliquid | Perp OI per asset across venues, OI ÷ market cap, OI-weighted funding, volume ÷ OI |
| **Zero-fee trenches · pair impact** | Hyperliquid order books; Kraken Futures (optional) | Buy/sell impact in bps for your pair size, round trip with and without fees, and every long/short pair that fits your max impact |
| **Journal** (owner only) | Your fills (typed or pasted CSV) + Hyperliquid marks | Move since each fill, P&L, how long ago |

**Score.** Seven components, each −1…+1, weighted (Rules → Signal weights), summed to ±100:
breakout (fresh close through the prior N-bar high/low and still holding), momentum, volume vs
median, funding (paying to be long counts against longs), leverage (perp OI 0.5–10% of market
cap fuels moves; above 20% is liquidation risk), OI flow (price and OI rising together = new
longs; needs a day of hourly snapshots), and Korea flow (heavy Korean over-trading helps early,
warns late). N is 20 bars on 1D, 10 on 3D, 8 on 1W.

**Size** = the smallest of: risk ÷ stop distance (stop = 1.5 ATR by default), equity × leverage
cap (separate caps for BTC/ETH and alts — set them to your funded-account rules), and a share of
total perp open interest (0.25% by default).

**Link parameters** (so a URL reproduces a view; the zero-fee trenches names are kept):
`tf=1d|3d|1w`, `excluded=KAITO,PENGU`, `universe=30`, `pairImpact=1`, `pairImpactBps=20`,
`pairSize=25000`, `kraken=0|1`.

Keys: `1` / `3` / `w` switch timeframe, `r` refreshes.

## Deploy

```bash
cd ~/chat/terminal
npm install
npx wrangler login
SECRETS_FILE=$(mktemp)
cat > "$SECRETS_FILE" <<EOF
ROOM_PASSWORD=pick-a-long-password
SESSION_SECRET=$(openssl rand -hex 32)
EOF
npx wrangler deploy --secrets-file "$SECRETS_FILE"
rm "$SECRETS_FILE"
npx wrangler d1 migrations apply trading-terminal --remote
```

Optional: a free CoinGecko Demo key raises rate limits — `npx wrangler secret put COINGECKO_API_KEY`.

**Own domain:** domain on Cloudflare DNS → in `wrangler.jsonc` uncomment
`"routes": [{ "pattern": "terminal.yourdomain.com", "custom_domain": true }]` → deploy.

**Sharing:** Share → Create link. The link opens the market panels read-only (never the
journal); Turn off kills it.

**Plan limits:** on the Workers Free plan a request may make 50 outbound calls, which caps the
board at 36 coins (`universe`). The Paid plan ($5/month) lifts that.

Binance is not used as a source: its futures API refuses US-hosted requests, and Cloudflare
often serves from the US. CoinGecko's derivatives feed already includes Binance's open interest
and funding.

## Develop

```bash
npm test                       # signal math + API on fixtures (workerd + local D1)
node scripts/mock-market.mjs & # synthetic market data on :9911
npx wrangler dev --var MARKET_BASE_OVERRIDE:http://127.0.0.1:9911
```
