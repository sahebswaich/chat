// Pure signal math for the terminal (no I/O, so every rule here is unit-tested on fixtures).
//
// Inputs per coin: candles for the chosen timeframe, perp context (funding, OI, mark), the
// cross-venue OI CoinGecko aggregates, market cap, Korean exchange turnover and order-book
// depth. Output: a long and a short score with a per-component breakdown, the breakout
// "since" story, and a position size bounded by risk, open interest, depth and leverage.

export type Timeframe = "1d" | "3d" | "1w";

export interface TimeframeConfig {
  interval: Timeframe;
  /** Candles requested. */
  bars: number;
  /** Prior bars a breakout must clear. */
  lookback: number;
  /** Bars for the momentum return. */
  momentum: number;
  /** Hours back for the open-interest change (needs hourly snapshots). */
  oiWindowHours: number;
  label: string;
}

export const TIMEFRAMES: Record<Timeframe, TimeframeConfig> = {
  "1d": { interval: "1d", bars: 90, lookback: 20, momentum: 5, oiWindowHours: 24, label: "Daily" },
  "3d": { interval: "3d", bars: 60, lookback: 10, momentum: 3, oiWindowHours: 72, label: "3-Day" },
  "1w": { interval: "1w", bars: 52, lookback: 8, momentum: 2, oiWindowHours: 168, label: "Weekly" },
};

export function parseTimeframe(value: string | null): Timeframe {
  return value === "3d" || value === "1w" ? value : "1d";
}

export interface Bar {
  t: number;
  o: number;
  h: number;
  l: number;
  c: number;
  v: number;
}

export function toBars(candles: { t: number; o: string; h: string; l: string; c: string; v: string }[]): Bar[] {
  return candles
    .map((k) => ({ t: k.t, o: +k.o, h: +k.h, l: +k.l, c: +k.c, v: +k.v }))
    .filter((b) => [b.o, b.h, b.l, b.c, b.v].every(Number.isFinite))
    .sort((a, b) => a.t - b.t);
}

const median = (xs: number[]) => {
  if (!xs.length) return NaN;
  const s = [...xs].sort((a, b) => a - b);
  const m = s.length >> 1;
  return s.length % 2 ? s[m]! : (s[m - 1]! + s[m]!) / 2;
};

/** Average true range over the last `n` bars, as a fraction of the last close. */
export function atrPct(bars: Bar[], n = 14): number {
  if (bars.length < 2) return NaN;
  const trs: number[] = [];
  for (let i = Math.max(1, bars.length - n); i < bars.length; i++) {
    const b = bars[i]!;
    const prev = bars[i - 1]!.c;
    trs.push(Math.max(b.h - b.l, Math.abs(b.h - prev), Math.abs(b.l - prev)));
  }
  const atr = trs.reduce((a, x) => a + x, 0) / trs.length;
  return atr / bars[bars.length - 1]!.c;
}

export function returnPct(bars: Bar[], k: number): number {
  if (bars.length <= k) return NaN;
  return bars[bars.length - 1]!.c / bars[bars.length - 1 - k]!.c - 1;
}

/** Last bar's volume over the median of the `lookback` bars before it. */
export function volumeExpansion(bars: Bar[], lookback: number): number {
  if (bars.length < lookback + 1) return NaN;
  const prior = bars.slice(-lookback - 1, -1).map((b) => b.v);
  const base = median(prior);
  return base > 0 ? bars[bars.length - 1]!.v / base : NaN;
}

export interface Breakout {
  direction: "up" | "down" | null;
  /** The prior high (up) or low (down) the move cleared. */
  level: number | null;
  /** Close of the bar that first cleared the level. */
  triggerClose: number | null;
  /** Open time (ms) of that bar: "since when". */
  since: number | null;
  barsSince: number | null;
  /** Last close vs the trigger close (signed, fraction). */
  moveSince: number | null;
  /** Last close beyond the level, in ATRs (positive = still through the level). */
  extensionAtr: number | null;
  /** The move is still through the level on the last close. */
  holding: boolean;
}

const NO_BREAKOUT: Breakout = {
  direction: null,
  level: null,
  triggerClose: null,
  since: null,
  barsSince: null,
  moveSince: null,
  extensionAtr: null,
  holding: false,
};

/**
 * The most recent fresh breakout: the latest bar (within the last `lookback` bars) whose close
 * cleared the highest high (or lowest low) of the `lookback` bars before it, when the bar before
 * it had not. Reports when it happened and how far price has gone since.
 */
