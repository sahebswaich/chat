import { createExecutionContext, waitOnExecutionContext } from "cloudflare:test";
import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import worker from "../src/index";
import { admin, BASE, call, createInvite, errorOf, signUp } from "./helpers";

describe("POST /v1/redeem", () => {
  it("redeems a code and returns a token, name and daily limit", async () => {
    const { code } = await createInvite("James", { dailyLimit: 50 });
    expect(code).toMatch(/^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);

    const res = await call("POST", "/v1/redeem", { body: { code, device: "James's iPhone" } });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { token: string; name: string; dailyLimit: number };
    expect(body.name).toBe("James");
    expect(body.dailyLimit).toBe(50);
    expect(body.token).toMatch(/^[A-Za-z0-9_-]{43}$/);

    // The raw token is never stored, only its SHA-256 hash.
    const row = await env.DB.prepare("SELECT token_hash, device, name FROM users").first<{
      token_hash: string;
      device: string;
      name: string;
    }>();
    expect(row?.token_hash).toMatch(/^[0-9a-f]{64}$/);
    expect(row?.token_hash).not.toContain(body.token);
    expect(row?.device).toBe("James's iPhone");
    const dump = JSON.stringify((await env.DB.prepare("SELECT * FROM users").all()).results);
    expect(dump).not.toContain(body.token);

    // The token works.
    const me = await call("GET", "/v1/me", { token: body.token });
    expect(me.status).toBe(200);
    expect(await me.json()).toEqual({ name: "James", usedToday: 0, dailyLimit: 50, supportEmail: "" });
  });

  it("uses DAILY_LIMIT when the invite has no limit of its own", async () => {
    const { code } = await createInvite("Ava");
    const res = await call("POST", "/v1/redeem", { body: { code } });
    expect(((await res.json()) as { dailyLimit: number }).dailyLimit).toBe(200);
  });

  it("accepts the code in any case, with or without the dash, with spaces", async () => {
    const { code } = await createInvite("Mia", { uses: 3 });
    const bare = code.replace("-", "");
    for (const variant of [bare.toLowerCase(), ` ${code.slice(0, 4)} ${code.slice(5)} `, `${code.slice(0, 4)}–${code.slice(5)}`]) {
      const res = await call("POST", "/v1/redeem", { body: { code: variant, device: "iPad" } });
      expect(res.status, variant).toBe(200);
    }
  });

  it("returns 410 code_used_up once all uses are taken, and decrements uses", async () => {
    const { code } = await createInvite("Leo", { uses: 2 });
    expect((await call("POST", "/v1/redeem", { body: { code } })).status).toBe(200);

    const list = (await (await admin("GET", "/admin/invites")).json()) as { invites: { usesLeft: number }[] };
    expect(list.invites[0]!.usesLeft).toBe(1);

    expect((await call("POST", "/v1/redeem", { body: { code } })).status).toBe(200);
    const res = await call("POST", "/v1/redeem", { body: { code } });
    expect(res.status).toBe(410);
    expect((await errorOf(res)).code).toBe("code_used_up");
  });

  it("never over-redeems under concurrent requests", async () => {
    const { code } = await createInvite("Zoe", { uses: 2 });
    const results = await Promise.all(
      Array.from({ length: 6 }, () => call("POST", "/v1/redeem", { body: { code } })),
    );
    const statuses = results.map((r) => r.status).sort();
    expect(statuses).toEqual([200, 200, 410, 410, 410, 410]);
  });

  it("returns 404 invalid_code for unknown or malformed codes", async () => {
    for (const code of ["ZZZZ-ZZZZ", "not a code", "K7QM-2XP", "UUUU-UUUU"]) {
      const res = await call("POST", "/v1/redeem", { body: { code } });
      expect(res.status, code).toBe(404);
      expect((await errorOf(res)).code).toBe("invalid_code");
    }
  });

  it("returns 400 invalid_request for a bad body", async () => {
    for (const body of ["not json", "[]", {}, { code: 42 }, { code: "" }, { code: "ABCD-EFGH", device: 7 }]) {
      const res = await call("POST", "/v1/redeem", { body });
      expect(res.status, JSON.stringify(body)).toBe(400);
      const err = await errorOf(res);
      expect(err.code).toBe("invalid_request");
      expect(err.message).toBeTruthy();
    }
  });
});

