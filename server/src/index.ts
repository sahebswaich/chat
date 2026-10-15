// Nimbus server: one Cloudflare Worker. Routes follow the "Server API" contract
// in docs/ARCHITECTURE.md; see server/README.md for deployment.

import { createInvite, deleteInvite, listInvites, listReports, listUsers, revokeUser } from "./admin";
import { requireAdmin } from "./auth";
import { handleCreateCard, handleGetCard } from "./cards";
import { handleChat } from "./chat";
import type { AppEnv } from "./env";
import { errorResponse, HttpError, json } from "./http";
import { homePage, joinPage, privacyPage } from "./pages";
import { handleMe, handleRedeem, handleReport } from "./users";

type Handler = (request: Request, env: AppEnv, ctx: ExecutionContext, params: string[]) => Promise<Response> | Response;

interface Route {
  method: string;
  pattern: RegExp;
  handler: Handler;
}

const admin =
  (handler: Handler): Handler =>
  async (request, env, ctx, params) => {
    await requireAdmin(request, env);
    return handler(request, env, ctx, params);
  };

const routes: Route[] = [
  { method: "GET", pattern: /^\/health$/, handler: () => json({ ok: true }) },
  { method: "GET", pattern: /^\/$/, handler: () => homePage() },
  { method: "GET", pattern: /^\/privacy\/?$/, handler: (req) => privacyPage(new URL(req.url).host) },
  {
    method: "GET",
    pattern: /^\/join\/([^/]{1,128})\/?$/,
    handler: (req, env, _ctx, [code]) => joinPage(code!, new URL(req.url).host, env.TESTFLIGHT_URL),
  },
  {
    method: "GET",
    pattern: /^\/c\/([A-Za-z0-9_-]{12,64})(\.json)?$/,
    handler: (_req, env, _ctx, [id, ext]) => handleGetCard(env, id!, ext === ".json"),
  },

  { method: "POST", pattern: /^\/v1\/redeem$/, handler: (req, env) => handleRedeem(req, env) },
  { method: "GET", pattern: /^\/v1\/me$/, handler: (req, env, ctx) => handleMe(req, env, ctx) },
  { method: "POST", pattern: /^\/v1\/chat$/, handler: (req, env, ctx) => handleChat(req, env, ctx) },
  { method: "POST", pattern: /^\/v1\/report$/, handler: (req, env, ctx) => handleReport(req, env, ctx) },
  { method: "POST", pattern: /^\/v1\/cards$/, handler: (req, env, ctx) => handleCreateCard(req, env, ctx) },

  { method: "POST", pattern: /^\/admin\/invites$/, handler: admin((req, env) => createInvite(req, env)) },
  { method: "GET", pattern: /^\/admin\/invites$/, handler: admin((_req, env) => listInvites(env)) },
  {
    method: "DELETE",
    pattern: /^\/admin\/invites\/([^/]{1,64})$/,
    handler: admin((_req, env, _ctx, [code]) => deleteInvite(env, code!)),
  },
  { method: "GET", pattern: /^\/admin\/users$/, handler: admin((_req, env) => listUsers(env)) },
  {
    method: "POST",
    pattern: /^\/admin\/users\/([^/]{1,64})\/revoke$/,
    handler: admin((_req, env, _ctx, [id]) => revokeUser(env, id!)),
  },
  { method: "GET", pattern: /^\/admin\/reports$/, handler: admin((_req, env) => listReports(env)) },
];

async function route(request: Request, env: AppEnv, ctx: ExecutionContext): Promise<Response> {
  const { pathname } = new URL(request.url);
  const method = request.method === "HEAD" ? "GET" : request.method;
  let pathMatched = false;
  for (const r of routes) {
    const match = r.pattern.exec(pathname);
    if (!match) continue;
    pathMatched = true;
    if (r.method !== method) continue;
    const response = await r.handler(request, env, ctx, match.slice(1) as string[]);
    return request.method === "HEAD" ? new Response(null, response) : response;
  }
  if (pathMatched) throw new HttpError(405, "method_not_allowed", `${request.method} is not allowed here.`);
  throw new HttpError(404, "not_found", "Not found.");
}

export default {
  async fetch(request, env, ctx): Promise<Response> {
    try {
      return await route(request, env, ctx);
    } catch (err) {
      if (err instanceof HttpError) return errorResponse(err);
      console.error("Unhandled error", err);
      return errorResponse(new HttpError(500, "internal", "Something went wrong on the server."));
    }
  },
} satisfies ExportedHandler<AppEnv>;
