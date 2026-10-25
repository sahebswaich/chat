// Test helpers: call the Worker, sign in, and answer market-API fetches from fixtures.

import { exports } from "cloudflare:workers";
import { expect, vi } from "vitest";

export const BASE = "https://terminal.example.com";
export const PASSWORD = "test-password";
const MARKET = "https://market.test";

export function call(method: string, path: string, opts: { body?: unknown; cookie?: string; headers?: Record<string, string> } = {}) {
  const headers: Record<string, string> = { ...opts.headers };
  if (opts.body !== undefined) headers["content-type"] = "application/json";
  if (opts.cookie) headers["cookie"] = opts.cookie;
  return exports.default.fetch(
    new Request(BASE + path, { method, headers, body: opts.body === undefined ? undefined : JSON.stringify(opts.body), redirect: "manual" }),
  );
}

export const cookieFrom = (res: Response) => (res.headers.get("set-cookie") ?? "").split(";")[0]!;

export async function signIn(): Promise<string> {
  const res = await call("POST", "/login", { body: { password: PASSWORD }, headers: { "cf-connecting-ip": "10.0.0.1" } });
  expect(res.status).toBe(200);
  return cookieFrom(res);
}

const DAY = 86_400_000;

/** Daily candles: flat around 100 for `flat` days, then a breakout leg up. */
export function candles(coin: string, n = 90, breakoutAt = 3) {
  const out = [];
  const start = Date.UTC(2026, 6, 1);
  for (let i = 0; i < n; i++) {
    const fromEnd = n - 1 - i;
    const base = coin === "ETH" ? 100 - (i % 3) : 100 + (i % 3);
    const c = fromEnd < breakoutAt ? (coin === "ETH" ? 90 - (breakoutAt - fromEnd) * 3 : 110 + (breakoutAt - fromEnd) * 3) : base;
    out.push({ t: start + i * DAY, T: start + (i + 1) * DAY - 1, o: String(c), h: String(c + 1), l: String(c - 1), c: String(c), v: String(fromEnd < breakoutAt ? 3000 : 1000) });
  }
  return out;
}

export const hlMeta = [
  {
    universe: [
      { name: "BTC", szDecimals: 5, maxLeverage: 40 },
      { name: "ETH", szDecimals: 4, maxLeverage: 25 },
      { name: "kPEPE", szDecimals: 0, maxLeverage: 10 },
      { name: "OLD", szDecimals: 0, maxLeverage: 3, isDelisted: true },
    ],
  },
  [
    { funding: "0.0000125", openInterest: "20000", prevDayPx: "105", dayNtlVlm: "5000000000", premium: "0", oraclePx: "118", markPx: "119", impactPxs: ["118.9", "119.1"] },
    { funding: "-0.00002", openInterest: "300000", prevDayPx: "88", dayNtlVlm: "2000000000", premium: "0", oraclePx: "81", markPx: "81", impactPxs: ["80.9", "81.1"] },
    { funding: "0.0001", openInterest: "1000000000", prevDayPx: "0.01", dayNtlVlm: "50000000", premium: "0", oraclePx: "0.012", markPx: "0.012", impactPxs: null },
    { funding: "0", openInterest: "1", prevDayPx: "1", dayNtlVlm: "1", premium: "0", oraclePx: "1", markPx: "1", impactPxs: null },
  ],
];

export const cgMarkets = [
  { id: "bitcoin", symbol: "btc", name: "Bitcoin", current_price: 119, market_cap: 2_000_000_000_000, total_volume: 50_000_000_000 },
  { id: "ethereum", symbol: "eth", name: "Ethereum", current_price: 81, market_cap: 400_000_000_000, total_volume: 20_000_000_000 },
  { id: "pepe", symbol: "pepe", name: "Pepe", current_price: 0.000012, market_cap: 5_000_000_000, total_volume: 1_000_000_000 },
  { id: "xrp", symbol: "xrp", name: "XRP", current_price: 2, market_cap: 100_000_000_000, total_volume: 5_000_000_000 },
  { id: "fake-xrp", symbol: "xrp", name: "Fake XRP", current_price: 1, market_cap: 1_000, total_volume: 999_000_000_000 },
];

