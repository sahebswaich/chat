// /api/market/* — composes the sources into the terminal's panels — and the hourly snapshot.

import type { AppEnv } from "../env";
import { json } from "../http";
import { nowIso } from "../util";
import {
  type BithumbAll,
  type CgMarket,
  type HlMetaAndCtxs,
  type SourceStatus,
  type UpbitTicker,
  bithumbTickers,
  coingeckoDerivatives,
  coingeckoMarkets,
  hyperliquidBook,
  hyperliquidCandles,
  hyperliquidMeta,
  krakenFuturesTickers,
  upbitTickers,
} from "./sources";
import {
  type AccountRules,
  type CoinFeatures,
  DEFAULT_ACCOUNT,
  DEFAULT_WEIGHTS,
  TIMEFRAMES,
  type Weights,
  aggregateDerivatives,
  atrPct,
  bestSide,
  findBreakout,
  fundingApr,
  impactBps,
  koreaFlow,
  parseTimeframe,
  returnPct,
  sizePosition,
  toBars,
  volumeExpansion,
  windowChange,
} from "./signals";

/** Hyperliquid's base taker fee (bps) — used to show cost with and without fees. */
export const HL_TAKER_BPS = 4.5;
const MAX_UNIVERSE = 36;
const FALLBACK_USD_KRW = 1380;

/** Hyperliquid lists 1000×-scaled memes as "kPEPE"; map to the plain ticker. */
export const hlSymbol = (name: string) => (/^k[A-Z0-9]{2,}$/.test(name) ? name.slice(1) : name).toUpperCase();

export function parseList(value: string | null): Set<string> {
  return new Set(
    (value ?? "")
      .split(/[,\s]+/)
      .map((s) => s.trim().toUpperCase())
      .filter(Boolean),
  );
}

function num(params: URLSearchParams, key: string, fallback: number, min: number, max: number): number {
  const raw = params.get(key);
  if (raw === null || raw === "") return fallback;
  const v = Number(raw);
  return Number.isFinite(v) ? Math.min(max, Math.max(min, v)) : fallback;
}

interface HlRow {
  name: string;
  symbol: string;
  mark: number;
  fundingHourly: number;
  oiUsd: number;
  dayVolumeUsd: number;
  maxLeverage: number;
}

export function hlRows(meta: HlMetaAndCtxs | null): HlRow[] {
  if (!meta) return [];
  const [{ universe }, ctxs] = meta;
  const rows: HlRow[] = [];
  universe.forEach((u, i) => {
    const c = ctxs[i];
    if (!c || u.isDelisted) return;
    const mark = Number(c.markPx);
    rows.push({
      name: u.name,
      symbol: hlSymbol(u.name),
      mark,
      fundingHourly: Number(c.funding),
      oiUsd: Number(c.openInterest) * mark,
      dayVolumeUsd: Number(c.dayNtlVlm),
      maxLeverage: u.maxLeverage,
    });
  });
  return rows.filter((r) => Number.isFinite(r.mark) && r.mark > 0);
}

/** Highest-market-cap coin per ticker (the list is sorted by market cap). */
export function marketsBySymbol(markets: CgMarket[] | null): Map<string, CgMarket> {
  const map = new Map<string, CgMarket>();
  for (const m of markets ?? []) {
    const sym = m.symbol.toUpperCase();
    if (!map.has(sym)) map.set(sym, m);
  }
  return map;
}

