// JSON responses, the contract's error shape, and request-body parsing.

/** Thrown by handlers; turned into `{"error": {"code", "message"}}` by the router. */
export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly extra?: Record<string, unknown>,
    readonly headers?: Record<string, string>,
  ) {
    super(message);
  }
}

const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
} as const;

export function json(data: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(data), { status, headers: { ...JSON_HEADERS, ...headers } });
}

export function errorResponse(err: HttpError): Response {
  return json(
    { error: { code: err.code, message: err.message, ...(err.extra ?? {}) } },
    err.status,
    err.headers,
  );
}

export function noContent(): Response {
  return new Response(null, { status: 204 });
}

export const invalidRequest = (message: string) => new HttpError(400, "invalid_request", message);

/** Upper bound for any request body (40 messages × 20k chars + context fits easily). */
const MAX_BODY_BYTES = 2_000_000;

/** Reads and parses a JSON object body, or throws 400 invalid_request. */
export async function readJsonObject(request: Request): Promise<Record<string, unknown>> {
  const declared = Number(request.headers.get("content-length") ?? "0");
  if (declared > MAX_BODY_BYTES) throw invalidRequest("Request body is too large.");
  let text: string;
  try {
    text = await request.text();
  } catch {
    throw invalidRequest("Could not read the request body.");
  }
  if (text.length > MAX_BODY_BYTES) throw invalidRequest("Request body is too large.");
  let value: unknown;
  try {
    value = JSON.parse(text);
  } catch {
    throw invalidRequest("Request body must be valid JSON.");
  }
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw invalidRequest("Request body must be a JSON object.");
  }
  return value as Record<string, unknown>;
}

/** Optional string field: undefined/null → undefined; otherwise must be a string ≤ max chars. */
export function optionalString(
  body: Record<string, unknown>,
  key: string,
  max: number,
): string | undefined {
  const value = body[key];
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string") throw invalidRequest(`"${key}" must be a string.`);
  if (value.length > max) throw invalidRequest(`"${key}" must be at most ${max} characters.`);
  return value;
}

/** Required non-blank string field ≤ max chars (returned untrimmed unless `trim`). */
export function requiredString(
  body: Record<string, unknown>,
  key: string,
  max: number,
  trim = false,
): string {
  const value = optionalString(body, key, max);
  if (value === undefined || value.trim() === "") throw invalidRequest(`"${key}" is required.`);
  return trim ? value.trim() : value;
}

/** Optional integer field within [min, max]; undefined/null → undefined. */
export function optionalInt(
  body: Record<string, unknown>,
  key: string,
  min: number,
  max: number,
): number | undefined {
  const value = body[key];
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) {
    throw invalidRequest(`"${key}" must be a whole number from ${min} to ${max}.`);
  }
  return value;
}

/**
 * "https://<host>" for links handed out (invite and card URLs). Plain http is
 * kept only for local development hosts (wrangler dev).
 */
export function publicOrigin(request: Request): string {
  const url = new URL(request.url);
  const local = ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname) || url.hostname.endsWith(".localhost");
  return `${local ? url.protocol : "https:"}//${url.host}`;
}
