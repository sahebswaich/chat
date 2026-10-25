#!/usr/bin/env node
// Local stand-in for the market APIs, for `wrangler dev` without internet access or to try
// the UI with stable data. Start it, then set MARKET_BASE_OVERRIDE=http://127.0.0.1:9911
// in .dev.vars. Data is synthetic (seeded), shaped like the real responses.
//
//   node scripts/mock-market.mjs [port]

import { createServer } from "node:http";

const port = Number(process.argv[2] ?? 9911);
const COINS = [
  ["BTC", 112000, 2.2e12, 40], ["ETH", 4100, 4.9e11, 25], ["SOL", 210, 1.1e11, 20], ["XRP", 2.6, 1.5e11, 20],
  ["DOGE", 0.24, 3.5e10, 20], ["HYPE", 46, 1.5e10, 10], ["SUI", 3.4, 1.2e10, 10], ["LINK", 22, 1.4e10, 10],
  ["AVAX", 29, 1.2e10, 10], ["ENA", 0.62, 4.1e9, 10], ["WLD", 1.3, 2.9e9, 10], ["TIA", 1.6, 1.2e9, 10],
  ["ONDO", 0.92, 2.9e9, 10], ["NEAR", 2.8, 3.5e9, 10], ["ADA", 0.82, 2.9e10, 10], ["XLM", 0.38, 1.2e10, 10],
  ["STX", 0.62, 9.5e8, 5], ["TAO", 420, 4e9, 5], ["kPEPE", 0.0105, 4.4e9, 10], ["WIF", 0.85, 8.5e8, 10],
  ["KAITO", 1.4, 3.4e8, 5], ["PENGU", 0.031, 1.9e9, 5], ["AAVE", 290, 4.4e9, 10], ["ARB", 0.45, 2.4e9, 10],
];
const KOREA = { XRP: 129.3e9, WLD: 106.3e9, NEAR: 36.0e9, TIA: 35.1e9, ONDO: 28.1e9, ENA: 18.0e9, ADA: 10.5e9, STX: 10.3e9, XLM: 9.8e9, BTC: 180e9, ETH: 95e9, SOL: 60e9, DOGE: 40e9, SUI: 22e9, USDT: 400e9 };

let seed = 7;
const rand = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
const sym = (name) => (name.startsWith("k") ? name.slice(1) : name);

function candles(coin, interval, n = 90) {
  const [, px] = COINS.find(([c]) => c === coin) ?? [coin, 1];
  const step = { "1d": 1, "3d": 3, "1w": 7 }[interval] ?? 1;
  seed = [...coin].reduce((a, ch) => a + ch.charCodeAt(0), 0) * 97 + step;
  const drift = (rand() - 0.45) * 0.01 * step;
  let c = px / (1 + drift * n);
  const out = [];
  const start = Date.now() - n * step * 86400000;
  for (let i = 0; i < n; i++) {
    const breakout = i > n - 4 && rand() > 0.35 ? (rand() > 0.3 ? 1.06 : 0.94) : 1;
    const o = c;
    c = c * (1 + drift + (rand() - 0.5) * 0.05 * Math.sqrt(step)) * breakout;
    const h = Math.max(o, c) * (1 + rand() * 0.02);
    const l = Math.min(o, c) * (1 - rand() * 0.02);
    out.push({ t: start + i * step * 86400000, T: start + (i + 1) * step * 86400000 - 1, o: String(o), h: String(h), l: String(l), c: String(c), v: String(1000 * (breakout !== 1 ? 3 : 1) * (0.6 + rand())) });
  }
  return out;
}

function book(coin) {
  const [, px] = COINS.find(([c]) => c === coin) ?? [coin, 1];
  const depth = coin === "BTC" || coin === "ETH" ? 4e5 : coin === "KAITO" || coin === "STX" ? 4e3 : 4e4;
  const side = (dir) => Array.from({ length: 20 }, (_, i) => {
    const p = px * (1 + dir * 0.0004 * (i + 1));
    return { px: String(p), sz: String(depth / p), n: 3 };
  });
  return { coin, time: Date.now(), levels: [side(-1), side(1)] };
}

const routes = {
  "/coingecko/api/v3/coins/markets": () => COINS.map(([c, px, mcap]) => ({ id: sym(c).toLowerCase(), symbol: sym(c).toLowerCase(), name: sym(c), current_price: px, market_cap: mcap, total_volume: mcap * 0.04 })),
  "/coingecko/api/v3/derivatives": () => COINS.flatMap(([c, px, mcap]) => ["Binance (Futures)", "Bybit", "OKX", "Hyperliquid"].map((m, i) => ({ market: m, symbol: `${sym(c)}USDT`, index_id: sym(c), price: String(px), contract_type: "perpetual", funding_rate: (rand() - 0.3) * 0.03, open_interest: mcap * (0.004 + rand() * 0.03) / (i + 1), volume_24h: mcap * 0.05 / (i + 1) }))),
  "/upbit/v1/ticker/all": () => [...Object.entries(KOREA).map(([s, v]) => ({ market: `KRW-${s}`, trade_price: s === "USDT" ? 1395 : 1000, acc_trade_price_24h: v * 0.7, signed_change_rate: (rand() - 0.4) * 0.12 }))],
  "/bithumb/public/ticker/ALL_KRW": () => ({ status: "0000", data: Object.fromEntries(Object.entries(KOREA).map(([s, v]) => [s, { closing_price: "1", acc_trade_value_24H: String(v * 0.3), fluctate_rate_24H: String(((rand() - 0.4) * 12).toFixed(2)) }])) }),
  "/krakenFutures/derivatives/api/v3/tickers": () => ({ tickers: COINS.map(([c, px]) => ({ symbol: `PF_${c === "BTC" ? "XBT" : sym(c)}USD`, bid: px * 0.9997, ask: px * 1.0003, bidSize: 5, askSize: 5 })) }),
};

createServer(async (req, res) => {
  const url = new URL(req.url, "http://x");
  let body = "";
  for await (const chunk of req) body += chunk;
  let data;
  if (url.pathname === "/hyperliquid/info") {
    const q = JSON.parse(body || "{}");
    if (q.type === "metaAndAssetCtxs") {
      data = [
        { universe: COINS.map(([c, , , lev]) => ({ name: c, szDecimals: 2, maxLeverage: lev })) },
        COINS.map(([c, px, mcap]) => ({ funding: String((rand() - 0.35) * 0.00006), openInterest: String((mcap * 0.003) / px), prevDayPx: String(px * 0.98), dayNtlVlm: String(mcap * 0.01), premium: "0", oraclePx: String(px), markPx: String(px) })),
      ];
    } else if (q.type === "candleSnapshot") data = candles(q.req.coin, q.req.interval);
    else if (q.type === "l2Book") data = book(q.coin);
  } else {
    const handler = routes[url.pathname];
    data = handler?.();
  }
  if (data === undefined) {
    res.writeHead(404).end("not found");
    return;
  }
  res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(data));
}).listen(port, "127.0.0.1", () => console.log(`mock market data on http://127.0.0.1:${port}`));
