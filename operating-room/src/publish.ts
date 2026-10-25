// Publishing: any page (markdown or HTML) at /p/<slug>, optionally on its own hostname
// (<slug>.<PUBLISH_HOST_SUFFIX>, or a custom_host such as memo.example.com).

import type { AppEnv } from "./env";
import { HttpError, invalidRequest, json, optionalString, readJsonObject, requiredString } from "./http";
import { escapeHtml, nowIso } from "./util";

export const SLUG_RE = /^[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?$/;
const HOST_RE = /^(?=.{1,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/;
const MAX_PUBLICATION_CHARS = 5_000_000;

export interface Publication {
  slug: string;
  title: string;
  kind: "markdown" | "html";
  body: string;
  visibility: "private" | "public";
  custom_host: string | null;
  created_at: string;
  updated_at: string;
}

const summary = (p: Omit<Publication, "body">) => ({
  slug: p.slug,
  title: p.title,
  kind: p.kind,
  visibility: p.visibility,
  customHost: p.custom_host,
  path: `/p/${p.slug}`,
  createdAt: p.created_at,
  updatedAt: p.updated_at,
});

/** PUT /api/publications/<slug> {title, kind, body, visibility, customHost?} — create or replace. */
export async function upsertPublication(request: Request, env: AppEnv, slug: string): Promise<Response> {
  if (!SLUG_RE.test(slug)) throw invalidRequest("Slugs use a–z, 0–9 and dashes (max 64).");
  const body = await readJsonObject(request);
  const title = requiredString(body, "title", 200, true);
  const kind = body["kind"] ?? "markdown";
  if (kind !== "markdown" && kind !== "html") throw invalidRequest('"kind" must be "markdown" or "html".');
  const content = requiredString(body, "body", MAX_PUBLICATION_CHARS);
  const visibility = body["visibility"] ?? "private";
  if (visibility !== "private" && visibility !== "public") throw invalidRequest('"visibility" must be "private" or "public".');
  const hostInput = optionalString(body, "customHost", 253)?.trim().toLowerCase() || null;
  if (hostInput !== null && !HOST_RE.test(hostInput)) throw invalidRequest('"customHost" must be a hostname such as memo.example.com.');
  const now = nowIso();
  try {
    await env.DB.prepare(
      `INSERT INTO publications (slug, title, kind, body, visibility, custom_host, created_at, updated_at)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?7)
       ON CONFLICT (slug) DO UPDATE SET title = ?2, kind = ?3, body = ?4, visibility = ?5, custom_host = ?6, updated_at = ?7`,
    )
      .bind(slug, title, kind, content, visibility, hostInput, now)
      .run();
  } catch (err) {
    if (String(err).includes("UNIQUE")) throw new HttpError(409, "host_taken", "Another publication already uses that host.");
    throw err;
  }
  const row = await env.DB.prepare(
    "SELECT slug, title, kind, visibility, custom_host, created_at, updated_at FROM publications WHERE slug = ?1",
  )
    .bind(slug)
    .first<Omit<Publication, "body">>();
  return json(summary(row!));
}

export async function listPublications(env: AppEnv): Promise<Response> {
  const { results } = await env.DB.prepare(
    "SELECT slug, title, kind, visibility, custom_host, created_at, updated_at FROM publications ORDER BY updated_at DESC",
  ).all<Omit<Publication, "body">>();
  return json({ publications: results.map(summary) });
}

export async function deletePublication(env: AppEnv, slug: string): Promise<Response> {
  const res = await env.DB.prepare("DELETE FROM publications WHERE slug = ?1").bind(slug).run();
  if (!res.meta.changes) throw new HttpError(404, "not_found", "No publication with that slug.");
  return json({ ok: true });
}

export async function getPublication(env: AppEnv, slug: string): Promise<Publication | null> {
  if (!SLUG_RE.test(slug)) return null;
  return env.DB.prepare("SELECT * FROM publications WHERE slug = ?1").bind(slug).first<Publication>();
}

/** The publication a hostname maps to: a custom_host, or <slug>.<PUBLISH_HOST_SUFFIX>. */
export async function publicationForHost(env: AppEnv, host: string): Promise<Publication | null> {
  const hostname = host.toLowerCase().replace(/:\d+$/, "");
  const byHost = await env.DB.prepare("SELECT * FROM publications WHERE custom_host = ?1").bind(hostname).first<Publication>();
  if (byHost) return byHost;
  const suffix = env.PUBLISH_HOST_SUFFIX?.trim().toLowerCase();
  if (suffix && hostname.endsWith("." + suffix)) {
    const slug = hostname.slice(0, -suffix.length - 1);
    if (!slug.includes(".")) return getPublication(env, slug);
  }
  return null;
}

/**
 * Renders a publication. HTML is served as written but sandboxed (opaque origin: its
 * scripts cannot read the room's cookies or call the room's API). Markdown goes into the
 * paper template, rendered in the browser with marked + DOMPurify.
 */
export function renderPublication(p: Publication): Response {
  if (p.kind === "html") {
    return new Response(p.body, {
      headers: {
        "content-type": "text/html; charset=utf-8",
        "content-security-policy": "sandbox allow-scripts allow-popups allow-forms allow-modals allow-downloads",
        "cache-control": "no-store",
      },
    });
  }
  const payload = JSON.stringify({ title: p.title, markdown: p.body, updatedAt: p.updated_at }).replace(/</g, "\\u003c");
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(p.title)}</title>
<link rel="stylesheet" href="/assets/paper.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/marked/12.0.2/marked.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/dompurify/3.1.6/purify.min.js"></script>
</head>
<body class="paper-desk">
<div class="paper-toolbar no-print"><a href="/">← Room</a><span></span><button type="button" data-print>Save as PDF</button></div>
<article class="paper" id="doc"></article>
<script type="application/json" id="pub">${payload}</script>
<script src="/assets/publication.js"></script>
<script src="/assets/discussion.js" defer></script>
</body>
</html>`;
  return new Response(html, { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" } });
}
