import { describe, expect, it } from "vitest";
import {
  type Bar,
  type CoinFeatures,
  aggregateDerivatives,
  atrPct,
  findBreakout,
  impactBps,
  koreaFlow,
  parseTimeframe,
  scoreSide,
  sizePosition,
  volumeExpansion,
  windowChange,
} from "../src/market/signals";

const DAY = 86_400_000;

function bars(closes: number[], vols?: number[]): Bar[] {
  return closes.map((c, i) => ({ t: i * DAY, o: c, h: c + 1, l: c - 1, c, v: vols?.[i] ?? 100 }));
}

const range = (n: number, f: (i: number) => number) => Array.from({ length: n }, (_, i) => f(i));

function features(over: Partial<CoinFeatures> = {}): CoinFeatures {
  return {
    symbol: "SOL",
    price: 100,
    atrPct: 0.04,
    momentum: 0,
    volumeExpansion: 1,
    breakout: { direction: null, level: null, triggerClose: null, since: null, barsSince: null, moveSince: null, extensionAtr: null, holding: false },
    fundingHourly: 0,
    perpOiUsd: 1e9,
    oiToMcap: 0.03,
    oiChange: null,
    priceChangeWindow: null,
    koreaVsGlobal: null,
    koreaInterest: null,
    maxLeverage: 20,
    ...over,
  };
}

describe("timeframes", () => {
  it("defaults to daily", () => {
    expect(parseTimeframe(null)).toBe("1d");
    expect(parseTimeframe("3d")).toBe("3d");
    expect(parseTimeframe("1w")).toBe("1w");
    expect(parseTimeframe("bogus")).toBe("1d");
  });
});

describe("findBreakout", () => {
  it("finds a fresh upside breakout and reports when and how far since", () => {
    const closes = [...range(30, (i) => 100 + (i % 3)), 106, 110, 113];
    const b = findBreakout(bars(closes), 20);
    expect(b.direction).toBe("up");
    expect(b.barsSince).toBe(2);
    expect(b.since).toBe(30 * DAY);
    expect(b.level).toBe(103); // highest high (102 + 1) of the 20 bars before the trigger
    expect(b.triggerClose).toBe(106);
    expect(b.moveSince).toBeCloseTo(113 / 106 - 1, 10);
    expect(b.holding).toBe(true);
  });

  it("finds a downside breakdown", () => {
    const closes = [...range(30, (i) => 100 + (i % 3)), 95, 92];
    const b = findBreakout(bars(closes), 20);
    expect(b.direction).toBe("down");
    expect(b.barsSince).toBe(1);
    expect(b.holding).toBe(true);
  });

  it("marks a failed breakout as not holding", () => {
    const closes = [...range(30, (i) => 100 + (i % 3)), 106, 101];
    const b = findBreakout(bars(closes), 20);
    expect(b.direction).toBe("up");
    expect(b.holding).toBe(false);
  });

  it("returns nothing in a range or with too little history", () => {
    expect(findBreakout(bars(range(40, (i) => 100 + (i % 3))), 20).direction).toBeNull();
    expect(findBreakout(bars([1, 2, 3]), 20).direction).toBeNull();
  });
});

describe("atr, volume", () => {
  it("computes ATR as a fraction of price", () => {
    const b = bars(range(20, () => 100));
    expect(atrPct(b)).toBeCloseTo(0.02, 10); // high-low = 2 on a 100 close
  });

  it("measures the last bar's volume against the median", () => {
    const b = bars(range(21, () => 100), [...range(20, (i) => (i % 2 ? 100 : 200)), 450]);
    expect(volumeExpansion(b, 20)).toBeCloseTo(3, 10);
  });
});

describe("impactBps", () => {
  const bids = [
    { px: 99.9, sz: 100 },
    { px: 99.8, sz: 100 },
  ];
  const asks = [
    { px: 100.1, sz: 100 },
    { px: 100.2, sz: 100 },
  ];

  it("walks the book and reports bps from mid", () => {
    // $5,005 fits in the first ask level (100.1 × 100 = $10,010): 10 bps from mid 100.
    expect(impactBps(bids, asks, 5005, "buy")).toBeCloseTo(10, 6);
    expect(impactBps(bids, asks, 5000, "sell")).toBeCloseTo(10, 6);
  });

  it("averages across levels", () => {
    const bps = impactBps(bids, asks, 15_000, "buy");
    expect(bps).toBeGreaterThan(10);
    expect(bps).toBeLessThan(20);
  });

  it("is infinite when the visible book cannot fill the size", () => {
    expect(impactBps(bids, asks, 1e9, "buy")).toBe(Infinity);
  });
});

describe("koreaFlow", () => {
  it("computes Korea share, global share and the ratio, and ranks interest", () => {
    const rows = koreaFlow(
      {
        krw: new Map([
          ["XRP", { turnover: 300e9, change: 0.08 }],
          ["BTC", { turnover: 300e9, change: 0.02 }],
          ["DUST", { turnover: 1e6, change: 0.5 }],
        ]),
        globalVolume: new Map([
          ["XRP", 5e9],
          ["BTC", 45e9],
        ]),
        usdKrw: 1400,
      },
      1e9,
    );
    expect(rows.map((r) => r.symbol)).toEqual(["XRP", "BTC"]); // DUST is below the turnover floor
    const xrp = rows[0]!;
    expect(xrp.koreaShare).toBeCloseTo(0.5, 5); // dust still counts toward total KRW turnover
    expect(xrp.globalShare).toBeCloseTo(0.1, 10);
    expect(xrp.koreaVsGlobal).toBeCloseTo(5, 4);
    expect(xrp.usdTurnover).toBeCloseTo(300e9 / 1400, 3);
    expect(xrp.interest).toBeGreaterThan(rows[1]!.interest);
  });
});