export function koreaTurnover(upbit: UpbitTicker[] | null, bithumb: BithumbAll | null) {
  const krw = new Map<string, { turnover: number; change: number | null }>();
  let usdKrw = FALLBACK_USD_KRW;
  for (const t of upbit ?? []) {
    if (!t.market.startsWith("KRW-")) continue;
    const sym = t.market.slice(4).toUpperCase();
    if (sym === "USDT" && t.trade_price > 0) usdKrw = t.trade_price;
    krw.set(sym, { turnover: t.acc_trade_price_24h, change: t.signed_change_rate });
  }
  if (bithumb?.status === "0000") {
    for (const [sym, v] of Object.entries(bithumb.data)) {
      if (typeof v !== "object" || v === null) continue;
      const turnover = Number(v.acc_trade_value_24H);
      if (!Number.isFinite(turnover)) continue;
      const key = sym.toUpperCase();
      const prev = krw.get(key);
      const change = v.fluctate_rate_24H !== undefined ? Number(v.fluctate_rate_24H) / 100 : null;
      krw.set(key, { turnover: (prev?.turnover ?? 0) + turnover, change: prev?.change ?? change });
    }
  }
  // Stablecoins dominate KRW turnover but say nothing about interest in a coin.
  for (const stable of ["USDT", "USDC", "USDE", "DAI"]) krw.delete(stable);
  return { krw, usdKrw };
}

function globalVolumes(bySymbol: Map<string, CgMarket>): Map<string, number> {
  const out = new Map<string, number>();
  for (const [sym, m] of bySymbol) {
    if (["USDT", "USDC", "USDE", "DAI", "FDUSD"].includes(sym)) continue;
    if (m.total_volume && m.total_volume > 0) out.set(sym, m.total_volume);
  }
  return out;
}

function marketCaps(bySymbol: Map<string, CgMarket>): Map<string, number> {
  const out = new Map<string, number>();
  for (const [sym, m] of bySymbol) if (m.market_cap && m.market_cap > 0) out.set(sym, m.market_cap);
  return out;
}

const sourcesSummary = (status: SourceStatus[]) => status.map(({ name, ok, error, ms }) => ({ name, ok, ...(error ? { error } : {}), ms }));

// ---------- /api/market/korea ----------

export async function koreaPanel(env: AppEnv): Promise<Response> {
  const status: SourceStatus[] = [];
  const [upbit, bithumb, markets] = await Promise.all([upbitTickers(env, status), bithumbTickers(env, status), coingeckoMarkets(env, status)]);
  const { krw, usdKrw } = koreaTurnover(upbit, bithumb);
  const rows = koreaFlow({ krw, globalVolume: globalVolumes(marketsBySymbol(markets)), usdKrw });
  return json({ generatedAt: nowIso(), usdKrw, screened: rows.length, rows: rows.slice(0, 60), sources: sourcesSummary(status) });
}

// ---------- /api/market/leverage ----------

export async function leveragePanel(env: AppEnv): Promise<Response> {
  const status: SourceStatus[] = [];
  const [derivs, markets, meta] = await Promise.all([coingeckoDerivatives(env, status), coingeckoMarkets(env, status), hyperliquidMeta(env, status)]);
  const rows = aggregateDerivatives(derivs ?? [], marketCaps(marketsBySymbol(markets)));
  const hl = new Map(hlRows(meta).map((r) => [r.symbol, r]));
  return json({
    generatedAt: nowIso(),
    rows: rows.slice(0, 150).map((r) => {
      const h = hl.get(r.symbol);
      return {
        ...r,
        hlOiUsd: h?.oiUsd ?? null,
        hlFundingApr: h ? fundingApr(h.fundingHourly) : null,
        hlMaxLeverage: h?.maxLeverage ?? null,
      };
    }),
    totals: {
      perpOiUsd: rows.reduce((a, r) => a + r.perpOiUsd, 0),
      perpVolumeUsd: rows.reduce((a, r) => a + r.perpVolumeUsd, 0),
    },
    sources: sourcesSummary(status),
  });
}

// ---------- /api/market/board ----------

function readWeights(p: URLSearchParams): Weights {
  const w = { ...DEFAULT_WEIGHTS };
  for (const key of Object.keys(w) as (keyof Weights)[]) w[key] = num(p, `w_${key}`, w[key], 0, 10);
  return w;
}

