// Public HTML pages: /join/:code, /privacy, /terms, /support, /c/:id, and small
// fallbacks. Every dynamic value goes through escapeHtml().

import { escapeHtml, formatInviteCode, normalizeInviteCode } from "./util";

const CSS = `
:root{
  --bg:#f5f5fb;--surface:rgba(255,255,255,.82);--border:rgba(20,20,60,.08);
  --text:#14142b;--muted:#5b5b76;--accent:#5856F6;--accent-2:#8B5CF6;--accent-3:#22D3EE;
  --code-bg:rgba(88,86,246,.08);--shadow:0 20px 50px -20px rgba(60,50,180,.35);
  color-scheme:light dark;
}
@media (prefers-color-scheme:dark){:root{
  --bg:#0b0b14;--surface:rgba(28,28,44,.78);--border:rgba(255,255,255,.08);
  --text:#f2f2fa;--muted:#a3a3bd;--code-bg:rgba(139,92,246,.18);--shadow:0 20px 60px -20px rgba(0,0,0,.6);
}}
*{box-sizing:border-box}
html,body{margin:0;padding:0}
body{
  min-height:100vh;background:var(--bg);color:var(--text);
  font:17px/1.5 -apple-system,BlinkMacSystemFont,"SF Pro Text","Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  -webkit-font-smoothing:antialiased;
}
.glow{position:fixed;inset:-30vh -20vw auto -20vw;height:70vh;z-index:0;pointer-events:none;
  background:radial-gradient(60% 60% at 30% 40%,rgba(88,86,246,.35),transparent 70%),
             radial-gradient(50% 50% at 70% 30%,rgba(34,211,238,.25),transparent 70%),
             radial-gradient(50% 60% at 55% 60%,rgba(139,92,246,.28),transparent 70%);
  filter:blur(20px)}
main{position:relative;z-index:1;max-width:560px;margin:0 auto;padding:48px 16px 40px}
.brand{display:flex;align-items:center;gap:12px;margin-bottom:28px}
.logo{width:44px;height:44px;border-radius:13px;flex:none;
  background:linear-gradient(135deg,var(--accent),var(--accent-2) 55%,var(--accent-3));
  box-shadow:0 8px 20px -6px rgba(88,86,246,.6);display:grid;place-items:center}
.logo svg{width:26px;height:26px}
.brand b{font-size:22px;letter-spacing:-.02em}
.card{background:var(--surface);border:1px solid var(--border);border-radius:24px;padding:24px;
  box-shadow:var(--shadow);-webkit-backdrop-filter:blur(24px) saturate(1.4);backdrop-filter:blur(24px) saturate(1.4)}
h1{font-size:28px;line-height:1.2;letter-spacing:-.02em;margin:0 0 8px}
h2{font-size:19px;margin:28px 0 6px;letter-spacing:-.01em}
p{margin:0 0 12px}
.muted{color:var(--muted)}
.small{font-size:14px}
.code{font:700 clamp(34px,11vw,52px)/1.1 ui-monospace,"SF Mono",Menlo,monospace;letter-spacing:.06em;
  text-align:center;margin:20px 0 6px;padding:18px 8px;border-radius:18px;background:var(--code-bg);
  word-break:break-all;user-select:all;-webkit-user-select:all}
.btn{display:block;width:100%;text-align:center;text-decoration:none;font-weight:600;font-size:17px;
  padding:15px 18px;border-radius:16px;margin-top:12px;border:1px solid var(--border);color:var(--text);background:var(--surface)}
.btn.primary{color:#fff;border:0;background:linear-gradient(135deg,var(--accent),var(--accent-2) 60%,#6d6af8);
  box-shadow:0 10px 24px -10px rgba(88,86,246,.8)}
.steps{margin:18px 0 0;padding-left:22px;color:var(--muted)}
.steps li{margin:4px 0}
.q{font-weight:600;font-size:19px;line-height:1.35;margin:0 0 14px;white-space:pre-wrap;overflow-wrap:anywhere}
.a{white-space:pre-wrap;overflow-wrap:anywhere}
.a code{font:15px ui-monospace,"SF Mono",Menlo,monospace;background:var(--code-bg);padding:1px 5px;border-radius:6px}
.by{display:flex;align-items:center;gap:8px;margin-top:18px;font-size:14px;color:var(--muted)}
.dot{width:8px;height:8px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--accent-3))}
ul.plain{padding-left:20px;margin:0 0 12px}
ul.plain li{margin:4px 0}
a{color:var(--accent)}
footer{margin-top:28px;text-align:center;font-size:13px;color:var(--muted)}
footer a{color:inherit}
`;

