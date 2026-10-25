#!/usr/bin/env python3
"""Build the Prime Treatise from treatise/*.md into paper pages.

    python3 scripts/build_treatise.py [--artifact OUT.html]

Reads treatise/ch*.md (one chapter per file, in filename order), treatise/vision.json and
treatise/pods/*.json. Writes:
  public/treatise/index.html   the Operating Room edition (print → PDF, discussion threads)
  public/data/vision.json      home-page hero, stats and eras
  public/data/pods.json        home-page pods (merged, ordered)
  --artifact OUT.html          a self-contained edition (inline CSS/JS, no print button) for sharing

Markdown dialect: GitHub tables, "## Title {#id}" anchors, and callouts written as blockquotes
starting with [!number], [!quote] or [!tension] (see treatise/README.md).
Needs: pip install markdown
"""

from __future__ import annotations

import argparse
import html
import json
import re
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "treatise"
PAPER_CSS = ROOT / "public" / "assets" / "paper.css"

ROMAN = re.compile(r"^(?P<num>[IVXLC]+)\.\s+(?P<title>.+)$")
APPX = re.compile(r"^Appendix (?P<num>[A-Z])\.\s+(?P<title>.+)$")


def render_markdown(text: str) -> str:
    md = markdown.Markdown(extensions=["tables", "attr_list", "sane_lists"], output_format="html")
    out = md.convert(text)
    out = re.sub(r"<table>", '<div class="tbl-wrap"><table>', out)
    out = re.sub(r"</table>", "</table></div>", out)
    out = re.sub(r"<p><em>(Sources?:.*?)</em></p>", r'<p class="source"><em>\1</em></p>', out, flags=re.S)
    out = re.sub(r"<li>\s*\[ \]\s*", '<li class="task"><span class="box" aria-hidden="true">☐</span> ', out)
    out = re.sub(r"<li>\s*\[[xX]\]\s*", '<li class="task done"><span class="box" aria-hidden="true">☑</span> ', out)
    return re.sub(r"<blockquote>(.*?)</blockquote>", callouts, out, flags=re.S)


CALLOUT_P = re.compile(r"<p>\[!(number|quote|tension)\]\s*(.*?)</p>", re.S)


def callouts(m: re.Match) -> str:
    """A blockquote may hold several callouts (Markdown merges adjacent ones); split them.
    Paragraphs after a callout's first line stay with that callout as context."""
    inner = m.group(1).strip()
    if not CALLOUT_P.match(inner):
        return m.group(0)
    out, pos = [], 0
    starts = list(CALLOUT_P.finditer(inner))
    for i, c in enumerate(starts):
        end = starts[i + 1].start() if i + 1 < len(starts) else len(inner)
        out.append(callout(c.group(1), c.group(2).strip(), inner[c.end():end].strip()))
    return "".join(out)


def callout(kind: str, first: str, rest: str) -> str:
    lines = [ln.strip() for ln in re.split(r"<br\s*/?>|\n", first) if ln.strip()]
    if kind == "number":
        head = lines[0] if lines else ""
        value, _, label = head.partition(" — ")
        context = " ".join(lines[1:]) + rest
        ctx = f'<span class="c">{context}</span>' if context.strip() else ""
        return f'<div class="callout number"><span class="v">{value.strip()}</span><span class="l">{label.strip()}</span>{ctx}</div>'
    if kind == "quote":
        body = " ".join(lines)
        quote, sep, who = body.rpartition(" — ")
        if not sep:
            quote, who = body, ""
        who_html = f'<span class="who">— {who}</span>' if who else ""
        return f'<div class="callout quote">{quote}{who_html}{rest}</div>'
    return f'<div class="callout tension">{" ".join(lines)}{rest}</div>'


def chapter_meta(path: Path, text: str) -> dict:
    key = re.sub(r"^ch\d+_", "", path.stem)
    first = next((ln for ln in text.splitlines() if ln.startswith("# ")), "# " + key)
    title = re.sub(r"\s*\{#[^}]+\}\s*$", "", first[2:]).strip()
    m_id = re.search(r"\{#([a-z0-9-]+)\}\s*$", first)
    if m_id:
        key = m_id.group(1)
    kicker = ""
    if m := ROMAN.match(title):
        kicker, title = f"Chapter {m.group('num')}", m.group("title")
    elif m := APPX.match(title):
        kicker, title = f"Appendix {m.group('num')}", m.group("title")
    body = text.replace(first, "", 1).replace("<!-- END CHAPTER -->", "")
    words = len(re.findall(r"[A-Za-z0-9$%]+", body))
    return {"key": key, "kicker": kicker, "title": title, "body": body, "words": words}