describe("authentication", () => {
  it("requires a bearer token on /v1 routes", async () => {
    for (const [method, path] of [
      ["GET", "/v1/me"],
      ["DELETE", "/v1/me"],
      ["POST", "/v1/chat"],
      ["POST", "/v1/report"],
      ["POST", "/v1/cards"],
    ] as const) {
      const res = await call(method, path, { body: method === "POST" ? {} : undefined });
      expect(res.status, path).toBe(401);
      expect(await errorOf(res)).toMatchObject({ code: "unauthorized" });
    }
  });

  it("rejects an unknown token", async () => {
    const res = await call("GET", "/v1/me", { token: "definitely-not-a-real-token" });
    expect(res.status).toBe(401);
    expect((await errorOf(res)).code).toBe("unauthorized");
  });

  it("rejects a revoked user and records last_seen_at for active ones", async () => {
    const token = await signUp("Noah");
    expect((await call("GET", "/v1/me", { token })).status).toBe(200);
    const user = await env.DB.prepare("SELECT id, last_seen_at FROM users").first<{ id: string; last_seen_at: string | null }>();
    expect(user?.last_seen_at).toBeTruthy();

    expect((await admin("POST", `/admin/users/${user!.id}/revoke`)).status).toBe(204);
    const res = await call("GET", "/v1/me", { token });
    expect(res.status).toBe(401);
  });
});

describe("POST /v1/report", () => {
  it("stores the report and returns 204", async () => {
    const token = await signUp("Ivy");
    const res = await call("POST", "/v1/report", {
      token,
      body: { messages: [{ role: "user", content: "say something rude" }], answer: "nope", reason: "offensive" },
    });
    expect(res.status).toBe(204);
    const list = (await (await admin("GET", "/admin/reports")).json()) as { reports: any[] };
    expect(list.reports).toHaveLength(1);
    expect(list.reports[0]).toMatchObject({
      userName: "Ivy",
      messages: [{ role: "user", content: "say something rude" }],
      answer: "nope",
      reason: "offensive",
    });
  });

  it("validates the body", async () => {
    const token = await signUp("Ivy");
    const res = await call("POST", "/v1/report", { token, body: { messages: [{ role: "system", content: 1 }] } });
    expect(res.status).toBe(400);
    expect((await errorOf(res)).code).toBe("invalid_request");
  });
});

describe("GET /v1/me", () => {
  it("returns SUPPORT_EMAIL as supportEmail when it is set", async () => {
    const token = await signUp("Ava");
    const ctx = createExecutionContext();
    const res = await worker.fetch(
      new Request(`${BASE}/v1/me`, { headers: { authorization: `Bearer ${token}` } }),
      { ...env, SUPPORT_EMAIL: " owner@example.com " },
      ctx,
    );
    await waitOnExecutionContext(ctx);
    expect(await res.json()).toEqual({ name: "Ava", usedToday: 0, dailyLimit: 200, supportEmail: "owner@example.com" });
  });
});

describe("DELETE /v1/me", () => {
  it("deletes the account, usage and cards, keeps reports unlinked, and kills the token", async () => {
    const token = await signUp("Mia");
    const other = await signUp("Leo");
    const id = (await env.DB.prepare("SELECT id FROM users WHERE name = 'Mia'").first<{ id: string }>())!.id;
    const today = new Date().toISOString().slice(0, 10);
    await env.DB.prepare("INSERT INTO usage (user_id, day, count) VALUES (?1, ?2, 4)").bind(id, today).run();
    expect((await call("POST", "/v1/cards", { token, body: { question: "q", answer: "a" } })).status).toBe(200);
    expect((await call("POST", "/v1/cards", { token: other, body: { question: "q2", answer: "a2" } })).status).toBe(200);
    const report = { messages: [{ role: "user", content: "hm" }], answer: "bad", reason: "offensive" };
    expect((await call("POST", "/v1/report", { token, body: report })).status).toBe(204);

    const res = await call("DELETE", "/v1/me", { token });
    expect(res.status).toBe(204);
    expect(await res.text()).toBe("");

    const count = async (sql: string) => (await env.DB.prepare(sql).bind(id).first<{ n: number }>())!.n;
    expect(await count("SELECT COUNT(*) AS n FROM users WHERE id = ?1")).toBe(0);
    expect(await count("SELECT COUNT(*) AS n FROM usage WHERE user_id = ?1")).toBe(0);
    expect(await count("SELECT COUNT(*) AS n FROM cards WHERE user_id = ?1")).toBe(0);
    expect(await count("SELECT COUNT(*) AS n FROM reports WHERE user_id = ?1")).toBe(0);
    // Other people's data is untouched.
    expect((await env.DB.prepare("SELECT COUNT(*) AS n FROM cards").first<{ n: number }>())!.n).toBe(1);

    // The report is kept for moderation, without the link to the user.
    const reports = (await (await admin("GET", "/admin/reports")).json()) as { reports: any[] };
    expect(reports.reports).toHaveLength(1);
    expect(reports.reports[0]).toMatchObject({ userId: null, userName: null, answer: "bad", reason: "offensive" });

    expect((await call("GET", "/v1/me", { token })).status).toBe(401);
    expect((await call("DELETE", "/v1/me", { token })).status).toBe(401);
    expect((await call("GET", "/v1/me", { token: other })).status).toBe(200);
  });
});
