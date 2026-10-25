import { exports } from "cloudflare:workers";
import { describe, expect, it } from "vitest";

const BASE = "https://room.example.com";

function call(method: string, path: string, opts: { body?: unknown; cookie?: string; headers?: Record<string, string>; base?: string } = {}) {
  const headers: Record<string, string> = { ...opts.headers };
  if (opts.body !== undefined) headers["content-type"] = "application/json";
  if (opts.cookie) headers["cookie"] = opts.cookie;
  return exports.default.fetch(
    new Request((opts.base ?? BASE) + path, { method, headers, body: opts.body === undefined ? undefined : JSON.stringify(opts.body), redirect: "manual" }),
  );
}

const cookieFrom = (res: Response) => (res.headers.get("set-cookie") ?? "").split(";")[0]!;

async function owner(): Promise<string> {
  const res = await call("POST", "/login", { body: { password: "test-password" }, headers: { "cf-connecting-ip": "10.0.0.2" } });
  expect(res.status).toBe(200);
  return cookieFrom(res);
}

async function shareLink(cookie: string, scope: string, role: "view" | "comment", extra: Record<string, unknown> = {}) {
  const res = await call("POST", "/api/shares", { cookie, body: { label: "Friend", scope, role, ...extra } });
  expect(res.status).toBe(200);
  const data = (await res.json()) as { url: string; id: string };
  const open = await call("GET", new URL(data.url).pathname);
  expect(open.status).toBe(302);
  expect(open.headers.get("location")).toBe(scope);
  return { id: data.id, guest: cookieFrom(open) };
}

describe("gate", () => {
  it("asks strangers for the password and keeps the API closed", async () => {
    const page = await call("GET", "/", { headers: { accept: "text/html" } });
    expect(await page.text()).toContain('type="password"');
    expect((await call("GET", "/api/publications")).status).toBe(401);
    expect((await call("POST", "/login", { body: { password: "wrong" } })).status).toBe(401);
  });

  it("lets the owner in", async () => {
    const cookie = await owner();
    const res = await call("GET", "/api/session", { cookie });
    expect(await res.json()).toEqual({ signedIn: true, role: "owner", scope: "/" });
  });

  it("keeps a share-link guest inside the link's scope", async () => {
    const { guest } = await shareLink(await owner(), "/treatise", "comment");
    expect((await call("GET", "/api/comments?page=/treatise", { cookie: guest })).status).toBe(200);
    expect((await call("GET", "/api/comments?page=/other", { cookie: guest })).status).toBe(403);
    expect((await call("GET", "/api/publications", { cookie: guest })).status).toBe(403);
    // The home page sends a guest to the page their link opens.
    const home = await call("GET", "/", { cookie: guest, headers: { accept: "text/html" } });
    expect(home.status).toBe(302);
    expect(new URL(home.headers.get("location")!).pathname).toBe("/treatise");
  });

  it("turns a link off when revoked or expired", async () => {
    const cookie = await owner();
    const { id, guest } = await shareLink(cookie, "/treatise", "view");
    expect((await call("DELETE", `/api/shares/${id}`, { cookie })).status).toBe(200);
    expect((await call("GET", "/api/comments?page=/treatise", { cookie: guest })).status).toBe(401);
    const list = (await (await call("GET", "/api/shares", { cookie })).json()) as { shares: { revokedAt: string | null }[] };
    expect(list.shares[0]!.revokedAt).not.toBeNull();
  });

  it("rejects malformed scopes", async () => {
    const res = await call("POST", "/api/shares", { cookie: await owner(), body: { label: "x", scope: "https://evil.example", role: "view" } });
    expect(res.status).toBe(400);
  });
});

