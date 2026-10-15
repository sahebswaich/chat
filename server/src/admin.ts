// Owner routes under /admin/*, protected by ADMIN_TOKEN (see auth.requireAdmin).

import { defaultDailyLimit, type AppEnv } from "./env";
import { HttpError, json, noContent, optionalInt, publicOrigin, readJsonObject, requiredString } from "./http";
import { formatInviteCode, newInviteCode, normalizeInviteCode, nowIso, utcDay } from "./util";

const MAX_LIST = 500;

/** POST /admin/invites {"name", "uses"?, "dailyLimit"?} → {"code", "url"} */
export async function createInvite(request: Request, env: AppEnv): Promise<Response> {
  const body = await readJsonObject(request);
  const name = requiredString(body, "name", 100, true);
  const uses = optionalInt(body, "uses", 1, 10_000) ?? 1;
  const dailyLimit = optionalInt(body, "dailyLimit", 0, 1_000_000) ?? null;

  // 32^8 ≈ 1.1e12 codes; a collision is astronomically unlikely, but retry anyway.
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newInviteCode();
    const result = await env.DB.prepare(
      `INSERT INTO invites (code, name, uses_left, daily_limit, created_at) VALUES (?1, ?2, ?3, ?4, ?5)
       ON CONFLICT (code) DO NOTHING`,
    )
      .bind(code, name, uses, dailyLimit, nowIso())
      .run();
    if (result.meta.changes === 1) {
      const shown = formatInviteCode(code);
      return json({ code: shown, url: `${publicOrigin(request)}/join/${shown}` });
    }
  }
  throw new HttpError(500, "internal", "Could not generate a unique invite code. Try again.");
}

/** GET /admin/invites → {"invites": [{code, name, usesLeft, dailyLimit, createdAt}]} */
export async function listInvites(env: AppEnv): Promise<Response> {
  const { results } = await env.DB.prepare(
    `SELECT code, name, uses_left, daily_limit, created_at FROM invites ORDER BY created_at DESC LIMIT ${MAX_LIST}`,
  ).all<{ code: string; name: string; uses_left: number; daily_limit: number | null; created_at: string }>();
  const fallback = defaultDailyLimit(env);
  return json({
    invites: results.map((r) => ({
      code: formatInviteCode(r.code),
      name: r.name,
      usesLeft: r.uses_left,
      dailyLimit: r.daily_limit ?? fallback,
      createdAt: r.created_at,
    })),
  });
}

/** DELETE /admin/invites/:code → 204 (404 if there is no such invite). Existing users keep access. */
export async function deleteInvite(env: AppEnv, rawCode: string): Promise<Response> {
  const code = normalizeInviteCode(decodeURIComponentSafe(rawCode));
  const result = code
    ? await env.DB.prepare("DELETE FROM invites WHERE code = ?1").bind(code).run()
    : { meta: { changes: 0 } };
  if (result.meta.changes === 0) throw new HttpError(404, "invalid_code", "No invite with that code.");
  return noContent();
}

/** GET /admin/users → {"users": [{id, name, device, createdAt, lastSeenAt, usedToday, revoked}]} */
export async function listUsers(env: AppEnv): Promise<Response> {
  const { results } = await env.DB.prepare(
    `SELECT u.id, u.name, u.device, u.created_at, u.last_seen_at, u.revoked_at, COALESCE(g.count, 0) AS used_today
     FROM users u LEFT JOIN usage g ON g.user_id = u.id AND g.day = ?1
     ORDER BY u.created_at DESC LIMIT ${MAX_LIST}`,
  )
    .bind(utcDay())
    .all<{
      id: string;
      name: string;
      device: string | null;
      created_at: string;
      last_seen_at: string | null;
      revoked_at: string | null;
      used_today: number;
    }>();
  return json({
    users: results.map((r) => ({
      id: r.id,
      name: r.name,
      device: r.device,
      createdAt: r.created_at,
      lastSeenAt: r.last_seen_at,
      usedToday: r.used_today,
      revoked: r.revoked_at !== null,
    })),
  });
}

/** POST /admin/users/:id/revoke → 204 (404 if unknown). The user's token stops working immediately. */
export async function revokeUser(env: AppEnv, rawId: string): Promise<Response> {
  const id = decodeURIComponentSafe(rawId);
  const result = await env.DB.prepare("UPDATE users SET revoked_at = COALESCE(revoked_at, ?1) WHERE id = ?2")
    .bind(nowIso(), id)
    .run();
  if (result.meta.changes === 0) throw new HttpError(404, "not_found", "No user with that id.");
  return noContent();
}

/** GET /admin/reports → {"reports": [{id, userId, userName, messages, answer, reason, createdAt}]}, newest first. */
export async function listReports(env: AppEnv): Promise<Response> {
  const { results } = await env.DB.prepare(
    `SELECT r.id, r.user_id, u.name AS user_name, r.messages, r.answer, r.reason, r.created_at
     FROM reports r LEFT JOIN users u ON u.id = r.user_id
     ORDER BY r.id DESC LIMIT ${MAX_LIST}`,
  ).all<{
    id: number;
    user_id: string;
    user_name: string | null;
    messages: string;
    answer: string;
    reason: string;
    created_at: string;
  }>();
  return json({
    reports: results.map((r) => ({
      id: r.id,
      userId: r.user_id,
      userName: r.user_name,
      messages: safeParse(r.messages),
      answer: r.answer,
      reason: r.reason,
      createdAt: r.created_at,
    })),
  });
}

function safeParse(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function decodeURIComponentSafe(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}
