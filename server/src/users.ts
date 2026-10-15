// App-user routes: redeem an invite, who am I, delete my account, report an answer.

import { requireUser, usedToday } from "./auth";
import { defaultDailyLimit, supportEmail, type AppEnv } from "./env";
import { HttpError, invalidRequest, json, noContent, optionalString, readJsonObject, requiredString } from "./http";
import { isRecord, newToken, newUserId, normalizeInviteCode, nowIso, sha256Hex } from "./util";

const MAX_REPORT_MESSAGES = 40;
const MAX_REPORT_CHARS = 20_000;

/** POST /v1/redeem {"code", "device"} → {"token", "name", "dailyLimit"} */
export async function handleRedeem(request: Request, env: AppEnv): Promise<Response> {
  const body = await readJsonObject(request);
  const rawCode = requiredString(body, "code", 64);
  const device = optionalString(body, "device", 200)?.trim() || null;

  const code = normalizeInviteCode(rawCode);
  if (!code) throw new HttpError(404, "invalid_code", "That invite code doesn't exist. Check it and try again.");

  // Atomically take one use; only succeeds while uses are left.
  const invite = await env.DB.prepare(
    "UPDATE invites SET uses_left = uses_left - 1 WHERE code = ?1 AND uses_left > 0 RETURNING name, daily_limit",
  )
    .bind(code)
    .first<{ name: string; daily_limit: number | null }>();

  if (!invite) {
    const exists = await env.DB.prepare("SELECT 1 AS found FROM invites WHERE code = ?1").bind(code).first();
    if (exists) throw new HttpError(410, "code_used_up", "That invite code has already been used.");
    throw new HttpError(404, "invalid_code", "That invite code doesn't exist. Check it and try again.");
  }

  const token = newToken();
  try {
    await env.DB.prepare(
      `INSERT INTO users (id, token_hash, name, device, invite_code, daily_limit, created_at)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)`,
    )
      .bind(newUserId(), await sha256Hex(token), invite.name, device, code, invite.daily_limit, nowIso())
      .run();
  } catch (err) {
    // Give the use back so a transient failure doesn't burn the invite.
    await env.DB.prepare("UPDATE invites SET uses_left = uses_left + 1 WHERE code = ?1").bind(code).run();
    throw err;
  }

  return json({
    token,
    name: invite.name,
    dailyLimit: invite.daily_limit ?? defaultDailyLimit(env),
  });
}

/** GET /v1/me → {"name", "usedToday", "dailyLimit", "supportEmail"} */
export async function handleMe(request: Request, env: AppEnv, ctx: ExecutionContext): Promise<Response> {
  const user = await requireUser(request, env, ctx);
  return json({
    name: user.name,
    usedToday: await usedToday(env, user.id),
    dailyLimit: user.dailyLimit,
    supportEmail: supportEmail(env),
  });
}

/**
 * DELETE /v1/me → 204. Deletes the caller's account: the user row, usage
 * counters and the cards they created. Reports are kept for moderation with the
 * link to the user removed. The token stops working immediately.
 */
export async function handleDeleteMe(request: Request, env: AppEnv, ctx: ExecutionContext): Promise<Response> {
  const user = await requireUser(request, env, ctx);
  // One batch = one transaction: either everything is removed or nothing is.
  await env.DB.batch([
    env.DB.prepare("DELETE FROM usage WHERE user_id = ?1").bind(user.id),
    env.DB.prepare("DELETE FROM cards WHERE user_id = ?1").bind(user.id),
    env.DB.prepare("UPDATE reports SET user_id = NULL WHERE user_id = ?1").bind(user.id),
    env.DB.prepare("DELETE FROM users WHERE id = ?1").bind(user.id),
  ]);
  return noContent();
}

/** POST /v1/report {"messages", "answer", "reason"} → 204. The only chat content ever stored. */
export async function handleReport(request: Request, env: AppEnv, ctx: ExecutionContext): Promise<Response> {
  const user = await requireUser(request, env, ctx);
  const body = await readJsonObject(request);

  const raw = body["messages"] ?? [];
  if (!Array.isArray(raw) || raw.length > MAX_REPORT_MESSAGES) {
    throw invalidRequest(`"messages" must be an array of at most ${MAX_REPORT_MESSAGES} entries.`);
  }
  const messages = raw.map((m: unknown, i: number) => {
    if (
      !isRecord(m) ||
      (m["role"] !== "user" && m["role"] !== "assistant") ||
      typeof m["content"] !== "string" ||
      m["content"].length > MAX_REPORT_CHARS
    ) {
      throw invalidRequest(`messages[${i}] must be {"role": "user"|"assistant", "content": "<text>"}.`);
    }
    return { role: m["role"], content: m["content"] };
  });
  const answer = optionalString(body, "answer", MAX_REPORT_CHARS) ?? "";
  const reason = optionalString(body, "reason", 1000)?.trim() || "unspecified";
  if (messages.length === 0 && answer.trim() === "") {
    throw invalidRequest('A report needs "messages" or an "answer".');
  }

  await env.DB.prepare(
    "INSERT INTO reports (user_id, messages, answer, reason, created_at) VALUES (?1, ?2, ?3, ?4, ?5)",
  )
    .bind(user.id, JSON.stringify(messages), answer, reason, nowIso())
    .run();
  return noContent();
}
