// The password gate: owner sign-in, signed session cookies, and share links (/s/<token>)
// that open the terminal read-only without the password. Same design as ../operating-room.

import type { AppEnv } from "./env";
import { HttpError, invalidRequest, json, publicOrigin, readJsonObject, optionalInt, requiredString } from "./http";
import { newId, newToken, nowIso, readCookie, sha256Hex, signPayload, timingSafeEqualStrings, verifyPayload } from "./util";

export const SESSION_COOKIE = "room_session";
const OWNER_SESSION_DAYS = 30;
const GUEST_SESSION_DAYS = 7;
const LOGIN_WINDOW_MINUTES = 15;
const LOGIN_MAX_FAILURES = 10;

export type Role = "owner" | "comment" | "view";

export interface Session {
  role: Role;
  /** Path prefix a guest may open; owners have "/". */
  scope: string;
  /** Share id for guests (checked for revocation), absent for the owner. */
  share?: string;
  exp: number;
}

const DAY_MS = 86_400_000;

export async function readSession(request: Request, env: AppEnv): Promise<Session | null> {
  const raw = readCookie(request, SESSION_COOKIE);
  if (!raw || raw.length > 2048) return null;
  const session = await verifyPayload<Session>(raw, env.SESSION_SECRET);
  if (!session || typeof session.exp !== "number" || session.exp < Date.now()) return null;
  if (session.role !== "owner" && session.share) {
    const row = await env.DB.prepare("SELECT revoked_at, expires_at FROM shares WHERE id = ?1")
      .bind(session.share)
      .first<{ revoked_at: string | null; expires_at: string | null }>();
    if (!row || row.revoked_at !== null) return null;
    if (row.expires_at !== null && row.expires_at < nowIso()) return null;
  }
  return session;
}

async function sessionCookie(request: Request, env: AppEnv, session: Session): Promise<string> {
  const value = await signPayload(session, env.SESSION_SECRET);
  const maxAge = Math.max(0, Math.floor((session.exp - Date.now()) / 1000));
  const secure = new URL(request.url).protocol === "https:" ? "; Secure" : "";
  return `${SESSION_COOKIE}=${encodeURIComponent(value)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${secure}`;
}

export function clearSessionCookie(): string {
  return `${SESSION_COOKIE}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0`;
}

/** Whether `session` may open `path` (owners: everything; guests: their scope only). */
export function allows(session: Session, path: string): boolean {
  if (session.role === "owner") return true;
  const scope = session.scope.replace(/\/+$/, "");
  return path === scope || path.startsWith(scope + "/") || path.startsWith(scope + "?");
}

export function requireOwner(session: Session | null): Session {
  if (!session || session.role !== "owner") throw new HttpError(403, "forbidden", "Only the owner can do that.");
  return session;
}

function clientKey(request: Request): string {
  return request.headers.get("cf-connecting-ip") ?? "unknown";
}

/** POST /login {password} → sets the owner session cookie. */
export async function handleLogin(request: Request, env: AppEnv): Promise<Response> {
  const body = await readJsonObject(request);
  const password = requiredString(body, "password", 512);
  const client = clientKey(request);
  const since = new Date(Date.now() - LOGIN_WINDOW_MINUTES * 60_000).toISOString();
  const failures = await env.DB.prepare("SELECT COUNT(*) AS n FROM login_attempts WHERE client = ?1 AND at > ?2")
    .bind(client, since)
    .first<{ n: number }>();
  if ((failures?.n ?? 0) >= LOGIN_MAX_FAILURES) {
    throw new HttpError(429, "too_many_attempts", `Too many wrong passwords. Try again in ${LOGIN_WINDOW_MINUTES} minutes.`);
  }
  if (!env.ROOM_PASSWORD || !(await timingSafeEqualStrings(password, env.ROOM_PASSWORD))) {
    await env.DB.prepare("INSERT INTO login_attempts (client, at) VALUES (?1, ?2)").bind(client, nowIso()).run();
    throw new HttpError(401, "wrong_password", "That password is not right.");
  }
  await env.DB.prepare("DELETE FROM login_attempts WHERE client = ?1 OR at < ?2").bind(client, since).run();
  const session: Session = { role: "owner", scope: "/", exp: Date.now() + OWNER_SESSION_DAYS * DAY_MS };
  return json({ ok: true }, 200, { "set-cookie": await sessionCookie(request, env, session) });
}