const LOGO = `<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M7.5 18.5h9a4.5 4.5 0 0 0 .6-8.96A6 6 0 0 0 5.6 11.1 3.75 3.75 0 0 0 7.5 18.5Z" fill="#fff"/></svg>`;

interface PageOptions {
  description?: string;
  ogTitle?: string;
  status?: number;
  cache?: string;
}

function page(title: string, body: string, opts: PageOptions = {}): Response {
  const description = opts.description ?? "Nimbus: an AI that lives in iMessage.";
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#5856F6">
<title>${escapeHtml(title)}</title>
<meta name="description" content="${escapeHtml(description)}">
<meta property="og:site_name" content="Nimbus">
<meta property="og:title" content="${escapeHtml(opts.ogTitle ?? title)}">
<meta property="og:description" content="${escapeHtml(description)}">
<meta name="robots" content="noindex">
<style>${CSS}</style>
</head>
<body>
<div class="glow"></div>
<main>
<div class="brand"><div class="logo">${LOGO}</div><b>Nimbus</b></div>
${body}
<footer><a href="/privacy">Privacy</a> · <a href="/terms">Terms</a> · <a href="/support">Support</a></footer>
</main>
</body>
</html>`;
  return new Response(html, {
    status: opts.status ?? 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": opts.cache ?? "no-store",
      "x-content-type-options": "nosniff",
      "referrer-policy": "no-referrer",
      "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; img-src data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
    },
  });
}

/** Only https TestFlight / App Store links are shown as a button. */
function safeHttpsUrl(value: string | undefined): string | null {
  if (!value) return null;
  try {
    const url = new URL(value.trim());
    return url.protocol === "https:" ? url.toString() : null;
  } catch {
    return null;
  }
}

/** GET /join/:code: invite landing page. */
export function joinPage(rawCode: string, host: string, testflightUrl: string | undefined): Response {
  let decoded = rawCode;
  try {
    decoded = decodeURIComponent(rawCode);
  } catch {
    // keep the raw text
  }
  const normalized = normalizeInviteCode(decoded);
  const shown = normalized ? formatInviteCode(normalized) : decoded.slice(0, 64);
  const deepLink = `nimbus://join?${new URLSearchParams({ code: shown, host }).toString()}`;
  const testflight = safeHttpsUrl(testflightUrl);

  const body = `
<div class="card">
  <h1>You're invited to Nimbus</h1>
  <p class="muted">Nimbus is an AI that lives in iMessage. Ask it anything, then send the answer straight into your chat.</p>
  <div class="code" aria-label="Invite code">${escapeHtml(shown)}</div>
  <p class="muted small" style="text-align:center">Your invite code${normalized ? "" : " (this doesn't look like a valid code; check the link)"}</p>
  ${testflight ? `<a class="btn primary" href="${escapeHtml(testflight)}">Install Nimbus from TestFlight</a>` : ""}
  <a class="btn${testflight ? "" : " primary"}" href="${escapeHtml(deepLink)}">Open Nimbus</a>
  <ol class="steps small">
    ${testflight ? "<li>Install Nimbus from TestFlight (get the TestFlight app first if asked).</li>" : "<li>Install Nimbus on your iPhone or iPad.</li>"}
    <li>Tap <b>Open Nimbus</b>, or open the app and type the code above.</li>
    <li>In Messages, tap <b>+</b> and choose <b>Nimbus</b>.</li>
  </ol>
</div>`;
  return page("Join Nimbus", body, {
    description: "You're invited to Nimbus, an AI that lives in iMessage.",
  });
}

