// Renders a published markdown page into the paper template (see publish.ts), using the same
// callout conventions as the treatise: "> [!number] value — label", "> [!quote] …", "> [!tension] …".
(() => {
  const data = JSON.parse(document.getElementById("pub").textContent);
  const slug = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 60);
  let md = data.markdown;
  // "## Title {#id}" → keep the id as a marker the renderer leaves alone.
  md = md.replace(/^(#{1,3} .*?)\s*\{#([a-z0-9-]+)\}\s*$/gm, (_, h, id) => `${h} [[id:${id}]]`);
  const html = window.marked.parse(md, { gfm: true });
  const doc = document.getElementById("doc");
  doc.innerHTML = window.DOMPurify.sanitize(html);
  for (const h of doc.querySelectorAll("h1, h2, h3")) {
    const m = /\[\[id:([a-z0-9-]+)\]\]/.exec(h.innerHTML);
    if (m) h.innerHTML = h.innerHTML.replace(m[0], "").trim();
    h.id = m ? m[1] : slug(h.textContent);
  }
  for (const bq of doc.querySelectorAll("blockquote")) {
    const first = bq.querySelector("p");
    const m = first && /^\[!(number|quote|tension)\]\s*/.exec(first.textContent);
    if (!m) continue;
    const kind = m[1];
    const div = document.createElement("div");
    div.className = `callout ${kind}`;
    const text = first.innerHTML.replace(/^\[!(number|quote|tension)\]\s*/, "");
    const rest = [...bq.children].slice(1).map((n) => n.outerHTML).join("");
    if (kind === "number") {
      const [v, ...l] = text.split(/\s+—\s+/);
      const lines = l.join(" — ").split(/<br\s*\/?>|\n/);
      div.innerHTML = `<span class="v">${v}</span><span class="l">${lines[0] ?? ""}</span>${lines.slice(1).join(" ") || rest ? `<span class="c">${lines.slice(1).join(" ")}${rest}</span>` : ""}`;
    } else if (kind === "quote") {
      const parts = text.split(/\s+—\s+(?=[^—]*$)/);
      div.innerHTML = `${parts[0]}${parts[1] ? `<span class="who">— ${parts[1]}</span>` : ""}${rest}`;
    } else {
      div.innerHTML = text + rest;
    }
    bq.replaceWith(div);
  }
  for (const p of doc.querySelectorAll("p")) {
    if (/^Sources?:/i.test(p.textContent.trim()) && p.querySelector("em")) p.classList.add("source");
  }
  document.title = data.title;
  document.querySelector("[data-print]")?.addEventListener("click", () => window.print());
})();
