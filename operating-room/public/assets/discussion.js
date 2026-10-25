// Discussion threads for paper pages: a badge beside every section heading (h2[id]) opens that
// section's thread. Works for the owner and for share-link guests; quietly does nothing on
// public pages opened without a session.
(() => {
  const page = location.pathname.replace(/\/index\.html$/, "").replace(/\/$/, "") || "/";
  const NAME_KEY = "room.discussionName";
  let comments = [];
  let canComment = false;
  let isOwner = false;
  let openAnchor = null;

  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const when = (iso) => new Date(iso).toLocaleString("en-US", { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
  const getName = () => {
    try {
      return localStorage.getItem(NAME_KEY) ?? "";
    } catch {
      return "";
    }
  };
  const setName = (v) => {
    try {
      localStorage.setItem(NAME_KEY, v);
    } catch {
      /* ignore */
    }
  };

  const panel = document.createElement("aside");
  panel.className = "thread";
  panel.setAttribute("aria-label", "Discussion");
  panel.innerHTML = `<header><b></b><button type="button" aria-label="Close">Close</button></header><div class="msgs"></div><div class="foot"></div>`;
  panel.querySelector("header button").addEventListener("click", () => close());

  function close() {
    panel.classList.remove("open");
    openAnchor = null;
  }

  function sectionTitle(anchor) {
    const h = document.getElementById(anchor);
    return h ? h.textContent.replace(/\s*💬.*$/, "").trim() : "Whole page";
  }

  function renderBadges() {
    for (const btn of document.querySelectorAll(".discuss-btn")) {
      const n = comments.filter((c) => c.anchor === btn.dataset.anchor && !c.resolvedAt).length;
      btn.textContent = n ? `💬 ${n}` : "💬";
      btn.classList.toggle("has", n > 0);
    }
  }

  function renderThread() {
    if (openAnchor === null) return;
    panel.querySelector("header b").textContent = sectionTitle(openAnchor);
    const mine = comments.filter((c) => c.anchor === openAnchor);
    const roots = mine.filter((c) => !c.parentId);
    const rows = [];
    for (const r of roots) {
      rows.push(r);
      rows.push(...mine.filter((c) => c.parentId === r.id).map((c) => ({ ...c, reply: true })));
    }
    panel.querySelector(".msgs").innerHTML =
      rows
        .map(
          (c) => `<div class="msg${c.reply ? " reply" : ""}${c.resolvedAt ? " resolved" : ""}"><span class="who">${esc(c.author)}</span><span class="when">${when(c.createdAt)}${c.resolvedAt ? " · resolved" : ""}</span>
          <p>${esc(c.body)}</p><div class="acts">${canComment && !c.reply ? `<button data-reply="${esc(c.id)}">Reply</button>` : ""}${isOwner && !c.resolvedAt && !c.reply ? `<button data-resolve="${esc(c.id)}">Resolve</button>` : ""}</div></div>`,
        )
        .join("") || `<p class="muted" style="color:#8b867b">No comments on this section yet.</p>`;
    const foot = panel.querySelector(".foot");
    if (!canComment) {
      foot.innerHTML = `<div class="ro">View-only link — you can read the discussion.</div>`;
      return;
    }
    foot.innerHTML = `<form><input name="author" placeholder="Your name" maxlength="60" ${isOwner ? 'hidden value="Owner"' : ""} value="${esc(getName())}"><input type="hidden" name="parentId"><div class="replying" hidden></div><textarea name="body" placeholder="Add to the discussion…" maxlength="8000" required></textarea><button type="submit">Post</button></form>`;
  }

  panel.addEventListener("click", async (e) => {
    const reply = e.target.closest("[data-reply]");
    const resolve = e.target.closest("[data-resolve]");
    const form = panel.querySelector("form");
    if (reply && form) {
      form.parentId.value = reply.dataset.reply;
      const box = form.querySelector(".replying");
      box.hidden = false;
      box.textContent = "Replying to a comment";
      form.body.focus();
    }
    if (resolve) {
      await fetch(`/api/comments/${encodeURIComponent(resolve.dataset.resolve)}/resolve`, { method: "POST" });
      await load();
    }
  });

  panel.addEventListener("submit", async (e) => {
    e.preventDefault();
    const f = e.target;
    const author = f.author.value.trim();
    if (!isOwner) setName(author);
    const res = await fetch("/api/comments", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ page, anchor: openAnchor, author, body: f.body.value, ...(f.parentId.value ? { parentId: f.parentId.value } : {}) }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      alert(data?.error?.message ?? "Could not post.");
      return;
    }
    await load();
  });

  function open(anchor) {
    openAnchor = anchor;
    renderThread();
    panel.classList.add("open");
  }

  async function load() {
    const res = await fetch(`/api/comments?page=${encodeURIComponent(page)}`);
    if (!res.ok) return false;
    const data = await res.json();
    comments = data.comments;
    canComment = data.canComment;
    isOwner = data.isOwner;
    renderBadges();
    renderThread();
    return true;
  }

  async function init() {
    const ok = await load();
    if (!ok) return;
    document.body.appendChild(panel);
    for (const h of document.querySelectorAll(".paper h2[id], .paper h1[id]")) {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "discuss-btn no-print";
      btn.dataset.anchor = h.id;
      btn.title = "Discuss this section";
      btn.addEventListener("click", () => open(h.id));
      h.appendChild(btn);
    }
    renderBadges();
    const hash = new URLSearchParams(location.hash.slice(1)).get("discuss");
    if (hash) open(hash);
    setInterval(() => {
      if (document.visibilityState === "visible") load();
    }, 20000);
  }

  window.roomDiscussion = { open };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