function readAccount(p: URLSearchParams): AccountRules {
  const d = DEFAULT_ACCOUNT;
  return {
    equity: num(p, "equity", d.equity, 0, 1e10),
    riskUsd: num(p, "risk", d.riskUsd, 0, 1e9),
    maxLeverageMajors: num(p, "levMajors", d.maxLeverageMajors, 0, 100),
    maxLeverageAlts: num(p, "levAlts", d.maxLeverageAlts, 0, 100),
    maxOiFraction: num(p, "oiFrac", d.maxOiFraction, 0, 1),
    stopAtr: num(p, "stopAtr", d.stopAtr, 0.1, 10),
  };
}

interface SnapshotRow {
  coin: string;
  ts: string;
  oi_usd: number | null;
  mark: number | null;
}

async function snapshotSeries(env: AppEnv, coins: string[], windowHours: number) {
  const out = new Map<string, SnapshotRow[]>();
  if (!coins.length) return out;
  const since = new Date(Date.now() - (windowHours + 3) * 3_600_000).toISOString();
  const placeholders = coins.map((_, i) => `?${i + 2}`).join(",");
  const { results } = await env.DB.prepare(
    `SELECT coin, ts, oi_usd, mark FROM market_snapshots WHERE ts >= ?1 AND coin IN (${placeholders}) ORDER BY ts`,
  )
    .bind(since, ...coins)
    .all<SnapshotRow>();
  for (const r of results) {
    const list = out.get(r.coin) ?? [];
    list.push(r);
    out.set(r.coin, list);
  }
  return out;
}

export async function boardPanel(env: AppEnv, url: URL): Promise<Response> {
  const p = url.searchParams;
  const tf = parseTimeframe(p.get("tf"));
  const cfg = TIMEFRAMES[tf];
  const exclude = parseList(p.get("exclude") ?? p.get("excluded"));
  const universeSize = Math.round(num(p, "universe", 30, 5, MAX_UNIVERSE));
  const weights = readWeights(p);
  const account = readAccount(p);
  const status: SourceStatus[] = [];

  const [meta, markets, derivs, upbit, bithumb] = await Promise.all([
    hyperliquidMeta(env, status),
    coingeckoMarkets(env, status),
    coingeckoDerivatives(env, status),
    upbitTickers(env, status),
    bithumbTickers(env, status),
  ]);
  const bySymbol = marketsBySymbol(markets);
  const leverage = new Map(aggregateDerivatives(derivs ?? [], marketCaps(bySymbol)).map((r) => [r.symbol, r]));
  const { krw, usdKrw } = koreaTurnover(upbit, bithumb);
  const korea = new Map(koreaFlow({ krw, globalVolume: globalVolumes(bySymbol), usdKrw }).map((r) => [r.symbol, r]));

  const universe = hlRows(meta)
    .filter((r) => !exclude.has(r.symbol))
    .sort((a, b) => b.dayVolumeUsd - a.dayVolumeUsd)
    .slice(0, universeSize);
  const [candles, snapshots] = await Promise.all([
    Promise.all(universe.map((r) => hyperliquidCandles(env, r.name, cfg.interval, cfg.bars, status))),
    snapshotSeries(env, universe.map((r) => r.symbol), cfg.oiWindowHours).catch(() => new Map<string, SnapshotRow[]>()),
  ]);

  const ideas = universe.flatMap((r, i) => {
    const bars = toBars(candles[i] ?? []);
    if (bars.length < cfg.lookback + 2) return [];
    const lev = leverage.get(r.symbol);
    const kr = korea.get(r.symbol);
    const series = snapshots.get(r.symbol) ?? [];
    const features: CoinFeatures = {
      symbol: r.symbol,
      price: r.mark,
      atrPct: atrPct(bars),
      momentum: returnPct(bars, cfg.momentum),
      volumeExpansion: volumeExpansion(bars, cfg.lookback),
      breakout: findBreakout(bars, cfg.lookback),
      fundingHourly: r.fundingHourly,
      perpOiUsd: lev?.perpOiUsd ?? r.oiUsd,
      oiToMcap: lev?.oiToMcap ?? null,
      oiChange: windowChange(series.map((s) => ({ ts: s.ts, value: s.oi_usd })), cfg.oiWindowHours),
      priceChangeWindow: windowChange(series.map((s) => ({ ts: s.ts, value: s.mark })), cfg.oiWindowHours),
      koreaVsGlobal: kr?.koreaVsGlobal ?? null,
      koreaInterest: kr?.interest ?? null,
      maxLeverage: r.maxLeverage,
    };
    const scored = bestSide(features, weights);
    return [
      {
        symbol: r.symbol,
        hlName: r.name,
        side: scored.side,
        score: scored.score,
        components: scored.components,
        price: r.mark,
        atrPct: features.atrPct,
        momentum: features.momentum,
        volumeExpansion: features.volumeExpansion,
        breakout: features.breakout,
        fundingApr: fundingApr(r.fundingHourly),
        perpOiUsd: features.perpOiUsd,
        hlOiUsd: r.oiUsd,
        oiToMcap: features.oiToMcap,
        oiChange: features.oiChange,
        koreaVsGlobal: features.koreaVsGlobal,
        koreaInterest: features.koreaInterest,
        marketCap: bySymbol.get(r.symbol)?.market_cap ?? null,
        maxLeverage: r.maxLeverage,
        sizing: sizePosition(features, scored.side, account),
        spark: bars.slice(-30).map((b) => b.c),
      },
    ];
  });
  ideas.sort((a, b) => b.score - a.score);
  return json({
    generatedAt: nowIso(),
    timeframe: { key: tf, ...cfg },
    weights,
    account,
    excluded: [...exclude],
    ideas,
    sources: sourcesSummary(status),
  });
}