export function handleLogout(): Response {
  return json({ ok: true }, 200, { "set-cookie": clearSessionCookie() });
}

const SCOPE_RE = /^\/[A-Za-z0-9/_.-]{0,200}$/;

interface ShareRow {
  id: string;
  label: string;
  scope: string;
  role: "view" | "comment";
  created_at: string;
  expires_at: string | null;
  revoked_at: string | null;
  last_used_at: string | null;
}

/** POST /api/shares {label, scope, role, expiresInDays?} → {url, ...}. Owner only. */
export async function createShare(request: Request, env: AppEnv): Promise<Response> {
  const body = await readJsonObject(request);
  const label = requiredString(body, "label", 120, true);
  const scope = requiredString(body, "scope", 200, true);
  if (!SCOPE_RE.test(scope) || scope.includes("..")) throw invalidRequest('"scope" must be a path such as "/terminal".');
  const role = body["role"] ?? "view";
  if (role !== "view" && role !== "comment") throw invalidRequest('"role" must be "view" or "comment".');
  const days = optionalInt(body, "expiresInDays", 1, 3650);
  const token = newToken();
  const id = newId("sh");
  const expires = days === undefined ? null : new Date(Date.now() + days * DAY_MS).toISOString();
  await env.DB.prepare(
    "INSERT INTO shares (id, token_hash, label, scope, role, created_at, expires_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
  )
    .bind(id, await sha256Hex(token), label, scope, role, nowIso(), expires)
    .run();
  return json({ id, label, scope, role, expiresAt: expires, url: `${publicOrigin(request)}/s/${token}` });
}

export async function listShares(env: AppEnv): Promise<Response> {
  const { results } = await env.DB.prepare(
    "SELECT id, label, scope, role, created_at, expires_at, revoked_at, last_used_at FROM shares ORDER BY created_at DESC",
  ).all<ShareRow>();
  return json({
    shares: results.map((r) => ({
      id: r.id,
      label: r.label,
      scope: r.scope,
      role: r.role,
      createdAt: r.created_at,
      expiresAt: r.expires_at,
      revokedAt: r.revoked_at,
      lastUsedAt: r.last_used_at,
    })),
  });
}

export async function revokeShare(env: AppEnv, id: string): Promise<Response> {
  const res = await env.DB.prepare("UPDATE shares SET revoked_at = ?1 WHERE id = ?2 AND revoked_at IS NULL")
    .bind(nowIso(), id)
    .run();
  if (!res.meta.changes) throw new HttpError(404, "not_found", "No active share link with that id.");
  return json({ ok: true });
}

/** GET /s/<token> → guest session cookie for the link's scope, then redirect there. */
export async function openShare(request: Request, env: AppEnv, token: string): Promise<Response> {
  const row = await env.DB.prepare(
    "SELECT id, label, scope, role, created_at, expires_at, revoked_at, last_used_at FROM shares WHERE token_hash = ?1",
  )
    .bind(await sha256Hex(token))
    .first<ShareRow>();
  const now = nowIso();
  if (!row || row.revoked_at !== null || (row.expires_at !== null && row.expires_at < now)) {
    throw new HttpError(404, "link_expired", "This link has expired or been turned off. Ask for a new one.");
  }
  await env.DB.prepare("UPDATE shares SET last_used_at = ?1 WHERE id = ?2").bind(now, row.id).run();
  const linkExpiry = row.expires_at ? Date.parse(row.expires_at) : Infinity;
  const session: Session = {
    role: row.role,
    scope: row.scope,
    share: row.id,
    exp: Math.min(Date.now() + GUEST_SESSION_DAYS * DAY_MS, linkExpiry),
  };
  return new Response(null, {
    status: 302,
    headers: { location: row.scope, "set-cookie": await sessionCookie(request, env, session) },
  });
}

/** GET /api/session → who the visitor is (used by the pages to show owner tools). */
export function describeSession(session: Session | null): Response {
  if (!session) return json({ signedIn: false });
  return json({ signedIn: true, role: session.role, scope: session.scope });
}
