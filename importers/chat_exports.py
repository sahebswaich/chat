#!/usr/bin/env python3
"""Turn ChatGPT and claude.ai data exports into one Markdown file per conversation.

Both apps export a .zip containing conversations.json:
  * ChatGPT:  Settings → Data controls → Export data (emailed link).
  * claude.ai: Settings → Privacy → Export data (emailed link).
Drop the .zip (or the extracted conversations.json) anywhere, then:

  python3 chat_exports.py ~/Downloads/chatgpt-export.zip --out "AI Inbox/ChatGPT"
  python3 chat_exports.py ~/Downloads/claude-export.zip --out "AI Inbox/Claude" --match crypto --match perp

--match keeps only conversations whose title or text contains any term (case-insensitive);
_index.json lists every conversation written with its date, title and which terms it hit.
The format (ChatGPT vs claude.ai) is detected automatically.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path


def load_conversations(path: Path) -> list[dict]:
    if path.suffix == ".zip":
        with zipfile.ZipFile(path) as z:
            names = [n for n in z.namelist() if n.endswith("conversations.json")]
            if not names:
                sys.exit(f"No conversations.json inside {path}")
            return json.loads(z.read(names[0]))
    return json.loads(path.read_text(encoding="utf-8"))


def ts(value) -> str:
    if value in (None, ""):
        return ""
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value, timezone.utc).isoformat()
    return str(value)


def chatgpt_messages(conv: dict) -> list[tuple[str, str, str]]:
    """Walks ChatGPT's message tree from the current node back to the root (the visible branch)."""
    mapping = conv.get("mapping") or {}
    node_id = conv.get("current_node")
    chain = []
    while node_id and node_id in mapping:
        node = mapping[node_id]
        msg = node.get("message")
        if msg and msg.get("content"):
            role = (msg.get("author") or {}).get("role", "")
            parts = msg["content"].get("parts") or []
            text = "\n".join(p if isinstance(p, str) else p.get("text", "") for p in parts if p).strip()
            if not text and msg["content"].get("text"):
                text = msg["content"]["text"]
            if text and role in ("user", "assistant"):
                chain.append((role, ts(msg.get("create_time")), text))
        node_id = node.get("parent")
    return list(reversed(chain))


def claude_messages(conv: dict) -> list[tuple[str, str, str]]:
    out = []
    for m in conv.get("chat_messages") or []:
        role = "user" if m.get("sender") == "human" else "assistant"
        text = m.get("text") or ""
        if not text:
            text = "\n".join(c.get("text", "") for c in m.get("content") or [] if c.get("type") == "text")
        for f in m.get("attachments") or []:
            if f.get("extracted_content"):
                text += f"\n\n[attachment: {f.get('file_name', 'file')}]\n{f['extracted_content']}"
        if text.strip():
            out.append((role, ts(m.get("created_at")), text.strip()))
    return out


def slug(text: str, n: int = 70) -> str:
    return (re.sub(r"[^A-Za-z0-9]+", "-", text).strip("-")[:n] or "untitled").lower()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("export", help=".zip from ChatGPT/claude.ai, or a conversations.json")
    ap.add_argument("--out", default="chat-export", help="output folder")
    ap.add_argument("--match", action="append", default=[], help="keep conversations containing this term (repeatable)")
    args = ap.parse_args()

    convs = load_conversations(Path(args.export).expanduser())
    out = Path(args.out).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    terms = [t.lower() for t in args.match]
    index = []
    for conv in convs:
        is_claude = "chat_messages" in conv
        source = "claude.ai" if is_claude else "ChatGPT"
        title = conv.get("name") or conv.get("title") or "Untitled"
        created = ts(conv.get("created_at") or conv.get("create_time"))
        msgs = claude_messages(conv) if is_claude else chatgpt_messages(conv)
        if not msgs:
            continue
        haystack = (title + "\n" + "\n".join(t for _, _, t in msgs)).lower()
        hits = [t for t in terms if t in haystack]
        if terms and not hits:
            continue
        conv_id = conv.get("uuid") or conv.get("id") or conv.get("conversation_id") or slug(title)
        name = f"{created[:10] or 'undated'}__{slug(title)}__{str(conv_id)[:8]}.md"
        body = [f"# {title}", "", f"- **Source:** {source}", f"- **Started:** {created}", f"- **Id:** {conv_id}", ""]
        for role, when, text in msgs:
            body += [f"## {'You' if role == 'user' else 'Assistant'}" + (f" · {when[:16]}" if when else ""), "", text, ""]
        (out / name).write_text("\n".join(body), encoding="utf-8")
        index.append({"file": name, "title": title, "source": source, "started": created, "messages": len(msgs), "hits": hits})
    index.sort(key=lambda r: r["started"], reverse=True)
    (out / "_index.json").write_text(json.dumps(index, indent=2), encoding="utf-8")
    print(f"Wrote {len(index)} conversation(s) to {out}")


if __name__ == "__main__":
    main()
