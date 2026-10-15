// Small, dependency-free helpers: random ids, invite codes, hashing, time.

/** Crockford base32 alphabet: no I, L, O or U, so codes are easy to read aloud and type. */
export const CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
const INVITE_CODE_RE = /^[0-9A-HJKMNP-TV-Z]{8}$/;

/** `length` random Crockford base32 characters (unbiased: 256 is a multiple of 32). */
export function randomCrockford(length: number): string {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  let out = "";
  for (const b of bytes) out += CROCKFORD[b & 31];
  return out;
}

/**
 * Normalises a typed or pasted invite code to its stored form (8 uppercase
 * Crockford characters, no dash). Accepts any case, spaces, hyphens and other
 * dash characters, and maps the look-alikes O → 0 and I/L → 1. Returns null
 * if the result is not a well-formed code.
 */
export function normalizeInviteCode(input: string): string | null {
  const cleaned = input
    .toUpperCase()
    .replace(/[\s\p{Pd}_]/gu, "")
    .replace(/O/g, "0")
    .replace(/[IL]/g, "1");
  return INVITE_CODE_RE.test(cleaned) ? cleaned : null;
}

/** "K7QM2XPA" → "K7QM-2XPA". */
export function formatInviteCode(code: string): string {
  return `${code.slice(0, 4)}-${code.slice(4)}`;
}

export function newInviteCode(): string {
  return randomCrockford(8);
}

export function base64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** Opaque bearer token: 32 random bytes, base64url (43 chars). Only its hash is stored. */
export function newToken(): string {
  return base64url(crypto.getRandomValues(new Uint8Array(32)));
}

/** User id, e.g. "u_7k2m9qxz4t" (50 random bits; plenty for an invite-only app). */
export function newUserId(): string {
  return `u_${randomCrockford(10).toLowerCase()}`;
}

/** Card id: 12 random bytes → 16 base64url chars (96 bits, unguessable). */
export function newCardId(): string {
  return base64url(crypto.getRandomValues(new Uint8Array(12)));
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

export function nowIso(now: Date = new Date()): string {
  return now.toISOString();
}

/** The usage "day" key: the current UTC date as YYYY-MM-DD. */
export function utcDay(now: Date = new Date()): string {
  return now.toISOString().slice(0, 10);
}

export function nextUtcMidnight(now: Date = new Date()): Date {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1));
}

/** "3h 12m" / "45m" / "less than a minute". */
export function humanDuration(ms: number): string {
  const totalMinutes = Math.floor(ms / 60_000);
  if (totalMinutes < 1) return "less than a minute";
  const h = Math.floor(totalMinutes / 60);
  const m = totalMinutes % 60;
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
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