def build_pages(chapters: list[dict], vision: dict) -> str:
    toc_items = "".join(
        f'<li><span class="n">{html.escape(c["kicker"].replace("Chapter ", "").replace("Appendix ", "App. "))}</span>'
        f'<a href="#{c["key"]}">{html.escape(c["title"])}</a><span class="w">{c["words"]:,} words</span></li>'
        for c in chapters
    )
    total = sum(c["words"] for c in chapters)
    stats = "".join(
        f'<div class="callout number"><span class="v">{html.escape(s["value"])}</span><span class="l">{html.escape(s["label"])}</span></div>'
        for s in vision.get("cover_stats", vision.get("stats", []))[:4]
    )
    cover = f"""<article class="paper cover" id="cover">
<p class="cover-kicker">{html.escape(vision.get("kicker", "The unified vision"))}</p>
<h1 class="cover-title">X → ∞</h1>
<p class="cover-sub">The Prime Treatise</p>
<p class="cover-by">Saheb Swaich · compiled {html.escape(vision.get("compiled", ""))} · {len(chapters)} parts · {total:,} words</p>
<p class="cover-abstract">{html.escape(vision.get("abstract", vision.get("thesis", "")))}</p>
<div class="cover-stats">{stats}</div>
<nav class="toc" aria-label="Contents"><h2 id="contents">Contents</h2><ol>{toc_items}</ol></nav>
<div class="folio">X → ∞ · The Prime Treatise</div>
</article>"""
    parts = [cover]
    for c in chapters:
        h1 = f'<h1 id="{c["key"]}-title">' + (f'<span class="kicker">{html.escape(c["kicker"])}</span>' if c["kicker"] else "") + f'{html.escape(c["title"])}</h1>'
        parts.append(
            f'<article class="paper" id="{c["key"]}" data-title="{html.escape(c["title"])}">{h1}\n{render_markdown(c["body"])}\n'
            f'<div class="folio">X → ∞ · {html.escape(c["kicker"] or c["title"])}</div></article>'
        )
    return "\n".join(parts)


EXTRA_CSS = """
.cover { text-align: left; }
.cover-kicker { font: 600 12.5px/1 var(--sans); letter-spacing: 0.24em; text-transform: uppercase; color: var(--accent); margin: 0 0 30px; }
.cover-title { font: 400 clamp(64px, 12vw, 128px)/0.9 var(--display) !important; letter-spacing: -0.03em; margin: 0 0 6px !important; }
.cover-sub { font: italic 400 30px/1.2 var(--serif); margin: 0 0 26px; color: var(--ink-2); }
.cover-by { font: 500 14px/1.4 var(--sans); letter-spacing: 0.04em; color: var(--ink-2); border-top: 1px solid var(--ink); border-bottom: 1px solid var(--rule); padding: 10px 0; }
.cover-abstract { font: 400 19px/1.55 var(--serif); margin: 22px 0; }
.cover-stats { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; margin: 18px 0 8px; }
.cover-stats .callout { margin: 0; }
.cover .toc li .n { width: 52px; flex: none; }
.cover .toc h2 { font: 600 13px/1 var(--sans); letter-spacing: 0.18em; text-transform: uppercase; color: var(--ink-2); margin-top: 40px; }
.paper li.task { list-style: none; margin-left: -22px; }
.paper li.task .box { font-family: var(--sans); color: var(--accent); }
.progress { position: fixed; left: 0; right: 0; top: 0; height: 3px; z-index: 20; pointer-events: none; }
.progress span { display: block; height: 100%; width: 0; background: var(--accent); }
.paper-toolbar .tb-title { font: 400 18px/1 var(--display); color: var(--ink); white-space: nowrap; }
.paper-toolbar .tb-group { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; justify-content: flex-end; }
.paper-toolbar select, .paper-toolbar input[type="search"] { font: 14px var(--sans); border: 1px solid var(--desk-line); border-radius: 7px; padding: 7px 9px; background: var(--paper); color: var(--ink); max-width: 220px; }
.paper-toolbar .count { font: 12.5px var(--mono); color: var(--ink); background: var(--paper); border-radius: 6px; padding: 4px 8px; }
mark.hit { background: #ffe58a; color: inherit; padding: 0 1px; border-radius: 2px; }
mark.hit.now { background: #ffb02e; outline: 2px solid #ffb02e; }
@media screen and (max-width: 700px) { .cover-stats { grid-template-columns: 1fr; } .paper-toolbar .tb-title { display: none; } }
@media print { .progress { display: none; } }
"""