export function findBreakout(bars: Bar[], lookback: number): Breakout {
  if (bars.length < lookback + 2) return NO_BREAKOUT;
  const n = bars.length;
  const priorHigh = (i: number) => Math.max(...bars.slice(i - lookback, i).map((b) => b.h));
  const priorLow = (i: number) => Math.min(...bars.slice(i - lookback, i).map((b) => b.l));
  const atr = atrPct(bars) * bars[n - 1]!.c;
  for (let j = n - 1; j >= Math.max(lookback + 1, n - lookback); j--) {
    const b = bars[j]!;
    const prev = bars[j - 1]!;
    for (const direction of ["up", "down"] as const) {
      const level = direction === "up" ? priorHigh(j) : priorLow(j);
      const prevLevel = direction === "up" ? priorHigh(j - 1) : priorLow(j - 1);
      const cleared = direction === "up" ? b.c > level : b.c < level;
      const prevCleared = direction === "up" ? prev.c > prevLevel : prev.c < prevLevel;
      if (cleared && !prevCleared) {
        const last = bars[n - 1]!.c;
        const sign = direction === "up" ? 1 : -1;
        return {
          direction,
          level,
          triggerClose: b.c,
          since: b.t,
          barsSince: n - 1 - j,
          moveSince: last / b.c - 1,
          extensionAtr: atr > 0 ? (sign * (last - level)) / atr : null,
          holding: sign * (last - level) > 0,
        };
      }
    }
  }
  return NO_BREAKOUT;
}

export interface BookLevel {
  px: number;
  sz: number;
}

/**
 * Price impact (basis points vs mid) of a market order for `notionalUsd`, walking the book.
 * Returns Infinity if the visible book is too thin to fill it.
 */
export function impactBps(bids: BookLevel[], asks: BookLevel[], notionalUsd: number, side: "buy" | "sell"): number {
  if (!bids.length || !asks.length || notionalUsd <= 0) return NaN;
  const mid = (bids[0]!.px + asks[0]!.px) / 2;
  const levels = side === "buy" ? asks : bids;
  let remaining = notionalUsd;
  let qty = 0;
  let cost = 0;
  for (const { px, sz } of levels) {
    const take = Math.min(remaining, px * sz);
    qty += take / px;
    cost += take;
    remaining -= take;
    if (remaining <= 1e-9) break;
  }
  if (remaining > 1e-9) return Infinity;
  const avg = cost / qty;
  return (Math.abs(avg - mid) / mid) * 10_000;
}

/** Round trip at `notionalUsd`: buy impact + sell impact + taker fee both ways. */
export function roundTripBps(bids: BookLevel[], asks: BookLevel[], notionalUsd: number, takerFeeBps: number): number {
  return impactBps(bids, asks, notionalUsd, "buy") + impactBps(bids, asks, notionalUsd, "sell") + 2 * takerFeeBps;
}

// ---------- Korea flow (TokenPost-style "Korea vs global") ----------

export interface KoreaRow {
  symbol: string;
  krwTurnover: number;
  usdTurnover: number;
  /** Share of all KRW turnover on Upbit + Bithumb. */
  koreaShare: number;
  /** Share of global 24h volume across the top coins (CoinGecko). */
  globalShare: number | null;
  /** koreaShare / globalShare: how much more Korea trades it than the world does. */
  koreaVsGlobal: number | null;
  change24h: number | null;
  interest: number;
}

export interface KoreaInput {
  /** symbol → KRW turnover (Upbit + Bithumb summed) and 24h change. */
  krw: Map<string, { turnover: number; change: number | null }>;
  /** symbol → global 24h USD volume. */
  globalVolume: Map<string, number>;
  usdKrw: number;
}

const pctRank = (values: number[]) => {
  const sorted = [...values].sort((a, b) => a - b);
  return (v: number) => {
    if (!sorted.length) return 0;
    let lo = 0;
    let hi = sorted.length;
    while (lo < hi) {
      const mid = (lo + hi) >> 1;
      if (sorted[mid]! < v) lo = mid + 1;
      else hi = mid;
    }
    return sorted.length === 1 ? 1 : lo / (sorted.length - 1);
  };
};

/**
 * Korea share vs global share per coin, and an interest score (0–100): 50% how over-traded the
 * coin is in Korea relative to the world, 30% its share of Korean turnover, 20% how hard it moved
 * on the Korean venues. Coins with less than `minKrw` turnover are dropped as noise.
 */
