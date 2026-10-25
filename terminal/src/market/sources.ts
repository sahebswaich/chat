// Public market-data sources the terminal reads. Every fetch has a timeout and is cached at
// the edge (Cache API) for a short TTL, so one page load costs a handful of upstream calls
// no matter how many people have the room open. Each source fails soft: a source that is
// down just leaves its columns empty.

import type { AppEnv } from "../env";

export interface SourceStatus {
  name: string;
  ok: boolean;
  error?: string;
  ms: number;
}

const UPSTREAM = {
  coingecko: "https://api.coingecko.com",
  hyperliquid: "https://api.hyperliquid.xyz",
  upbit: "https://api.upbit.com",
  bithumb: "https://api.bithumb.com",
  krakenFutures: "https://futures.kraken.com",
} as const;

export type UpstreamName = keyof typeof UPSTREAM;

/** Base URL for a source; tests point every source at one fake host. */
export function upstream(env: AppEnv, name: UpstreamName): string {
  return env.MARKET_BASE_OVERRIDE ? `${env.MARKET_BASE_OVERRIDE}/${name}` : UPSTREAM[name];
}

const TIMEOUT_MS = 8000;

/**
 * GET/POST JSON with a timeout and an edge-cache TTL. POST bodies are part of the cache
 * key (Hyperliquid's API is POST-only), so the key is a synthetic GET URL carrying the body
 * as a query parameter (the Cache API ignores #fragments, so they can't tell bodies apart).
 */