// ---------- /api/market/impact ----------

export async function impactPanel(env: AppEnv, url: URL): Promise<Response> {
  const p = url.searchParams;
  const size = num(p, "pairSize", num(p, "size", 25_000, 100, 1e8), 100, 1e8);
  const maxBps = num(p, "pairImpactBps", num(p, "bps", 20, 0.1, 1000), 0.1, 1000);
  const exclude = parseList(p.get("excluded") ?? p.get("exclude"));
  const includeKraken = p.get("kraken") === "1";
  const status: SourceStatus[] = [];
  const meta = await hyperliquidMeta(env, status);
  const wanted = parseList(p.get("coins"));
  const rows = hlRows(meta)
    .filter((r) => !exclude.has(r.symbol) && (wanted.size === 0 || wanted.has(r.symbol)))
    .sort((a, b) => b.dayVolumeUsd - a.dayVolumeUsd)
    .slice(0, Math.round(num(p, "limit", 25, 1, 40)));
  const [books, kraken] = await Promise.all([
    Promise.all(rows.map((r) => hyperliquidBook(env, r.name, status))),
    includeKraken ? krakenFuturesTickers(env, status) : Promise.resolve(null),
  ]);
  const krakenBySymbol = new Map<string, { spreadBps: number; topNotional: number }>();
  for (const t of kraken?.tickers ?? []) {
    const m = /^PF_([A-Z0-9]+)USD$/.exec(t.symbol);
    if (!m || !t.bid || !t.ask) continue;
    const sym = m[1] === "XBT" ? "BTC" : m[1]!;
    const mid = (t.bid + t.ask) / 2;
    krakenBySymbol.set(sym, {
      spreadBps: ((t.ask - t.bid) / mid) * 10_000,
      topNotional: Math.min(t.bidSize ?? 0, t.askSize ?? 0) * mid,
    });
  }
  const coins = rows.map((r, i) => {
    const book = books[i];
    const bids = (book?.levels[0] ?? []).map((l) => ({ px: +l.px, sz: +l.sz }));
    const asks = (book?.levels[1] ?? []).map((l) => ({ px: +l.px, sz: +l.sz }));
    const buy = impactBps(bids, asks, size, "buy");
    const sell = impactBps(bids, asks, size, "sell");
    const worst = Math.max(buy, sell);
    return {
      symbol: r.symbol,
      buyImpactBps: Number.isFinite(buy) ? buy : null,
      sellImpactBps: Number.isFinite(sell) ? sell : null,
      roundTripBps: Number.isFinite(buy + sell) ? buy + sell : null,
      roundTripWithFeesBps: Number.isFinite(buy + sell) ? buy + sell + 2 * HL_TAKER_BPS : null,
      passes: Number.isFinite(worst) && worst <= maxBps,
      dayVolumeUsd: r.dayVolumeUsd,
      oiUsd: r.oiUsd,
      kraken: krakenBySymbol.get(r.symbol) ?? null,
    };
  });
  // Pair impact: long A + short B at `size` each — A's buy impact plus B's sell impact.
  const passing = coins.filter((c) => c.passes);
  const pairs: { long: string; short: string; impactBps: number }[] = [];
  for (const a of passing) {
    for (const b of passing) {
      if (a.symbol === b.symbol || a.buyImpactBps === null || b.sellImpactBps === null) continue;
      const total = a.buyImpactBps + b.sellImpactBps;
      if (total <= maxBps) pairs.push({ long: a.symbol, short: b.symbol, impactBps: total });
    }
  }
  pairs.sort((x, y) => x.impactBps - y.impactBps);
  return json({
    generatedAt: nowIso(),
    params: { pairSize: size, pairImpactBps: maxBps, excluded: [...exclude], kraken: includeKraken },
    takerFeeBps: { hyperliquid: HL_TAKER_BPS },
    coins,
    pairs: pairs.slice(0, 50),
    sources: sourcesSummary(status),
  });
}