/** Renders a tiny, safe Markdown subset (input is escaped first; only fixed tags are added). */
function renderAnswer(text: string): string {
  return escapeHtml(text)
    .split("\n")
    .map((line) =>
      line
        .replace(/^#{1,6}\s+(.*)$/, "<strong>$1</strong>")
        .replace(/^(\s*)[-*]\s+/, "$1• ")
        .replace(/\*\*([^*\n]+)\*\*/g, "<strong>$1</strong>")
        .replace(/`([^`\n]+)`/g, "<code>$1</code>"),
    )
    .join("\n")
    .replace(/^```[^\n]*\n?|\n?```$/gm, "");
}

export interface CardView {
  question: string;
  answer: string;
}

/** GET /c/:id: the web fallback for a Nimbus card bubble. */
export function cardPage(card: CardView): Response {
  const snippet = card.answer.length > 200 ? `${card.answer.slice(0, 199)}…` : card.answer;
  const body = `
<article class="card">
  ${card.question.trim() ? `<p class="q">${escapeHtml(card.question)}</p>` : ""}
  <div class="a">${renderAnswer(card.answer)}</div>
  <div class="by"><span class="dot"></span>Answered by Nimbus</div>
</article>`;
  return page(card.question.trim() ? `${card.question.slice(0, 80)} · Nimbus` : "Nimbus", body, {
    description: snippet,
    ogTitle: card.question.trim() || "Answered by Nimbus",
    cache: "public, max-age=3600",
  });
}

export function cardNotFoundPage(): Response {
  return page(
    "Card not found · Nimbus",
    `<div class="card"><h1>Card not found</h1><p class="muted">This Nimbus card doesn't exist or has been removed.</p></div>`,
    { status: 404 },
  );
}

export function homePage(): Response {
  return page(
    "Nimbus",
    `<div class="card"><h1>Nimbus server</h1><p class="muted">This server powers the Nimbus app. If you've been invited, open your invite link on your iPhone.</p></div>`,
  );
}

const EMAIL_RE = /^[^\s@<>"'()]+@[^\s@<>"'()]+\.[^\s@<>"'()]+$/;

/** How to reach the owner: a mailto link when SUPPORT_EMAIL is set, otherwise the inviter. */
function contactHtml(email: string): string {
  if (email && EMAIL_RE.test(email)) {
    return `<a href="mailto:${escapeHtml(email)}">${escapeHtml(email)}</a>`;
  }
  if (email) return escapeHtml(email);
  return "the person who sent you your invite (the owner of this Nimbus server)";
}

/** GET /privacy */
export function privacyPage(host: string, email: string): Response {
  const body = `
<div class="card">
  <h1>Privacy policy</h1>
  <p class="muted small">Applies to the Nimbus app, its iMessage extension and widgets, and the server at ${escapeHtml(host)}.</p>

  <h2>The short version</h2>
  <p>Your questions and any text you paste are sent to <b>Anthropic's Claude API</b> to generate answers. The Nimbus server doesn't keep your chats. It only stores what it needs to run invites and daily limits, plus anything you explicitly choose to share (a report or a card).</p>

  <h2>What is sent to generate answers</h2>
  <ul class="plain">
    <li>Your question and the earlier messages of that Nimbus conversation.</li>
    <li>Any text you paste or share into Nimbus, such as a conversation you want a reply to, explained or fact-checked.</li>
    <li>The style and where you asked from (the app, iMessage or Siri), so the answer is formatted correctly.</li>
  </ul>
  <p>This is sent over HTTPS to the Nimbus server, which forwards it to Anthropic's Claude API and streams the answer back. If web search is on, Claude may search the web to answer. Under Anthropic's commercial terms, data sent through the API is <b>not used to train their models</b>. Anthropic may keep API data for a limited time for safety and abuse monitoring, as described in its own privacy policy.</p>

  <h2>What the Nimbus server stores</h2>
  <ul class="plain">
    <li><b>Invite and account:</b> the name the owner gave your invite, the device name your app sent when you joined, when you joined and when you were last active. Your sign-in token is stored only as a one-way hash.</li>
    <li><b>Usage counters:</b> how many questions you asked each day, to enforce the daily limit.</li>
    <li><b>Reports:</b> if you tap Report on an answer, that conversation, the answer and your reason are stored so the owner can review it.</li>
    <li><b>Cards:</b> if you send an answer as a Nimbus card, the question and answer are stored so the card's link works for people who can't open iMessage apps (for example on a Mac). Anyone with the link can view that card.</li>
  </ul>
  <p>The server does <b>not</b> store your questions, pasted text or answers otherwise. Your chat history stays on your device. Cloudflare, which hosts the server, may briefly keep standard request logs with technical details like IP address and time.</p>

  <h2>What is not collected</h2>
  <p>No advertising, no tracking, no selling of data, no analytics SDKs. Nimbus can't read your Messages; it only sees text you type, paste or explicitly share into it.</p>

  <h2>Deleting your data</h2>
  <p>In the app, open Settings and tap <b>Delete my data</b>. That deletes your account, usage counters and the cards you created from the server straight away. Reports you sent are kept for moderation, without the link to your account. Deleting the app removes your chat history from your device. You can also ask the owner to delete your data.</p>

  <h2>Contact</h2>
  <p>Questions about privacy? Contact ${contactHtml(email)}.</p>
</div>`;
  return page("Privacy · Nimbus", body, { cache: "public, max-age=3600" });
}