SCRIPT = """
(() => {
  const papers = [...document.querySelectorAll('.paper')];
  const jump = document.getElementById('jump');
  if (jump) {
    jump.innerHTML = '<option value="">Go to…</option>' + papers.filter(p => p.id !== 'cover').map(p => {
      const k = p.querySelector('h1 .kicker');
      return `<option value="${p.id}">${k ? k.textContent + ' · ' : ''}${p.dataset.title || p.id}</option>`;
    }).join('');
    jump.addEventListener('change', () => { if (jump.value) document.getElementById(jump.value).scrollIntoView({ behavior: 'smooth' }); });
  }
  const bar = document.querySelector('.progress span');
  const onScroll = () => {
    const h = document.documentElement.scrollHeight - innerHeight;
    if (bar) bar.style.width = (h > 0 ? (scrollY / h) * 100 : 0) + '%';
  };
  addEventListener('scroll', onScroll, { passive: true }); onScroll();

  const find = document.getElementById('find');
  const count = document.getElementById('findCount');
  let hits = [], at = -1, timer;
  function clear() {
    for (const m of document.querySelectorAll('mark.hit')) m.replaceWith(document.createTextNode(m.textContent));
    for (const p of papers) p.normalize();
    hits = []; at = -1;
  }
  function search(q) {
    clear();
    if (q.length < 2) { count.hidden = true; return; }
    const re = new RegExp(q.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&'), 'gi');
    for (const p of papers) {
      const walker = document.createTreeWalker(p, NodeFilter.SHOW_TEXT, { acceptNode: n => n.parentElement.closest('script,style,.discuss-btn') ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT });
      const nodes = []; let n; while ((n = walker.nextNode())) nodes.push(n);
      for (const node of nodes) {
        const text = node.nodeValue; re.lastIndex = 0;
        if (!re.test(text)) continue;
        const frag = document.createDocumentFragment(); let last = 0; re.lastIndex = 0; let m;
        while ((m = re.exec(text))) {
          frag.append(text.slice(last, m.index));
          const mark = document.createElement('mark'); mark.className = 'hit'; mark.textContent = m[0];
          frag.append(mark); hits.push(mark); last = m.index + m[0].length;
          if (hits.length > 2000) break;
        }
        frag.append(text.slice(last)); node.replaceWith(frag);
        if (hits.length > 2000) break;
      }
    }
    count.hidden = false;
    count.textContent = hits.length ? `${hits.length} found · Enter for next` : 'No matches';
    if (hits.length) next();
  }
  function next() {
    if (!hits.length) return;
    hits[at]?.classList.remove('now');
    at = (at + 1) % hits.length;
    hits[at].classList.add('now');
    hits[at].scrollIntoView({ block: 'center', behavior: 'smooth' });
    count.textContent = `${at + 1} of ${hits.length} · Enter for next`;
  }
  if (find) {
    find.addEventListener('input', () => { clearTimeout(timer); timer = setTimeout(() => search(find.value.trim()), 250); });
    find.addEventListener('keydown', e => { if (e.key === 'Enter') { e.preventDefault(); next(); } });
  }
  document.querySelector('[data-print]')?.addEventListener('click', () => window.print());
  if (location.hash.length > 1) document.getElementById(location.hash.slice(1))?.scrollIntoView();
})();
"""