export const cgDerivatives = [
  { market: "Binance (Futures)", symbol: "BTCUSDT", index_id: "BTC", price: "119", contract_type: "perpetual", funding_rate: 0.01, open_interest: 30_000_000_000, volume_24h: 60_000_000_000 },
  { market: "Bybit", symbol: "BTCUSDT", index_id: "BTC", price: "119", contract_type: "perpetual", funding_rate: 0.03, open_interest: 10_000_000_000, volume_24h: 20_000_000_000 },
  { market: "CME", symbol: "BTCZ6", index_id: "BTC", price: "119", contract_type: "futures", funding_rate: null, open_interest: 9_000_000_000, volume_24h: 1 },
  { market: "Binance (Futures)", symbol: "ETHUSDT", index_id: "ETH", price: "81", contract_type: "perpetual", funding_rate: -0.01, open_interest: 12_000_000_000, volume_24h: 30_000_000_000 },
  { market: "Binance (Futures)", symbol: "1000PEPEUSDT", index_id: "PEPE", price: "0.012", contract_type: "perpetual", funding_rate: 0.05, open_interest: 600_000_000, volume_24h: 900_000_000 },
];

export const upbit = [
  { market: "KRW-BTC", trade_price: 160_000_000, acc_trade_price_24h: 200_000_000_000, signed_change_rate: 0.02 },
  { market: "KRW-XRP", trade_price: 2800, acc_trade_price_24h: 300_000_000_000, signed_change_rate: 0.08 },
  { market: "KRW-USDT", trade_price: 1400, acc_trade_price_24h: 500_000_000_000, signed_change_rate: 0 },
  { market: "BTC-ETH", trade_price: 0.03, acc_trade_price_24h: 1, signed_change_rate: 0 },
];

export const bithumb = {
  status: "0000",
  data: {
    BTC: { closing_price: "160000000", acc_trade_value_24H: "100000000000", fluctate_rate_24H: "2.1" },
    PEPE: { closing_price: "0.02", acc_trade_value_24H: "50000000000", fluctate_rate_24H: "-4.0" },
    date: "1790000000000",
  },
};

export function book(mid: number, levels = 20, sizeUsd = 50_000, tick = 0.0005) {
  const bids = [];
  const asks = [];
  for (let i = 0; i < levels; i++) {
    const bpx = mid * (1 - tick * (i + 1));
    const apx = mid * (1 + tick * (i + 1));
    bids.push({ px: String(bpx), sz: String(sizeUsd / bpx), n: 1 });
    asks.push({ px: String(apx), sz: String(sizeUsd / apx), n: 1 });
  }
  return { coin: "X", time: 0, levels: [bids, asks] };
}

/** Drops cached CoinGecko answers so a test can see CoinGecko fail. */
export async function clearCoingeckoCache() {
  await caches.default.delete(new Request(`${MARKET}/coingecko/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&page=1&price_change_percentage=24h,7d`));
  await caches.default.delete(new Request(`${MARKET}/coingecko/api/v3/derivatives?include_tickers=unexpired`));
}

/** Answers every market fetch from fixtures; returns the URLs/bodies requested. */
export function mockMarkets(overrides: { failCoingecko?: boolean } = {}) {
  const calls: string[] = [];
  vi.spyOn(globalThis, "fetch").mockImplementation(async (input: RequestInfo | URL, init?: RequestInit) => {
    const req = new Request(input, init);
    const url = req.url;
    if (!url.startsWith(MARKET)) throw new Error(`Unexpected outbound fetch in test: ${url}`);
    const path = url.slice(MARKET.length);
    const body = req.method === "POST" ? ((await req.json()) as { type: string; req?: { coin: string }; coin?: string }) : null;
    calls.push(body ? `${path} ${body.type}${body.req ? ":" + body.req.coin : body.coin ? ":" + body.coin : ""}` : path);
    const ok = (data: unknown) => new Response(JSON.stringify(data), { headers: { "content-type": "application/json" } });
    if (path.startsWith("/coingecko/")) {
      if (overrides.failCoingecko) return new Response("rate limited", { status: 429 });
      return ok(path.includes("/derivatives") ? cgDerivatives : cgMarkets);
    }
    if (path === "/hyperliquid/info" && body) {
      if (body.type === "metaAndAssetCtxs") return ok(hlMeta);
      if (body.type === "candleSnapshot") return ok(candles(body.req!.coin));
      if (body.type === "l2Book") return ok(body.coin === "kPEPE" ? book(0.012, 2, 5_000) : book(100));
    }
    if (path.startsWith("/upbit/")) return ok(upbit);
    if (path.startsWith("/bithumb/")) return ok(bithumb);
    if (path.startsWith("/krakenFutures/")) {
      return ok({ tickers: [{ symbol: "PF_XBTUSD", bid: 118.9, ask: 119.1, bidSize: 10, askSize: 12 }, { symbol: "PI_XBTUSD", bid: 1, ask: 2 }] });
    }
    return new Response("not found", { status: 404 });
  });
  return calls;
}
