#!/usr/bin/env python3
"""Single-file edition of the Operating Room home page (no server needed).

    python3 scripts/build_home_artifact.py OUT.html [--treatise-url URL] [--terminal-url URL]

Inlines public/assets/room.css and home.js and embeds public/data/*.json as window.ROOM_DATA,
so the page works as a standalone shareable page. Run build_treatise.py first.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBLIC = ROOT / "public"

EDGE_CSS = """
body { padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); }
body::before { content: ""; position: fixed; inset: 0 0 auto; height: env(safe-area-inset-top, 0px); z-index: 31; background: var(--bg); }
.top { top: env(safe-area-inset-top, 0px); margin-left: calc(-1 * max(16px, env(safe-area-inset-left, 0px))); margin-right: calc(-1 * max(16px, env(safe-area-inset-right, 0px))); padding-left: max(24px, env(safe-area-inset-left, 0px)); padding-right: max(24px, env(safe-area-inset-right, 0px)); }
.home { padding-left: 0; padding-right: 0; }
.drawer { padding-top: calc(22px + env(safe-area-inset-top, 0px)); padding-right: max(24px, env(safe-area-inset-right, 0px)); padding-bottom: calc(40px + env(safe-area-inset-bottom, 0px)); }
.drawer .close { top: calc(14px + env(safe-area-inset-top, 0px)); right: max(14px, env(safe-area-inset-right, 0px)); }
@media (prefers-reduced-motion: reduce) { .drawer, .scrim, .tile { transition: none; } }
"""


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--treatise-url")
    ap.add_argument("--terminal-url")
    args = ap.parse_args()

    page = (PUBLIC / "index.html").read_text(encoding="utf-8")
    fonts = re.search(r'<link href="(https://fonts\.googleapis\.com/[^"]+)" rel="stylesheet">', page).group(1)
    body = page[page.index("<body>") + 6 : page.index('<script type="module"')]
    css = (PUBLIC / "assets" / "room.css").read_text(encoding="utf-8")
    js = (PUBLIC / "assets" / "home.js").read_text(encoding="utf-8")
    data = {
        "session": {"signedIn": False},
        "config": {"roomName": "Operating Room", "terminalUrl": args.terminal_url, "treatiseUrl": args.treatise_url},
        "vision": json.loads((PUBLIC / "data" / "vision.json").read_text(encoding="utf-8")),
        "orgs": json.loads((PUBLIC / "data" / "orgs.json").read_text(encoding="utf-8")),
        "pods": json.loads((PUBLIC / "data" / "pods.json").read_text(encoding="utf-8")),
    }
    payload = json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
    if args.treatise_url:
        body = body.replace('href="/treatise/"', f'href="{args.treatise_url}"')
    html = f"""<title>Operating Room</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="{fonts}">
<style>{css}{EDGE_CSS}</style>
{body}
<script>window.ROOM_DATA = {payload};</script>
<script type="module">{js}</script>
"""
    Path(args.out).write_text(html, encoding="utf-8")
    print(f"wrote {args.out} ({len(html):,} bytes)")


if __name__ == "__main__":
    main()