describe("aggregateDerivatives", () => {
  it("sums perp OI across venues, OI-weights funding and divides by market cap", () => {
    const rows = aggregateDerivatives(
      [
        { index_id: "btc", contract_type: "perpetual", open_interest: 30, volume_24h: 60, funding_rate: 0.01 },
        { index_id: "BTC", contract_type: "perpetual", open_interest: 10, volume_24h: 20, funding_rate: 0.03 },
        { index_id: "BTC", contract_type: "futures", open_interest: 999, volume_24h: 1, funding_rate: null },
      ],
      new Map([["BTC", 1000]]),
    );
    expect(rows).toHaveLength(1);
    expect(rows[0]!.perpOiUsd).toBe(40);
    expect(rows[0]!.avgFundingPct).toBeCloseTo(0.015, 10);
    expect(rows[0]!.oiToMcap).toBeCloseTo(0.04, 10);
    expect(rows[0]!.turnover).toBeCloseTo(2, 10);
    expect(rows[0]!.venues).toBe(2);
  });
});

describe("scoreSide", () => {
  const upBreakout = { direction: "up" as const, level: 103, triggerClose: 106, since: 0, barsSince: 1, moveSince: 0.03, extensionAtr: 1, holding: true };

  it("prefers the long side on a fresh, holding upside breakout", () => {
    const f = features({ breakout: upBreakout, momentum: 0.1, volumeExpansion: 2.5 });
    expect(scoreSide(f, "long").score).toBeGreaterThan(30);
    expect(scoreSide(f, "short").score).toBeLessThan(-30);
  });

  it("penalises paying heavy funding to be long", () => {
    const calm = scoreSide(features({ breakout: upBreakout, fundingHourly: 0 }), "long").score;
    const crowded = scoreSide(features({ breakout: upBreakout, fundingHourly: 0.0001 }), "long").score; // ~88% APR
    expect(crowded).toBeLessThan(calm);
  });

  it("rewards rising OI behind a rising price for longs", () => {
    const base = scoreSide(features({ breakout: upBreakout }), "long").score;
    const fueled = scoreSide(features({ breakout: upBreakout, oiChange: 0.2, priceChangeWindow: 0.1 }), "long").score;
    expect(fueled).toBeGreaterThan(base);
    const comp = scoreSide(features({ breakout: upBreakout, oiChange: 0.2, priceChangeWindow: 0.1 }), "long").components.find((c) => c.key === "oiFlow");
    expect(comp?.note).toContain("new longs");
  });

  it("explains each component", () => {
    const s = scoreSide(features({ breakout: upBreakout, koreaVsGlobal: 12 }), "long");
    expect(s.components.map((c) => c.key)).toEqual(["breakout", "momentum", "volume", "funding", "leverage", "oiFlow", "korea"]);
    expect(s.components.find((c) => c.key === "korea")?.note).toContain("12.0× Korea vs global");
  });
});

describe("sizePosition", () => {
  const rules = { equity: 100_000, riskUsd: 1000, maxLeverageMajors: 5, maxLeverageAlts: 2, maxOiFraction: 0.0025, stopAtr: 1.5 };

  it("sizes by risk when that is the tightest limit", () => {
    const s = sizePosition(features({ atrPct: 0.04, perpOiUsd: 1e12 }), "long", rules);
    expect(s.stopPct).toBeCloseTo(0.06, 10);
    expect(s.notionalUsd).toBeCloseTo(1000 / 0.06, 6);
    expect(s.boundBy).toBe("risk");
    expect(s.stopPrice).toBeCloseTo(94, 6);
    expect(s.targetPrice).toBeCloseTo(112, 6);
  });

  it("caps alts at the alt leverage limit and majors at the major limit", () => {
    const loose = { ...rules, riskUsd: 50_000 };
    const alt = sizePosition(features({ atrPct: 0.001, perpOiUsd: 1e12 }), "long", loose);
    expect(alt.boundBy).toBe("leverage");
    expect(alt.notionalUsd).toBe(200_000);
    const btc = sizePosition(features({ symbol: "BTC", atrPct: 0.001, perpOiUsd: 1e12 }), "short", loose);
    expect(btc.notionalUsd).toBe(500_000);
    expect(btc.stopPrice).toBeGreaterThan(100);
  });

  it("never takes more than the allowed share of open interest", () => {
    const s = sizePosition(features({ atrPct: 0.001, perpOiUsd: 10_000_000 }), "long", rules);
    expect(s.boundBy).toBe("open interest");
    expect(s.notionalUsd).toBe(25_000);
  });
});

describe("windowChange", () => {
  it("compares the latest value with the newest one at least a window old", () => {
    const now = Date.parse("2026-10-25T12:00:00Z");
    const series = [
      { ts: "2026-10-24T10:00:00.000Z", value: 100 },
      { ts: "2026-10-24T12:00:00.000Z", value: 110 },
      { ts: "2026-10-25T11:00:00.000Z", value: 121 },
    ];
    expect(windowChange(series, 24, now)).toBeCloseTo(0.1, 10);
    expect(windowChange(series, 72, now)).toBeNull();
  });
});
