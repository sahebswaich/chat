// Trading terminal: one Cloudflare Worker in front of the static terminal in public/.
// Every request passes the password gate first; share links open it read-only.

import { roomName, type AppEnv } from "./env";
import { createShare, describeSession, handleLogin, handleLogout, listShares, openShare, readSession, requireOwner, revokeShare, type Session } from "./gate";
import { errorResponse, HttpError, json } from "./http";
import { addFills, deleteFill, listFills } from "./journal";
import { boardPanel, impactPanel, koreaPanel, leveragePanel, takeSnapshot } from "./market/api";
import { loginPage, noticePage } from "./pages";

interface Ctx {
  request: Request;
  env: AppEnv;
  url: URL;
  session: Session | null;
  params: string[];
}

interface Route {
  method: string;
  pattern: RegExp;
  /** "public": no session. "session": owner or any share-link guest. "owner": owner only. */
  access: "public" | "session" | "owner";
  handler: (c: Ctx) => Promise<Response> | Response;
}

const routes: Route[] = [
  { method: "GET", pattern: /^\/health$/, access: "public", handler: () => json({ ok: true }) },
  { method: "POST", pattern: /^\/login$/, access: "public", handler: (c) => handleLogin(c.request, c.env) },
  { method: "POST", pattern: /^\/logout$/, access: "public", handler: () => handleLogout() },
  { method: "GET", pattern: /^\/s\/([A-Za-z0-9_-]{20,64})$/, access: "public", handler: (c) => openShare(c.request, c.env, c.params[0]!) },
  { method: "GET", pattern: /^\/api\/session$/, access: "public", handler: (c) => describeSession(c.session) },

  { method: "GET", pattern: /^\/api\/shares$/, access: "owner", handler: (c) => listShares(c.env) },
  { method: "POST", pattern: /^\/api\/shares$/, access: "owner", handler: (c) => createShare(c.request, c.env) },
  { method: "DELETE", pattern: /^\/api\/shares\/([A-Za-z0-9_-]{1,64})$/, access: "owner", handler: (c) => revokeShare(c.env, c.params[0]!) },

  { method: "GET", pattern: /^\/api\/market\/board$/, access: "session", handler: (c) => boardPanel(c.env, c.url) },
  { method: "GET", pattern: /^\/api\/market\/korea$/, access: "session", handler: (c) => koreaPanel(c.env) },
  { method: "GET", pattern: /^\/api\/market\/leverage$/, access: "session", handler: (c) => leveragePanel(c.env) },
  { method: "GET", pattern: /^\/api\/market\/impact$/, access: "session", handler: (c) => impactPanel(c.env, c.url) },
  { method: "POST", pattern: /^\/api\/market\/snapshot$/, access: "owner", handler: async (c) => json(await takeSnapshot(c.env)) },

  // The journal is the owner's own trades: never shown to share-link guests.
  { method: "GET", pattern: /^\/api\/fills$/, access: "owner", handler: (c) => listFills(c.env) },
  { method: "POST", pattern: /^\/api\/fills$/, access: "owner", handler: (c) => addFills(c.request, c.env) },
  { method: "DELETE", pattern: /^\/api\/fills\/([A-Za-z0-9_-]{1,64})$/, access: "owner", handler: (c) => deleteFill(c.env, c.params[0]!) },
];

/** Static files every visitor needs (the sign-in page's styles). */
const ALWAYS_PUBLIC = /^\/(assets\/[A-Za-z0-9._-]+|favicon\.(ico|svg)|robots\.txt)$/;

const wantsHtml = (request: Request) => (request.headers.get("accept") ?? "").includes("text/html");

async function handle(request: Request, env: AppEnv): Promise<Response> {
  const url = new URL(request.url);
  const method = request.method === "HEAD" ? "GET" : request.method;
  const session = await readSession(request, env);
  const ctx: Ctx = { request, env, url, session, params: [] };

  for (const r of routes) {
    const match = r.pattern.exec(url.pathname);
    if (!match || r.method !== method) continue;
    ctx.params = match.slice(1);
    if (r.access !== "public") {
      if (!session) throw new HttpError(401, "unauthorized", "Sign in to the terminal first.");
      if (r.access === "owner") requireOwner(session);
    }
    return r.handler(ctx);
  }
  if (routes.some((r) => r.pattern.test(url.pathname))) {
    throw new HttpError(405, "method_not_allowed", `${request.method} is not supported here.`);
  }
  if (url.pathname.startsWith("/api/")) throw new HttpError(404, "not_found", "No such endpoint.");
  if (method !== "GET") throw new HttpError(405, "method_not_allowed", `${request.method} is not supported here.`);

  if (!ALWAYS_PUBLIC.test(url.pathname) && !session) {
    if (wantsHtml(request) || url.pathname === "/" || url.pathname.endsWith("/") || url.pathname.endsWith(".html")) {
      return loginPage(roomName(env), url.pathname + url.search);
    }
    throw new HttpError(401, "unauthorized", "Sign in to the terminal first.");
  }
  const res = await env.ASSETS.fetch(request);
  if (res.status === 404 && wantsHtml(request)) return noticePage("Not found", "There is no page at this address.", 404);
  const headers = new Headers(res.headers);
  headers.set("cache-control", "no-store");
  headers.set("x-robots-tag", "noindex");
  return new Response(res.body, { status: res.status, headers });
}

export default {
  async fetch(request, env): Promise<Response> {
    try {
      const response = await handle(request, env);
      return request.method === "HEAD" ? new Response(null, response) : response;
    } catch (err) {
      if (err instanceof HttpError) return errorResponse(err);
      console.error("unhandled error", err);
      return errorResponse(new HttpError(500, "internal_error", "Something went wrong. Try again."));
    }
  },
  async scheduled(_controller, env, ctx): Promise<void> {
    ctx.waitUntil(
      takeSnapshot(env)
        .then((r) => console.log("snapshot", r.rows, JSON.stringify(r.sources.filter((s) => !s.ok))))
        .catch((err: unknown) => console.error("snapshot failed", err)),
    );
  },
} satisfies ExportedHandler<AppEnv>;
