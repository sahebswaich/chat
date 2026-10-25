// Small, dependency-free helpers: ids, tokens, hashing, HMAC signing, time, HTML escaping.

export function base64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function base64urlDecode(text: string): Uint8Array {
  const b64 = text.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((text.length + 3) % 4);
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

/** Opaque token: 32 random bytes, base64url (43 chars). Only its hash is stored. */
export function newToken(): string {
  return base64url(crypto.getRandomValues(new Uint8Array(32)));
}

/** Short random id with a prefix, e.g. "c_Q2x9…" (96 bits). */
export function newId(prefix: string): string {
  return `${prefix}_${base64url(crypto.getRandomValues(new Uint8Array(12)))}`;
}

export async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** Constant-time string comparison (hashes both sides first so lengths always match). */
export async function timingSafeEqualStrings(a: string, b: string): Promise<boolean> {
  const enc = new TextEncoder();
  const [ha, hb] = await Promise.all([
    crypto.subtle.digest("SHA-256", enc.encode(a)),
    crypto.subtle.digest("SHA-256", enc.encode(b)),
  ]);
  return crypto.subtle.timingSafeEqual(ha, hb);
}

async function hmacKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, [
    "sign",
    "verify",
  ]);
}

/** "<base64url(payload)>.<base64url(hmac)>" */
export async function signPayload(payload: unknown, secret: string): Promise<string> {
  const body = base64url(new TextEncoder().encode(JSON.stringify(payload)));
  const sig = await crypto.subtle.sign("HMAC", await hmacKey(secret), new TextEncoder().encode(body));
  return `${body}.${base64url(new Uint8Array(sig))}`;
}

/** Returns the payload of a value made by signPayload, or null if it was tampered with. */
export async function verifyPayload<T>(value: string, secret: string): Promise<T | null> {
  const dot = value.indexOf(".");
  if (dot <= 0 || dot === value.length - 1) return null;
  const body = value.slice(0, dot);
  let sig: Uint8Array;
  try {
    sig = base64urlDecode(value.slice(dot + 1));
  } catch {
    return null;
  }
  const ok = await crypto.subtle.verify("HMAC", await hmacKey(secret), sig, new TextEncoder().encode(body));
  if (!ok) return null;
  try {
    return JSON.parse(new TextDecoder().decode(base64urlDecode(body))) as T;
  } catch {
    return null;
  }
}

export function nowIso(now: Date = new Date()): string {
  return now.toISOString();
}

/** Escape text for HTML element content and quoted attribute values. */
export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** Reads a cookie value from the Cookie header. */
export function readCookie(request: Request, name: string): string | null {
  const header = request.headers.get("cookie") ?? "";
  for (const part of header.split(";")) {
    const eq = part.indexOf("=");
    if (eq < 0) continue;
    if (part.slice(0, eq).trim() === name) return decodeURIComponent(part.slice(eq + 1).trim());
  }
  return null;
}
