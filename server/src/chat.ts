// POST /v1/chat: validate, count against the daily limit, then stream Claude's
// answer to the app as Server-Sent Events (meta → status → delta… → done|error).

import Anthropic from "@anthropic-ai/sdk";
import type { BetaMessageStreamParams } from "@anthropic-ai/sdk/resources/beta/messages/messages";
import { consumeDailyQuota, refundDailyQuota, requireUser, type User } from "./auth";
import { modelId, type AppEnv } from "./env";
import { HttpError, invalidRequest, optionalString, readJsonObject } from "./http";
import { firstUserTurn, STYLES, SURFACES, systemPrompt, type Style, type Surface } from "./prompts";
import { humanDuration, isRecord, nextUtcMidnight, utcDay } from "./util";

type BetaMessageParam = Anthropic.Beta.Messages.BetaMessageParam;
type BetaContentBlock = Anthropic.Beta.Messages.BetaContentBlock;
type BetaContentBlockParam = Anthropic.Beta.Messages.BetaContentBlockParam;

export const MAX_MESSAGES = 40;
export const MAX_CONTENT_CHARS = 20_000;
export const MAX_CONTEXT_CHARS = 20_000;
/** How many times a `pause_turn` (long server-side web search loop) is resumed. */
export const MAX_CONTINUATIONS = 3;
/** Beta header for the scalar `fallbacks: "default"` form (the array form uses -2026-06-01). */
export const FALLBACK_BETA = "server-side-fallback-2026-07-01";
/** Send an SSE comment if nothing was written for this long (keeps mobile connections alive). */
const HEARTBEAT_MS = 15_000;

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface ChatRequest {
  messages: ChatMessage[];
  style: Style;
  surface: Surface;
  context: string | undefined;
  webSearch: boolean;
}

/** Strict validation of the /v1/chat body (unknown extra keys are ignored for forward compatibility). */
export function parseChatRequest(body: Record<string, unknown>): ChatRequest {
  const raw = body["messages"];
  if (!Array.isArray(raw) || raw.length === 0) {
    throw invalidRequest('"messages" must be a non-empty array.');
  }
  if (raw.length > MAX_MESSAGES) {
    throw invalidRequest(`"messages" can have at most ${MAX_MESSAGES} entries.`);
  }
  const messages: ChatMessage[] = raw.map((m: unknown, i: number) => {
    if (!isRecord(m)) throw invalidRequest(`messages[${i}] must be an object.`);
    const expected = i % 2 === 0 ? "user" : "assistant";
    if (m["role"] !== "user" && m["role"] !== "assistant") {
      throw invalidRequest(`messages[${i}].role must be "user" or "assistant".`);
    }
    if (m["role"] !== expected) {
      throw invalidRequest(
        `messages must alternate user/assistant starting with user; messages[${i}] should be "${expected}".`,
      );
    }
    const content = m["content"];
    if (typeof content !== "string" || content.trim() === "") {
      throw invalidRequest(`messages[${i}].content must be a non-empty string.`);
    }
    if (content.length > MAX_CONTENT_CHARS) {
      throw invalidRequest(`messages[${i}].content must be at most ${MAX_CONTENT_CHARS} characters.`);
    }
    return { role: expected, content };
  });
  if (messages[messages.length - 1]!.role !== "user") {
    throw invalidRequest("The last message must be from the user.");
  }

  const style = body["style"] ?? "default";
  if (typeof style !== "string" || !(STYLES as readonly string[]).includes(style)) {
    throw invalidRequest(`"style" must be one of: ${STYLES.join(", ")}.`);
  }
  const surface = body["surface"] ?? "messages";
  if (typeof surface !== "string" || !(SURFACES as readonly string[]).includes(surface)) {
    throw invalidRequest(`"surface" must be one of: ${SURFACES.join(", ")}.`);
  }
  const context = optionalString(body, "context", MAX_CONTEXT_CHARS);
  const webSearch = body["webSearch"] ?? false;
  if (typeof webSearch !== "boolean") throw invalidRequest('"webSearch" must be true or false.');

  return { messages, style: style as Style, surface: surface as Surface, context, webSearch };
}

export async function handleChat(request: Request, env: AppEnv, ctx: ExecutionContext): Promise<Response> {
  const user = await requireUser(request, env, ctx);
  const chat = parseChatRequest(await readJsonObject(request));

  // The limit is enforced (and the request counted) before Claude is called.
  const now = new Date();
  const day = utcDay(now);
  const used = await consumeDailyQuota(env, user.id, user.dailyLimit, day);
  if (used === null) throw dailyLimitError(user.dailyLimit, now);

  return streamAnswer(env, ctx, user, chat, { day, used, now });
}