def site_edition(pages: str) -> str:
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>The Prime Treatise</title>
<link rel="stylesheet" href="/assets/paper.css">
<style>{EXTRA_CSS}</style>
</head>
<body class="paper-desk">
<div class="progress"><span></span></div>
<header class="paper-toolbar no-print">
  <a href="/">← Room</a>
  <span class="tb-title">X → ∞ · The Prime Treatise</span>
  <div class="tb-group">
    <select id="jump" aria-label="Go to chapter"></select>
    <input id="find" type="search" placeholder="Search the treatise" aria-label="Search the treatise">
    <span id="findCount" class="count" hidden></span>
    <button type="button" data-print>Save as PDF</button>
  </div>
</header>
<main>
{pages}
</main>
<script>{SCRIPT}</script>
<script src="/assets/discussion.js" defer></script>
</body>
</html>
"""


def artifact_edition(pages: str) -> str:
    css = PAPER_CSS.read_text(encoding="utf-8")
    font_import = re.search(r'@import url\("([^"]+)"\);', css)
    css = re.sub(r'@import url\("[^"]+"\);\n?', "", css).replace("body.paper-desk", "body")
    shell_css = """
body { padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); }
body::before { content: ""; position: fixed; inset: 0 0 auto; height: env(safe-area-inset-top, 0px); z-index: 10; background: var(--desk); }
.paper-toolbar { top: env(safe-area-inset-top, 0px); margin-left: calc(-1 * max(16px, env(safe-area-inset-left, 0px))); margin-right: calc(-1 * max(16px, env(safe-area-inset-right, 0px))); padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); }
.paper { width: min(860px, 100%); }
@media screen and (max-width: 700px) { body { padding-left: 0; padding-right: 0; } .paper-toolbar { margin: 0; } .paper { padding-left: max(18px, env(safe-area-inset-left, 0px)); padding-right: max(18px, env(safe-area-inset-right, 0px)); } }
@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }
"""
    fonts = f'<link rel="stylesheet" href="{font_import.group(1)}">' if font_import else ""
    return f"""<title>The Prime Treatise</title>
<meta name="claude:viewport-fit-sides" content="cover">
{fonts}
<style>{css}{EXTRA_CSS}{shell_css}</style>
<div class="progress"><span></span></div>
<header class="paper-toolbar">
  <span class="tb-title">X → ∞ · The Prime Treatise</span>
  <div class="tb-group">
    <select id="jump" aria-label="Go to chapter"></select>
    <input id="find" type="search" placeholder="Search the treatise" aria-label="Search the treatise">
    <span id="findCount" class="count" hidden></span>
  </div>
</header>
<main>
{pages}
</main>
<script>{SCRIPT}</script>
"""


def merge_pods() -> list[dict]:
    order = json.loads((SRC / "pods" / "_order.json").read_text()) if (SRC / "pods" / "_order.json").exists() else []
    pods: dict[str, dict] = {}
    for f in sorted((SRC / "pods").glob("*.json")):
        if f.name.startswith("_"):
            continue
        for p in json.loads(f.read_text(encoding="utf-8")):
            pods.setdefault(p["id"], p)
    ranked = [pods.pop(i) for i in order if i in pods]
    return ranked + list(pods.values())


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--artifact", help="also write a self-contained edition to this path")
    args = ap.parse_args()
    vision = json.loads((SRC / "vision.json").read_text(encoding="utf-8"))
    chapters = [chapter_meta(p, p.read_text(encoding="utf-8")) for p in sorted(SRC.glob("ch*.md"))]
    pages = build_pages(chapters, vision)
    out = ROOT / "public" / "treatise" / "index.html"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(site_edition(pages), encoding="utf-8")
    data = ROOT / "public" / "data"
    data.mkdir(parents=True, exist_ok=True)
    (data / "vision.json").write_text(json.dumps(vision, indent=1, ensure_ascii=False), encoding="utf-8")
    pods = merge_pods()
    (data / "pods.json").write_text(json.dumps(pods, indent=1, ensure_ascii=False), encoding="utf-8")
    if args.artifact:
        Path(args.artifact).write_text(artifact_edition(pages), encoding="utf-8")
    print(f"{len(chapters)} chapters, {sum(c['words'] for c in chapters):,} words, {len(pods)} pods → {out}")


if __name__ == "__main__":
    main()
