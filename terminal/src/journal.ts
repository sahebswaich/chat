// Trade journal: fills typed in or pasted as CSV, with "move since fill" against the live mark.

import type { AppEnv } from "./env";
import { HttpError, invalidRequest, json, readJsonObject } from "./http";
import { currentMarks } from "./market/api";
import { newId, nowIso } from "./util";

interface FillRow {
  id: string;
  account: string;
  coin: string;
  side: "buy" | "sell";
  price: number;
  size: number;
  leverage: number | null;
  filled_at: string;
  note: string;
}

export interface FillInput {
  account: string;
  coin: string;
  side: "buy" | "sell";
  price: number;
  size: number;
  leverage: number | null;
  filledAt: string;
  note: string;
}

const COIN_RE = /^[A-Z0-9]{1,15}$/;

function parseSide(value: string): "buy" | "sell" | null {
  const v = value.trim().toLowerCase();
  if (["buy", "b", "long", "open long", "close short"].includes(v)) return "buy";
  if (["sell", "s", "short", "open short", "close long"].includes(v)) return "sell";
  return null;
}

/** Validates one fill object from JSON. */
export function parseFill(raw: Record<string, unknown>): FillInput {
  const coin = String(raw["coin"] ?? "").trim().toUpperCase().replace(/[-/]?(USDT?|USDC|PERP)$/, "");
  if (!COIN_RE.test(coin)) throw invalidRequest(`Unrecognised coin "${String(raw["coin"] ?? "")}".`);
  const side = parseSide(String(raw["side"] ?? ""));
  if (!side) throw invalidRequest(`Side must be buy/sell (or long/short) for ${coin}.`);
  const price = Number(raw["price"]);
  const size = Number(raw["size"]);
  if (!(price > 0) || !(size > 0)) throw invalidRequest(`Price and size must be positive numbers for ${coin}.`);
  const lev = raw["leverage"] === undefined || raw["leverage"] === null || raw["leverage"] === "" ? null : Number(raw["leverage"]);
  if (lev !== null && !(lev > 0 && lev <= 200)) throw invalidRequest(`Leverage must be between 0 and 200 for ${coin}.`);
  const when = String(raw["filledAt"] ?? raw["time"] ?? "").trim();
  const ts = when ? Date.parse(when) : Date.now();
  if (!Number.isFinite(ts)) throw invalidRequest(`Unreadable time "${when}" for ${coin}.`);
  return {
    account: String(raw["account"] ?? "main").trim().slice(0, 40) || "main",
    coin,
    side,
    price,
    size,
    leverage: lev,
    filledAt: new Date(ts).toISOString(),
    note: String(raw["note"] ?? "").slice(0, 500),
  };
}

/** One CSV (or TSV) line → cells; double-quoted cells may contain the separator and "" escapes. */
export function splitCsvLine(line: string, sep = ","): string[] {
  const cells: string[] = [];
  let cell = "";
  let quoted = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i]!;
    if (quoted) {
      if (ch === '"' && line[i + 1] === '"') {
        cell += '"';
        i++;
      } else if (ch === '"') quoted = false;
      else cell += ch;
    } else if (ch === '"') quoted = true;
    else if (ch === sep) {
      cells.push(cell.trim());
      cell = "";
    } else cell += ch;
  }
  cells.push(cell.trim());
  return cells;
}

/**
 * Parses pasted CSV with a header row. Recognised headers (any case): time/date/filled_at,
 * coin/symbol/asset/market, side/direction, price/px, size/qty/amount, leverage/lev, account, note.
 */
export function parseFillsCsv(text: string): FillInput[] {
  const lines = text.split(/\r?\n/).filter((l) => l.trim());
  if (lines.length < 2) throw invalidRequest("Paste a header row and at least one fill.");
  const split = (line: string) => splitCsvLine(line, line.includes("\t") && !line.includes(",") ? "\t" : ",");
  const header = split(lines[0]!).map((h) => h.toLowerCase());
  const col = (...names: string[]) => header.findIndex((h) => names.includes(h));
  const idx = {
    time: col("time", "date", "filled_at", "filledat", "timestamp"),
    coin: col("coin", "symbol", "asset", "market", "ticker"),
    side: col("side", "direction", "dir"),
    price: col("price", "px", "fill price", "avg price"),
    size: col("size", "qty", "quantity", "amount", "sz"),
    lev: col("leverage", "lev"),
    account: col("account"),
    note: col("note", "notes"),
  };
  if (idx.coin < 0 || idx.side < 0 || idx.price < 0 || idx.size < 0) {
    throw invalidRequest("CSV needs coin, side, price and size columns.");
  }
  return lines.slice(1).map((line) => {
    const c = split(line);
    const get = (i: number) => (i >= 0 ? c[i] : undefined);
    return parseFill({
      coin: get(idx.coin),
      side: get(idx.side),
      price: get(idx.price)?.replace(/[$,]/g, ""),
      size: get(idx.size)?.replace(/[$,]/g, ""),
      leverage: get(idx.lev)?.replace(/x$/i, ""),
      filledAt: get(idx.time),
      account: get(idx.account),
      note: get(idx.note),
    });
  });
}

/** POST /api/fills {fills: [...]} or {csv: "..."} */
export async function addFills(request: Request, env: AppEnv): Promise<Response> {
  const body = await readJsonObject(request);
  let fills: FillInput[];
  if (typeof body["csv"] === "string") fills = parseFillsCsv(body["csv"]);
  else if (Array.isArray(body["fills"])) fills = body["fills"].map((f) => parseFill((f ?? {}) as Record<string, unknown>));
  else throw invalidRequest('Send "fills" (a list) or "csv" (text).');
  if (fills.length > 2000) throw invalidRequest("At most 2000 fills per import.");
  const now = nowIso();
  const stmt = env.DB.prepare(
    "INSERT INTO fills (id, account, coin, side, price, size, leverage, filled_at, note, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
  );
  if (fills.length) {
    await env.DB.batch(fills.map((f) => stmt.bind(newId("f"), f.account, f.coin, f.side, f.price, f.size, f.leverage, f.filledAt, f.note, now)));
  }
  return json({ added: fills.length });
}

/** GET /api/fills → fills with the move since each fill and unrealised P&L at the live mark. */
export async function listFills(env: AppEnv): Promise<Response> {
  const { results } = await env.DB.prepare("SELECT * FROM fills ORDER BY filled_at DESC LIMIT 500").all<FillRow>();
  const marks = results.length ? await currentMarks(env).catch(() => new Map<string, number>()) : new Map<string, number>();
  return json({
    fills: results.map((f) => {
      const mark = marks.get(f.coin) ?? null;
      const dir = f.side === "buy" ? 1 : -1;
      const move = mark === null ? null : mark / f.price - 1;
      return {
        id: f.id,
        account: f.account,
        coin: f.coin,
        side: f.side,
        price: f.price,
        size: f.size,
        notionalUsd: f.price * f.size,
        leverage: f.leverage,
        filledAt: f.filled_at,
        note: f.note,
        mark,
        moveSincePct: move === null ? null : move * 100,
        pnlUsd: move === null ? null : dir * (mark! - f.price) * f.size,
        hoursSince: (Date.now() - Date.parse(f.filled_at)) / 3_600_000,
      };
    }),
  });
}

export async function deleteFill(env: AppEnv, id: string): Promise<Response> {
  const res = await env.DB.prepare("DELETE FROM fills WHERE id = ?1").bind(id).run();
  if (!res.meta.changes) throw new HttpError(404, "not_found", "No fill with that id.");
  return json({ ok: true });
}