export async function fetchJson<T>(
  url: string,
  opts: { ttl: number; method?: "GET" | "POST"; body?: unknown; headers?: Record<string, string> },
  status: SourceStatus[],
  name: string,
): Promise<T | null> {
  const started = Date.now();
  const bodyText = opts.body === undefined ? undefined : JSON.stringify(opts.body);
  const cacheKey = new Request(bodyText ? `${url}${url.includes("?") ? "&" : "?"}__body=${encodeURIComponent(bodyText)}` : url);
  const cache = (globalThis as { caches?: CacheStorage }).caches?.default as Cache | undefined;
  try {
    const cached = cache ? await cache.match(cacheKey) : undefined;
    if (cached) {
      status.push({ name, ok: true, ms: Date.now() - started });
      return (await cached.json()) as T;
    }
    const res = await fetch(url, {
      method: opts.method ?? "GET",
      headers: { accept: "application/json", ...(bodyText ? { "content-type": "application/json" } : {}), ...opts.headers },
      body: bodyText,
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const text = await res.text();
    const data = JSON.parse(text) as T;
    if (cache) {
      await cache.put(
        cacheKey,
        new Response(text, { headers: { "content-type": "application/json", "cache-control": `max-age=${opts.ttl}` } }),
      );
    }
    status.push({ name, ok: true, ms: Date.now() - started });
    return data;
  } catch (err) {
    status.push({ name, ok: false, error: String((err as Error).message ?? err), ms: Date.now() - started });
    return null;
  }
}

// ---------- CoinGecko ----------

export interface CgMarket {
  id: string;
  symbol: string;
  name: string;
  current_price: number | null;
  market_cap: number | null;
  total_volume: number | null;
  price_change_percentage_24h_in_currency?: number | null;
  price_change_percentage_7d_in_currency?: number | null;
}

export interface CgDerivative {
  market: string;
  symbol: string;
  index_id: string;
  price: string | number | null;
  contract_type: string;
  funding_rate: number | null;
  open_interest: number | null;
  volume_24h: number | null;
  basis?: number | null;
  spread?: number | null;
}

function cgHeaders(env: AppEnv): Record<string, string> {
  return env.COINGECKO_API_KEY ? { "x-cg-demo-api-key": env.COINGECKO_API_KEY } : {};
}

/** Top 250 coins by market cap (two pages would double the rate-limit cost; 250 covers every liquid perp). */
export function coingeckoMarkets(env: AppEnv, status: SourceStatus[]) {
  const url =
    `${upstream(env, "coingecko")}/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&page=1` +
    `&price_change_percentage=24h,7d`;
  return fetchJson<CgMarket[]>(url, { ttl: 300, headers: cgHeaders(env) }, status, "coingecko:markets");
}

/** Every derivatives ticker CoinGecko tracks (perps across ~100 venues): OI and funding per venue. */
export function coingeckoDerivatives(env: AppEnv, status: SourceStatus[]) {
  const url = `${upstream(env, "coingecko")}/api/v3/derivatives?include_tickers=unexpired`;
  return fetchJson<CgDerivative[]>(url, { ttl: 300, headers: cgHeaders(env) }, status, "coingecko:derivatives");
}

// ---------- Hyperliquid ----------

export interface HlAssetCtx {
  funding: string;
  openInterest: string;
  prevDayPx: string;
  dayNtlVlm: string;
  premium: string | null;
  oraclePx: string;
  markPx: string;
  midPx?: string | null;
  impactPxs?: [string, string] | null;
}

export type HlMetaAndCtxs = [{ universe: { name: string; szDecimals: number; maxLeverage: number; isDelisted?: boolean }[] }, HlAssetCtx[]];

export interface HlCandle {
  t: number;
  T: number;
  o: string;
  h: string;
  l: string;
  c: string;
  v: string;
}

export interface HlBook {
  levels: [{ px: string; sz: string; n: number }[], { px: string; sz: string; n: number }[]];
}

export function hyperliquidMeta(env: AppEnv, status: SourceStatus[]) {
  return fetchJson<HlMetaAndCtxs>(
    `${upstream(env, "hyperliquid")}/info`,
    { ttl: 60, method: "POST", body: { type: "metaAndAssetCtxs" } },
    status,
    "hyperliquid:meta",
  );
}

export type Interval = "1d" | "3d" | "1w";

const INTERVAL_MS: Record<Interval, number> = { "1d": 86_400_000, "3d": 3 * 86_400_000, "1w": 7 * 86_400_000 };

export function hyperliquidCandles(env: AppEnv, coin: string, interval: Interval, bars: number, status: SourceStatus[]) {
  const endTime = Date.now();
  const startTime = endTime - INTERVAL_MS[interval] * (bars + 1);
  // Round the window so the cache key changes once per hour, not every request.
  const hour = 3_600_000;
  return fetchJson<HlCandle[]>(
    `${upstream(env, "hyperliquid")}/info`,
    {
      ttl: 900,
      method: "POST",
      body: { type: "candleSnapshot", req: { coin, interval, startTime: Math.floor(startTime / hour) * hour, endTime: Math.ceil(endTime / hour) * hour } },
    },
    status,
    `hyperliquid:candles:${coin}`,
  );
}

export function hyperliquidBook(env: AppEnv, coin: string, status: SourceStatus[]) {
  return fetchJson<HlBook>(
    `${upstream(env, "hyperliquid")}/info`,
    { ttl: 30, method: "POST", body: { type: "l2Book", coin } },
    status,
    `hyperliquid:book:${coin}`,
  );
}

// ---------- Korea: Upbit + Bithumb ----------

export interface UpbitTicker {
  market: string;
  trade_price: number;
  acc_trade_price_24h: number;
  signed_change_rate: number;
}

export function upbitTickers(env: AppEnv, status: SourceStatus[]) {
  return fetchJson<UpbitTicker[]>(
    `${upstream(env, "upbit")}/v1/ticker/all?quote_currencies=KRW`,
    { ttl: 120 },
    status,
    "upbit:tickers",
  );
}

export interface BithumbAll {
  status: string;
  data: Record<string, { closing_price?: string; acc_trade_value_24H?: string; fluctate_rate_24H?: string } | string>;
}

export function bithumbTickers(env: AppEnv, status: SourceStatus[]) {
  return fetchJson<BithumbAll>(`${upstream(env, "bithumb")}/public/ticker/ALL_KRW`, { ttl: 120 }, status, "bithumb:tickers");
}

// ---------- Kraken Futures (optional venue for the pair-impact screen) ----------

export interface KrakenTicker {
  symbol: string;
  markPrice?: number;
  bid?: number;
  ask?: number;
  bidSize?: number;
  askSize?: number;
  openInterest?: number;
  vol24h?: number;
  fundingRate?: number;
  tag?: string;
}

export function krakenFuturesTickers(env: AppEnv, status: SourceStatus[]) {
  return fetchJson<{ tickers: KrakenTicker[] }>(
    `${upstream(env, "krakenFutures")}/derivatives/api/v3/tickers`,
    { ttl: 60 },
    status,
    "kraken:futures",
  );
}
