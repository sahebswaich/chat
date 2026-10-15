// Nimbus cards: POST /v1/cards stores an answer the user chose to send as a
// card; GET /c/:id (HTML) and /c/:id.json show it to anyone with the link.

import { requireUser } from "./auth";
import type { AppEnv } from "./env";
import { json, optionalString, publicOrigin, readJsonObject, requiredString } from "./http";
import { cardNotFoundPage, cardPage } from "./pages";
import { newCardId, nowIso } from "./util";

export const MAX_CARD_QUESTION = 2_000;
export const MAX_CARD_ANSWER = 20_000;

interface CardRow {
  id: string;
  question: string;
  answer: string;
  created_at: string;
}

/** POST /v1/cards {"question", "answer"} → {"id", "url"} */
export async function handleCreateCard(request: Request, env: AppEnv, ctx: ExecutionContext): Promise<Response> {
  const user = await requireUser(request, env, ctx);
  const body = await readJsonObject(request);
  const question = optionalString(body, "question", MAX_CARD_QUESTION) ?? "";
  const answer = requiredString(body, "answer", MAX_CARD_ANSWER);

  const id = newCardId();
  await env.DB.prepare("INSERT INTO cards (id, user_id, question, answer, created_at) VALUES (?1, ?2, ?3, ?4, ?5)")
    .bind(id, user.id, question, answer, nowIso())
    .run();
  return json({ id, url: `${publicOrigin(request)}/c/${id}` });
}

async function findCard(env: AppEnv, id: string): Promise<CardRow | null> {
  return env.DB.prepare("SELECT id, question, answer, created_at FROM cards WHERE id = ?1").bind(id).first<CardRow>();
}

/** GET /c/:id and /c/:id.json (the query string, which carries the in-message copy, is ignored). */
export async function handleGetCard(env: AppEnv, id: string, asJson: boolean): Promise<Response> {
  const card = await findCard(env, id);
  if (asJson) {
    if (!card) return json({ error: { code: "not_found", message: "Card not found." } }, 404);
    return json(
      { id: card.id, question: card.question, answer: card.answer, createdAt: card.created_at },
      200,
      { "cache-control": "public, max-age=3600" },
    );
  }
  return card ? cardPage(card) : cardNotFoundPage();
}
