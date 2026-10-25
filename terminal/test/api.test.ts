import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import { parseFillsCsv } from "../src/journal";
import { call, clearCoingeckoCache, cookieFrom, mockMarkets, signIn } from "./helpers";

describe("gate", () => {
  it("shows the sign-in page to strangers and rejects API calls", async () => {
    const page = await call("GET", "/", { headers: { accept: "text/html" } });
    expect(page.status).toBe(200);
    expect(await page.text()).toContain('type="password"');
    expect((await call("GET", "/api/market/korea")).status).toBe(401);
  });

  it("rejects a wrong password and slows down guessing", async () => {
    for (let i = 0; i < 10; i++) {
      const res = await call("POST", "/login", { body: { password: "nope" }, headers: { "cf-connecting-ip": "1.2.3.4" } });
      expect(res.status).toBe(401);
    }
    const blocked = await call("POST", "/login", { body: { password: "test-password" }, headers: { "cf-connecting-ip": "1.2.3.4" } });
    expect(blocked.status).toBe(429);
  });

  it("rejects a tampered session cookie", async () => {
    const cookie = await signIn();
    const tampered = cookie.slice(0, -3) + (cookie.endsWith("A") ? "B" : "A") + cookie.slice(-2);
    expect((await call("GET", "/api/fills", { cookie: tampered })).status).toBe(401);
  });

  it("lets a share link read the market but not the journal, until revoked", async () => {
    mockMarkets();
    const owner = await signIn();
    const created = await call("POST", "/api/shares", { cookie: owner, body: { label: "Desk", scope: "/", role: "view" } });
    expect(created.status).toBe(200);
    const { url, id } = (await created.json()) as { url: string; id: string };
    const open = await call("GET", new URL(url).pathname);
    expect(open.status).toBe(302);
    const guest = cookieFrom(open);
    expect((await call("GET", "/api/market/korea", { cookie: guest })).status).toBe(200);
    expect((await call("GET", "/api/fills", { cookie: guest })).status).toBe(403);
    expect((await call("DELETE", `/api/shares/${id}`, { cookie: owner })).status).toBe(200);
    expect((await call("GET", "/api/market/korea", { cookie: guest })).status).toBe(401);
  });
});

