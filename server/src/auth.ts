// Bearer-token auth for app users and the owner's admin token.

import { defaultDailyLimit, type AppEnv } from "./env";
import { HttpError } from "./http";
import { nowIso, sha256Hex, timingSafeEqualStrings, utcDay } from "./util";

export interface User {
  id: string;
  name: string;
  device: string | null;
  /** Effective per-day message limit (the user's own, else DAILY_LIMIT). */
  dailyLimit: number;
}

interface UserRow {
  id: string;
  name: string;
  device: string | null;
  daily_limit: number | null;
  revoked_at: string | null;
}

const unauthorized = () =>
  new HttpError(401, "unauthorized", "Missing or invalid token. Redeem an invite code to sign in.", undefined, {
    "www-authenticate": 'Bearer realm="nimbus"',
  });

export function bearerToken(request: Request): string | null {
  const header = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(\S+)\s*$/i.exec(header);
  return match ? match[1]! : null;
}

/**
 * Resolves the calling user from `Authorization: Bearer <token>` by looking up
 * the token's SHA-256 hash (raw tokens are never stored). Revoked users get 401.
 * Updates `last_seen_at` in the background.
 */
export async function requireUser(request: Request, env: AppEnv, ctx: ExecutionContext): Promise<User> {
  const token = bearerToken(request);
  if (!token || token.length > 256) throw unauthorized();
  const hash = await sha256Hex(token);
  const row = await env.DB.prepare(
    "SELECT id, name, device, daily_limit, revoked_at FROM users WHERE token_hash = ?1",
  )
    .bind(hash)
    .first<UserRow>();
  if (!row || row.revoked_at !== null) throw unauthorized();
  ctx.waitUntil(
    env.DB.prepare("UPDATE users SET last_seen_at = ?1 WHERE id = ?2")
      .bind(nowIso(), row.id)
      .run()
      .catch((err: unknown) => console.error("last_seen_at update failed", err)),
  );
  return {
    id: row.id,
    name: row.name,
    device: row.device,
    dailyLimit: row.daily_limit ?? defaultDailyLimit(env),
  };
}

/** Owner routes: `Authorization: Bearer $ADMIN_TOKEN`, compared in constant time. */
export async function requireAdmin(request: Request, env: AppEnv): Promise<void> {
  const expected = env.ADMIN_TOKEN ?? "";
  const given = bearerToken(request) ?? "";
  // An unset/empty ADMIN_TOKEN disables the admin API entirely.
  const ok = expected.length > 0 && (await timingSafeEqualStrings(given, expected));
  if (!ok) throw new HttpError(401, "unauthorized", "Invalid admin token.");
}

export async function usedToday(env: AppEnv, userId: string, day = utcDay()): Promise<number> {
  const row = await env.DB.prepare("SELECT count FROM usage WHERE user_id = ?1 AND day = ?2")
    .bind(userId, day)
    .first<{ count: number }>();
  return row?.count ?? 0;
}

/**
 * Atomically counts one request against today's limit. Returns the new count,
 * or null if the user has already reached `limit` (nothing is counted then).
 */
export async function consumeDailyQuota(
  env: AppEnv,
  userId: string,
  limit: number,
  day = utcDay(),
): Promise<number | null> {
  if (limit <= 0) return null;
  const row = await env.DB.prepare(
    `INSERT INTO usage (user_id, day, count) VALUES (?1, ?2, 1)
     ON CONFLICT (user_id, day) DO UPDATE SET count = count + 1 WHERE usage.count < ?3
     RETURNING count`,
  )
    .bind(userId, day, limit)
    .first<{ count: number }>();
  return row?.count ?? null;
}

/** Gives back one counted request (used when Claude failed before answering anything). */
export async function refundDailyQuota(env: AppEnv, userId: string, day: string): Promise<void> {
  await env.DB.prepare("UPDATE usage SET count = count - 1 WHERE user_id = ?1 AND day = ?2 AND count > 0")
    .bind(userId, day)
    .run();
}