function dailyLimitError(limit: number, now: Date): HttpError {
  const reset = nextUtcMidnight(now);
  const wait = reset.getTime() - now.getTime();
  return new HttpError(
    429,
    "daily_limit",
    `You've used all ${limit} messages for today. Your limit resets at midnight UTC (in ${humanDuration(wait)}).`,
    { resetAt: reset.toISOString() },
    { "retry-after": String(Math.ceil(wait / 1000)) },
  );
}

type ErrorCode = "refusal" | "upstream" | "overloaded" | "max_tokens";

const MESSAGES: Record<ErrorCode, string> = {
  refusal: "Nimbus can't help with that one. Try asking a different way.",
  max_tokens: "The answer got too long and was cut off.",
  overloaded: "Claude is very busy right now. Try again in a moment.",
  upstream: "Something went wrong while getting the answer. Try again.",
};

interface Hooks {
  signal: AbortSignal;
  onStatus(state: "searching" | "writing"): void;
  onText(text: string): void;
}

function streamAnswer(
  env: AppEnv,
  ctx: ExecutionContext,
  user: User,
  chat: ChatRequest,
  usage: { day: string; used: number; now: Date },
): Response {
  const encoder = new TextEncoder();
  const upstream = new AbortController();
  let controller!: ReadableStreamDefaultController<Uint8Array>;
  let open = true;
  let lastWrite = Date.now();

  const body = new ReadableStream<Uint8Array>({
    start(c) {
      controller = c;
    },
    cancel() {
      console.log("DEBUG cancel called");
      // The app disconnected: stop paying for tokens nobody will read.
      open = false;
      upstream.abort();
    },
  });

  const write = (chunk: string) => {
    if (!open) return;
    try {
      controller.enqueue(encoder.encode(chunk));
      lastWrite = Date.now();
    } catch {
      open = false;
      upstream.abort();
    }
  };
  const send = (event: string, data: unknown) => write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
  const heartbeat = setInterval(() => {
    if (Date.now() - lastWrite >= HEARTBEAT_MS - 1000) write(": keepalive\n\n");
  }, HEARTBEAT_MS);

  let textSent = false;
  let status: "searching" | "writing" | null = null;
  const hooks: Hooks = {
    signal: upstream.signal,
    onStatus(state) {
      if (state === status) return;
      status = state;
      send("status", { state });
    },
    onText(text) {
      if (text === "") return;
      if (status !== "writing") hooks.onStatus("writing");
      textSent = true;
      send("delta", { text });
    },
  };

  const model = modelId(env);
  const pump = (async () => {
    try {
      send("meta", { model });
      const stopReason = await runClaude(env, chat, model, usage.now, hooks);
      if (stopReason === "refusal") {
        send("error", { code: "refusal", message: MESSAGES.refusal });
      } else if (stopReason === "max_tokens" || stopReason === "model_context_window_exceeded") {
        send("error", { code: "max_tokens", message: MESSAGES.max_tokens });
      } else if (stopReason === "pause_turn" && !textSent) {
        // Still searching after MAX_CONTINUATIONS resumptions and nothing to show.
        await refund(env, user, usage.day);
        send("error", { code: "upstream", message: "The search took too long. Try again." });
      } else {
        send("done", { stopReason, usedToday: usage.used, dailyLimit: user.dailyLimit });
      }
    } catch (err) {
      if (!open || upstream.signal.aborted || err instanceof Anthropic.APIUserAbortError) return;
      const code = classifyError(err);
      // Don't charge the user for a request Claude never answered.
      if (!textSent) await refund(env, user, usage.day);
      send("error", { code, message: MESSAGES[code] });
    } finally {
      clearInterval(heartbeat);
      if (open) {
        open = false;
        try {
          controller.close();
        } catch {
          // already closed/errored
        }
      }
    }
  })();
  ctx.waitUntil(pump);

  return new Response(body, {
    status: 200,
    headers: {
      "content-type": "text/event-stream",
      "cache-control": "no-cache",
      "x-accel-buffering": "no",
    },
  });
}

async function refund(env: AppEnv, user: User, day: string): Promise<void> {
  try {
    await refundDailyQuota(env, user.id, day);
  } catch (err) {
    console.error("usage refund failed", err);
  }
}

/** Maps an error from the Claude API / SDK to the contract's SSE error codes. */
export function classifyError(err: unknown): "upstream" | "overloaded" {
  if (err instanceof Anthropic.RateLimitError) return "overloaded";
  if (err instanceof Anthropic.APIConnectionError) {
    console.error("Claude API connection error", err.message);
    return "upstream";
  }
  if (err instanceof Anthropic.AuthenticationError || err instanceof Anthropic.PermissionDeniedError) {
    console.error("Claude API rejected the server's credentials - check the ANTHROPIC_API_KEY secret", err.message);
    return "upstream";
  }
  if (err instanceof Anthropic.APIError) {
    // 529 before the stream starts, or an `overloaded_error` event mid-stream (status undefined).
    if (err.status === 529 || err.type === "overloaded_error" || err.type === "rate_limit_error") {
      return "overloaded";
    }
    console.error(`Claude API error ${err.status ?? "(mid-stream)"} ${err.type ?? ""}`, err.message);
    return "upstream";
  }
  console.error("Unexpected error while streaming", err);
  return "upstream";
}

