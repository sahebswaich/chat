// Test helpers: call the Worker, seed invites/users, and fake the Claude API.

import { env, exports } from "cloudflare:workers";
import { expect, vi } from "vitest";

export const BASE = "https://nimbus.example.com";
export const ADMIN_TOKEN = "test-admin-token";
export const CLAUDE_BASE = "https://claude-api.test";

interface CallOptions {
  body?: unknown;
  token?: string;
  headers?: Record<string, string>;
}

export function call(method: string, path: string, opts: CallOptions = {}): Promise<Response> {
  const headers: Record<string, string> = { ...opts.headers };
  if (opts.body !== undefined) headers["content-type"] ??= "application/json";
  if (opts.token) headers["authorization"] = `Bearer ${opts.token}`;
  const init: RequestInit = { method, headers };
  if (opts.body !== undefined) init.body = typeof opts.body === "string" ? opts.body : JSON.stringify(opts.body);
  return exports.default.fetch(new Request(BASE + path, init));
}

export const admin = (method: string, path: string, body?: unknown) =>
  call(method, path, { body, token: ADMIN_TOKEN });

export async function createInvite(name = "James", extra: Record<string, unknown> = {}) {
  const res = await admin("POST", "/admin/invites", { name, ...extra });
  expect(res.status).toBe(200);
  return (await res.json()) as { code: string; url: string };
}

/** Creates an invite and redeems it; returns the bearer token. */
export async function signUp(name = "James", extra: Record<string, unknown> = {}): Promise<string> {
  const { code } = await createInvite(name, extra);
  const res = await call("POST", "/v1/redeem", { body: { code, device: "Test iPhone" } });
  expect(res.status).toBe(200);
  return ((await res.json()) as { token: string }).token;
}

export async function errorOf(res: Response): Promise<{ code: string; message: string }> {
  const body = (await res.json()) as { error: { code: string; message: string } };
  return body.error;
}

// ---------------------------------------------------------------------------
// Fake Claude Messages API

export interface SseEvent {
  type: string;
  [key: string]: unknown;
}

export function messageStart(model = "claude-opus-5-5"): SseEvent {
  return {
    type: "message_start",
    message: {
      id: "msg_01TestTestTestTestTest",
      type: "message",
      role: "assistant",
      model,
      content: [],
      stop_reason: null,
      stop_sequence: null,
      stop_details: null,
      usage: { input_tokens: 412, output_tokens: 1, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 },
    },
  };
}

/** Adaptive thinking with display "omitted": an empty thinking block carrying only a signature. */
export function thinkingBlock(index: number): SseEvent[] {
  return [
    { type: "content_block_start", index, content_block: { type: "thinking", thinking: "", signature: "" } },
    { type: "content_block_delta", index, delta: { type: "signature_delta", signature: "EqQBCkYIBxgCKkA=" } },
    { type: "content_block_stop", index },
  ];
}

export function textBlock(index: number, chunks: string[]): SseEvent[] {
  return [
    { type: "content_block_start", index, content_block: { type: "text", text: "" } },
    ...chunks.map((text) => ({ type: "content_block_delta", index, delta: { type: "text_delta", text } })),
    { type: "content_block_stop", index },
  ];
}

export function messageEnd(stopReason: string, stopDetails: unknown = null): SseEvent[] {
  return [
    {
      type: "message_delta",
      delta: { stop_reason: stopReason, stop_sequence: null, stop_details: stopDetails },
      usage: { output_tokens: 87 },
    },
    { type: "message_stop" },
  ];
}

/** A complete streamed answer: thinking, then text in chunks, then the stop reason. */
export function textAnswer(chunks: string[], stopReason = "end_turn", stopDetails: unknown = null): SseEvent[] {
  return [
    messageStart(),
    ...thinkingBlock(0),
    { type: "ping" },
    ...textBlock(1, chunks),
    ...messageEnd(stopReason, stopDetails),
  ];
}

export function sseBody(events: SseEvent[]): string {
  return events.map((e) => `event: ${e.type}\ndata: ${JSON.stringify(e)}\n\n`).join("");
}