/** GET /terms */
export function termsPage(host: string, email: string): Response {
  const body = `
<div class="card">
  <h1>Terms of use</h1>
  <p class="muted small">For the Nimbus app, its iMessage extension and widgets, and the server at ${escapeHtml(host)}. By using Nimbus you agree to these terms.</p>

  <h2>Invite only</h2>
  <p>Nimbus is a private service run by its owner for people they invite. Your invite is personal; don't share your access.</p>

  <h2>Zero tolerance for objectionable content and abuse</h2>
  <p>There is <b>zero tolerance</b> for objectionable or abusive content or users. Don't use Nimbus to create or send content that is sexual content involving minors, sexually explicit, hateful, harassing, bullying, threatening, violent, or that helps anyone cause serious harm or break the law. Don't use it to target, impersonate or deceive other people, and don't try to get around its safety limits.</p>
  <p>Misuse ends your access: the owner can revoke it at any time, without notice.</p>

  <h2>AI answers can be wrong</h2>
  <p>Answers are generated by AI (Anthropic's Claude) and can be inaccurate, incomplete or out of date. Check anything important, and don't rely on Nimbus for medical, legal, financial or safety decisions. You are responsible for what you send to other people.</p>

  <h2>Report anything objectionable</h2>
  <p>Every answer, including cards other people send you, has a <b>Report</b> action. Reports go to the owner, who reviews them within 24 hours and removes content or access as needed.</p>

  <h2>Your data</h2>
  <p>Your questions and pasted text are sent to Anthropic's Claude API to generate answers. See the <a href="/privacy">privacy policy</a> for what is stored and how to delete it.</p>

  <h2>No warranty</h2>
  <p>Nimbus is provided as is, without warranties, and may change or stop at any time. Daily limits apply.</p>

  <h2>Contact</h2>
  <p>Contact ${contactHtml(email)}.</p>
</div>`;
  return page("Terms · Nimbus", body, { cache: "public, max-age=3600" });
}

/** GET /support */
export function supportPage(host: string, email: string): Response {
  const body = `
<div class="card">
  <h1>Nimbus support</h1>
  <p class="muted">Help for the Nimbus app and its iMessage extension (server: ${escapeHtml(host)}).</p>

  <h2>Contact</h2>
  <p>Email ${contactHtml(email)} with questions or problems.</p>

  <h2>Report an answer</h2>
  <p>Touch and hold any Nimbus answer, or a Nimbus card someone sent you, and choose <b>Report</b>. Pick a reason and send. Reports go straight to the owner, who reviews them within 24 hours and removes content or access as needed.</p>

  <h2>Common questions</h2>
  <ul class="plain">
    <li><b>Where is Nimbus in Messages?</b> Open a conversation, tap <b>+</b>, then <b>More</b>, and choose <b>Nimbus</b>. Drag it up to keep it at the top.</li>
    <li><b>I hit my daily limit.</b> Limits reset at midnight UTC.</li>
    <li><b>My invite code doesn't work.</b> Codes look like <b>K7QM-2XPA</b> and can only be used a set number of times. Ask the person who invited you for a new one.</li>
    <li><b>How do I delete my data?</b> In the app, open Settings and tap <b>Delete my data</b>. See the <a href="/privacy">privacy policy</a>.</li>
  </ul>
  <p class="small muted">See also the <a href="/terms">terms of use</a>.</p>
</div>`;
  return page("Support · Nimbus", body, { cache: "public, max-age=3600" });
}