/** The request's messages in API form; the first user turn carries the date and pasted context. */
export function toApiMessages(chat: ChatRequest, now: Date): BetaMessageParam[] {
  return chat.messages.map((m, i) => ({
    role: m.role,
    content: i === 0 ? firstUserTurn(m.content, chat.context, now) : m.content,
  }));
}

export function buildParams(chat: ChatRequest, model: string, now: Date): BetaMessageStreamParams {
  const snappy = chat.surface !== "app";
  return {
    model,
    max_tokens: snappy ? 16_000 : 64_000,
    // Frozen per (surface, style) so the cached prefix is reused.
    system: systemPrompt(chat.surface, chat.style),
    messages: toApiMessages(chat, now),
    // Automatic prompt caching: caches up to the last cacheable block.
    cache_control: { type: "ephemeral" },
    // Thinking is always on for this model; effort controls depth and latency.
    output_config: { effort: snappy ? "low" : "medium" },
    // Server-side refusal fallback: a policy decline is retried on Anthropic's
    // recommended fallback model inside the same call (and the same stream).
    betas: [FALLBACK_BETA],
    fallbacks: "default",
    ...(chat.webSearch ? { tools: [{ type: "web_search_20260209", name: "web_search", max_uses: 3 }] } : {}),
  };
}

/**
 * Streams one answer, resuming `pause_turn` up to MAX_CONTINUATIONS times by
 * re-sending the conversation with the paused assistant content appended (no
 * extra user message). Returns the final stop reason.
 */
async function runClaude(env: AppEnv, chat: ChatRequest, model: string, now: Date, hooks: Hooks): Promise<string> {
  const client = new Anthropic({
    apiKey: env.ANTHROPIC_API_KEY,
    authToken: null,
    baseURL: env.ANTHROPIC_BASE_URL || null,
    maxRetries: 2,
  });
  const params = buildParams(chat, model, now);
  let messages = params.messages;

  for (let continuation = 0; ; continuation++) {
    const stream = client.beta.messages.stream({ ...params, messages }, { signal: hooks.signal });
    for await (const event of stream) {
      if (event.type === "content_block_start") {
        const block = event.content_block;
        if (block.type === "server_tool_use") hooks.onStatus("searching");
        else if (block.type === "text") {
          hooks.onStatus("writing");
          hooks.onText(block.text);
        }
      } else if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
        hooks.onText(event.delta.text);
      }
    }
    const message = await stream.finalMessage();
    if (message.stop_reason === "pause_turn" && continuation < MAX_CONTINUATIONS) {
      messages = appendAssistant(messages, echoableContent(message.content));
      continue;
    }
    return message.stop_reason ?? "end_turn";
  }
}

/** Appends paused assistant content, merging into a trailing assistant turn from an earlier pause. */
function appendAssistant(messages: BetaMessageParam[], content: BetaContentBlockParam[]): BetaMessageParam[] {
  const last = messages[messages.length - 1];
  if (last && last.role === "assistant" && Array.isArray(last.content)) {
    return [...messages.slice(0, -1), { role: "assistant", content: [...last.content, ...content] }];
  }
  return [...messages, { role: "assistant", content }];
}

/**
 * Response content made safe to echo back on a continuation. After a mid-output
 * refusal fallback, blocks before the last `fallback` marker are reduced to text
 * and paired server-tool blocks (thinking, tool_use and unpaired server_tool_use
 * from the declined model are dropped); the `fallback` markers themselves are
 * dropped. Without a fallback, content is echoed unchanged.
 */
export function echoableContent(content: BetaContentBlock[]): BetaContentBlockParam[] {
  const boundary = content.findLastIndex((b) => b.type === "fallback");
  const resultIds = new Set<string>();
  for (const b of content) {
    if ("tool_use_id" in b && typeof b.tool_use_id === "string") resultIds.add(b.tool_use_id);
  }
  const serverUseIds = new Set<string>();
  for (const b of content) if (b.type === "server_tool_use") serverUseIds.add(b.id);

  const kept = content.filter((b, i) => {
    if (b.type === "fallback") return false;
    if (i > boundary) return true;
    if (b.type === "text") return true;
    if (b.type === "server_tool_use") return resultIds.has(b.id);
    if ("tool_use_id" in b && typeof b.tool_use_id === "string") return serverUseIds.has(b.tool_use_id);
    return false;
  });
  // Response blocks are valid request blocks (that is how pause_turn resumption works).
  return kept;
}