export function koreaFlow(input: KoreaInput, minKrw = 1e9): KoreaRow[] {
  const totalKrw = [...input.krw.values()].reduce((a, x) => a + x.turnover, 0);
  const totalGlobal = [...input.globalVolume.values()].reduce((a, x) => a + x, 0);
  const rows: KoreaRow[] = [];
  for (const [symbol, { turnover, change }] of input.krw) {
    if (turnover < minKrw || totalKrw <= 0) continue;
    const g = input.globalVolume.get(symbol);
    const koreaShare = turnover / totalKrw;
    const globalShare = g && totalGlobal > 0 ? g / totalGlobal : null;
    rows.push({
      symbol,
      krwTurnover: turnover,
      usdTurnover: turnover / input.usdKrw,
      koreaShare,
      globalShare,
      koreaVsGlobal: globalShare ? koreaShare / globalShare : null,
      change24h: change,
      interest: 0,
    });
  }
  const ratioRank = pctRank(rows.filter((r) => r.koreaVsGlobal !== null).map((r) => Math.log(r.koreaVsGlobal!)));
  const shareRank = pctRank(rows.map((r) => r.koreaShare));
  const moveRank = pctRank(rows.map((r) => Math.abs(r.change24h ?? 0)));
  for (const r of rows) {
    const ratio = r.koreaVsGlobal === null ? 0.5 : ratioRank(Math.log(r.koreaVsGlobal));
    r.interest = Math.round(1000 * (0.5 * ratio + 0.3 * shareRank(r.koreaShare) + 0.2 * moveRank(Math.abs(r.change24h ?? 0)))) / 10;
  }
  return rows.sort((a, b) => b.interest - a.interest);
}

// ---------- Leverage map (CoinGecko derivatives aggregated by asset) ----------

export interface LeverageRow {
  symbol: string;
  perpOiUsd: number;
  perpVolumeUsd: number;
  /** Open-interest-weighted funding rate across venues (% per venue funding interval). */
  avgFundingPct: number | null;
  venues: number;
  marketCap: number | null;
  /** Perp OI / market cap: how levered the coin is. */
  oiToMcap: number | null;
  /** Perp volume / OI: how fast positions turn over. */
  turnover: number | null;
}

export function aggregateDerivatives(
  tickers: { index_id: string; contract_type: string; open_interest: number | null; volume_24h: number | null; funding_rate: number | null }[],
  marketCaps: Map<string, number>,
): LeverageRow[] {
  const by = new Map<string, { oi: number; vol: number; fw: number; fwOi: number; venues: number }>();
  for (const t of tickers) {
    if (t.contract_type !== "perpetual" || !t.index_id) continue;
    const sym = t.index_id.toUpperCase();
    const oi = t.open_interest && t.open_interest > 0 ? t.open_interest : 0;
    const agg = by.get(sym) ?? { oi: 0, vol: 0, fw: 0, fwOi: 0, venues: 0 };
    agg.oi += oi;
    agg.vol += t.volume_24h && t.volume_24h > 0 ? t.volume_24h : 0;
    if (t.funding_rate !== null && Number.isFinite(t.funding_rate) && oi > 0) {
      agg.fw += t.funding_rate * oi;
      agg.fwOi += oi;
    }
    agg.venues += 1;
    by.set(sym, agg);
  }
  const rows: LeverageRow[] = [];
  for (const [symbol, a] of by) {
    if (a.oi <= 0) continue;
    const mcap = marketCaps.get(symbol) ?? null;
    rows.push({
      symbol,
      perpOiUsd: a.oi,
      perpVolumeUsd: a.vol,
      avgFundingPct: a.fwOi > 0 ? a.fw / a.fwOi : null,
      venues: a.venues,
      marketCap: mcap,
      oiToMcap: mcap && mcap > 0 ? a.oi / mcap : null,
      turnover: a.oi > 0 ? a.vol / a.oi : null,
    });
  }
  return rows.sort((a, b) => b.perpOiUsd - a.perpOiUsd);
}

// ---------- Scoring ----------

export interface CoinFeatures {
  symbol: string;
  price: number;
  atrPct: number;
  momentum: number;
  volumeExpansion: number;
  breakout: Breakout;
  /** Hourly funding rate (fraction), e.g. Hyperliquid's. */
  fundingHourly: number | null;
  perpOiUsd: number | null;
  oiToMcap: number | null;
  /** OI change over the timeframe window (fraction), from hourly snapshots. */
  oiChange: number | null;
  /** Price change over the same window (fraction). */
  priceChangeWindow: number | null;
  koreaVsGlobal: number | null;
  koreaInterest: number | null;
  maxLeverage: number | null;
}

export interface Weights {
  breakout: number;
  momentum: number;
  volume: number;
  funding: number;
  leverage: number;
  oiFlow: number;
  korea: number;
}

