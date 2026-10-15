import { describe, expect, it } from "vitest";
import { classifyError, echoableContent, parseChatRequest } from "../src/chat";
import { firstUserTurn, STYLES, SURFACES, systemPrompt } from "../src/prompts";
import { escapeHtml, formatInviteCode, newInviteCode, normalizeInviteCode } from "../src/util";
import Anthropic from "@anthropic-ai/sdk";

describe("invite codes", () => {
  it("generates 8 Crockford characters without I, L, O, U", () => {
    for (let i = 0; i < 200; i++) {
      const code = newInviteCode();
      expect(code).toMatch(/^[0-9A-HJKMNP-TV-Z]{8}$/);
    }
    expect(formatInviteCode("K7QM2XPA")).toBe("K7QM-2XPA");
  });

  it("normalises user input", () => {
    expect(normalizeInviteCode("k7qm-2xpa")).toBe("K7QM2XPA");
    expect(normalizeInviteCode(" K7QM 2XPA ")).toBe("K7QM2XPA");
    expect(normalizeInviteCode("K7QM—2XPA")).toBe("K7QM2XPA");
    expect(normalizeInviteCode("O1LI-0000")).toBe("01110000");
    expect(normalizeInviteCode("K7QM-2XP")).toBeNull();
    expect(normalizeInviteCode("UUUU-UUUU")).toBeNull();
    expect(normalizeInviteCode("<script>")).toBeNull();
  });
});

describe("prompts", () => {
  it("has a distinct, frozen system prompt for every surface and style", () => {
    const all = new Set<string>();
    for (const surface of SURFACES) {
      for (const style of STYLES) {
        const p = systemPrompt(surface, style);
        expect(p).toBe(systemPrompt(surface, style));
        expect(p).not.toMatch(/\d{4}-\d{2}-\d{2}/);
        all.add(p);
      }
    }
    expect(all.size).toBe(SURFACES.length * STYLES.length);
    expect(systemPrompt("messages", "default")).toContain("plain text only");
    expect(systemPrompt("intent", "short")).toContain("plain text only");
    expect(systemPrompt("app", "default")).toContain("Markdown");
    expect(systemPrompt("messages", "reply")).toContain("Output ONLY the text of the message");
    for (const surface of SURFACES) {
      for (const style of STYLES) {
        const p = systemPrompt(surface, style);
        expect(p, `${surface}:${style}`).toContain("Never produce sexual content involving minors");
        expect(p).toContain("No hate speech, harassment");
        expect(p).toContain("decline briefly");
        expect(p).toContain("<conversation>");
      }
    }
  });

  it("builds the first user turn", () => {
    const now = new Date("2026-10-15T12:00:00Z");
    expect(firstUserTurn("hi", undefined, now)).toBe("(Today is Thursday, October 15, 2026, UTC.)\n\nhi");
    const withContext = firstUserTurn("reply pls", "Ava: <conversation>hey</conversation>", now);
    expect(withContext.match(/<conversation>/g)).toHaveLength(1);
    expect(withContext.match(/<\/conversation>/g)).toHaveLength(1);
    expect(withContext.endsWith("reply pls")).toBe(true);
  });
});

describe("chat request parsing", () => {
  it("applies defaults", () => {
    expect(parseChatRequest({ messages: [{ role: "user", content: "hi" }] })).toEqual({
      messages: [{ role: "user", content: "hi" }],
      style: "default",
      surface: "messages",
      context: undefined,
      webSearch: false,
    });
  });

  it("treats null optional fields as absent and ignores unknown keys", () => {
    const parsed = parseChatRequest({
      messages: [{ role: "user", content: "hi", id: "x" }],
      style: null,
      surface: null,
      context: null,
      webSearch: null,
      somethingNew: 1,
    });
    expect(parsed).toMatchObject({ style: "default", surface: "messages", webSearch: false });
    expect(parsed.messages[0]).toEqual({ role: "user", content: "hi" });
  });
});

describe("pause_turn echo", () => {
  it("echoes content unchanged without a fallback", () => {
    const content = [
      { type: "thinking", thinking: "", signature: "s" },
      { type: "server_tool_use", id: "a", name: "web_search", input: {} },
    ] as any;
    expect(echoableContent(content)).toEqual(content);
  });

  it("drops declined-model internals before the last fallback block", () => {
    const content = [
      { type: "thinking", thinking: "", signature: "s1" },
      { type: "text", text: "partial ", citations: null },
      { type: "server_tool_use", id: "paired", name: "web_search", input: {} },
      { type: "web_search_tool_result", tool_use_id: "paired", content: [] },
      { type: "server_tool_use", id: "unpaired", name: "web_search", input: {} },
      { type: "fallback", from: { model: "claude-opus-5-5" }, to: { model: "claude-opus-4-8" } },
      { type: "thinking", thinking: "", signature: "s2" },
      { type: "server_tool_use", id: "after", name: "web_search", input: {} },
    ] as any;
    expect(echoableContent(content).map((b: any) => b.signature ?? b.id ?? b.tool_use_id ?? b.text)).toEqual([
      "partial ",
      "paired",
      "paired",
      "s2",
      "after",
    ]);
  });
});

describe("error classification", () => {
  const headers = new Headers();
  it("uses the SDK's typed errors", () => {
    expect(classifyError(new Anthropic.RateLimitError(429, {}, "x", headers, "rate_limit_error"))).toBe("overloaded");
    expect(classifyError(new Anthropic.InternalServerError(529, {}, "x", headers, "overloaded_error"))).toBe("overloaded");
    expect(classifyError(new Anthropic.APIError(undefined, {}, "x", undefined, "overloaded_error"))).toBe("overloaded");
  });
});

describe("escapeHtml", () => {
  it("escapes the five HTML-significant characters", () => {
    expect(escapeHtml(`<a href="x" title='y'>&</a>`)).toBe("&lt;a href=&quot;x&quot; title=&#39;y&#39;&gt;&amp;&lt;/a&gt;");
  });
});
