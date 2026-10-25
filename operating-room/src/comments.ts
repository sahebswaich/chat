// Discussion: threads attached to a page path and (optionally) a section anchor.

import type { AppEnv } from "./env";
import { allows, type Session } from "./gate";
import { HttpError, invalidRequest, json, optionalString, readJsonObject, requiredString } from "./http";
import { newId, nowIso } from "./util";

const PAGE_RE = /^\/[A-Za-z0-9/_.-]{0,200}$/;
const ANCHOR_RE = /^[A-Za-z0-9_.:-]{0,120}$/;

interface CommentRow {
  id: string;
  page: string;
  anchor: string;
  parent_id: string | null;
  author: string;
  body: string;
  created_at: string;
  resolved_at: string | null;
}

function checkPage(page: string, session: Session): void {
  if (!PAGE_RE.test(page) || page.includes("..")) throw invalidRequest('"page" must be a path such as "/treatise".');
  if (!allows(session, page)) throw new HttpError(403, "forbidden", "This link does not open that page.");
}

/** GET /api/comments?page=/treatise[&since=ISO] */
export async function listComments(url: URL, env: AppEnv, session: Session): Promise<Response> {
  const page = url.searchParams.get("page") ?? "";
  checkPage(page, session);
  const since = url.searchParams.get("since");
  const stmt = since
    ? env.DB.prepare("SELECT * FROM comments WHERE page = ?1 AND created_at > ?2 ORDER BY created_at").bind(page, since)
    : env.DB.prepare("SELECT * FROM comments WHERE page = ?1 ORDER BY created_at").bind(page);
  const { results } = await stmt.all<CommentRow>();
  return json({
    comments: results.map((c) => ({
      id: c.id,
      anchor: c.anchor,
      parentId: c.parent_id,
      author: c.author,
      body: c.body,
      createdAt: c.created_at,
      resolvedAt: c.resolved_at,
    })),
    canComment: session.role !== "view",
    isOwner: session.role === "owner",
  });
}

/** POST /api/comments {page, anchor?, parentId?, author, body} */
export async function addComment(request: Request, env: AppEnv, session: Session): Promise<Response> {
  if (session.role === "view") throw new HttpError(403, "forbidden", "This link is view-only.");
  const body = await readJsonObject(request);
  const page = requiredString(body, "page", 200, true);
  checkPage(page, session);
  const anchor = optionalString(body, "anchor", 120)?.trim() ?? "";
  if (!ANCHOR_RE.test(anchor)) throw invalidRequest('"anchor" has unsupported characters.');
  const parentId = optionalString(body, "parentId", 64) ?? null;
  const author = session.role === "owner" ? (optionalString(body, "author", 60)?.trim() || "Owner") : requiredString(body, "author", 60, true);
  const text = requiredString(body, "body", 8000, true);
  if (parentId) {
    const parent = await env.DB.prepare("SELECT page FROM comments WHERE id = ?1").bind(parentId).first<{ page: string }>();
    if (!parent || parent.page !== page) throw invalidRequest('"parentId" is not a comment on this page.');
  }
  const id = newId("c");
  const createdAt = nowIso();
  await env.DB.prepare(
    "INSERT INTO comments (id, page, anchor, parent_id, author, body, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
  )
    .bind(id, page, anchor, parentId, author, text, createdAt)
    .run();
  return json({ id, anchor, parentId, author, body: text, createdAt, resolvedAt: null });
}

/** POST /api/comments/<id>/resolve — owner only. */
export async function resolveComment(env: AppEnv, id: string): Promise<Response> {
  const res = await env.DB.prepare("UPDATE comments SET resolved_at = ?1 WHERE id = ?2 AND resolved_at IS NULL")
    .bind(nowIso(), id)
    .run();
  if (!res.meta.changes) throw new HttpError(404, "not_found", "No open comment with that id.");
  return json({ ok: true });
}
