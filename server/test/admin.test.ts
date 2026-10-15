import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import { ADMIN_TOKEN, admin, BASE, call, createInvite, errorOf, signUp } from "./helpers";

describe("admin auth", () => {
  const routes = [
    ["POST", "/admin/invites"],
    ["GET", "/admin/invites"],
    ["DELETE", "/admin/invites/ABCD-EFGH"],
    ["GET", "/admin/users"],
    ["POST", "/admin/users/u_x/revoke"],
    ["GET", "/admin/reports"],
  ] as const;

  it("rejects a missing or wrong admin token with 401", async () => {
    for (const [method, path] of routes) {
      for (const token of [undefined, "wrong", `${ADMIN_TOKEN}x`, ADMIN_TOKEN.slice(0, -1)]) {
        const res = await call(method, path, { token, body: method === "POST" ? { name: "X" } : undefined });
        expect(res.status, `${method} ${path} token=${token}`).toBe(401);
        expect((await errorOf(res)).code).toBe("unauthorized");
      }
    }
  });

  it("does not accept a user token", async () => {
    const token = await signUp();
    expect((await call("GET", "/admin/users", { token })).status).toBe(401);
  });
});

describe("invites", () => {
  it("creates, lists and deletes invites", async () => {
    const created = await createInvite("James", { uses: 3, dailyLimit: 25 });
    expect(created.code).toMatch(/^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);
    expect(created.url).toBe(`${BASE}/join/${created.code}`);
    await createInvite("Ava");

    const list = (await (await admin("GET", "/admin/invites")).json()) as { invites: any[] };
    expect(list.invites).toHaveLength(2);
    const james = list.invites.find((i) => i.name === "James");
    expect(james).toMatchObject({ code: created.code, name: "James", usesLeft: 3, dailyLimit: 25 });
    expect(new Date(james.createdAt).toString()).not.toBe("Invalid Date");
    expect(list.invites.find((i) => i.name === "Ava")).toMatchObject({ usesLeft: 1, dailyLimit: 200 });

    // Delete accepts the code with or without the dash, any case.
    const del = await admin("DELETE", `/admin/invites/${created.code.replace("-", "").toLowerCase()}`);
    expect(del.status).toBe(204);
    const after = (await (await admin("GET", "/admin/invites")).json()) as { invites: any[] };
    expect(after.invites.map((i) => i.name)).toEqual(["Ava"]);

    // A deleted invite can no longer be redeemed.
    const redeem = await call("POST", "/v1/redeem", { body: { code: created.code } });
    expect(redeem.status).toBe(404);

    expect((await admin("DELETE", `/admin/invites/${created.code}`)).status).toBe(404);
  });

  it("validates invite input", async () => {
    for (const body of [{}, { name: "" }, { name: "X", uses: 0 }, { name: "X", uses: 1.5 }, { name: "X", dailyLimit: -1 }]) {
      const res = await admin("POST", "/admin/invites", body);
      expect(res.status, JSON.stringify(body)).toBe(400);
      expect((await errorOf(res)).code).toBe("invalid_request");
    }
  });
});

describe("users", () => {
  it("lists users with today's usage and revokes them", async () => {
    await signUp("Saheb");
    const id = (await env.DB.prepare("SELECT id FROM users").first<{ id: string }>())!.id;
    const today = new Date().toISOString().slice(0, 10);
    await env.DB.prepare("INSERT INTO usage (user_id, day, count) VALUES (?1, ?2, 7)").bind(id, today).run();
    await env.DB.prepare("INSERT INTO usage (user_id, day, count) VALUES (?1, '2020-01-01', 99)").bind(id).run();

    const list = (await (await admin("GET", "/admin/users")).json()) as { users: any[] };
    expect(list.users).toHaveLength(1);
    expect(list.users[0]).toMatchObject({ id, name: "Saheb", device: "Test iPhone", usedToday: 7, revoked: false });
    expect(list.users[0].createdAt).toBeTruthy();
    expect(list.users[0]).toHaveProperty("lastSeenAt");

    expect((await admin("POST", `/admin/users/${id}/revoke`)).status).toBe(204);
    const after = (await (await admin("GET", "/admin/users")).json()) as { users: any[] };
    expect(after.users[0].revoked).toBe(true);

    expect((await admin("POST", "/admin/users/u_nope/revoke")).status).toBe(404);
  });
});

describe("routing", () => {
  it("returns JSON 404 / 405 errors", async () => {
    const notFound = await call("GET", "/nope");
    expect(notFound.status).toBe(404);
    expect((await errorOf(notFound)).code).toBe("not_found");
    const wrongMethod = await call("GET", "/v1/chat");
    expect(wrongMethod.status).toBe(405);
  });
});