export const DEFAULT_WEIGHTS: Weights = {
  breakout: 3,
  momentum: 1.5,
  volume: 1,
  funding: 1,
  leverage: 1,
  oiFlow: 1,
  korea: 0.75,
};

export interface Component {
  key: keyof Weights;
  value: number;
  weight: number;
  note: string;
}

export interface Scored {
  side: "long" | "short";
  score: number;
  components: Component[];
}

const clamp = (x: number, lo = -1, hi = 1) => Math.max(lo, Math.min(hi, x));
const fin = (x: number | null | undefined): x is number => typeof x === "number" && Number.isFinite(x);

export const fundingApr = (hourly: number) => hourly * 24 * 365;

/** Scores one side. Each component is in [-1, 1] before weighting; the sum is scaled to ±100. */
export function scoreSide(f: CoinFeatures, side: "long" | "short", w: Weights = DEFAULT_WEIGHTS): Scored {
  const s = side === "long" ? 1 : -1;
  const comps: Component[] = [];

  // Breakout: fresh and holding in our direction is the core of the setup.
  const b = f.breakout;
  let bo = 0;
  let boNote = "no fresh breakout";
  if (b.direction && fin(b.barsSince)) {
    const dir = b.direction === "up" ? 1 : -1;
    const freshness = Math.max(0, 1 - b.barsSince / 8);
    const ext = fin(b.extensionAtr) ? clamp(b.extensionAtr / 2, -1, 1) : 0;
    bo = dir * s * (b.holding ? 0.5 + 0.5 * freshness : -0.5) * (ext > 1.5 ? 0.7 : 1);
    const when = b.barsSince === 0 ? "on this bar" : `${b.barsSince} bar${b.barsSince === 1 ? "" : "s"} ago`;
    boNote = `${b.direction === "up" ? "broke above" : "broke below"} ${when}, ${
      b.holding ? "holding" : "failed"
    }, ${fin(b.moveSince) ? (b.moveSince * 100).toFixed(1) : "?"}% since`;
  }
  comps.push({ key: "breakout", value: clamp(bo), weight: w.breakout, note: boNote });

  const mom = fin(f.momentum) && fin(f.atrPct) && f.atrPct > 0 ? Math.tanh(f.momentum / (f.atrPct * 2)) : 0;
  comps.push({ key: "momentum", value: s * mom, weight: w.momentum, note: `${fin(f.momentum) ? (f.momentum * 100).toFixed(1) : "?"}% over the momentum window` });

  const vol = fin(f.volumeExpansion) && f.volumeExpansion > 0 ? Math.tanh(Math.log(f.volumeExpansion)) : 0;
  // Volume confirms whichever way price is breaking, so it follows the breakout direction.
  const volDir = b.direction === "down" ? -1 : 1;
  comps.push({ key: "volume", value: s * volDir * vol, weight: w.volume, note: `${fin(f.volumeExpansion) ? f.volumeExpansion.toFixed(2) : "?"}× median volume` });

  // Funding: paying to be long (high positive APR) is crowding for longs and fuel for shorts.
  let fund = 0;
  let fundNote = "no funding data";
  if (fin(f.fundingHourly)) {
    const apr = fundingApr(f.fundingHourly);
    fund = -s * Math.tanh(apr / 0.5);
    fundNote = `${(apr * 100).toFixed(1)}% APR ${apr >= 0 ? "(longs pay)" : "(shorts pay)"}`;
  }
  comps.push({ key: "funding", value: clamp(fund), weight: w.funding, note: fundNote });

  // Leverage: some perp OI relative to market cap fuels moves; too much is a liquidation risk.
  let lev = 0;
  let levNote = "no OI/mcap";
  if (fin(f.oiToMcap)) {
    const r = f.oiToMcap;
    lev = r < 0.005 ? -0.3 : r <= 0.1 ? 0.5 : r <= 0.2 ? 0 : -0.6;
    levNote = `perp OI ${(r * 100).toFixed(1)}% of mcap`;
  }
  comps.push({ key: "leverage", value: lev, weight: w.leverage, note: levNote });

  // OI flow: price and OI rising together = new positions behind the move.
  let flow = 0;
  let flowNote = "OI history building (hourly snapshots)";
  if (fin(f.oiChange) && fin(f.priceChangeWindow)) {
    const p = Math.sign(f.priceChangeWindow);
    const o = Math.sign(f.oiChange);
    flow = s * p * (o > 0 ? 0.8 : -0.3);
    const label = p > 0 ? (o > 0 ? "new longs" : "short covering") : o > 0 ? "new shorts" : "long liquidation";
    flowNote = `OI ${(f.oiChange * 100).toFixed(1)}% with price ${(f.priceChangeWindow * 100).toFixed(1)}%: ${label}`;
  }
  comps.push({ key: "oiFlow", value: clamp(flow), weight: w.oiFlow, note: flowNote });

  // Korea: strong Korean over-trading is retail flow; it helps momentum longs early, warns late.
  let kr = 0;
  let krNote = "not listed in Korea";
  if (fin(f.koreaVsGlobal)) {
    const late = fin(b.barsSince) && b.barsSince > 5;
    kr = s * Math.tanh(Math.log(Math.max(f.koreaVsGlobal, 1e-6)) / 2) * (late ? -0.5 : 1);
    krNote = `${f.koreaVsGlobal.toFixed(1)}× Korea vs global${late ? " (late move: fade risk)" : ""}`;
  }
  comps.push({ key: "korea", value: clamp(kr), weight: w.korea, note: krNote });

  const totalWeight = comps.reduce((a, c) => a + c.weight, 0) || 1;
  const score = (100 * comps.reduce((a, c) => a + c.value * c.weight, 0)) / totalWeight;
  return { side, score: Math.round(score * 10) / 10, components: comps };
}