describe("discussion", () => {
  it("lets comment links post and view links only read", async () => {
    const cookie = await owner();
    const commenter = (await shareLink(cookie, "/treatise", "comment")).guest;
    const viewer = (await shareLink(cookie, "/treatise", "view")).guest;
    const posted = await call("POST", "/api/comments", { cookie: commenter, body: { page: "/treatise", anchor: "glx", author: "Ana", body: "What is the royalty?" } });
    expect(posted.status).toBe(200);
    const { id } = (await posted.json()) as { id: string };
    const reply = await call("POST", "/api/comments", { cookie, body: { page: "/treatise", anchor: "glx", parentId: id, body: "60% of fees." } });
    expect(reply.status).toBe(200);
    expect((await call("POST", "/api/comments", { cookie: viewer, body: { page: "/treatise", author: "V", body: "hi" } })).status).toBe(403);
    const list = (await (await call("GET", "/api/comments?page=/treatise", { cookie: viewer })).json()) as {
      comments: { author: string; parentId: string | null }[];
      canComment: boolean;
    };
    expect(list.canComment).toBe(false);
    expect(list.comments.map((c) => c.author)).toEqual(["Ana", "Owner"]);
    expect(list.comments[1]!.parentId).toBe(id);
    expect((await call("POST", `/api/comments/${id}/resolve`, { cookie: commenter })).status).toBe(403);
    expect((await call("POST", `/api/comments/${id}/resolve`, { cookie })).status).toBe(200);
  });

  it("requires guests to give a name", async () => {
    const { guest } = await shareLink(await owner(), "/treatise", "comment");
    expect((await call("POST", "/api/comments", { cookie: guest, body: { page: "/treatise", body: "anon" } })).status).toBe(400);
  });
});

describe("publishing", () => {
  it("publishes markdown into the paper template, private by default", async () => {
    const cookie = await owner();
    const put = await call("PUT", "/api/publications/glx-memo", { cookie, body: { title: "GLX memo", body: "# Hello\n\n<script>x</script>" } });
    expect(put.status).toBe(200);
    expect(await put.json()).toMatchObject({ slug: "glx-memo", visibility: "private", path: "/p/glx-memo" });
    const page = await call("GET", "/p/glx-memo", { cookie });
    const html = await page.text();
    expect(html).toContain("/assets/paper.css");
    expect(html).toContain("\\u003cscript>x\\u003c/script>"); // embedded safely as JSON
    const stranger = await call("GET", "/p/glx-memo", { headers: { accept: "text/html" } });
    expect(await stranger.text()).toContain('type="password"');
  });

  it("serves public pages to anyone and HTML pages sandboxed", async () => {
    const cookie = await owner();
    await call("PUT", "/api/publications/deck", { cookie, body: { title: "Deck", kind: "html", body: "<h1>Deck</h1>", visibility: "public" } });
    const res = await call("GET", "/p/deck");
    expect(res.status).toBe(200);
    expect(res.headers.get("content-security-policy")).toContain("sandbox");
    expect(res.headers.get("content-security-policy")).not.toContain("allow-same-origin");
    expect(await res.text()).toBe("<h1>Deck</h1>");
  });

  it("serves a publication on its own subdomain and custom host", async () => {
    const cookie = await owner();
    await call("PUT", "/api/publications/vision", { cookie, body: { title: "Vision", body: "x", visibility: "public", customHost: "vision.example.org" } });
    const sub = await call("GET", "/", { base: "https://vision.pub.example.com" });
    expect(await sub.text()).toContain("<title>Vision</title>");
    const custom = await call("GET", "/", { base: "https://vision.example.org" });
    expect(await custom.text()).toContain("<title>Vision</title>");
    const taken = await call("PUT", "/api/publications/other", { cookie, body: { title: "Other", body: "y", customHost: "vision.example.org" } });
    expect(taken.status).toBe(409);
  });

  it("lets a share link open one private publication", async () => {
    const cookie = await owner();
    await call("PUT", "/api/publications/memo", { cookie, body: { title: "Memo", body: "secret" } });
    await call("PUT", "/api/publications/other", { cookie, body: { title: "Other", body: "secret 2" } });
    const { guest } = await shareLink(cookie, "/p/memo", "view");
    expect((await call("GET", "/p/memo", { cookie: guest })).status).toBe(200);
    expect((await call("GET", "/p/other", { cookie: guest })).status).toBe(403);
  });

  it("validates slugs and deletes", async () => {
    const cookie = await owner();
    expect((await call("PUT", "/api/publications/Bad_Slug", { cookie, body: { title: "x", body: "y" } })).status).toBe(400);
    await call("PUT", "/api/publications/temp", { cookie, body: { title: "t", body: "y" } });
    expect((await call("DELETE", "/api/publications/temp", { cookie })).status).toBe(200);
    expect((await call("GET", "/p/temp", { cookie })).status).toBe(404);
  });
});