describe("market panels", () => {
  it("korea: Upbit + Bithumb turnover vs CoinGecko global volume", async () => {
    mockMarkets();
    const res = await call("GET", "/api/market/korea", { cookie: await signIn() });
    const data = (await res.json()) as { usdKrw: number; rows: { symbol: string; koreaShare: number; koreaVsGlobal: number | null }[] };
    expect(data.usdKrw).toBe(1400);
    const symbols = data.rows.map((r) => r.symbol);
    expect(symbols).toContain("XRP");
    expect(symbols).not.toContain("USDT");
    const btc = data.rows.find((r) => r.symbol === "BTC")!;
    // BTC: 300B of 650B KRW turnover (XRP 300B + BTC 300B + PEPE 50B).
    expect(btc.koreaShare).toBeCloseTo(300 / 650, 6);
    // The highest-market-cap "XRP" wins the ticker, not the fake one with huge volume.
    const xrp = data.rows.find((r) => r.symbol === "XRP")!;
    expect(xrp.koreaVsGlobal).toBeGreaterThan(1);
  });

  it("leverage: OI/mcap by asset, joined with Hyperliquid", async () => {
    mockMarkets();
    const res = await call("GET", "/api/market/leverage", { cookie: await signIn() });
    const data = (await res.json()) as { rows: { symbol: string; perpOiUsd: number; oiToMcap: number; hlMaxLeverage: number | null }[] };
    const btc = data.rows.find((r) => r.symbol === "BTC")!;
    expect(btc.perpOiUsd).toBe(40_000_000_000);
    expect(btc.oiToMcap).toBeCloseTo(0.02, 10);
    expect(btc.hlMaxLeverage).toBe(40);
    expect(data.rows.find((r) => r.symbol === "PEPE")!.hlMaxLeverage).toBe(10); // kPEPE → PEPE
  });

  it("board: ranks setups for the chosen timeframe with sizing and excludes coins", async () => {
    const calls = mockMarkets();
    const res = await call("GET", "/api/market/board?tf=3d&exclude=PEPE&equity=50000&risk=500", { cookie: await signIn() });
    expect(res.status).toBe(200);
    const data = (await res.json()) as {
      timeframe: { key: string; interval: string };
      ideas: { symbol: string; side: string; score: number; breakout: { direction: string; since: number }; sizing: { notionalUsd: number; boundBy: string } }[];
      account: { equity: number };
    };
    expect(data.timeframe.key).toBe("3d");
    expect(data.account.equity).toBe(50_000);
    expect(data.ideas.map((i) => i.symbol).sort()).toEqual(["BTC", "ETH"]);
    const btc = data.ideas.find((i) => i.symbol === "BTC")!;
    expect(btc.side).toBe("long");
    expect(btc.breakout.direction).toBe("up");
    expect(btc.sizing.notionalUsd).toBeGreaterThan(0);
    const eth = data.ideas.find((i) => i.symbol === "ETH")!;
    expect(eth.side).toBe("short");
    expect(calls.some((c) => c.includes("candleSnapshot:kPEPE"))).toBe(false);
    expect(calls.some((c) => c.includes("candleSnapshot:OLD"))).toBe(false); // delisted
  });

  it("board still answers when CoinGecko is down, and says so", async () => {
    await clearCoingeckoCache();
    mockMarkets({ failCoingecko: true });
    const res = await call("GET", "/api/market/board?tf=1w&universe=5", { cookie: await signIn() });
    const data = (await res.json()) as { ideas: unknown[]; sources: { name: string; ok: boolean }[] };
    expect(data.ideas.length).toBeGreaterThan(0);
    expect(data.sources.filter((s) => !s.ok).map((s) => s.name)).toContain("coingecko:markets");
  });

  it("impact: keeps the zero-fee trenches link parameters", async () => {
    mockMarkets();
    const res = await call("GET", "/api/market/impact?excluded=ETH&pairImpact=1&pairImpactBps=20&pairSize=25000&kraken=1", { cookie: await signIn() });
    const data = (await res.json()) as {
      params: { pairSize: number; pairImpactBps: number; excluded: string[]; kraken: boolean };
      coins: { symbol: string; passes: boolean; buyImpactBps: number | null; kraken: { spreadBps: number } | null }[];
      pairs: { long: string; short: string; impactBps: number }[];
    };
    expect(data.params).toEqual({ pairSize: 25000, pairImpactBps: 20, excluded: ["ETH"], kraken: true });
    expect(data.coins.map((c) => c.symbol)).not.toContain("ETH");
    const btc = data.coins.find((c) => c.symbol === "BTC")!;
    expect(btc.passes).toBe(true);
    expect(btc.buyImpactBps).toBeCloseTo(5, 6);
    expect(btc.kraken?.spreadBps).toBeGreaterThan(0);
    const pepe = data.coins.find((c) => c.symbol === "PEPE")!;
    expect(pepe.passes).toBe(false); // two thin levels can't fill $25k
    expect(data.pairs.every((p) => p.impactBps <= 20)).toBe(true);
  });

  it("snapshot writes one row per listed coin", async () => {
    mockMarkets();
    const res = await call("POST", "/api/market/snapshot", { cookie: await signIn() });
    expect(((await res.json()) as { rows: number }).rows).toBe(3);
    const row = await env.DB.prepare("SELECT * FROM market_snapshots WHERE coin = 'BTC'").first<{ agg_oi_usd: number; korea_share: number }>();
    expect(row?.agg_oi_usd).toBe(40_000_000_000);
    expect(row?.korea_share).toBeGreaterThan(0);
  });
});

describe("journal", () => {
  it("parses pasted CSV in common exchange formats", () => {
    const fills = parseFillsCsv("Time,Symbol,Direction,Price,Qty,Lev\n2026-10-01 12:00,BTC-USDT,Open Long,\"61,000\",0.5,5x\n2026-10-02,ETHPERP,short,2400,2,");
    expect(fills).toHaveLength(2);
    expect(fills[0]).toMatchObject({ coin: "BTC", side: "buy", price: 61000, size: 0.5, leverage: 5 });
    expect(fills[1]).toMatchObject({ coin: "ETH", side: "sell", price: 2400, leverage: null });
    expect(() => parseFillsCsv("a,b\n1,2")).toThrow(/coin, side, price and size/);
  });

  it("stores fills and reports the move since each one at the live mark", async () => {
    mockMarkets();
    const owner = await signIn();
    const add = await call("POST", "/api/fills", {
      cookie: owner,
      body: { fills: [{ coin: "BTC", side: "buy", price: 100, size: 2, leverage: 3, filledAt: "2026-10-20T00:00:00Z" }] },
    });
    expect(add.status).toBe(200);
    const res = await call("GET", "/api/fills", { cookie: owner });
    const data = (await res.json()) as { fills: { coin: string; mark: number; moveSincePct: number; pnlUsd: number }[] };
    expect(data.fills[0]).toMatchObject({ coin: "BTC", mark: 119 });
    expect(data.fills[0]!.moveSincePct).toBeCloseTo(19, 6);
    expect(data.fills[0]!.pnlUsd).toBeCloseTo(38, 6);
  });
});