/** An SSE response delivered in small, uneven chunks (as a real network would). */
export function sseResponse(events: SseEvent[]): Response {
  const bytes = new TextEncoder().encode(sseBody(events));
  let offset = 0;
  const body = new ReadableStream<Uint8Array>({
    pull(controller) {
      if (offset >= bytes.length) return controller.close();
      const size = 7 + (offset % 53);
      controller.enqueue(bytes.slice(offset, offset + size));
      offset += size;
    },
  });
  return new Response(body, {
    status: 200,
    headers: { "content-type": "text/event-stream; charset=utf-8", "request-id": "req_test" },
  });
}

export function apiErrorResponse(status: number, type: string, message: string): Response {
  return new Response(JSON.stringify({ type: "error", error: { type, message }, request_id: "req_test" }), {
    status,
    // Keep the SDK's automatic retries instant in tests.
    headers: { "content-type": "application/json", "retry-after-ms": "1", "request-id": "req_test" },
  });
}

export interface ClaudeCall {
  url: string;
  headers: Headers;
  body: Record<string, any>;
  signal: AbortSignal | null;
}

type Reply = Response | ((call: ClaudeCall) => Response | Promise<Response>);

/**
 * Intercepts `fetch` from the Worker (tests and Worker share one isolate) and
 * answers Claude API calls from `replies`, in order. Any other outbound request
 * fails the test.
 */
export function mockClaude(...replies: Reply[]): { calls: ClaudeCall[] } {
  const calls: ClaudeCall[] = [];
  vi.spyOn(globalThis, "fetch").mockImplementation(async (input: RequestInfo | URL, init?: RequestInit) => {
    const request = new Request(input, init);
    if (!request.url.startsWith(`${CLAUDE_BASE}/`)) {
      throw new Error(`Unexpected outbound fetch in test: ${request.url}`);
    }
    const call: ClaudeCall = {
      url: request.url,
      headers: request.headers,
      body: (await request.json()) as Record<string, any>,
      signal: init?.signal ?? null,
    };
    calls.push(call);
    const reply = replies.shift();
    if (!reply) throw new Error("Unexpected extra Claude API call");
    return typeof reply === "function" ? reply(call) : reply;
  });
  return { calls };
}

export interface ParsedEvent {
  event: string;
  data: any;
}

/** Parses a text/event-stream body into events (ignoring `:` comment lines). */
export function parseSse(text: string): ParsedEvent[] {
  const events: ParsedEvent[] = [];
  for (const block of text.split("\n\n")) {
    if (!block.trim()) continue;
    let event = "";
    const data: string[] = [];
    for (const line of block.split("\n")) {
      if (line.startsWith(":")) continue;
      if (line.startsWith("event: ")) event = line.slice(7);
      else if (line.startsWith("data: ")) data.push(line.slice(6));
    }
    if (!event && data.length === 0) continue;
    expect(event, `SSE block without event line: ${block}`).not.toBe("");
    expect(data.length, `SSE event ${event} must have exactly one data line`).toBe(1);
    events.push({ event, data: JSON.parse(data[0]!) });
  }
  return events;
}

export async function chat(token: string, body: Record<string, unknown>) {
  const res = await call("POST", "/v1/chat", { token, body });
  return res;
}

export async function chatEvents(token: string, body: Record<string, unknown>) {
  const res = await chat(token, body);
  expect(res.status).toBe(200);
  expect(res.headers.get("content-type")).toBe("text/event-stream");
  expect(res.headers.get("cache-control")).toBe("no-cache");
  return parseSse(await res.text());
}

export const ask = (text: string, extra: Record<string, unknown> = {}) => ({
  messages: [{ role: "user", content: text }],
  ...extra,
});

export async function usageCount(userName: string): Promise<number> {
  const row = await env.DB.prepare(
    "SELECT COALESCE(SUM(g.count), 0) AS n FROM usage g JOIN users u ON u.id = g.user_id WHERE u.name = ?1",
  )
    .bind(userName)
    .first<{ n: number }>();
  return row?.n ?? 0;
}
