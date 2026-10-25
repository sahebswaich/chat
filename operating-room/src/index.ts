// Operating Room: one Cloudflare Worker in front of the static pages in public/ (home,
// treatise, publishing). Every request passes the gate first; see README.md for the access model.

import { addComment, listComments, resolveComment } from "./comments";
import { roomName, type AppEnv } from "./env";
import { allows, createShare, describeSession, handleLogin, handleLogout, listShares, openShare, readSession, requireOwner, revokeShare, type Session } from "./gate";
import { errorResponse, HttpError, json } from "./http";
import { loginPage, noticePage } from "./pages";
import { deletePublication, getPublication, listPublications, publicationForHost, renderPublication, upsertPublication } from "./publish";

interface Ctx {
  request: Request;
  env: AppEnv;
  url: URL;
  session: Session | null;
  params: string[];
}

type Handler = (c: Ctx) => Promise<Response> | Response;

interface Route {
  method: string;
  pattern: RegExp;
  /** "public": no session needed. "session": any signed-in visitor allowed on `scopeOf`. "owner": owner only. */
  access: "public" | "session" | "owner";
  /** For guest sessions: the page this API call belongs to (checked against the share scope). */
  scopeOf?: (c: Ctx) => string;
  handler: Handler;
}

const routes: Route[] = [
  { method: "GET", pattern: /^\/health$/, access: "public", handler: () => json({ ok: true }) },
  { method: "POST", pattern: /^\/login$/, access: "public", handler: (c) => handleLogin(c.request, c.env) },
  { method: "POST", pattern: /^\/logout$/, access: "public", handler: () => handleLogout() },
  { method: "GET", pattern: /^\/s\/([A-Za-z0-9_-]{20,64})$/, access: "public", handler: (c) => openShare(c.request, c.env, c.params[0]!) },
  { method: "GET", pattern: /^\/api\/session$/, access: "public", handler: (c) => describeSession(c.session) },
  {
    method: "GET",
    pattern: /^\/api\/config$/,
    access: "session",
    handler: (c) => json({ roomName: roomName(c.env), terminalUrl: c.env.TERMINAL_URL?.trim() || null }),
  },

  { method: "GET", pattern: /^\/api\/shares$/, access: "owner", handler: (c) => listShares(c.env) },
  { method: "POST", pattern: /^\/api\/shares$/, access: "owner", handler: (c) => createShare(c.request, c.env) },
  { method: "DELETE", pattern: /^\/api\/shares\/([A-Za-z0-9_-]{1,64})$/, access: "owner", handler: (c) => revokeShare(c.env, c.params[0]!) },

  { method: "GET", pattern: /^\/api\/publications$/, access: "owner", handler: (c) => listPublications(c.env) },
  { method: "PUT", pattern: /^\/api\/publications\/([^/]{1,64})$/, access: "owner", handler: (c) => upsertPublication(c.request, c.env, c.params[0]!) },
  { method: "DELETE", pattern: /^\/api\/publications\/([^/]{1,64})$/, access: "owner", handler: (c) => deletePublication(c.env, c.params[0]!) },

  // Comment routes check the page against the share scope themselves.
  { method: "GET", pattern: /^\/api\/comments$/, access: "session", handler: (c) => listComments(c.url, c.env, c.session!) },
  { method: "POST", pattern: /^\/api\/comments$/, access: "session", handler: (c) => addComment(c.request, c.env, c.session!) },
  { method: "POST", pattern: /^\/api\/comments\/([A-Za-z0-9_-]{1,64})\/resolve$/, access: "owner", handler: (c) => resolveComment(c.env, c.params[0]!) },
];

/** Static files every visitor needs (the sign-in page's styles and the shared scripts). */
const ALWAYS_PUBLIC = /^\/(assets\/[A-Za-z0-9._-]+|favicon\.(ico|svg)|robots\.txt)$/;

const wantsHtml = (request: Request) => (request.headers.get("accept") ?? "").includes("text/html");

async function servePublication(c: Ctx, slug: string): Promise<Response> {
  const pub = await getPublication(c.env, slug);
  if (!pub) return noticePage("Not found", "There is no page at this address.", 404);
  if (pub.visibility === "public") return renderPublication(pub);
  if (!c.session) return loginPage(roomName(c.env), c.url.pathname);
  if (!allows(c.session, `/p/${slug}`)) return noticePage("No access", "This link does not open that page.", 403);
  return renderPublication(pub);
}

async function handle(request: Request, env: AppEnv): Promise<Response> {
  const url = new URL(request.url);
  const method = request.method === "HEAD" ? "GET" : request.method;
  const session = await readSession(request, env);
  const ctx: Ctx = { request, env, url, session, params: [] };

  // A publication's own hostname (custom host or <slug>.<PUBLISH_HOST_SUFFIX>) shows only that page.
  if (method === "GET" && !url.pathname.startsWith("/assets/") && !["/login", "/health"].includes(url.pathname) && !url.pathname.startsWith("/s/") && !url.pathname.startsWith("/api/")) {
    const pub = await publicationForHost(env, url.host);
    if (pub) return servePublication(ctx, pub.slug);
  }

  for (const r of routes) {
    const match = r.pattern.exec(url.pathname);
    if (!match) continue;
    if (r.method !== method) continue;
    ctx.params = match.slice(1);
    if (r.access !== "public") {
      if (!session) throw new HttpError(401, "unauthorized", "Sign in to the room first.");
      if (r.access === "owner") requireOwner(session);
      if (r.scopeOf && !allows(session, r.scopeOf(ctx))) throw new HttpError(403, "forbidden", "This link does not open that page.");
    }
    return r.handler(ctx);
  }
  if (routes.some((r) => r.pattern.test(url.pathname))) {
    throw new HttpError(405, "method_not_allowed", `${request.method} is not supported here.`);
  }
  if (url.pathname.startsWith("/api/")) throw new HttpError(404, "not_found", "No such endpoint.");

  const pubMatch = /^\/p\/([^/]+)\/?$/.exec(url.pathname);
  if (pubMatch && method === "GET") return servePublication(ctx, pubMatch[1]!);

  if (method !== "GET") throw new HttpError(405, "method_not_allowed", `${request.method} is not supported here.`);

  // Static pages: the gate covers everything except the shared assets.
  if (!ALWAYS_PUBLIC.test(url.pathname)) {
    if (!session) {
      if (url.pathname === "/" || wantsHtml(request) || url.pathname.endsWith("/") || url.pathname.endsWith(".html")) {
        return loginPage(roomName(env), url.pathname + url.search);
      }
      throw new HttpError(401, "unauthorized", "Sign in to the room first.");
    }
    const page = url.pathname.replace(/\/index\.html$/, "").replace(/\/$/, "") || "/";
    if (!allows(session, page) && !allows(session, url.pathname)) {
      // A guest landing on the home page goes to the page their link opens.
      if (page === "/") return Response.redirect(new URL(session.scope, url).toString(), 302);
      return noticePage("No access", "This link does not open that page.", 403);
    }
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
} satisfies ExportedHandler<AppEnv>;
