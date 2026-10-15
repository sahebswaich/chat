import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import { BASE, call, errorOf, signUp } from "./helpers";

describe("public pages", () => {
  it("GET /health", async () => {
    const res = await call("GET", "/health");
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ ok: true });
  });

  it("GET /join/:code shows the code, the deep link and no TestFlight button when unset", async () => {
    const res = await call("GET", "/join/k7qm2xpa");
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("text/html; charset=utf-8");
    const html = await res.text();
    expect(html).toContain("K7QM-2XPA");
    expect(html).toContain('href="nimbus://join?code=K7QM-2XPA&amp;host=nimbus.example.com"');
    expect(html).toContain("Open Nimbus");
    expect(html).not.toContain("Install from TestFlight");
    expect(html).toContain("prefers-color-scheme:dark");
    expect(html).toContain("#5856F6");
  });

  it("GET /join/:code escapes HTML in the code", async () => {
    const evil = encodeURIComponent(`<script>alert("x")</script>`);
    const res = await call("GET", `/join/${evil}`);
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).not.toContain("<script>");
    expect(html).not.toContain('alert("x")');
    expect(html).toContain("&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;");

    const attr = await (await call("GET", `/join/${encodeURIComponent(`"><img src=x onerror=alert(1)>`)}`)).text();
    expect(attr).not.toContain("<img");
    expect(attr).not.toMatch(/"\s*onerror=/);
  });

  it("GET /privacy explains what is sent and stored", async () => {
    const res = await call("GET", "/privacy");
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).toContain("Anthropic");
    expect(html).toContain("not used to train");
    expect(html).toContain("Usage counters");
    expect(html).toContain("Reports");
  });
});

describe("cards", () => {
  it("creates a card and serves it as HTML and JSON", async () => {
    const token = await signUp("James");
    const res = await call("POST", "/v1/cards", {
      token,
      body: { question: "what is <b>nephilim</b>", answer: "Figures in **Genesis 6**.\n- giants" },
    });
    expect(res.status).toBe(200);
    const { id, url } = (await res.json()) as { id: string; url: string };
    expect(id).toMatch(/^[A-Za-z0-9_-]{16}$/);
    expect(url).toBe(`${BASE}/c/${id}`);

    const page = await call("GET", `/c/${id}?q=ignored&a=ignored&v=1`);
    expect(page.status).toBe(200);
    const html = await page.text();
    expect(html).toContain("what is &lt;b&gt;nephilim&lt;/b&gt;");
    expect(html).toContain("<strong>Genesis 6</strong>");
    expect(html).toContain("• giants");
    expect(html).toContain("Answered by Nimbus");

    const data = await call("GET", `/c/${id}.json`);
    expect(data.status).toBe(200);
    const card = (await data.json()) as Record<string, string>;
    expect(card).toMatchObject({ id, question: "what is <b>nephilim</b>", answer: "Figures in **Genesis 6**.\n- giants" });
    expect(card["createdAt"]).toBeTruthy();

    const row = await env.DB.prepare("SELECT user_id FROM cards WHERE id = ?1").bind(id).first<{ user_id: string }>();
    expect(row?.user_id).toMatch(/^u_/);
  });

  it("404s unknown cards", async () => {
    const page = await call("GET", "/c/AAAAAAAAAAAAAAAA");
    expect(page.status).toBe(404);
    expect(await page.text()).toContain("Card not found");
    const data = await call("GET", "/c/AAAAAAAAAAAAAAAA.json");
    expect(data.status).toBe(404);
    expect((await errorOf(data)).code).toBe("not_found");
  });

  it("validates card input", async () => {
    const token = await signUp("James");
    for (const body of [{ question: "q" }, { question: "x".repeat(2001), answer: "a" }, { answer: "x".repeat(20_001) }]) {
      const res = await call("POST", "/v1/cards", { token, body });
      expect(res.status).toBe(400);
    }
  });
});