export function bestSide(f: CoinFeatures, w: Weights = DEFAULT_WEIGHTS): Scored {
  const long = scoreSide(f, "long", w);
  const short = scoreSide(f, "short", w);
  return long.score >= short.score ? long : short;
}

// ---------- Sizing ----------

export interface AccountRules {
  /** Account equity in USD (e.g. a funded account's size). */
  equity: number;
  /** Max loss per trade in USD. */
  riskUsd: number;
  /** Leverage cap for BTC/ETH and for everything else (funded accounts often split these). */
  maxLeverageMajors: number;
  maxLeverageAlts: number;
  /** Never be more than this fraction of total perp OI. */
  maxOiFraction: number;
  /** Stop distance in ATRs. */
  stopAtr: number;
}

export const DEFAULT_ACCOUNT: AccountRules = {
  equity: 100_000,
  riskUsd: 1_000,
  maxLeverageMajors: 5,
  maxLeverageAlts: 2,
  maxOiFraction: 0.0025,
  stopAtr: 1.5,
};

export interface Sizing {
  stopPct: number;
  stopPrice: number;
  targetPrice: number;
  notionalUsd: number;
  leverage: number;
  /** Which limit decided the size. */
  boundBy: "risk" | "leverage" | "open interest" | "venue";
  caps: { risk: number; leverage: number; openInterest: number | null; venue: number | null };
}

export function sizePosition(f: CoinFeatures, side: "long" | "short", rules: AccountRules = DEFAULT_ACCOUNT): Sizing {
  const stopPct = Math.max(0.005, (fin(f.atrPct) ? f.atrPct : 0.05) * rules.stopAtr);
  const isMajor = f.symbol === "BTC" || f.symbol === "ETH";
  const levCap = Math.min(isMajor ? rules.maxLeverageMajors : rules.maxLeverageAlts, f.maxLeverage ?? Infinity);
  const caps = {
    risk: rules.riskUsd / stopPct,
    leverage: rules.equity * levCap,
    openInterest: fin(f.perpOiUsd) ? f.perpOiUsd * rules.maxOiFraction : null,
    venue: null as number | null,
  };
  const entries: [Sizing["boundBy"], number][] = [
    ["risk", caps.risk],
    ["leverage", caps.leverage],
  ];
  if (caps.openInterest !== null) entries.push(["open interest", caps.openInterest]);
  const [boundBy, notional] = entries.reduce((a, b) => (b[1] < a[1] ? b : a));
  const dir = side === "long" ? 1 : -1;
  return {
    stopPct,
    stopPrice: f.price * (1 - dir * stopPct),
    targetPrice: f.price * (1 + dir * stopPct * 2),
    notionalUsd: Math.max(0, notional),
    leverage: rules.equity > 0 ? notional / rules.equity : 0,
    boundBy,
    caps,
  };
}

/** Change of a snapshot series over a window: value now vs the closest snapshot ≥ window old. */
export function windowChange(series: { ts: string; value: number | null }[], windowHours: number, now = Date.now()): number | null {
  const valid = series.filter((p) => fin(p.value) && p.value! > 0).sort((a, b) => a.ts.localeCompare(b.ts));
  if (valid.length < 2) return null;
  const latest = valid[valid.length - 1]!;
  const cutoff = now - windowHours * 3_600_000;
  const past = [...valid].reverse().find((p) => Date.parse(p.ts) <= cutoff);
  if (!past) return null;
  return latest.value! / past.value! - 1;
}
