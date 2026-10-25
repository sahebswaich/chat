// Server-rendered pages: sign-in and simple notices. Everything else is static in public/.

import { escapeHtml } from "./util";

function shell(title: string, body: string, status = 200): Response {
  return new Response(
    `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${escapeHtml(title)}</title>
<link rel="stylesheet" href="/assets/room.css">
</head>
<body class="gate">
${body}
</body>
</html>`,
    { status, headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" } },
  );
}

export function loginPage(roomName: string, next: string): Response {
  const safeNext = next.startsWith("/") && !next.startsWith("//") ? next : "/";
  return shell(
    roomName,
    `<main class="gate-card">
  <div class="gate-mark" aria-hidden="true">X<sup>∞</sup></div>
  <h1>${escapeHtml(roomName)}</h1>
  <p class="muted">Private. Enter the password.</p>
  <form id="login" autocomplete="on">
    <input type="password" name="password" placeholder="Password" autocomplete="current-password" required autofocus>
    <button type="submit">Enter</button>
    <p class="error" role="alert" hidden></p>
  </form>
  <p class="muted small">Got a share link? Open it directly — no password needed.</p>
</main>
<script>
const form = document.getElementById("login");
const err = form.querySelector(".error");
form.addEventListener("submit", async (e) => {
  e.preventDefault();
  err.hidden = true;
  const res = await fetch("/login", { method: "POST", headers: { "content-type": "application/json" },
    body: JSON.stringify({ password: form.password.value }) });
  if (res.ok) { location.href = ${JSON.stringify(safeNext)}; return; }
  const data = await res.json().catch(() => ({}));
  err.textContent = data?.error?.message ?? "Could not sign in.";
  err.hidden = false;
});
</script>`,
  );
}

export function noticePage(title: string, message: string, status: number): Response {
  return shell(
    title,
    `<main class="gate-card">
  <div class="gate-mark" aria-hidden="true">X<sup>∞</sup></div>
  <h1>${escapeHtml(title)}</h1>
  <p class="muted">${escapeHtml(message)}</p>
  <p><a href="/">Go to the room</a></p>
</main>`,
    status,
  );
}