// ---------- hourly snapshot (cron) ----------

export async function takeSnapshot(env: AppEnv): Promise<{ rows: number; sources: ReturnType<typeof sourcesSummary> }> {
  const status: SourceStatus[] = [];
  const [meta, markets, derivs, upbit, bithumb] = await Promise.all([
    hyperliquidMeta(env, status),
    coingeckoMarkets(env, status),
    coingeckoDerivatives(env, status),
    upbitTickers(env, status),
    bithumbTickers(env, status),
  ]);
  const bySymbol = marketsBySymbol(markets);
  const leverage = new Map(aggregateDerivatives(derivs ?? [], marketCaps(bySymbol)).map((r) => [r.symbol, r]));
  const { krw, usdKrw } = koreaTurnover(upbit, bithumb);
  const korea = new Map(koreaFlow({ krw, globalVolume: globalVolumes(bySymbol), usdKrw }, 0).map((r) => [r.symbol, r]));
  const hour = new Date();
  hour.setUTCMinutes(0, 0, 0);
  const ts = hour.toISOString();
  const stmt = env.DB.prepare(
    `INSERT OR REPLACE INTO market_snapshots (ts, coin, mark, funding_hourly, oi_usd, agg_oi_usd, market_cap, korea_share, korea_turnover_krw)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)`,
  );
  const batch = hlRows(meta).map((r) =>
    stmt.bind(
      ts,
      r.symbol,
      r.mark,
      r.fundingHourly,
      r.oiUsd,
      leverage.get(r.symbol)?.perpOiUsd ?? null,
      bySymbol.get(r.symbol)?.market_cap ?? null,
      korea.get(r.symbol)?.koreaShare ?? null,
      korea.get(r.symbol)?.krwTurnover ?? null,
    ),
  );
  const cutoff = new Date(Date.now() - 21 * 86_400_000).toISOString();
  batch.push(env.DB.prepare("DELETE FROM market_snapshots WHERE ts < ?1").bind(cutoff));
  if (batch.length > 1) await env.DB.batch(batch);
  return { rows: batch.length - 1, sources: sourcesSummary(status) };
}

/** Current marks by symbol (journal "moves since"). */
export async function currentMarks(env: AppEnv): Promise<Map<string, number>> {
  const status: SourceStatus[] = [];
  return new Map(hlRows(await hyperliquidMeta(env, status)).map((r) => [r.symbol, r.mark]));
}

